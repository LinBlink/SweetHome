import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../core/home_widgets.dart';
import '../core/kinship/kinship_graph.dart';
import '../core/kinship/kinship_localizer.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/family_member_vm.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/error_banner.dart';

/// Returns the generation offset (relative to the viewer at Gen 0)
/// for any [relationCode] produced by the kinship engine.
///
/// Algorithm: walk each dot-separated token and accumulate a delta.
///   F / M          → -1  (parent, one generation up)
///   Son / Dau      → +1  (child, one generation down)
///   S / eB / yB /
///   eZ / yZ        →  0  (spouse / sibling stays at viewer's gen)
///
/// Special case: `SELF` is the viewer themselves → 0.
///
/// Examples:
///   `SELF`   →  0   (viewer)
///   `F`      → -1   (parent)
///   `F.F`    → -2   (grandparent)
///   `F.F.F`  → -3   (great-grandparent)
///   `S.F`    → -1   (parent-in-law — the `S` step doesn't shift gen)
///   `Son`    → +1   (child)
///   `Son.Son`→ +2   (grandchild)
///   `eB.Son` → +1   (nephew — sibling's child)
///   `Son.S`  → +1   (daughter/son-in-law — same gen as Son)
int generationOfRelationCode(String relationCode) {
  if (relationCode == 'SELF') return 0;
  final tokens = relationCode.split('.');
  var gen = 0;
  for (final t in tokens) {
    switch (t) {
      case 'F':
      case 'M':
        gen -= 1;
        break;
      case 'Son':
      case 'Dau':
        gen += 1;
        break;
      // S, eB, yB, eZ, yZ — no change in generation
    }
  }
  return gen;
}

/// Marquee-scrolling single-line label for the family-tree cards.
///
/// The cards are 92px wide (see [_FamilyTreeCanvas._cardWidth]) and
/// many Chinese kinship terms are 3-4 characters at 10-12pt, which
/// routinely exceeds that budget on its own — never mind a
/// compounded [S.M.F]-style "配偶的母亲的父亲" fallback. Plain
/// `Text` with `TextOverflow.ellipsis` drops the tail and a longer
/// name + a longer relation term together render as "..." for both,
/// which is unreadable. Static centered single-line text works
/// while the label fits; once it overflows, this widget animates
/// the text leftward through a clipped window so the user can read
/// it in full by letting it scroll.
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;

  const _MarqueeText({
    required this.text,
    required this.style,
    required this.maxWidth,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _overflows = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _measureAndMaybeStart());
  }

  @override
  void didUpdateWidget(covariant _MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.style != widget.style) {
      _ctrl.stop();
      _overflows = false;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _measureAndMaybeStart());
    }
  }

  void _measureAndMaybeStart() {
    if (!mounted) return;
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection:
          Directionality.maybeOf(context) ?? TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (!mounted) return;
    final w = tp.size.width;
    final overflows = w > widget.maxWidth - 0.5;
    if (overflows != _overflows) {
      setState(() => _overflows = overflows);
      if (overflows) {
        _ctrl.repeat();
      } else {
        _ctrl.stop();
      }
    } else if (overflows && !_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The marquee branch below wraps its scrolling Row in an
    // [OverflowBox] with an explicitly infinite height (needed so the
    // Row itself never trips a RenderFlex overflow assertion). An
    // OverflowBox reports that infinite height straight to its own
    // parent unless something above it clamps it first — normally
    // this card sits inside a fixed-height [Positioned], which does
    // that clamping, but the family tree canvas can also be nested
    // inside a horizontally-scrolling viewport (see
    // `_FamilyTreeCanvas.build`) whose cross-axis constraint is
    // unbounded, so relying on an ancestor to always supply a finite
    // height is fragile. Measuring and setting an explicit height
    // here makes this widget self-contained regardless of what
    // ancestor constraints it ends up under.
    final lineHeightTp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final lineHeight = lineHeightTp.height;
    return SizedBox(
      width: widget.maxWidth,
      height: lineHeight,
      child: ClipRect(
        child: _overflows
            // Animated scroll path: lay out two copies of the text
            // horizontally with a gap equal to the card width, and
            // translate the whole Row from 0 to -(textWidth + gap).
            // Looping just restarts at 0; the second copy keeps a
            // seamless visual because it lands in the visible
            // window as the first copy leaves it.
            //
            // The Row's natural width is `2 * textWidth + maxWidth`,
            // which overflows the 76px card width by 100+ pixels;
            // the outer [ClipRect] clips it visually, but a plain
            // unconstrained [Row] would still trip the parent
            // Row's RenderFlex overflow assertion in debug mode.
            // [OverflowBox] explicitly tells the layout system to
            // render the inner Row at its natural width and accept
            // the visual overflow (it gets clipped by the
            // surrounding [ClipRect]).
            ? AnimatedBuilder(
                animation: _ctrl,
                builder: (ctx, _) {
                  final tp = TextPainter(
                    text: TextSpan(text: widget.text, style: widget.style),
                    textDirection: Directionality.of(ctx),
                    maxLines: 1,
                  )..layout();
                  final w = tp.size.width;
                  final travel = w + widget.maxWidth;
                  return OverflowBox(
                    minWidth: 0,
                    maxWidth: double.infinity,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(-_ctrl.value * travel, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.text,
                              style: widget.style, maxLines: 1),
                          SizedBox(width: widget.maxWidth),
                          Text(widget.text,
                              style: widget.style, maxLines: 1),
                        ],
                      ),
                    ),
                  );
                },
              )
            : Text(
                widget.text,
                style: widget.style,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
              ),
      ),
    );
  }
}

/// "族谱" sub-app — a generation-bucketed family tree. Reads only
/// what the existing `GET /families/{familyId}/members` already
/// returns (per-member `relationCode` relative to the viewer), so
/// it works in both real and mock mode without any new API surface.
///
/// Every family member lands in the row corresponding to its
/// kinship generation (see [generationOfRelationCode]). The canvas
/// paints one row per generation that has at least one member,
/// top-down (most ancestors at the top, most descendants at the
/// bottom), with a marriage bus and parent→child drop trunks
/// drawn between rows. There is no upper bound on depth —
/// great-grandparents, great-great-grandparents, cousins of all
/// kinds, and arbitrarily far descendants all find a row.
class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  late Future<List<FamilyMemberVm>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthProvider>().loadFamilyMembers();
  }

  Future<void> _refresh() async {
    final next = context.read<AuthProvider>().loadFamilyMembers();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final me = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(
        title: l10n.familyTreeTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: l10n.locationRefresh,
          ),
        ],
      ),
      body: PaperBackground(
        child: FutureBuilder<List<FamilyMemberVm>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snap.hasError) {
            final isApi = snap.error is ApiException;
            return ErrorBanner(
              message: localizeErrorMessage(
                isApi
                    ? (snap.error as ApiException).message
                    : kNetworkErrorSentinel,
                l10n,
              ),
              onDismiss: _refresh,
            );
          }
          final members = snap.data ?? const <FamilyMemberVm>[];
          if (members.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 56,
                          color: AppColors.primaryLight.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.familyTreeEmpty,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.familyTreeEmptyDesc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return _FamilyTreeCanvas(
            members: members,
            viewerId: me?.userId,
            onRefresh: _refresh,
          );
        },
        ),
      ),
    );
  }
}

/// Returns `true` when two adjacent [relationCode]s in the same
/// row describe a married couple that should share a marriage bus.
/// Recognized couples:
/// - `SELF` ↔ `S`         (the viewer & spouse)
/// - `Son` ↔ `Son.S`      (son + daughter-in-law)
/// - `Dau` ↔ `Dau.S`      (daughter + son-in-law)
/// - `X` ↔ `X.S`          (any other blood member + their `.S`
///                          spouse, e.g. `eB` ↔ `eB.S`, `F.F` ↔
///                          `F.F.S`, …). The `.S` suffix is the
///                          canonical marker the kinship engine uses
///                          for "spouse of" so this rule generalizes
///                          to arbitrary depths.
/// - `X.F` ↔ `X.M`        (any two blood ancestors that are "X's
///                          father" and "X's mother" — same prefix,
///                          last segment F vs M — e.g. `F` ↔ `M` (the
///                          viewer's parents, X empty), `M.F` ↔
///                          `M.M` (外公/外婆), `M.F.F` ↔ `M.F.M`
///                          (母亲的爷爷/奶奶). Both are reached via
///                          the same node's father/mother edge, so
///                          they're always a married couple in this
///                          model.
bool _isMarriedCouple(String a, String b) {
  // Canonical viewer-gen couple.
  if ((a == 'SELF' && b == 'S') || (a == 'S' && b == 'SELF')) return true;
  // Generic blood-member + spouse pair (suffix `.S` is the kinship
  // engine's marker for "married into this family at this level").
  if (a.endsWith('.S') && b == a.substring(0, a.length - 2)) return true;
  if (b.endsWith('.S') && a == b.substring(0, b.length - 2)) return true;
  // Generic "X's father" ↔ "X's mother" pair, to arbitrary depth.
  final aParts = a.split('.');
  final bParts = b.split('.');
  if (aParts.length == bParts.length &&
      {aParts.last, bParts.last}.containsAll(const ['F', 'M']) &&
      aParts.sublist(0, aParts.length - 1).join('.') ==
          bParts.sublist(0, bParts.length - 1).join('.')) {
    return true;
  }
  return false;
}

/// The actual canvas: any number of rows (one per generation) of
/// `PersonCard`s, with a `CustomPainter` underneath drawing the
/// marriage / parent-child connectors. The whole thing is a
/// `SingleChildScrollView` so even a 12-generation family scrolls
/// cleanly on a phone screen.
class _FamilyTreeCanvas extends StatelessWidget {
  final List<FamilyMemberVm> members;
  final int? viewerId;
  final Future<void> Function() onRefresh;

  /// Card / spacing metrics — kept local so the canvas is self-contained.
  static const double _cardWidth = 92;
  static const double _cardHeight = 110;
  static const double _hGap = 16;
  static const double _vGap = 24;
  static const double _rowVerticalSpacing = 96;

  const _FamilyTreeCanvas({
    required this.members,
    required this.viewerId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final buckets = _bucket(members);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 32),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final viewportWidth = constraints.maxWidth;
            // Every relative gets its own generation row (no "extended"
            // fallback bucket), so a single row can hold far more cards
            // than a phone screen is wide — a viewer with two uncles,
            // their spouses, and a few cousins easily blows past 4-5
            // cards in one row. This scroll view is vertical-only, so a
            // row wider than the viewport would otherwise just get
            // clipped by the Stack's hard edge with no way to reach the
            // rest of it. When the widest row needs more room than the
            // screen has, size the canvas to that row's actual width and
            // let it scroll horizontally too.
            final contentWidth = _contentWidthFor(buckets, viewportWidth);
            final canvas = _buildCanvas(context, contentWidth, buckets);
            if (contentWidth <= viewportWidth) return canvas;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: contentWidth, child: canvas),
            );
          },
        ),
      ),
    );
  }

  /// The width the canvas actually needs: at least the viewport, but
  /// wide enough for the widest row's cards to render without clipping.
  double _contentWidthFor(FamilyTreeBuckets b, double viewportWidth) {
    var maxRowWidth = 0.0;
    for (final row in b.rows) {
      final w = _rowNaturalWidth(row.members, _alignFor(row));
      if (w > maxRowWidth) maxRowWidth = w;
    }
    return maxRowWidth > viewportWidth ? maxRowWidth : viewportWidth;
  }

  /// The width a row needs to lay out its cards at full size — the same
  /// math [_layoutRow] uses to position cards, just without a
  /// [canvasWidth] to center against. Used up front to size the canvas
  /// (see [_contentWidthFor]) before any row is actually positioned.
  double _rowNaturalWidth(List<FamilyMemberVm> members, _RowAlign align) {
    final count = members.length;
    if (count == 0) return 0;
    if (align != _RowAlign.viewerCentered) {
      return count * _cardWidth + (count - 1) * _hGap;
    }
    final hasSpouse = members.any((m) => m.relationCode == 'S');
    final hasSelf = members.any((m) => m.relationCode == 'SELF');
    final sibCount =
        count - (hasSpouse ? 1 : 0) - (hasSelf ? 1 : 0);
    final leftSibCount = sibCount ~/ 2;
    final rightSibCount = sibCount - leftSibCount;
    final leftWidth = leftSibCount > 0
        ? leftSibCount * _cardWidth + (leftSibCount - 1) * _hGap
        : 0.0;
    final rightWidth = rightSibCount > 0
        ? rightSibCount * _cardWidth + (rightSibCount - 1) * _hGap
        : 0.0;
    final pairWidth = hasSpouse ? _cardWidth * 2 + _hGap : _cardWidth;
    return leftWidth +
        pairWidth +
        rightWidth +
        (leftSibCount > 0 ? _hGap : 0) +
        (rightSibCount > 0 ? _hGap : 0);
  }

  Widget _buildCanvas(
    BuildContext context,
    double canvasWidth,
    FamilyTreeBuckets b,
  ) {
    // Lay out one row per generation. Each row's `_RowLayout.entries`
    // still have `rect.top = 0` at this point; the staggered
    // `runningTop` below patches the actual Y for every card so the
    // `Positioned` widgets in the Stack render at the right place.
    final rawRows = <_RowLayout>[];
    for (final row in b.rows) {
      rawRows.add(
        _layoutRow(
          members: row.members,
          canvasWidth: canvasWidth,
          align: _alignFor(row),
        ),
      );
    }

    var runningTop = 0.0;
    final placedRows = <_RowLayout>[];
    for (final raw in rawRows) {
      final placed = raw.copyWith(
        rowTopY: runningTop,
        rowBottomY: runningTop + _cardHeight,
        entries: [
          for (final e in raw.entries)
            e.copyWith(rect: e.rect.copyWith(top: runningTop)),
        ],
      );
      placedRows.add(placed);
      runningTop += _cardHeight + _rowVerticalSpacing;
    }
    final totalHeight = runningTop + _vGap;

    final interRowDrops = computeInterRowDrops(placedRows);

    // Marriage lines: walk every row, look for adjacent cards whose
    // codes form a couple (X + X.S, or the canonical F+M pair).
    // "Adjacent" means spatially adjacent (sorted by rect.centerX), not
    // adjacent in `row.entries`' bucket order — `_RowAlign.viewerCentered`
    // spatially reorders a row (siblings fan out left/right of the
    // SELF+spouse pair) without touching `entries`' underlying order, so
    // walking `entries` directly would pair up cards that only happen to
    // flank the SELF+spouse pair, drawing a spurious line straight through
    // it instead of between the two cards that are actually next to each
    // other on screen.
    final intraRowMarriages = <_CoupleMidpoint>[];
    for (final row in placedRows) {
      final spatial = [...row.entries]
        ..sort((a, b) => a.rect.centerX.compareTo(b.rect.centerX));
      for (var i = 0; i + 1 < spatial.length; i++) {
        final a = spatial[i];
        final b = spatial[i + 1];
        if (!_isMarriedCouple(a.member.relationCode, b.member.relationCode)) {
          continue;
        }
        intraRowMarriages.add(_CoupleMidpoint(left: a.rect, right: b.rect));
      }
    }

    final connectors = _ConnectorLayout(
      rows: placedRows,
      viewerId: viewerId,
      interRowDrops: interRowDrops,
      intraRowMarriages: intraRowMarriages,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _FamilyTreePainter(c: connectors),
                ),
              ),
              for (final row in placedRows) ...[
                for (final entry in row.entries)
                  Positioned(
                    left: entry.rect.left,
                    top: entry.rect.top,
                    width: entry.rect.width,
                    height: entry.rect.height,
                    child: _PersonCard(
                      member: entry.member,
                      isViewer: entry.member.userId == viewerId,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Build the bucket map from each member's `relationCode`.
  /// Every member lands in some generation row — there's no
  /// "extended" fallback anymore (see [bucketFamilyTreeMembers]).
  FamilyTreeBuckets _bucket(List<FamilyMemberVm> all) => bucketFamilyTreeMembers(all);

  /// Picks the layout mode for one generation row:
  /// - The viewer's own generation (0) uses [_RowAlign.viewerCentered]
  ///   so SELF anchors the row and siblings fan out left/right of the
  ///   SELF+spouse pair, instead of just falling wherever alphabetical
  ///   order happens to put them.
  /// - A row that's exactly one married couple (e.g. the F/M parents
  ///   row) uses [_RowAlign.symmetric] for the extra marriage-line
  ///   breathing room.
  /// - Everything else (children rows, multi-member ancestor rows,
  ///   etc.) uses [_RowAlign.groupCentered].
  _RowAlign _alignFor(FamilyTreeRow row) {
    if (row.generation == 0) return _RowAlign.viewerCentered;
    if (row.members.length == 2 &&
        _isMarriedCouple(
          row.members[0].relationCode,
          row.members[1].relationCode,
        )) {
      return _RowAlign.symmetric;
    }
    return _RowAlign.groupCentered;
  }

  /// Lay out a single row given the bucket contents. The actual
  /// x-position of every card is computed against [canvasWidth] —
  /// centered, symmetric, or viewer-centered depending on [align].
  _RowLayout _layoutRow({
    required List<FamilyMemberVm> members,
    required double canvasWidth,
    required _RowAlign align,
  }) {
    final count = members.length;
    final entries = <_RowEntry>[];
    var viewerIndexInRow = -1;
    for (int i = 0; i < count; i++) {
      if (members[i].relationCode == 'SELF') viewerIndexInRow = i;
      entries.add(
        _RowEntry(
          member: members[i],
          rect: const _CardRect(
            left: 0,
            top: 0,
            width: _cardWidth,
            height: _cardHeight,
          ),
        ),
      );
    }

    // Default — evenly-spaced left-to-right, centered. Used by
    // `groupCentered` (the children row).
    if (align != _RowAlign.viewerCentered) {
      final rowWidth = _rowNaturalWidth(members, align);
      var startX = (canvasWidth - rowWidth) / 2;
      if (startX < 0) startX = 0;
      for (int i = 0; i < count; i++) {
        entries[i] = entries[i].copyWith(
          rect: _CardRect(
            left: startX + i * (_cardWidth + _hGap),
            top: 0,
            width: _cardWidth,
            height: _cardHeight,
          ),
        );
      }
      if (align == _RowAlign.symmetric && count == 2) {
        // Symmetric — pull the pair slightly apart so the
        // marriage line between them has room to breathe.
        final totalGap = canvasWidth - 2 * _cardWidth;
        final innerGap = totalGap * 0.18;
        entries[0] = entries[0].copyWith(
          rect: _CardRect(
            left: (canvasWidth - 2 * _cardWidth - innerGap) / 2,
            top: 0,
            width: _cardWidth,
            height: _cardHeight,
          ),
        );
        entries[1] = entries[1].copyWith(
          rect: _CardRect(
            left: entries[0].rect.left + _cardWidth + innerGap,
            top: 0,
            width: _cardWidth,
            height: _cardHeight,
          ),
        );
      }
    } else {
      // Viewer-centered — SELF is the visual focal point of the
      // middle row. Siblings fan out symmetrically: ~half on the
      // left of SELF, ~half on the right of S (if S exists;
      // otherwise on the right of SELF). Spouse always pins to
      // SELF's right with a small marriage gap.
      final viewerIdx = viewerIndexInRow >= 0 ? viewerIndexInRow : 0;
      final spouseIdx = members.indexWhere((m) => m.relationCode == 'S');
      final hasSpouse = spouseIdx >= 0;

      // Identify sibling indices (everyone except SELF and S).
      final sibIndices = <int>[];
      for (int i = 0; i < count; i++) {
        if (i == viewerIdx) continue;
        if (i == spouseIdx) continue;
        sibIndices.add(i);
      }
      // Sort siblings by relationCode so the on-screen order is
      // stable / deterministic.
      sibIndices.sort((a, b) =>
          members[a].relationCode.compareTo(members[b].relationCode));

      // Split siblings left/right. An odd count puts the extra
      // sibling on the right (since the spouse lives on the
      // right and "right" is the modern-by-marriage side in
      // traditional layouts).
      final totalSibs = sibIndices.length;
      final leftSibCount = totalSibs ~/ 2;
      final rightSibCount = totalSibs - leftSibCount;
      final leftSibIndices = sibIndices.sublist(0, leftSibCount);
      final rightSibIndices = sibIndices.sublist(leftSibCount);

      final leftWidth = leftSibCount > 0
          ? leftSibCount * _cardWidth + (leftSibCount - 1) * _hGap
          : 0.0;
      final totalWidth = _rowNaturalWidth(members, align);
      var x = (canvasWidth - totalWidth) / 2;
      if (x < 0) x = 0;

      // Left siblings: from x, going right.
      for (int i = 0; i < leftSibIndices.length; i++) {
        entries[leftSibIndices[i]] = entries[leftSibIndices[i]].copyWith(
          rect: _CardRect(
            left: x + i * (_cardWidth + _hGap),
            top: 0,
            width: _cardWidth,
            height: _cardHeight,
          ),
        );
      }
      var cursor = x + leftWidth + (leftSibCount > 0 ? _hGap : 0);
      // SELF.
      entries[viewerIdx] = entries[viewerIdx].copyWith(
        rect: _CardRect(
          left: cursor,
          top: 0,
          width: _cardWidth,
          height: _cardHeight,
        ),
      );
      cursor += _cardWidth;
      // Spouse (S).
      if (hasSpouse) {
        entries[spouseIdx] = entries[spouseIdx].copyWith(
          rect: _CardRect(
            left: cursor + _hGap,
            top: 0,
            width: _cardWidth,
            height: _cardHeight,
          ),
        );
        cursor += _hGap + _cardWidth;
      }
      // Right siblings.
      cursor += (rightSibCount > 0 ? _hGap : 0);
      for (int i = 0; i < rightSibIndices.length; i++) {
        entries[rightSibIndices[i]] = entries[rightSibIndices[i]].copyWith(
          rect: _CardRect(
            left: cursor + i * (_cardWidth + _hGap),
            top: 0,
            width: _cardWidth,
            height: _cardHeight,
          ),
        );
      }
    }

    return _RowLayout(
      entries: entries,
      viewerIndexInRow: viewerIndexInRow,
      // top/bottom Y are computed after the row's vertical position
      // is known; assign default 0 here and the canvas wraps each
      // row at the right y in the loop.
      rowTopY: 0,
      rowBottomY: _cardHeight,
    );
  }
}

enum _RowAlign { symmetric, viewerCentered, groupCentered }

/// Public so widget tests can drive the layout without going
/// through the full `FamilyTreeScreen` plumbing (which depends on
/// `AuthProvider` and friends). Splitting the pure data transform
/// from the rendering layer also lets us assert the exact row
/// composition for each family shape.
@visibleForTesting
class FamilyTreeBuckets {
  /// One row per generation that has at least one member. Rows are
  /// ordered from highest generation (most ancestors) at index 0
  /// down to lowest generation (most descendants). SELF is at
  /// generation 0 — see [generationOfRelationCode] for the algorithm.
  final List<FamilyTreeRow> rows;

  const FamilyTreeBuckets({required this.rows});
}

/// One generation's worth of family members in the family tree.
/// All [members] share the same [generation] value. The canvas lays
/// one row per [FamilyTreeRow], top-down, sorted by [generation]
/// descending.
@visibleForTesting
class FamilyTreeRow {
  final int generation;
  final List<FamilyMemberVm> members;
  const FamilyTreeRow({required this.generation, required this.members});
}

/// Public for the same reason as [FamilyTreeBuckets]. Pure function
/// — no widget context, no async, easy to drive from a unit test.
///
/// The family tree's horizontal axis is generation (kin depth from
/// the viewer) and the vertical axis is the row at that depth.
/// Every member lands in exactly one row based on
/// [generationOfRelationCode], which walks each token of the
/// kinship code and accumulates a per-token delta (F/M -1,
/// Son/Dau +1, S/siblings 0). That handles arbitrary depth:
/// great-grandparents, great-great-grandparents, cousins-of-
/// uncle's-child, etc. all find their own row.
///
/// Within a single row, members are sorted alphabetically by their
/// `relationCode` string. This isn't a perfect family-tree ordering
/// (it doesn't special-case "F before M"), but it gives stable,
/// deterministic, locale-neutral placement — and the painter paints
/// marriage buses by detecting adjacent `X` / `X.S` pairs (or the
/// F/M couple), which is robust to whatever order alphabetical
/// sort produces.
///
/// Crucially: this function no longer produces an `extended`
/// fallback. Every member — including cousins, in-laws of distant
/// generations, uncles/aunts at the F.F.eB depth, etc. — finds a
/// home in some row. Nothing gets clipped from the tree.
@visibleForTesting
FamilyTreeBuckets bucketFamilyTreeMembers(List<FamilyMemberVm> all) {
  // Bucket by generation, preserving insertion order within each row
  // (the alphabetical sort runs once at the end).
  final byGeneration = <int, List<FamilyMemberVm>>{};
  for (final m in all) {
    final gen = generationOfRelationCode(m.relationCode);
    (byGeneration[gen] ??= <FamilyMemberVm>[]).add(m);
  }
  // Stable alphabetical sort within each row.
  for (final list in byGeneration.values) {
    list.sort((a, b) => a.relationCode.compareTo(b.relationCode));
  }
  // Emit rows sorted by generation ASCENDING (most ancestors at
  // index 0, viewer at the visual center, descendants at the end).
  // The canvas paints top-down, so index 0 ends up at the top of
  // the stack — and the most-ancestral generation is the most
  // negative integer (-3 → great-grandparents, +3 → great-grand-
  // children), so ascending generation = ancestors at the top.
  final sortedGens = byGeneration.keys.toList()..sort();
  return FamilyTreeBuckets(
    rows: [
      for (final gen in sortedGens)
        FamilyTreeRow(generation: gen, members: byGeneration[gen]!),
    ],
  );
}

class _CardRect {
  final double left;
  final double top;
  final double width;
  final double height;
  const _CardRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get centerX => left + width / 2;
  double get centerY => top + height / 2;
  double get right => left + width;
  double get bottom => top + height;

  _CardRect copyWith({double? left, double? top, double? width, double? height}) =>
      _CardRect(
        left: left ?? this.left,
        top: top ?? this.top,
        width: width ?? this.width,
        height: height ?? this.height,
      );
}

class _RowEntry {
  final FamilyMemberVm member;
  final _CardRect rect;
  const _RowEntry({required this.member, required this.rect});
  _RowEntry copyWith({_CardRect? rect}) =>
      _RowEntry(member: member, rect: rect ?? this.rect);
}

class _RowLayout {
  final List<_RowEntry> entries;
  final int viewerIndexInRow;
  final double rowTopY;
  final double rowBottomY;

  const _RowLayout({
    required this.entries,
    required this.viewerIndexInRow,
    required this.rowTopY,
    required this.rowBottomY,
  });

  _CardRect positionOf(int userId) {
    return entries.firstWhere((e) => e.member.userId == userId).rect;
  }

  _RowLayout copyWith({
    List<_RowEntry>? entries,
    int? viewerIndexInRow,
    double? rowTopY,
    double? rowBottomY,
  }) =>
      _RowLayout(
        entries: entries ?? this.entries,
        viewerIndexInRow: viewerIndexInRow ?? this.viewerIndexInRow,
        rowTopY: rowTopY ?? this.rowTopY,
        rowBottomY: rowBottomY ?? this.rowBottomY,
      );
}

class _CoupleMidpoint {
  final _CardRect left;
  final _CardRect right;
  const _CoupleMidpoint({required this.left, required this.right});
  double get x => (left.centerX + right.centerX) / 2;
}

/// Pre-computed positions / indices the painter needs to draw the
/// connectors. Computing it once outside the painter keeps the
/// `paint()` method pure and cheap to invoke. Every row position
/// is nullable — a family can be missing the parents row, the
/// children row, or both — so the painter null-checks before
/// drawing each line.
/// Computes the parent→child drop trunks between every adjacent
/// pair of placed rows. For each member in the lower row, finds
/// their closest ancestor in ANY upper row by walking the
/// relationCode up (e.g. `Son.Son.Son` first tries `Son.Son`, then
/// `Son`, then `SELF` — whichever exists in some row above).
///
/// Walking past the immediate parent matters when intermediate
/// generations are missing from the data: e.g. a family with
/// `F.F.F` and `F` but no `F.F` would otherwise produce no
/// `F.F.F → F` drop because the strict strip-one-segment rule
/// looks for `F.F` (absent) and gives up. The "walk up until you
/// find an ancestor present in the data" rule connects those
/// cases.
///
/// SELF is the one exception: its relationCode is empty so the
/// strip rule yields nothing. Instead SELF's parent in the family
/// graph is whoever sits one generation up in the upper rows,
/// conventionally the father (F) if present, else the mother (M).
/// Without this special case the F→SELF (and M→SELF) trunk never
/// gets drawn and the upper half of the tree looks disconnected.
///
/// Marked `@visibleForTesting` so the bucket/connector invariants
/// can be pinned down in a unit test (see
/// `test/family_tree_bucket_test.dart`).
@visibleForTesting
// ignore: library_private_types_in_public_api
List<_InterRowDrop> computeInterRowDrops(List<_RowLayout> placedRows) {
  final result = <_InterRowDrop>[];
  // Track relationCodes seen in rows ABOVE the current one
  // (smaller index in the placed list, which is sorted by
  // generation ASCENDING — older generations live at smaller
  // index, i.e. visually higher). Only ancestors live in the
  // "upper" set; including codes from the current or lower rows
  // would make every code find its own SELF and produce spurious
  // SELF→member drops.
  final upperByCode = <String, _RowEntry>{};
  for (final lower in placedRows) {
    // Group lower-row entries by their (closest-ancestor) parent
    // code. We use insertion order to keep "first same-gender
    // child" first, which keeps the visual pairing (e.g. Son.Son
    // attaches to the first Son, not the second) stable.
    final byParent = <String, List<_RowEntry>>{};
    for (final e in lower.entries) {
      final code = e.member.relationCode;
      final parentCode = _ancestorInUpperRows(code, upperByCode.keys);
      // The helper can return a code that isn't actually present
      // in the data (e.g. for `F` it returns `'SELF'` as the
      // parent — but SELF might not be in any row yet). The drop
      // only makes sense if the parent code is actually a member
      // of some row above us, so require it to be in [upperByCode]
      // before we use it.
      if (parentCode == null) continue;
      if (!upperByCode.containsKey(parentCode)) continue;
      (byParent[parentCode] ??= <_RowEntry>[]).add(e);
    }
    for (final entry in byParent.entries) {
      if (entry.value.isEmpty) continue;
      result.add(_InterRowDrop(
        parent: upperByCode[entry.key]!,
        children: entry.value,
      ));
    }
    // Promote the current row's entries into the upper set so
    // the next (lower) row can find them as ancestors.
    for (final e in lower.entries) {
      upperByCode[e.member.relationCode] = e;
    }
  }
  return result;
}

/// Resolves the closest-ancestor relationCode for a lower-row
/// member. Returns null when the member has no known ancestor in
/// the upper rows (e.g. the F row is the topmost generation in
/// the family data, so its ancestors are absent).
///
/// "Parent in the family graph" depends on whether the code is a
/// descendant chain (Son/Dau) or an ancestor chain (F/M):
///
///   - Descendant (e.g. `Son.Son`): the direct parent has FEWER
///     dot-segments — strip the last one to get the parent's
///     relationCode (here, `Son`).
///   - Ancestor (e.g. `F.F.F`): the direct parent has ONE MORE
///     dot-segment, but the new segment can be either F or M. The
///     relationCode only encodes the path the kinship engine walked
///     to reach this ancestor; the family-graph parent is whoever
///     the engine actually arrived at (a maternal-line `M.F` has
///     `M.F.F` or `M.F.M` as its parent, not a same-direction
///     `M.F.M` guess). We try BOTH directions, opposite-direction
///     first (so mixed-family chains like M → M.F → M.F.F connect
///     up cleanly when the data only carries the maternal half),
///     then same-direction. Whichever candidate is present in
///     [upperCodes] wins.
///
/// Spouse/sibling tokens (`S`, `eB`, `yB`, `eZ`, `yZ`) live at the
/// viewer's generation and have no upward parent in the family
/// tree.
String? _ancestorInUpperRows(
  String code,
  Iterable<String> upperCodes,
) {
  if (code == 'SELF') {
    // SELF has no relationCode; its parent is the closest blood
    // parent in the upper rows (F preferred, then M).
    if (upperCodes.contains('F')) return 'F';
    if (upperCodes.contains('M')) return 'M';
    return null;
  }
  // Spouse/siblings — no upper-row parent.
  if (code == 'S' || code == 'eB' || code == 'yB' ||
      code == 'eZ' || code == 'yZ') {
    return null;
  }
  // Descendant chain (Son, Dau, or any Son.* / Dau.*):
  // strip the last dot-segment to get the parent's relationCode.
  if (code == 'Son' || code == 'Dau' ||
      code.startsWith('Son.') || code.startsWith('Dau.')) {
    if (!code.contains('.')) {
      // Son / Dau's direct parent is the viewer (SELF).
      return 'SELF';
    }
    final dot = code.lastIndexOf('.');
    return code.substring(0, dot);
  }
  // Ancestor chain (F, M, or any F.* / M.*):
  // the direct parent in the family graph has one MORE
  // dot-segment. The new segment can be either F or M — try both,
  // opposite-direction first so a mixed-direction chain like
  // M → M.F → M.F.F doesn't drop its parent connection just
  // because the data happens to carry M.F.F rather than M.F.M.
  // The candidates therefore append another F or M segment to
  // [code] itself (not to a stripped prefix — stripping would
  // produce a same-generation relative, which is what the
  // descendant-chain branch above handles).
  if (code == 'F' || code == 'M' ||
      code.startsWith('F.') || code.startsWith('M.')) {
    final lastChar = code.endsWith('.F') || code == 'F' ? 'F' : 'M';
    final opposite = lastChar == 'F' ? 'M' : 'F';
    final candidates = <String>['$code.$opposite', '$code.$lastChar'];
    for (final candidate in candidates) {
      if (upperCodes.contains(candidate)) return candidate;
    }
    return null;
  }
  return null;
}

/// Stringly-typed view of [computeInterRowDrops] for test use. Returns
/// a list of `parentCode` → `[childCode, ...]` records, one per
/// detected drop, in the same order the painter will draw them.
/// `rows` here can be a list of [FamilyTreeRow] (the public,
/// test-friendly row type) — each row's [FamilyMemberVm] members
/// are read directly without needing rect metadata, because the
/// drop topology is purely a function of the relationCodes.
@visibleForTesting
List<({String parent, List<String> children})>
    computeInterRowDropCodes(List<FamilyTreeRow> rows) {
  final result = <({String parent, List<String> children})>[];
  // Tracks the set of relationCodes seen in all rows ABOVE the
  // current one (i.e. at smaller index, since rows are sorted by
  // generation ASCENDING so smaller index = older generation =
  // visually higher). Only ancestors live in the "upper" set; we
  // must not include codes from the current or lower rows or
  // every code would "find" its own SELF and produce spurious
  // SELF→member drops.
  final upperCodes = <String>{};
  for (final lower in rows) {
    final byParent = <String, List<String>>{};
    for (final m in lower.members) {
      final code = m.relationCode;
      final parentCode = _ancestorInUpperRows(code, upperCodes);
      // The helper can return a code that isn't actually present
      // in the data (e.g. for `F` it returns `'SELF'` as the
      // parent — but SELF might not be in any row yet). The drop
      // only makes sense if the parent code is actually a member
      // of some row above us, so require it to be in [upperCodes]
      // before we use it.
      if (parentCode == null) continue;
      if (!upperCodes.contains(parentCode)) continue;
      (byParent[parentCode] ??= <String>[]).add(code);
    }
    for (final entry in byParent.entries) {
      if (entry.value.isEmpty) continue;
      result.add((parent: entry.key, children: entry.value));
    }
    // Promote the current row's codes into the upper set so the
    // next (lower) row can find them as ancestors.
    for (final m in lower.members) {
      upperCodes.add(m.relationCode);
    }
  }
  return result;
}

/// Pre-computed positions / indices the painter needs to draw the
/// connectors. Computing it once outside the painter keeps the
/// `paint()` method pure and cheap to invoke.
///
/// [rows] is the placed-row list (top-down, generation ASCENDING
/// from most ancestors at index 0 to most descendants). Index i
/// and i+1 are adjacent rows; the painter draws a parent→child
/// trunk between every adjacent row pair.
///
/// Within each row, [intraRowMarriages] collects the horizontal
/// marriage-line pairs that the painter should render: typically
/// (F, M) in the parents row, (SELF, S) in the SELF row, and
/// (Son, Son.S) / (Dau, Dau.S) pairs in any row whose members
/// include a blood member + their `.S` spouse variant.
class _ConnectorLayout {
  final List<_RowLayout> rows;
  final int? viewerId;

  /// Drops between row i and row i+1: parent→child fan-outs.
  /// `length == rows.length - 1`; entry i is the drop from
  /// rows[i] (older) down to rows[i+1] (younger). When both rows
  /// exist, the drop is computed by matching each row[i+1] member's
  /// relationCode-prefix to a row[i] member's relationCode (the
  /// API gives us viewer-relative codes; the parent is the code
  /// with the last segment stripped). Empty drops are omitted.
  final List<_InterRowDrop> interRowDrops;

  /// Marriage-line pairs across all rows, normalized as
  /// "left card, right card" (left.centerX < right.centerX).
  final List<_CoupleMidpoint> intraRowMarriages;

  const _ConnectorLayout({
    required this.rows,
    required this.viewerId,
    required this.interRowDrops,
    required this.intraRowMarriages,
  });
}

/// One parent→child drop trunk between two adjacent rows. The
/// trunk starts at [parent] (in the row above) and fans out to
/// every [_RowEntry] in [children] (in the row below). Both
/// [parent] and [children] carry their [FamilyMemberVm.member]
/// reference so the painter can look up the parent row's
/// avatar-center Y and find the child row's rowTopY for the
/// bus-fan-out endpoint.
class _InterRowDrop {
  final _RowEntry parent;
  final List<_RowEntry> children;
  const _InterRowDrop({required this.parent, required this.children});
}

/// Paints the family-tree connectors (marriage + parent→child drop
/// lines). Uses soft terracotta lines on top of the warm background
/// so the structure reads at a glance without competing with the
/// avatar circles.
class _FamilyTreePainter extends CustomPainter {
  final _ConnectorLayout c;
  static const double _strokeW = 1.4;
  // Y offset, from each card's top, to the vertical center of its
  // avatar circle. Avatar is centered horizontally inside a 92px-wide
  // card with 10px vertical padding, and the column above the
  // avatar is centered vertically within the remaining 90px content
  // area. Marriage lines AND trunk-drop start points both anchor at
  // this Y so the trunk emerges straight out of the marriage bus's
  // midpoint — i.e. the bus lives at the avatar's vertical center,
  // and the trunk grows downward from the same pixel.
  static const double _avatarCenterYOffset = 38.5;

  _FamilyTreePainter({required this.c});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = _strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Marriage buses: one per detected couple across all rows. The
    // bus sits at the row's avatar-center Y so it crosses the
    // avatars' middles, matching the family-tree convention.
    for (final couple in c.intraRowMarriages) {
      final y = couple.left.top + _avatarCenterYOffset;
      final left = couple.left.right < couple.right.left
          ? couple.left.right
          : couple.left.centerX;
      final right = couple.left.right < couple.right.left
          ? couple.right.left
          : couple.left.centerX;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        paint,
      );
    }

    // Inter-row parent→child drops: one trunk per upper-row member
    // that has children in the next row. When that member is half of
    // a couple in this row (e.g. F+M, or SELF+S), the trunk emerges
    // from the marriage bus's midpoint — not from directly above one
    // parent's card — matching the convention that a couple's
    // children hang from the union, not from one spouse. Only when
    // the parent has no in-row spouse does the trunk fall back to
    // that member's own avatar center.
    for (final drop in c.interRowDrops) {
      if (drop.children.isEmpty) continue;
      final startY = drop.parent.rect.top + _avatarCenterYOffset;
      final endY = drop.children.first.rect.top;
      final trunkX = _trunkXFor(drop.parent.rect, c.intraRowMarriages);
      _drawBusFanOut(
        canvas,
        paint,
        trunkX: trunkX,
        trunkY: startY,
        busY: (startY + endY) / 2,
        endY: endY,
        targetXs: drop.children.map((e) => e.rect.centerX).toList(),
      );
    }
  }

  /// The X the parent→child trunk should drop from: the marriage
  /// bus's midpoint if [parentRect] is one half of a couple detected
  /// in this row, otherwise [parentRect]'s own center.
  double _trunkXFor(_CardRect parentRect, List<_CoupleMidpoint> marriages) {
    for (final couple in marriages) {
      if (identical(couple.left, parentRect) ||
          identical(couple.right, parentRect)) {
        return couple.x;
      }
    }
    return parentRect.centerX;
  }

  /// Shared "trunk down, bus across, drop to each target" shape
  /// used by every inter-row parent→child connector.
  void _drawBusFanOut(
    Canvas canvas,
    Paint paint, {
    required double trunkX,
    required double trunkY,
    required double busY,
    required double endY,
    required List<double> targetXs,
  }) {
    final xs = [...targetXs]..sort();
    canvas.drawLine(Offset(trunkX, trunkY), Offset(trunkX, busY), paint);
    canvas.drawLine(Offset(trunkX, busY), Offset(xs.first, busY), paint);
    if (xs.length > 1) {
      canvas.drawLine(Offset(xs.first, busY), Offset(xs.last, busY), paint);
    }
    for (final x in xs) {
      canvas.drawLine(Offset(x, busY), Offset(x, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FamilyTreePainter oldDelegate) {
    return oldDelegate.c != c;
  }
}

/// One person in the tree. Avatar + name + relation label, on a
/// soft surface card. The viewer card gets a warm terracotta border
/// so you can find yourself at a glance.
class _PersonCard extends StatelessWidget {
  final FamilyMemberVm member;
  final bool isViewer;
  const _PersonCard({required this.member, required this.isViewer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale;
    final viewer = context.watch<AuthProvider>().currentUser;
    final avatarColor = AppColors.avatarColorFor(
      member.userId,
      selfUserId: viewer?.userId,
    );

    final relationLabel = member.relationCode == 'SELF'
        ? l10n.familyTreeViewerLabel
        : relationLabelFor(
            relationCode: member.relationCode,
            targetGender: member.gender,
            viewerGender: genderFromString(viewer?.gender),
            appLocale: locale,
          );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isViewer ? AppColors.primary : AppColors.divider,
          width: isViewer ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarWidget(
            label: memberAvatarLabel(member.name),
            color: avatarColor,
            imageUrl: member.avatarUrl,
            radius: 20,
          ),
          const SizedBox(height: 6),
          Padding(
            // Padding on each side halves the card width for the
            // label — keeps "4-char name + 6-char term" from
            // horizontally colliding with the card edges.
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _MarqueeText(
              text: member.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isViewer
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
              // Card width minus the outer 6px horizontal padding
              // (`padding: const EdgeInsets.symmetric(vertical: 10,
              // horizontal: 6)` above) and the inner 2+2 px of this
              // Padding — keeps both lines inside the rounded card.
              maxWidth: _FamilyTreeCanvas._cardWidth - 6 * 2 - 4,
            ),
          ),
          const SizedBox(height: 1),
          if (relationLabel != null)
            _MarqueeText(
              text: relationLabel,
              style: TextStyle(
                fontSize: 10,
                color: isViewer
                    ? AppColors.primary
                    : AppColors.textHint,
                fontWeight: isViewer ? FontWeight.w700 : FontWeight.w500,
              ),
              maxWidth: _FamilyTreeCanvas._cardWidth - 6 * 2 - 4,
            ),
        ],
      ),
    );
  }
}

