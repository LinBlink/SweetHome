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
    display_role VARCHAR(20)                              COMMENT '家庭称谓，如：爸、妈、爷爷、小明',
    joined_at    DATETIME(3)                    NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '加入时间',
    deleted_at   DATETIME(3)                             COMMENT '退出/被移除时间（软删除）',

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

-- 家庭成员关系
INSERT INTO family_members (family_id, user_id, role, display_role)
VALUES (1, 1, 'admin', '爸'),
       (1, 2, 'member', '妈');

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
