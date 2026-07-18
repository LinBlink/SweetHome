import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/home_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/conversation_tile.dart';
import 'chat_room_screen.dart';

/// Full-screen chat search. Lives behind the magnifier icon in the
/// conversation list's app bar and searches through the local
/// `ChatLocalCache` snapshot the [ChatProvider] keeps in memory — so
/// it's instant, works offline, and doesn't need to be debounced
/// against a network round-trip.
///
/// Two result flavors:
///  - Conversation-name hits (no specific message — opening the
///    result jumps straight into the chat room at the bottom).
///  - Message-content hits (text only — image/voice bubbles carry
///    no searchable text). Each shows a brief snippet with the
///    query highlighted, the sender's name + avatar, and the
///    surrounding conversation context.
class SearchMessagesScreen extends StatefulWidget {
  const SearchMessagesScreen({super.key});

  @override
  State<SearchMessagesScreen> createState() => _SearchMessagesScreenState();
}

class _SearchMessagesScreenState extends State<SearchMessagesScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _query = _ctrl.text);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chat = context.watch<ChatProvider>();
    final hits = chat.searchMessages(_query);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(
        title: l10n.conversationsSearchTooltip,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: PaperBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.conversationsSearchHint,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textHint,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                          onPressed: () => _ctrl.clear(),
                        ),
                ),
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty
                  ? _EmptyHint(l10n: l10n)
                  : hits.isEmpty
                      ? _NoResults(l10n: l10n, query: _query.trim())
                      : _Results(hits: hits, query: _query.trim()),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyHint({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 44,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.conversationsSearchEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.inkFaded,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final AppLocalizations l10n;
  final String query;
  const _NoResults({required this.l10n, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.conversationsSearchNoResults(query),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.inkFaded,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final List<ChatSearchHit> hits;
  final String query;
  const _Results({required this.hits, required this.query});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: hits.length,
      itemBuilder: (ctx, i) {
        final hit = hits[i];
        final conv = hit.conversation;
        if (hit.message == null) {
          // Conversation-name match — open the chat room directly.
          return ConversationTile(
            conversation: conv,
            onTap: () => _openChat(context, conv.id),
          );
        }
        // Message match — render an inline snippet with a highlight.
        final m = hit.message!;
        return InkWell(
          onTap: () => _openChat(context, conv.id, targetMessage: m),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SnippetAvatar(conversation: conv),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conv.name.isEmpty
                                  ? m.senderName
                                  : '${conv.name} · ${m.senderName}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _relativeTime(m.sentAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        _highlightedSnippet(m.content, query),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openChat(BuildContext context, int convId, {Message? targetMessage}) {
    final chat = context.read<ChatProvider>();
    final conv = chat.conversations.firstWhere(
      (c) => c.id == convId,
      orElse: () => chat.conversations.first,
    );
    chat.setActiveConversation(conv.id);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: chat,
        child: ChatRoomScreen(
          conversationId: conv.id,
          conversationName: conv.name,
          targetMessageClientId: targetMessage?.clientId,
        ),
      ),
    ));
  }

  /// Compact "5 min ago" / "14:30" formatter — search results don't
  /// need the per-locale deep formatter, just enough to put the
  /// hit in time order at a glance.
  static String _relativeTime(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${ts.month}/${ts.day}';
  }

  static TextSpan _highlightedSnippet(String content, String query) {
    final lower = content.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    var idx = 0;
    while (idx < content.length) {
      final hit = lower.indexOf(q, idx);
      if (hit < 0) {
        spans.add(TextSpan(text: content.substring(idx)));
        break;
      }
      if (hit > idx) {
        spans.add(TextSpan(text: content.substring(idx, hit)));
      }
      spans.add(TextSpan(
        text: content.substring(hit, hit + q.length),
        style: TextStyle(
          backgroundColor: AppColors.linenDeep,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ));
      idx = hit + q.length;
    }
    return TextSpan(children: spans);
  }
}

class _SnippetAvatar extends StatelessWidget {
  final Conversation conversation;
  const _SnippetAvatar({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final bg = conversation.avatarColor;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        conversation.avatarLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}