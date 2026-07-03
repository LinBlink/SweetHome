-- ═══════════════════════════════════════════════════════════════
-- 过家家 · Sweet Home — MySQL 建表方案
-- 数据库版本：MySQL 8.0+
-- 字符集：utf8mb4 + utf8mb4_unicode_ci（支持 emoji 和完整中文）
-- ═══════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS sweethome
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE sweethome;

-- ───────────────────────────────────────────────────────────────
-- 设计原则：
--   1. BIGINT UNSIGNED AUTO_INCREMENT 主键：比 UUID 连接查询更快
--   2. DATETIME(3)：毫秒精度，避免 TIMESTAMP 的 2038 年问题
--   3. 软删除（deleted_at）：保留审计记录，所有查询加 WHERE deleted_at IS NULL
--   4. utf8mb4_unicode_ci：支持 emoji 和 CJK 正确排序
--   5. 所有外键加索引，避免锁表风险
-- ───────────────────────────────────────────────────────────────


-- ════════════════════════════════════════
-- 表 1：users（用户）
-- ════════════════════════════════════════
CREATE TABLE users
(
    id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '用户 ID',
    phone         VARCHAR(20)      NOT NULL COMMENT '手机号（唯一登录凭证）',
    password_hash VARCHAR(255)     NOT NULL COMMENT 'BCrypt 加密后的密码',
    name          VARCHAR(50)      NOT NULL COMMENT '用户昵称',
    avatar_url    VARCHAR(500)              COMMENT '头像 OSS 地址',
    created_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                            ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at    DATETIME(3)               COMMENT '软删除时间戳，NULL 表示未删除',

    PRIMARY KEY (id),
    UNIQUE KEY uk_phone (phone),
    INDEX idx_deleted_at (deleted_at)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '用户表';


-- ════════════════════════════════════════
-- 表 2：families（家庭）
-- ════════════════════════════════════════
CREATE TABLE families
(
    id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '家庭 ID',
    name              VARCHAR(100)    NOT NULL COMMENT '家庭名称，如：王家',
    invite_code       VARCHAR(12)              COMMENT '8位邀请码（大写字母+数字）',
    invite_expires_at DATETIME(3)              COMMENT '邀请码过期时间',
    created_by        BIGINT UNSIGNED NOT NULL COMMENT '创建者 user_id（家庭管理员）',
    created_at        DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at        DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                              ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at        DATETIME(3)              COMMENT '软删除时间戳',

    PRIMARY KEY (id),
    UNIQUE KEY uk_invite_code (invite_code),
    INDEX idx_deleted_at (deleted_at),
    CONSTRAINT fk_families_created_by
        FOREIGN KEY (created_by) REFERENCES users (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '家庭表';


-- ════════════════════════════════════════
-- 表 3：family_members（家庭成员关系）
-- ════════════════════════════════════════
CREATE TABLE family_members
(
    id           BIGINT UNSIGNED                NOT NULL AUTO_INCREMENT,
    family_id    BIGINT UNSIGNED                NOT NULL COMMENT '家庭 ID',
    user_id      BIGINT UNSIGNED                NOT NULL COMMENT '用户 ID',
    role         ENUM ('admin', 'member')        NOT NULL DEFAULT 'member' COMMENT '家庭角色：admin=管理员，member=成员',
    gender       ENUM ('male', 'female')        NOT NULL COMMENT '性别，亲属称谓计算的基础输入（父/母、兄弟/姐妹等由此区分）',
    birth_order  SMALLINT UNSIGNED                       COMMENT '同辈排行，数值越小越年长；NULL 表示未知（此时算法默认按年长处理），用于区分兄/弟、姐/妹',
    joined_at    DATETIME(3)                    NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '加入时间',
    deleted_at   DATETIME(3)                             COMMENT '退出/被移除时间（软删除）',
    -- 注：原 display_role（如"爸""妈"）字段已移除。它是固定中文文本、且对所有查看者显示相同内容，
    -- 不支持国际化，也无法表达"相对于查看者"的真实称谓（如爷爷看儿子应显示"儿子"而非"爸"）。
    -- 现改为 gender + birth_order + family_relations 关系图，由服务端按请求者身份 + Accept-Language
    -- 动态计算相对称谓，算法定义见 docs/api.md 「七、亲属称谓计算算法」。

    PRIMARY KEY (id),
    UNIQUE KEY uk_family_user (family_id, user_id),
    INDEX idx_family_id (family_id),
    INDEX idx_user_id (user_id),
    INDEX idx_deleted_at (deleted_at),
    CONSTRAINT fk_fm_family
        FOREIGN KEY (family_id) REFERENCES families (id),
    CONSTRAINT fk_fm_user
        FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '家庭成员关系表';


-- ════════════════════════════════════════
-- 表 4：conversations（会话）
-- ════════════════════════════════════════
CREATE TABLE conversations
(
    id              BIGINT UNSIGNED                  NOT NULL AUTO_INCREMENT COMMENT '会话 ID',
    type            ENUM ('group', 'direct')          NOT NULL COMMENT '会话类型：group=群聊，direct=私聊',
    name            VARCHAR(100)                              COMMENT '群聊名称；私聊为 NULL（查询时根据对方昵称动态生成）',
    family_id       BIGINT UNSIGNED                           COMMENT '所属家庭 ID；跨家庭私聊可为 NULL',
    last_message_id BIGINT UNSIGNED                           COMMENT '最新消息 ID（冗余字段，避免 JOIN）',
    last_message_at DATETIME(3)                               COMMENT '最新消息时间（用于列表排序）',
    created_at      DATETIME(3)                      NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at      DATETIME(3)                      NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                                              ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at      DATETIME(3)                               COMMENT '软删除时间戳',

    PRIMARY KEY (id),
    INDEX idx_family_id (family_id),
    INDEX idx_last_message_at (last_message_at DESC),
    INDEX idx_deleted_at (deleted_at),
    CONSTRAINT fk_conv_family
        FOREIGN KEY (family_id) REFERENCES families (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '聊天会话表（群聊 & 私聊）';


-- ════════════════════════════════════════
-- 表 5：conversation_members（会话成员）
-- ════════════════════════════════════════
CREATE TABLE conversation_members
(
    id                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    conversation_id      BIGINT UNSIGNED NOT NULL COMMENT '会话 ID',
    user_id              BIGINT UNSIGNED NOT NULL COMMENT '用户 ID',
    last_read_message_id BIGINT UNSIGNED          COMMENT '最后已读消息 ID（用于计算未读数）',
    last_read_at         DATETIME(3)              COMMENT '最后已读时间',
    joined_at            DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '加入会话时间',
    left_at              DATETIME(3)              COMMENT '退出会话时间（NULL 表示仍在）',

    PRIMARY KEY (id),
    UNIQUE KEY uk_conv_user (conversation_id, user_id),
    INDEX idx_user_id (user_id),
    INDEX idx_conversation_id (conversation_id),
    CONSTRAINT fk_cm_conversation
        FOREIGN KEY (conversation_id) REFERENCES conversations (id),
    CONSTRAINT fk_cm_user
        FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '会话成员表（记录每个用户的已读进度）';


-- ════════════════════════════════════════
-- 表 6：messages（消息）
-- ════════════════════════════════════════
-- 主要读取模式：WHERE conversation_id = ? AND id < ? ORDER BY id DESC LIMIT 50
-- 主要写入模式：INSERT ... ON DUPLICATE KEY（client_id 去重）
-- ════════════════════════════════════════
CREATE TABLE messages
(
    id              BIGINT UNSIGNED                            NOT NULL AUTO_INCREMENT COMMENT '消息 ID（服务端自增，全局有序）',
    conversation_id BIGINT UNSIGNED                            NOT NULL COMMENT '所属会话 ID',
    sender_id       BIGINT UNSIGNED                            NOT NULL COMMENT '发送者 user_id',
    type            ENUM ('text', 'image', 'voice', 'system') NOT NULL DEFAULT 'text' COMMENT '消息类型',
    content         TEXT                                       NOT NULL COMMENT 'text:消息内容; image/voice:OSS URL',
    client_id       VARCHAR(36)                                         COMMENT '客户端 UUID，用于乐观更新 echo 和重复投递去重',
    reply_to_id     BIGINT UNSIGNED                                     COMMENT '引用/回复的消息 ID（可选）',
    sent_at         DATETIME(3)                                NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '发送时间（客户端时间，服务端校验后存储）',
    deleted_at      DATETIME(3)                                         COMMENT '软删除（撤回）时间戳',

    PRIMARY KEY (id),
    UNIQUE KEY uk_client_id (client_id) COMMENT '防止重复投递，HTTP 兜底重试幂等',
    INDEX idx_conv_sent (conversation_id, sent_at DESC) COMMENT '核心分页查询索引',
    INDEX idx_sender_id (sender_id),
    INDEX idx_deleted_at (deleted_at),
    CONSTRAINT fk_msg_conv
        FOREIGN KEY (conversation_id) REFERENCES conversations (id),
    CONSTRAINT fk_msg_sender
        FOREIGN KEY (sender_id) REFERENCES users (id),
    CONSTRAINT fk_msg_reply
        FOREIGN KEY (reply_to_id) REFERENCES messages (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '消息表';


-- ════════════════════════════════════════
-- 表 7：refresh_tokens（刷新令牌）
-- ════════════════════════════════════════
CREATE TABLE refresh_tokens
(
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id     BIGINT UNSIGNED NOT NULL COMMENT '所属用户',
    token_hash  VARCHAR(255)    NOT NULL COMMENT '实际 Refresh Token 的 SHA-256 哈希（不存明文）',
    device_info VARCHAR(500)             COMMENT '设备信息（User-Agent / 设备名）',
    expires_at  DATETIME(3)     NOT NULL COMMENT 'Refresh Token 过期时间',
    created_at  DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    revoked_at  DATETIME(3)              COMMENT '主动吊销时间（登出时设置）',

    PRIMARY KEY (id),
    UNIQUE KEY uk_token_hash (token_hash),
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at),
    CONSTRAINT fk_rt_user
        FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Refresh Token 表（支持多设备登录）';


-- ════════════════════════════════════════
-- 表 8：family_relations（家庭亲属关系图）
-- 存储家庭成员之间的原始血亲/姻亲边（PARENT_OF 有向 + SPOUSE_OF 无向），
-- 是「相对称谓」算法的唯一数据来源——不存任何称谓文本，称谓由算法在
-- 每次请求时按查看者动态推导，详见 docs/api.md「七、亲属称谓计算算法」。
-- ════════════════════════════════════════
CREATE TABLE family_relations
(
    id                BIGINT UNSIGNED                  NOT NULL AUTO_INCREMENT,
    family_id         BIGINT UNSIGNED                  NOT NULL COMMENT '家庭 ID（冗余字段，便于按家庭批量取整张关系图）',
    subject_member_id BIGINT UNSIGNED                  NOT NULL COMMENT '关系主体 family_members.id',
    relation_type     ENUM ('PARENT_OF', 'SPOUSE_OF')  NOT NULL COMMENT 'PARENT_OF=subject 是 object 的父/母（有向）；SPOUSE_OF=互为配偶（无方向，写入时需规范化 subject_member_id < object_member_id 以防重复行）',
    object_member_id  BIGINT UNSIGNED                  NOT NULL COMMENT '关系客体 family_members.id',
    created_at        DATETIME(3)                      NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    deleted_at        DATETIME(3)                               COMMENT '软删除时间戳（如离婚、关系录入错误撤销）',

    PRIMARY KEY (id),
    UNIQUE KEY uk_relation (subject_member_id, relation_type, object_member_id),
    INDEX idx_family_id (family_id),
    INDEX idx_subject (subject_member_id),
    INDEX idx_object (object_member_id),
    CONSTRAINT fk_fr_family
        FOREIGN KEY (family_id) REFERENCES families (id),
    CONSTRAINT fk_fr_subject
        FOREIGN KEY (subject_member_id) REFERENCES family_members (id),
    CONSTRAINT fk_fr_object
        FOREIGN KEY (object_member_id) REFERENCES family_members (id),
    CONSTRAINT chk_fr_no_self
        CHECK (subject_member_id <> object_member_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '家庭成员关系图（血亲 PARENT_OF 有向边 + 姻亲 SPOUSE_OF 无向边）';


-- ════════════════════════════════════════
-- 表 9：family_join_requests（无邀请码的加入申请）
-- 申请人不知道邀请码，但知道家庭里某位成员（target_member）的手机号，
-- 提交申请后由该家庭管理员审批；批准后才真正创建 users/family_members/
-- family_relations 记录，与直接持邀请码加入（3.4）殊途同归。
-- 详见 docs/api.md「3.5 申请加入家庭（没有邀请码）」。
-- ════════════════════════════════════════
CREATE TABLE family_join_requests
(
    id                       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    family_id                BIGINT UNSIGNED NOT NULL COMMENT '目标家庭 ID（由 target_member_phone 反查得到）',
    target_member_id         BIGINT UNSIGNED NOT NULL COMMENT '申请人认识的已有家庭成员 family_members.id，作为关系锚点',
    requester_name           VARCHAR(50)     NOT NULL COMMENT '申请人昵称',
    requester_phone          VARCHAR(20)     NOT NULL COMMENT '申请人手机号，批准后用于创建 users 记录',
    requester_password_hash  VARCHAR(255)    NOT NULL COMMENT '申请时提交的密码（BCrypt），批准后直接复用，不要求二次输入',
    requester_gender         ENUM ('male', 'female') NOT NULL,
    relation_type            ENUM ('CHILD_OF', 'PARENT_OF', 'SPOUSE_OF', 'SIBLING_OF') NOT NULL COMMENT '申请人相对 target_member 的关系，语义同 family_relations 写入规则（docs/api.md §1.1/§3.4）',
    message                  VARCHAR(200)             COMMENT '申请人留言，供管理员审批参考',
    status                   ENUM ('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    created_at               DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    resolved_at              DATETIME(3)              COMMENT '审批/拒绝时间',
    resolved_by              BIGINT UNSIGNED          COMMENT '处理该申请的管理员 user_id',

    PRIMARY KEY (id),
    INDEX idx_family_id (family_id),
    INDEX idx_target_member (target_member_id),
    INDEX idx_status (status),
    INDEX idx_requester_phone (requester_phone),
    CONSTRAINT fk_fjr_family
        FOREIGN KEY (family_id) REFERENCES families (id),
    CONSTRAINT fk_fjr_target_member
        FOREIGN KEY (target_member_id) REFERENCES family_members (id),
    CONSTRAINT fk_fjr_resolved_by
        FOREIGN KEY (resolved_by) REFERENCES users (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '无邀请码的加入申请（凭已知家庭成员手机号发起，等待管理员审批）';


-- ═══════════════════════════════════════════════════════════════
-- 初始化数据（开发环境种子数据）
-- ═══════════════════════════════════════════════════════════════

-- 测试用户（密码：test123456，BCrypt 加密）
INSERT INTO users (id, phone, password_hash, name)
VALUES (1, '13800138000', '$2a$10$PlaceholderBcryptHashHere.AAAAAAAAAAAAAAAAAAAAAAAAAAAAa', '王建国'),
       (2, '13800138001', '$2a$10$PlaceholderBcryptHashHere.AAAAAAAAAAAAAAAAAAAAAAAAAAAAa', '张美玲');

-- 测试家庭
INSERT INTO families (id, name, created_by)
VALUES (1, '王家', 1);

-- 家庭成员关系（性别用于称谓计算；不再存任何称谓文本）
INSERT INTO family_members (id, family_id, user_id, role, gender)
VALUES (1, 1, 1, 'admin', 'male'),
       (2, 1, 2, 'member', 'female');

-- 家庭关系图：王建国与张美玲互为配偶
INSERT INTO family_relations (family_id, subject_member_id, relation_type, object_member_id)
VALUES (1, 1, 'SPOUSE_OF', 2);

-- 家庭群聊会话（注册时自动创建）
INSERT INTO conversations (id, type, name, family_id)
VALUES (1, 'group', '王家群聊', 1);

-- 群聊成员
INSERT INTO conversation_members (conversation_id, user_id)
VALUES (1, 1),
       (1, 2);


-- ═══════════════════════════════════════════════════════════════
-- 常用查询参考
-- ═══════════════════════════════════════════════════════════════

-- 获取用户的所有会话列表（按最新消息时间排序）
-- SELECT c.*, cm.last_read_message_id,
--        (SELECT COUNT(*) FROM messages m
--         WHERE m.conversation_id = c.id
--           AND m.id > COALESCE(cm.last_read_message_id, 0)
--           AND m.deleted_at IS NULL) AS unread_count
-- FROM conversations c
-- INNER JOIN conversation_members cm ON cm.conversation_id = c.id
-- WHERE cm.user_id = ? AND cm.left_at IS NULL AND c.deleted_at IS NULL
-- ORDER BY c.last_message_at DESC;

-- 分页加载消息历史（游标分页，性能稳定）
-- SELECT * FROM messages
-- WHERE conversation_id = ? AND id < ? AND deleted_at IS NULL
-- ORDER BY id DESC
-- LIMIT 50;

-- 定期清理过期的 Refresh Token（建议每日凌晨定时任务执行）
-- DELETE FROM refresh_tokens
-- WHERE expires_at < NOW() OR revoked_at IS NOT NULL;
