# 后端实现笔记：家庭加入/创建时的 family_relations 写入逻辑

> 这份笔记针对的是**独立的 Spring Boot 后端仓库**（不在本 Flutter 工作区内），记录 `FamiliesServiceImpl` 中 `joinFamily`/`createFamily` 应该如何根据注册请求的 `gender`/`relationToMemberId`/`relationType` 写入 `family_members` 和 `family_relations` 两张表。对应的 API 契约见 `docs/api.md` §1.1 与 §七，表结构见 `docs/schema.sql`。

## 完整实现

```java
package asia.sweethome.family.service.impl;

import asia.sweethome.chat.domain.po.Conversation;
import asia.sweethome.chat.domain.po.ConversationMember;
import asia.sweethome.chat.service.IConversationMembersService;
import asia.sweethome.chat.service.IConversationsService;
import asia.sweethome.common.constants.ConversationTypeConstants;
import asia.sweethome.common.constants.RelationTypeConstants;
import asia.sweethome.common.constants.RoleConstants;
import asia.sweethome.common.exception.BusinessException;
import asia.sweethome.common.exception.ErrorCode;
import asia.sweethome.family.domain.po.Family;
import asia.sweethome.family.domain.po.FamilyMemeber;
import asia.sweethome.family.domain.po.FamilyRelation;
import asia.sweethome.family.mapper.FamiliesMapper;
import asia.sweethome.family.service.IFamiliesService;
import asia.sweethome.family.service.IFamilyMembersService;
import asia.sweethome.family.service.IFamilyRelationsService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class FamiliesServiceImpl extends ServiceImpl<FamiliesMapper, Family> implements IFamiliesService {

    @Autowired
    private IFamilyMembersService familyMembersService;

    @Autowired
    private IFamilyRelationsService familyRelationsService;

    @Autowired
    private IConversationsService conversationsService;

    @Autowired
    private IConversationMembersService conversationMembersService;

    @Override
    @Transactional
    public Long joinFamily(
            Long userId,
            String inviteCode,
            String gender,
            Long relationToMemberId,
            String relationType
    ) {
        inviteCode = inviteCode.trim().toUpperCase();

        Family family = lambdaQuery().eq(Family::getInviteCode, inviteCode).one();
        if (family == null) {
            throw new BusinessException(ErrorCode.NO_SUCH_FAMILY);
        }

        LocalDateTime now = LocalDateTime.now();
        if (family.getInviteExpiresAt().isBefore(now)) {
            throw new BusinessException(ErrorCode.FAMILY_INVITE_CODE_EXPIRED);
        }

        Long familyId = family.getId();

        // relationToMemberId 必须属于同一个家庭，且未被软删除
        FamilyMemeber anchor = familyMembersService.lambdaQuery()
                .eq(FamilyMemeber::getId, relationToMemberId)
                .eq(FamilyMemeber::getFamilyId, familyId)
                .isNull(FamilyMemeber::getDeletedAt)
                .one();
        if (anchor == null) {
            throw new BusinessException(ErrorCode.INVALID_RELATION_ANCHOR);
        }

        // 0. 用户同一时刻只能属于一个家庭：若当前在其他家庭里还有未软删除的
        //    成员身份，先在同一事务内级联退出，再加入新家庭
        leaveCurrentFamilyIfAny(userId, familyId);

        // 1. 新成员加入 family_members
        FamilyMemeber newMember = new FamilyMemeber();
        newMember.setFamilyId(familyId);
        newMember.setUserId(userId);
        newMember.setRole(RoleConstants.FAMILY_MEMBER);
        newMember.setGender(gender);
        newMember.setJoinedAt(now);
        boolean memberSaved = familyMembersService.save(newMember);
        if (!memberSaved) {
            throw new BusinessException(ErrorCode.FAMILY_SAVE_FAILURE);
        }
        Long newMemberId = newMember.getId();

        // 2. 按 relationType 写 family_relations
        switch (relationType) {
            case RelationTypeConstants.CHILD_OF -> {
                addParentOf(familyId, anchor.getId(), newMemberId);
                // 若锚点已有配偶，同时给配偶也补一条直接血亲边，
                // 否则配偶视角算出来的关系会退化成"配偶的儿子"而不是"儿子"
                Long anchorSpouseId = findSpouseId(anchor.getId());
                if (anchorSpouseId != null) {
                    addParentOf(familyId, anchorSpouseId, newMemberId);
                }
            }
            case RelationTypeConstants.PARENT_OF ->
                    addParentOf(familyId, newMemberId, anchor.getId());
            case RelationTypeConstants.SPOUSE_OF -> {
                if (findSpouseId(anchor.getId()) != null) {
                    throw new BusinessException(ErrorCode.SPOUSE_ALREADY_EXISTS);
                }
                addSpouseOf(familyId, newMemberId, anchor.getId());
            }
            case RelationTypeConstants.SIBLING_OF -> {
                List<Long> anchorParentIds = familyRelationsService.lambdaQuery()
                        .eq(FamilyRelation::getRelationType, RelationTypeConstants.PARENT_OF)
                        .eq(FamilyRelation::getObjectMemberId, anchor.getId())
                        .isNull(FamilyRelation::getDeletedAt)
                        .list()
                        .stream()
                        .map(FamilyRelation::getSubjectMemberId)
                        .toList();
                if (anchorParentIds.isEmpty()) {
                    throw new BusinessException(ErrorCode.NO_KNOWN_PARENT);
                }
                anchorParentIds.forEach(parentId -> addParentOf(familyId, parentId, newMemberId));
            }
            default -> throw new BusinessException(ErrorCode.INVALID_RELATION_TYPE);
        }

        return familyId;
    }

    @Override
    @Transactional
    public Long createFamily(
            Long userId,
            String gender,
            String familyName
    ) {
        Family family = new Family();
        LocalDateTime now = LocalDateTime.now();
        family.setName(familyName);
        family.setCreatedBy(userId);
        family.setCreatedAt(now);
        family.setUpdatedAt(now);

        boolean familySaved = save(family);
        if (!familySaved) {
            throw new BusinessException(ErrorCode.FAMILY_SAVE_FAILURE);
        }

        FamilyMemeber familyMemeber = new FamilyMemeber();
        familyMemeber.setFamilyId(family.getId());
        familyMemeber.setUserId(userId);
        familyMemeber.setRole(RoleConstants.FAMILY_ADMIN);
        familyMemeber.setGender(gender);
        familyMemeber.setJoinedAt(now);

        familyMembersService.save(familyMemeber);

        return family.getId();
    }

    /**
     * 用户同一时刻只能属于一个家庭。若在 excludingFamilyId 之外的家庭里还有
     * 未软删除的成员身份，级联退出：软删除 family_members、软删除该成员在
     * 旧家庭图里的 family_relations 边、退出旧家庭群聊（不影响与旧家庭成员
     * 的私聊)，若退出的是唯一 admin 则自动转移或在无人可转移时软删除旧家庭。
     */
    private void leaveCurrentFamilyIfAny(Long userId, Long excludingFamilyId) {
        FamilyMemeber oldMembership = familyMembersService.lambdaQuery()
                .eq(FamilyMemeber::getUserId, userId)
                .ne(FamilyMemeber::getFamilyId, excludingFamilyId)
                .isNull(FamilyMemeber::getDeletedAt)
                .one();
        if (oldMembership == null) {
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        Long oldFamilyId = oldMembership.getFamilyId();

        // 1. 软删除旧的 family_members 记录
        oldMembership.setDeletedAt(now);
        familyMembersService.updateById(oldMembership);

        // 2. 软删除该成员在旧家庭图里的全部 family_relations 边
        List<FamilyRelation> staleRelations = familyRelationsService.lambdaQuery()
                .eq(FamilyRelation::getFamilyId, oldFamilyId)
                .and(w -> w.eq(FamilyRelation::getSubjectMemberId, oldMembership.getId())
                        .or().eq(FamilyRelation::getObjectMemberId, oldMembership.getId()))
                .isNull(FamilyRelation::getDeletedAt)
                .list();
        if (!staleRelations.isEmpty()) {
            staleRelations.forEach(rel -> rel.setDeletedAt(now));
            familyRelationsService.updateBatchById(staleRelations);
        }

        // 3. 退出旧家庭的群聊；与旧家庭成员之间已存在的私聊（direct）不受影响
        List<Long> groupConversationIds = conversationsService.lambdaQuery()
                .eq(Conversation::getFamilyId, oldFamilyId)
                .eq(Conversation::getType, ConversationTypeConstants.GROUP)
                .list()
                .stream()
                .map(Conversation::getId)
                .toList();
        if (!groupConversationIds.isEmpty()) {
            conversationMembersService.lambdaUpdate()
                    .in(ConversationMember::getConversationId, groupConversationIds)
                    .eq(ConversationMember::getUserId, userId)
                    .isNull(ConversationMember::getLeftAt)
                    .set(ConversationMember::getLeftAt, now)
                    .update();
        }

        // 4. 管理员孤儿处理：转移给最早加入的剩余成员，若已无活跃成员则软删除旧家庭
        if (RoleConstants.FAMILY_ADMIN.equals(oldMembership.getRole())) {
            FamilyMemeber successor = familyMembersService.lambdaQuery()
                    .eq(FamilyMemeber::getFamilyId, oldFamilyId)
                    .isNull(FamilyMemeber::getDeletedAt)
                    .orderByAsc(FamilyMemeber::getJoinedAt)
                    .last("LIMIT 1")
                    .one();
            if (successor != null) {
                successor.setRole(RoleConstants.FAMILY_ADMIN);
                familyMembersService.updateById(successor);
            } else {
                // 旧家庭已无任何活跃成员：整体软删除，created_by 保持不变仅作历史记录
                Family oldFamily = getById(oldFamilyId);
                oldFamily.setDeletedAt(now);
                updateById(oldFamily);
            }
        }
    }

    private Long findSpouseId(Long memberId) {
        FamilyRelation rel = familyRelationsService.lambdaQuery()
                .eq(FamilyRelation::getRelationType, RelationTypeConstants.SPOUSE_OF)
                .and(w -> w.eq(FamilyRelation::getSubjectMemberId, memberId)
                        .or().eq(FamilyRelation::getObjectMemberId, memberId))
                .isNull(FamilyRelation::getDeletedAt)
                .one();
        if (rel == null) return null;
        return rel.getSubjectMemberId().equals(memberId) ? rel.getObjectMemberId() : rel.getSubjectMemberId();
    }

    private void addParentOf(Long familyId, Long parentMemberId, Long childMemberId) {
        FamilyRelation rel = new FamilyRelation();
        rel.setFamilyId(familyId);
        rel.setSubjectMemberId(parentMemberId);
        rel.setRelationType(RelationTypeConstants.PARENT_OF);
        rel.setObjectMemberId(childMemberId);
        rel.setCreatedAt(LocalDateTime.now());
        familyRelationsService.save(rel);
    }

    private void addSpouseOf(Long familyId, Long memberIdA, Long memberIdB) {
        // 规范化，保证 SPOUSE_OF 无向边不会存两次
        long subject = Math.min(memberIdA, memberIdB);
        long object = Math.max(memberIdA, memberIdB);
        FamilyRelation rel = new FamilyRelation();
        rel.setFamilyId(familyId);
        rel.setSubjectMemberId(subject);
        rel.setRelationType(RelationTypeConstants.SPOUSE_OF);
        rel.setObjectMemberId(object);
        rel.setCreatedAt(LocalDateTime.now());
        familyRelationsService.save(rel);
    }
}
```

## 落地前还需要补的东西

- **`relationToMemberId` 类型**：建议改成 `Long`，与 `family_members.id`（`BIGINT UNSIGNED`）以及现有 `userId` 的类型对齐；如果 DTO 里定的是 `Integer`，插入 `family_relations` 前记得转型。
- **`ErrorCode` 需要新增的枚举值**：`INVALID_RELATION_ANCHOR`、`SPOUSE_ALREADY_EXISTS`、`NO_KNOWN_PARENT`（对应 `docs/api.md` 里已经写的 409）、`INVALID_RELATION_TYPE`。
- **`family_relations` 表目前还没有对应的 PO/Mapper/Service**，需要照着 `family_members` 现有的分层（`domain.po` + `mapper` + `service`/`serviceImpl`）新建一套。
- **`RelationTypeConstants` 常量类**：仿照现有 `RoleConstants`，装 `CHILD_OF`/`PARENT_OF`/`SPOUSE_OF`/`SIBLING_OF` 四个字符串常量。
- **`IConversationsService`/`IConversationMembersService`**：`leaveCurrentFamilyIfAny` 里用到，目前代码里也还没有对应实现，需要按 `docs/schema.sql` 的 `conversations`/`conversation_members` 表另建一套（如果聊天服务已经有现成的这两个 service，直接复用即可，不用重复建）。
- **`ConversationTypeConstants.GROUP`**：对应 `conversations.type` 枚举值 `'group'`，同样仿照 `RoleConstants` 建一个常量类（如果聊天服务那边已有类似常量，直接复用）。

## 修复的原始 bug（供对照）

原始 `FamiliesServiceImpl` 中存在以下问题，已在上面的版本中修正：

1. `familyMemeber.setGender( gender )` 缺分号，且方法体后面直接结束——缺 `familyMembersService.save(familyMemeber)` 和 `return familyId;`。
2. `IFamilyMembersService familyMembersService` 字段没有 `@Autowired`，Spring 不会注入，运行时是 `null`，调用即 NPE。
3. `createFamily` 里引用了方法参数中不存在的 `familyCreateInfoDTO` 变量（`getFamilyName()`/`getRole()`），且取出的 `role` 从未被使用——这是旧版签名遗留下来的死代码，已删除，直接使用方法参数 `familyName`。
4. `joinFamily` 完全没有处理 `relationToMemberId`/`relationType`，即没有写入任何 `family_relations` 记录。

## 后续补充：加入新家庭时级联退出旧家庭

`AuthUser`（Flutter 端）和整个前端 UI 都假设一个用户同一时刻只属于一个家庭，但 `family_members` 表在 DB 层面的唯一约束只是 `(family_id, user_id)`，并不禁止同一个 `user_id` 在多个家庭里都有未软删除的记录。因此 `joinFamily` 补充了 `leaveCurrentFamilyIfAny(userId, familyId)`——在写入新家庭数据之前、同一个 `@Transactional` 方法内，自动把用户从当前活跃的旧家庭里软删除移除（软删除 `family_members`/相关 `family_relations`、退出旧家庭群聊、必要时转移或软删除管理员孤儿家庭），而不是真的删除 `families` 整条记录（除非那个家庭已经没有任何活跃成员）。详见上面代码里的 `leaveCurrentFamilyIfAny` 方法，业务规则对照 `docs/api.md` §3.4。

## 后续补充：无邀请码的加入申请（docs/api.md §3.5）

UI 侧新增了"申请加入家庭"入口——申请人不知道邀请码，但知道家庭里某位成员（`target_member`）的手机号，提交申请后由该成员所在家庭的管理员在 App 内审批。对应 `docs/schema.sql` 新表 `family_join_requests`。参考实现（新建 `FamilyJoinRequestsServiceImpl`，复用上面 `FamiliesServiceImpl` 里已有的 `addParentOf`/`addSpouseOf`/`findSpouseId` 三个 helper，approve 时的关系写入规则与 `joinFamily` 完全一致，不重复贴一遍完整代码，只列关键方法骨架）：

```java
@Service
public class FamilyJoinRequestsServiceImpl extends ServiceImpl<FamilyJoinRequestsMapper, FamilyJoinRequest>
        implements IFamilyJoinRequestsService {

    @Autowired private IUsersService usersService;
    @Autowired private IFamilyMembersService familyMembersService;
    @Autowired private IFamilyRelationsService familyRelationsService;
    @Autowired private PasswordEncoder passwordEncoder; // 与 AuthService 注册流程共用同一套 BCrypt 编码器

    @Transactional
    public Long submit(String name, String phone, String password, String gender,
                        String targetMemberPhone, String relationType, String message) {
        if (usersService.lambdaQuery().eq(User::getPhone, phone).exists()) {
            throw new BusinessException(ErrorCode.PHONE_ALREADY_REGISTERED);
        }
        FamilyMemeber targetMember = resolveTargetMemberByPhone(targetMemberPhone); // 404 TARGET_MEMBER_NOT_FOUND

        FamilyJoinRequest req = new FamilyJoinRequest();
        req.setFamilyId(targetMember.getFamilyId());
        req.setTargetMemberId(targetMember.getId());
        req.setRequesterName(name);
        req.setRequesterPhone(phone);
        req.setRequesterPasswordHash(passwordEncoder.encode(password)); // 批准时直接复用，不要求二次输入
        req.setRequesterGender(gender);
        req.setRelationType(relationType);
        req.setMessage(message);
        req.setStatus(JoinRequestStatus.PENDING);
        req.setCreatedAt(LocalDateTime.now());
        save(req);
        return req.getId();
    }

    @Transactional
    public void approve(Long requestId, Long adminUserId) {
        FamilyJoinRequest req = getPendingOrThrow(requestId); // 409 REQUEST_ALREADY_RESOLVED

        User user = new User();
        user.setName(req.getRequesterName());
        user.setPhone(req.getRequesterPhone());
        user.setPasswordHash(req.getRequesterPasswordHash());
        usersService.save(user);

        FamilyMemeber newMember = new FamilyMemeber();
        newMember.setFamilyId(req.getFamilyId());
        newMember.setUserId(user.getId());
        newMember.setRole(RoleConstants.FAMILY_MEMBER);
        newMember.setGender(req.getRequesterGender());
        newMember.setJoinedAt(LocalDateTime.now());
        familyMembersService.save(newMember);

        // 与 FamiliesServiceImpl.joinFamily 的 CHILD_OF/PARENT_OF/SPOUSE_OF/SIBLING_OF
        // 四条分支完全一致的写边规则，直接复用那几个 private helper（建议把
        // addParentOf/addSpouseOf/findSpouseId 提到一个共享的 FamilyRelationWriter
        // 里，两个 Service 都注入它，避免复制一份重复逻辑）
        writeRelationEdges(req.getFamilyId(), req.getTargetMemberId(), newMember.getId(), req.getRelationType());

        req.setStatus(JoinRequestStatus.APPROVED);
        req.setResolvedAt(LocalDateTime.now());
        req.setResolvedBy(adminUserId);
        updateById(req);
        // 注意：这里不返回、也不生成申请人的 token——审批发生在管理员的会话里，
        // 申请人需要自己用刚才提交的手机号+密码走正常登录流程
    }

    @Transactional
    public void reject(Long requestId, Long adminUserId, String reason) {
        FamilyJoinRequest req = getPendingOrThrow(requestId);
        req.setStatus(JoinRequestStatus.REJECTED);
        req.setResolvedAt(LocalDateTime.now());
        req.setResolvedBy(adminUserId);
        updateById(req);
    }
}
```

落地前还需要补：`FamilyJoinRequest` PO/Mapper/Service（照 `family_relations` 现有分层新建）、`ErrorCode` 新增 `TARGET_MEMBER_NOT_FOUND`/`PHONE_ALREADY_REGISTERED`/`REQUEST_ALREADY_RESOLVED`、把 `addParentOf`/`addSpouseOf`/`findSpouseId` 从 `FamiliesServiceImpl` 提取成共享 helper（现在两个 Service 都需要用，不要复制粘贴一份）、审批接口需要校验当前登录用户在 `req.getFamilyId()` 里确实是 `role=admin`（不能审批别的家庭的申请）。
