import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final Set<int> _expandedTranslations = {};

  FamilyMember? _findMember(String id) {
    try {
      return mockFamily.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('王家群聊',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text('6人',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: mockMessages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildDateSeparator('今天');
                }
                final msg = mockMessages[index - 1];
                return _buildMessageItem(context, msg, index - 1);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFDDD9D0))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFDDD9D0))),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
      BuildContext context, ChatMessage msg, int msgIndex) {
    final member = _findMember(msg.senderId);
    final isMe = msg.isFromMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 46, bottom: 3),
              child: Text(
                member?.name ?? '',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      member?.avatarColor ?? AppColors.textSecondary,
                  child: Text(
                    member?.avatarLabel ?? '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _buildBubble(context, msg, isMe),
                    if (msg.translation != null)
                      _buildTranslationRow(msgIndex, msg.translation!),
                  ],
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text('爸',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                left: isMe ? 0 : 46, right: isMe ? 46 : 0, top: 3),
            child: Text(
              msg.time,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(
      BuildContext context, ChatMessage msg, bool isMe) {
    if (msg.type == MessageType.capsule) {
      return _buildCapsuleBubble(msg);
    }
    if (msg.type == MessageType.voice) {
      return _buildVoiceBubble(isMe);
    }

    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        msg.content,
        style: TextStyle(
          fontSize: 14,
          color: isMe ? Colors.white : AppColors.primary,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildVoiceBubble(bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_filled,
              color: isMe ? Colors.white : AppColors.primary, size: 22),
          const SizedBox(width: 8),
          const Text(
            '0:12',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(
                8,
                (i) => Container(
                      width: 2.5,
                      height: (i % 3 == 0)
                          ? 14
                          : (i % 3 == 1)
                              ? 8
                              : 11,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: (isMe ? Colors.white : AppColors.primaryLight)
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleBubble(ChatMessage msg) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B6914), Color(0xFFF4A261)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '时间胶囊',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '王小明18岁生日解锁',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationRow(int index, String translation) {
    final isExpanded = _expandedTranslations.contains(index);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedTranslations.remove(index);
          } else {
            _expandedTranslations.add(index);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(top: 4, left: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌐', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 3),
                Text(
                  '方言翻译',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.accent,
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 14,
                  color: AppColors.accent,
                ),
              ],
            ),
            if (isExpanded)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  translation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon:
                  const Icon(Icons.add_circle_outline, color: AppColors.primaryLight),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: '发送消息...',
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.image_outlined,
                  color: AppColors.primaryLight),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.mic_outlined,
                  color: AppColors.primaryLight),
              onPressed: () {},
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
