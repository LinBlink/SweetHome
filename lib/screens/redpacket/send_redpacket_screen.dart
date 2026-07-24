import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_config.dart';
import '../../core/error_messages.dart';
import '../../core/money/money_formatter.dart';
import '../../data/mock_data.dart';
import '../../l10n/app_localizations.dart';
import '../../models/api_exception.dart';
import '../../models/redpacket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/redpacket_service.dart';

/// §9.1 — Form sheet for sending a new red packet to the current
/// conversation. The flow is three steps:
/// 1. Validate locally (`totalAmount >= totalCount * 1 cent`,
///    `totalCount <= conversation.memberCount`, `totalAmount <= balance`).
/// 2. Call [RedpacketService.create] — server returns the new
///    [Redpacket] with `id` + `status = ongoing`.
/// 3. Drop a `REDPACKET` chat message into the conversation via
///    [ChatProvider.sendRedpacketMessage] so everyone in the room
///    sees the card (§9.1 explicitly delegates this to the client).
///
/// Then refresh the user's balance via [AuthProvider.refreshBalance]
/// since §9.1's response doesn't echo the new balance back.
///
/// Per the user's product call, this form does **not** carry a cover
/// message (留言) field — the server only stores `content = <redpacket
/// id>` for chat-message red packets (§4.4), and per §9 the red
/// packet entity itself doesn't carry a user-supplied caption.
///
/// In direct (1:1) chats the share count is forced to `1` (no
/// "split with yourself" semantics — a single packet can only be
/// grabbed by the one recipient). The count input is hidden in that
/// case so the user can't accidentally type something else.
class SendRedpacketScreen extends StatefulWidget {
  final int conversationId;
  final int conversationMemberCount;

  /// Whether the conversation is a group. Drives the share-count
  /// behaviour: `false` (direct chat) → fixed at 1.
  final bool isGroup;

  const SendRedpacketScreen({
    super.key,
    required this.conversationId,
    required this.conversationMemberCount,
    required this.isGroup,
  });

  @override
  State<SendRedpacketScreen> createState() => _SendRedpacketScreenState();
}

class _SendRedpacketScreenState extends State<SendRedpacketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  late final TextEditingController _countCtrl;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Direct chats always send 1 share; groups default to 1 and
    // let the user bump it up to the conversation's member count.
    _countCtrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  /// Parses the `totalAmount` field as a yuan input (e.g. `100` or
  /// `88.88`) and converts to **分** for the wire payload. Returns
  /// `null` if the text isn't a valid number, with [errorText] set to
  /// a localized hint.
  ({int cents, String? errorText}) _parseAmount(AppLocalizations l10n) {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) {
      return (cents: 0, errorText: l10n.redpacketErrorInvalidAmount);
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return (cents: 0, errorText: l10n.healthValueInvalid);
    }
    // Convert yuan → 分. `round()` avoids floating-point dust like
    // 88.88 yuan → 8887.999... cents; the server's `totalAmount` is
    // a long-int cent count so we can't ship fractional cents.
    return (cents: (parsed * 100).round(), errorText: null);
  }

  /// Parses the share count. Defaults to "at least 1" — empty / 0
  /// inputs are rejected.
  ({int count, String? errorText}) _parseCount(AppLocalizations l10n) {
    final raw = _countCtrl.text.trim();
    if (raw.isEmpty) {
      return (count: 0, errorText: l10n.redpacketErrorInvalidAmount);
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return (count: 0, errorText: l10n.healthValueInvalid);
    }
    return (count: parsed, errorText: null);
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmount(l10n);
    if (amount.errorText != null) {
      setState(() => _error = amount.errorText);
      return;
    }
    // Direct chats hard-code 1 share; the count input is hidden
    // anyway, but reassert the cap here in case the user came from
    // a re-pushed screen with stale state.
    final count = widget.isGroup
        ? _parseCount(l10n)
        : (count: 1, errorText: null);
    if (count.errorText != null) {
      setState(() => _error = count.errorText);
      return;
    }
    // §9.1 constraint: totalAmount must be at least totalCount
    // (every share needs ≥ 1 cent).
    if (amount.cents < count.count) {
      setState(() => _error = l10n.redpacketErrorInvalidAmount);
      return;
    }
    // §9.1 constraint: totalCount must not exceed the conversation's
    // member count (the server checks too, but front-stopping avoids
    // a round-trip and surfaces a clearer message).
    if (count.count > widget.conversationMemberCount) {
      setState(() => _error = l10n.redpacketErrorTooManyShares);
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    // Front-stop the balance check too — `INSUFFICIENT_FUND` from the
    // server would arrive in Chinese to the local user as the raw
    // error code, so the in-form hint is friendlier.
    if (amount.cents > user.balance) {
      setState(() => _error = l10n.redpacketErrorInsufficientFund);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      Redpacket redpacket;
      if (AppConfig.mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        redpacket = Redpacket(
          id: 9000 + DateTime.now().millisecondsSinceEpoch % 1000,
          userId: user.userId,
          totalAmount: amount.cents,
          totalCount: count.count,
          status: RedpacketStatus.ongoing,
          expiredAt: DateTime.now().add(const Duration(days: 1)),
          createdAt: DateTime.now(),
        );
        // Without this, the just-sent card's detail screen would 404 —
        // `RedpacketDetailScreen` looks up the id via
        // `MockDataSource.mockRedpacketById`, which otherwise only
        // knows about the two hardcoded fixtures (1001/1002).
        MockDataSource.registerCreatedRedpacket(redpacket);
      } else {
        final token = user.token;
        final service = RedpacketService(() => token);
        redpacket = await service.create(
          totalAmount: amount.cents,
          totalCount: count.count,
          conversationId: widget.conversationId,
        );
      }
      if (!mounted) return;
      // Drop the chat-card message into the conversation so every
      // member sees it. The red packet already exists server-side
      // (and the balance is already deducted) by this point, so a
      // failure here shouldn't block the flow — but it must not be
      // swallowed silently either, or the user has no idea the card
      // never went out. `ChatProvider.sendRedpacketMessage` throws
      // (rather than falling back to the REST endpoint, which
      // doesn't support `type=redpacket` — see its doc comment) when
      // the WebSocket is down, so surface that here.
      try {
        await context.read<ChatProvider>().sendRedpacketMessage(
              widget.conversationId,
              redpacket.id,
            );
      } catch (e, st) {
        // `ChatProvider.sendRedpacketMessage` shouldn't throw under normal
        // network conditions (WS send is fire-and-forget, the REST
        // fallback swallows its own exceptions) — if this fires, it's an
        // unexpected failure (e.g. `ChangeNotifier used after dispose`).
        // Log it so the real cause shows up in `flutter logs`/device
        // console instead of only ever seeing the generic snackbar text.
        debugPrint('sendRedpacketMessage failed: $e\n$st');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.redpacketMessageSendFailed)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 1600));
      }
      // Refetch `/users/me` to get the new balance (the §9.1 response
      // doesn't echo it back). Snapshot the AuthProvider before the
      // await so the fire-and-forget call doesn't capture a stale
      // BuildContext.
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      unawaitedRefreshBalance(authProvider);
      // Pop back to the chat room so the just-sent card is visible.
      // The chat-room's last-message preview will render the red
      // packet placeholder instead of the raw id.
      Navigator.of(context).pop(redpacket.id);
    } on ApiException catch (e) {
      setState(() => _error = localizeErrorMessage(e.message, l10n));
    } catch (_) {
      setState(
          () => _error = localizeErrorMessage(kNetworkErrorSentinel, l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Fire-and-forget balance refresh — we don't want the send-form
  /// stay-open waiting for the round-trip, but we *do* want the
  /// profile card and send-form on next open to show the new number.
  /// Takes the [AuthProvider] directly (rather than a [BuildContext])
  /// so the call site can capture the provider reference *before* an
  /// async gap and avoid the "use_build_context_synchronously"
  /// analyzer rule.
  void unawaitedRefreshBalance(AuthProvider auth) {
    // ignore: discarded_futures
    auth.refreshBalance();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().currentUser;
    final balance = user?.balance ?? 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.redpacketSendTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BalanceHint(balance: balance),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.redpacketTotalAmountLabel,
                    hintText: l10n.redpacketTotalAmountHint,
                    prefixIcon: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                    ),
                    prefixText: '¥ ',
                  ),
                  validator: (_) => null,
                ),
                // Hide the count input entirely on direct chats — per
                // the user's product call, the share count is fixed
                // at 1 there. Groups keep the editable field capped at
                // `conversation.memberCount` via the hint text.
                if (widget.isGroup) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _countCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.redpacketTotalCountLabel,
                      hintText: l10n.redpacketTotalCountHint(
                          widget.conversationMemberCount),
                      prefixIcon: Icon(
                        Icons.group_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    validator: (_) => null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed:
                      _submitting ? null : () => _submit(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          l10n.redpacketSendButton,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.4),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small "your balance" pill shown above the form so the user knows
/// what they can afford before they start typing. Uses the red packet
/// color (¥ symbol is the only place a balance is rendered in the
/// whole app right now, so we keep the visual tight).
class _BalanceHint extends StatelessWidget {
  final int balance;
  const _BalanceHint({required this.balance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.linen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileBalanceLabel,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.inkFaded,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.balanceValue(MoneyFormatter.format(balance)),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}