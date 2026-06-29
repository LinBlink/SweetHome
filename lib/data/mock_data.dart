import 'package:flutter/material.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2D3142);
  static const Color primaryLight = Color(0xFF4F5D75);
  static const Color accent = Color(0xFFF4A261);
  static const Color background = Color(0xFFF5F1EB);
  static const Color success = Color(0xFF52B788);
  static const Color warning = Color(0xFFE9C46A);
  static const Color danger = Color(0xFFE76F51);
  static const Color textSecondary = Color(0xFF6B7280);
}

// ─── Family Member ────────────────────────────────────────────────────────────

class FamilyMember {
  final String id;
  final String name;
  final String role;
  final String avatarLabel;
  final Color avatarColor;
  final int age;
  final bool isOnline;
  final String currentLocation;
  final bool isChild;
  final bool isElder;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarLabel,
    required this.avatarColor,
    required this.age,
    required this.isOnline,
    required this.currentLocation,
    this.isChild = false,
    this.isElder = false,
  });
}

final List<FamilyMember> mockFamily = [
  const FamilyMember(
    id: 'dad',
    name: '王建国',
    role: '爸',
    avatarLabel: '爸',
    avatarColor: Color(0xFF2D3142),
    age: 45,
    isOnline: true,
    currentLocation: '公司',
  ),
  const FamilyMember(
    id: 'mom',
    name: '张美玲',
    role: '妈',
    avatarLabel: '妈',
    avatarColor: Color(0xFFE91E63),
    age: 42,
    isOnline: true,
    currentLocation: '家',
  ),
  const FamilyMember(
    id: 'son',
    name: '王小明',
    role: '大儿子',
    avatarLabel: '明',
    avatarColor: Color(0xFF2196F3),
    age: 12,
    isOnline: false,
    currentLocation: '学校',
    isChild: true,
  ),
  const FamilyMember(
    id: 'daughter',
    name: '王小雨',
    role: '小女儿',
    avatarLabel: '雨',
    avatarColor: Color(0xFF9C27B0),
    age: 8,
    isOnline: true,
    currentLocation: '学校',
    isChild: true,
  ),
  const FamilyMember(
    id: 'grandpa',
    name: '王福海',
    role: '爷爷',
    avatarLabel: '爷',
    avatarColor: Color(0xFF795548),
    age: 70,
    isOnline: true,
    currentLocation: '小区公园',
    isElder: true,
  ),
  const FamilyMember(
    id: 'grandma',
    name: '陈桂芬',
    role: '奶奶',
    avatarLabel: '奶',
    avatarColor: Color(0xFF4CAF50),
    age: 67,
    isOnline: false,
    currentLocation: '家',
    isElder: true,
  ),
];

// ─── Chat Messages ────────────────────────────────────────────────────────────

enum MessageType { text, voice, image, capsule }

class ChatMessage {
  final String senderId;
  final String content;
  final String time;
  final String? translation;
  final MessageType type;
  final bool isFromMe;

  const ChatMessage({
    required this.senderId,
    required this.content,
    required this.time,
    this.translation,
    this.type = MessageType.text,
    this.isFromMe = false,
  });
}

final List<ChatMessage> mockMessages = [
  const ChatMessage(
    senderId: 'grandpa',
    content: '今朝我去公园散步，碰到老李头了，他也在锻炼哩！',
    time: '08:15',
    translation: '今天早上我去公园散步，遇到老李了，他也在锻炼！',
  ),
  const ChatMessage(
    senderId: 'grandma',
    content: '老头子，记得吃早饭，别光顾着聊天！',
    time: '08:17',
  ),
  const ChatMessage(
    senderId: 'mom',
    content: '小明小雨，今天有期末考试，加油！妈妈相信你们～',
    time: '08:20',
  ),
  const ChatMessage(
    senderId: 'son',
    content: '知道啦妈妈，我准备好了！',
    time: '08:22',
  ),
  const ChatMessage(
    senderId: 'grandpa',
    content: '[语音消息]',
    time: '08:35',
    type: MessageType.voice,
  ),
  const ChatMessage(
    senderId: 'dad',
    content: '爸，您今天步数达标了吗？多喝水哦',
    time: '09:10',
    isFromMe: true,
  ),
  const ChatMessage(
    senderId: 'grandpa',
    content: '晓得晓得，走了快六千步咯，等下再走走。',
    time: '09:12',
    translation: '知道知道，已经走了将近六千步了，等会儿再走走。',
  ),
  const ChatMessage(
    senderId: 'mom',
    content: '晚上做红烧肉，大家早点回来吃饭！🍖',
    time: '11:30',
  ),
  const ChatMessage(
    senderId: 'dad',
    content: '太好了！我会早点下班的',
    time: '11:32',
    isFromMe: true,
  ),
  const ChatMessage(
    senderId: 'dad',
    content: '王小明18岁生日解锁',
    time: '12:00',
    type: MessageType.capsule,
    isFromMe: true,
  ),
];

// ─── OA Requests ─────────────────────────────────────────────────────────────

class OARequest {
  final String id;
  final String title;
  final String applicant;
  final String applicantId;
  final String? amount;
  final String reason;
  final String status; // pending / approved / rejected
  final String submittedTime;
  final String category;
  final List<String> approvers;

  const OARequest({
    required this.id,
    required this.title,
    required this.applicant,
    required this.applicantId,
    this.amount,
    required this.reason,
    required this.status,
    required this.submittedTime,
    required this.category,
    required this.approvers,
  });
}

final List<OARequest> mockOARequests = [
  const OARequest(
    id: 'oa1',
    title: '申请购买学习平板',
    applicant: '王小明',
    applicantId: 'son',
    amount: '¥1,299',
    reason: '老师推荐用平板配合学习App，可以提高学习效率，我会好好保管的。',
    status: 'pending',
    submittedTime: '昨天 20:30',
    category: '教育采购',
    approvers: ['dad', 'mom'],
  ),
  const OARequest(
    id: 'oa2',
    title: '申请本周零花钱预支',
    applicant: '王小明',
    applicantId: 'son',
    amount: '¥50',
    reason: '同学生日想买个小礼物，这周零花钱已经用完了。',
    status: 'pending',
    submittedTime: '今天 07:45',
    category: '零花钱',
    approvers: ['dad'],
  ),
  const OARequest(
    id: 'oa3',
    title: '家庭出游张家界',
    applicant: '张美玲',
    applicantId: 'mom',
    amount: '¥3,500',
    reason: '暑假计划全家一起去张家界旅游，预计4天3晚，费用含交通住宿。',
    status: 'approved',
    submittedTime: '3天前',
    category: '家庭出行',
    approvers: ['dad'],
  ),
  const OARequest(
    id: 'oa4',
    title: '申请参加课外钢琴班',
    applicant: '王小雨',
    applicantId: 'daughter',
    amount: '¥2,400/学期',
    reason: '老师说小雨很有音乐天赋，想让她去学钢琴，每周一节课。',
    status: 'rejected',
    submittedTime: '5天前',
    category: '教育培训',
    approvers: ['dad', 'mom'],
  ),
];

// ─── Transactions ─────────────────────────────────────────────────────────────

class Transaction {
  final String title;
  final String category;
  final double amount;
  final String time;
  final bool isExpense;
  final IconData icon;
  final Color color;
  final String payer;

  const Transaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.time,
    required this.isExpense,
    required this.icon,
    required this.color,
    required this.payer,
  });
}

final List<Transaction> mockTransactions = [
  const Transaction(
    title: '超市购物',
    category: '日用百货',
    amount: 286.50,
    time: '今天 10:32',
    isExpense: true,
    icon: Icons.shopping_cart,
    color: Color(0xFF2196F3),
    payer: '张美玲',
  ),
  const Transaction(
    title: '王建国工资',
    category: '收入',
    amount: 18500.00,
    time: '今天 09:00',
    isExpense: false,
    icon: Icons.account_balance,
    color: Color(0xFF4CAF50),
    payer: '王建国',
  ),
  const Transaction(
    title: '小明英语培训',
    category: '教育培训',
    amount: 1200.00,
    time: '昨天 15:00',
    isExpense: true,
    icon: Icons.school,
    color: Color(0xFF9C27B0),
    payer: '张美玲',
  ),
  const Transaction(
    title: '家庭聚餐',
    category: '日常餐饮',
    amount: 432.00,
    time: '昨天 19:30',
    isExpense: true,
    icon: Icons.restaurant,
    color: Color(0xFFFF9800),
    payer: '王建国',
  ),
  const Transaction(
    title: '地铁公交',
    category: '交通出行',
    amount: 48.00,
    time: '前天',
    isExpense: true,
    icon: Icons.directions_transit,
    color: Color(0xFF00BCD4),
    payer: '王建国',
  ),
  const Transaction(
    title: '电影票',
    category: '娱乐休闲',
    amount: 120.00,
    time: '6月22日',
    isExpense: true,
    icon: Icons.movie,
    color: Color(0xFFE91E63),
    payer: '张美玲',
  ),
];

// ─── Budget Categories ─────────────────────────────────────────────────────────

class BudgetCategory {
  final String name;
  final double budget;
  final double spent;
  final Color color;
  final IconData icon;

  const BudgetCategory({
    required this.name,
    required this.budget,
    required this.spent,
    required this.color,
    required this.icon,
  });

  double get ratio => spent / budget;
}

final List<BudgetCategory> mockBudgets = [
  const BudgetCategory(
    name: '日常餐饮',
    budget: 4000,
    spent: 2850,
    color: Color(0xFFFF9800),
    icon: Icons.restaurant,
  ),
  const BudgetCategory(
    name: '教育培训',
    budget: 3000,
    spent: 3200,
    color: Color(0xFF9C27B0),
    icon: Icons.school,
  ),
  const BudgetCategory(
    name: '交通出行',
    budget: 800,
    spent: 420,
    color: Color(0xFF00BCD4),
    icon: Icons.directions_transit,
  ),
  const BudgetCategory(
    name: '娱乐休闲',
    budget: 1500,
    spent: 680,
    color: Color(0xFFE91E63),
    icon: Icons.movie,
  ),
  const BudgetCategory(
    name: '日用百货',
    budget: 1000,
    spent: 756,
    color: Color(0xFF2196F3),
    icon: Icons.shopping_bag,
  ),
];

// ─── Growth Records ────────────────────────────────────────────────────────────

class GrowthRecord {
  final String memberId;
  final String date;
  final double height;
  final double weight;

  const GrowthRecord({
    required this.memberId,
    required this.date,
    required this.height,
    required this.weight,
  });
}

final List<GrowthRecord> mockGrowthRecords = [
  // Son records
  const GrowthRecord(memberId: 'son', date: '2024.6', height: 148.0, weight: 39.5),
  const GrowthRecord(memberId: 'son', date: '2024.9', height: 149.8, weight: 40.2),
  const GrowthRecord(memberId: 'son', date: '2024.12', height: 151.2, weight: 41.0),
  const GrowthRecord(memberId: 'son', date: '2025.3', height: 152.6, weight: 41.8),
  const GrowthRecord(memberId: 'son', date: '2025.6', height: 153.5, weight: 42.3),
  // Daughter records
  const GrowthRecord(memberId: 'daughter', date: '2024.6', height: 122.0, weight: 22.1),
  const GrowthRecord(memberId: 'daughter', date: '2024.9', height: 123.5, weight: 22.8),
  const GrowthRecord(memberId: 'daughter', date: '2024.12', height: 125.0, weight: 23.4),
  const GrowthRecord(memberId: 'daughter', date: '2025.3', height: 126.8, weight: 24.0),
  const GrowthRecord(memberId: 'daughter', date: '2025.6', height: 128.2, weight: 24.7),
];

// ─── Vaccine Items ─────────────────────────────────────────────────────────────

class VaccineItem {
  final String name;
  final String memberId;
  final String dueDate;
  final bool isDone;

  const VaccineItem({
    required this.name,
    required this.memberId,
    required this.dueDate,
    required this.isDone,
  });
}

final List<VaccineItem> mockVaccines = [
  const VaccineItem(
    name: 'HPV疫苗（第二针）',
    memberId: 'daughter',
    dueDate: '2025年7月10日',
    isDone: false,
  ),
  const VaccineItem(
    name: '流感疫苗',
    memberId: 'grandpa',
    dueDate: '2025年9月01日',
    isDone: false,
  ),
  const VaccineItem(
    name: '甲肝疫苗',
    memberId: 'son',
    dueDate: '2025年4月15日',
    isDone: true,
  ),
  const VaccineItem(
    name: '新冠加强针',
    memberId: 'grandma',
    dueDate: '2025年3月20日',
    isDone: true,
  ),
];

// ─── Medication Reminders ──────────────────────────────────────────────────────

class MedicationReminder {
  final String name;
  final String memberId;
  final String dosage;
  final List<String> times;
  final int remainingDays;

  const MedicationReminder({
    required this.name,
    required this.memberId,
    required this.dosage,
    required this.times,
    required this.remainingDays,
  });
}

final List<MedicationReminder> mockMedications = [
  const MedicationReminder(
    name: '硝苯地平缓释片',
    memberId: 'grandpa',
    dosage: '1片',
    times: ['08:00', '20:00'],
    remainingDays: 12,
  ),
  const MedicationReminder(
    name: '阿司匹林肠溶片',
    memberId: 'grandpa',
    dosage: '1片',
    times: ['08:00'],
    remainingDays: 5,
  ),
  const MedicationReminder(
    name: '维生素D滴剂',
    memberId: 'daughter',
    dosage: '400IU',
    times: ['12:00'],
    remainingDays: 18,
  ),
];

// ─── Family Events ─────────────────────────────────────────────────────────────

class FamilyEvent {
  final String title;
  final String date;
  final String time;
  final IconData icon;
  final Color color;
  final String? note;

  const FamilyEvent({
    required this.title,
    required this.date,
    required this.time,
    required this.icon,
    required this.color,
    this.note,
  });
}

final List<FamilyEvent> mockEvents = [
  const FamilyEvent(
    title: '小明期末考试',
    date: '明天',
    time: '08:00 - 11:00',
    icon: Icons.edit_note,
    color: Color(0xFF2196F3),
    note: '数学+语文',
  ),
  const FamilyEvent(
    title: '爷爷生日',
    date: '后天',
    time: '18:30',
    icon: Icons.cake,
    color: Color(0xFFF4A261),
    note: '预订蛋糕 ✓',
  ),
  const FamilyEvent(
    title: '小雨钢琴课',
    date: '周六',
    time: '14:00 - 15:00',
    icon: Icons.piano,
    color: Color(0xFF9C27B0),
    note: null,
  ),
  const FamilyEvent(
    title: '家庭出游张家界',
    date: '7月15日',
    time: '全天',
    icon: Icons.landscape,
    color: Color(0xFF52B788),
    note: '已购票 ✓',
  ),
];

// ─── Habit Challenges ──────────────────────────────────────────────────────────

class HabitChallenge {
  final String title;
  final String memberId;
  final String description;
  final int streakDays;
  final int targetDays;
  final IconData icon;
  final Color color;

  const HabitChallenge({
    required this.title,
    required this.memberId,
    required this.description,
    required this.streakDays,
    required this.targetDays,
    required this.icon,
    required this.color,
  });

  double get progress => streakDays / targetDays;
}

final List<HabitChallenge> mockHabits = [
  const HabitChallenge(
    title: '每日阅读',
    memberId: 'son',
    description: '每天读书30分钟',
    streakDays: 7,
    targetDays: 30,
    icon: Icons.menu_book,
    color: Color(0xFF2196F3),
  ),
  const HabitChallenge(
    title: '刷牙打卡',
    memberId: 'daughter',
    description: '早晚各刷牙一次',
    streakDays: 12,
    targetDays: 30,
    icon: Icons.sentiment_very_satisfied,
    color: Color(0xFF9C27B0),
  ),
  const HabitChallenge(
    title: '晨练散步',
    memberId: 'grandpa',
    description: '每天散步8000步',
    streakDays: 21,
    targetDays: 60,
    icon: Icons.directions_walk,
    color: Color(0xFF4CAF50),
  ),
];
