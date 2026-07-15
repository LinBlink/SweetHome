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
import '../models/auth_models.dart';
import '../models/family_member_vm.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/error_banner.dart';

/// "族谱" sub-app — a clean 3-generation viewer-centric family tree.
/// Reads only what the existing `GET /families/{familyId}/members`
/// already returns (per-member `relationCode` relative to the viewer),
/// so it works in both real and mock mode without any new API surface.
///
/// Generation bucketing from `relationCode`:
///   Gen -1 (parents row)        →  F, M
///   Gen 0  (me + household row) →  SELF, S, eB, yB, eZ, yZ
///   Gen +1 (children row)       →  Son, Dau
///   Extended (everything else)  →  rendered as a compact list under
///                                  the canvas (in-laws, nieces,
///                                  cousins, great-grandparents, …)
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
            return const Center(
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.familyTreeEmptyDesc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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

/// The actual canvas: three rows of `PersonCard`s, with a `CustomPainter`
/// underneath drawing the marriage/parent-child connectors. The whole
/// thing is a `SingleChildScrollView` so even a 12-child family scrolls
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

    // If nothing falls into any tree row (all "extended"), skip the
    // canvas entirely — just show the list. Otherwise an empty canvas
    // with only the list looks broken.
    if (buckets.parents.isEmpty &&
        buckets.middle.isEmpty &&
        buckets.children.isEmpty) {
      return _ExtendedList(
        members: buckets.extended,
        viewerId: viewerId,
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 32),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final canvasWidth = constraints.maxWidth;
            return _buildCanvas(context, canvasWidth, buckets);
          },
        ),
      ),
    );
  }

  Widget _buildCanvas(
    BuildContext context,
    double canvasWidth,
    FamilyTreeBuckets b,
  ) {
    // Lay out each row by SEMANTIC ROLE (parents / middle / children),
    // not by list position. The middle row is mandatory (SELF is
    // always in it); the other two are optional — and the previous
    // implementation crashed or hid the children row whenever
    // parents was empty, because the connector code did
    // `rows[1] / rows[2]` regardless of which row was actually
    // there. Tracking rows by role instead fixes the "no parents
    // ⇒ no children" regression.
    final parentsRow = b.parents.isNotEmpty
        ? _layoutRow(
            members: b.parents,
            canvasWidth: canvasWidth,
            align: _RowAlign.symmetric,
          )
        : null;
    final middleRow = _layoutRow(
      members: b.middle,
      canvasWidth: canvasWidth,
      align: _RowAlign.viewerCentered,
    );
    final childrenRow = b.children.isNotEmpty
        ? _layoutRow(
            members: b.children,
            canvasWidth: canvasWidth,
            align: _RowAlign.groupCentered,
          )
        : null;

    // Stagger the rows vertically and patch each entry's `top` so
    // the `Positioned` widgets place the cards at the right Y.
    // The connectors reference these top values too, so they all
    // stay in sync.
    final presentRows = <_RowLayout>[
      ?parentsRow,
      middleRow,
      ?childrenRow,
    ];
    var runningTop = 0.0;
    for (var i = 0; i < presentRows.length; i++) {
      final row = presentRows[i];
      presentRows[i] = row.copyWith(
        rowTopY: runningTop,
        rowBottomY: runningTop + _cardHeight,
        entries: [
          for (final e in row.entries)
            e.copyWith(rect: e.rect.copyWith(top: runningTop)),
        ],
      );
      runningTop += _cardHeight + _rowVerticalSpacing;
    }

    final totalHeight = runningTop + _vGap;

    final viewer = middleRow.positionOf(
      b.middle.firstWhere(
        (m) => m.relationCode == 'SELF',
        orElse: () => b.middle.first,
      ).userId,
    );
    _CardRect? spouse;
    for (final m in b.middle) {
      if (m.relationCode == 'S') {
        spouse = middleRow.positionOf(m.userId);
        break;
      }
    }

    // The parent→middle drop and the middle→children drop are
    // independent. Either may be drawn alone, depending on which
    // rows are present. (Before, the children drop was gated on
    // `rows.length >= 3`, so a childless-without-parents family
    // hid the children row entirely.)
    final connectors = _ConnectorLayout(
      parentCouple: (parentsRow != null && b.parents.length >= 2)
          ? _CoupleMidpoint(
              left: parentsRow.positionOf(b.parents.first.userId),
              right: parentsRow.positionOf(b.parents.last.userId),
            )
          : null,
      parentSingle: (parentsRow != null && b.parents.length == 1)
          ? parentsRow.positionOf(b.parents.first.userId)
          : null,
      parentsRowBottomY: parentsRow?.rowBottomY,
      middleRowTopY: middleRow.rowTopY,
      middleRowBottomY: middleRow.rowBottomY,
      viewerPos: viewer,
      spousePos: spouse,
      childrenRowTopY: childrenRow?.rowTopY,
      childrenPositions: childrenRow != null
          ? [
              for (final m in b.children) childrenRow.positionOf(m.userId),
            ]
          : const [],
      leftSiblingBracketX: () {
        // The leftmost siblings (anything in `middle` that comes
        // before SELF in the sorted order) get a short bracket
        // that reaches up to the parents' drop-line.
        if (parentsRow == null) return null;
        if (middleRow.viewerIndexInRow < 0) return null;
        final leftSibs = <_CardRect>[];
        for (int i = 0; i < middleRow.viewerIndexInRow; i++) {
          if (b.middle[i].relationCode == 'S') continue;
          leftSibs.add(middleRow.positionOf(b.middle[i].userId));
        }
        if (leftSibs.isEmpty) return null;
        return leftSibs
            .map((p) => p.left + p.width / 2)
            .reduce((a, b) => a < b ? a : b);
      }(),
      rightSiblingBracketX: () {
        // Mirror of the above — siblings after SELF (excluding S).
        if (parentsRow == null) return null;
        if (middleRow.viewerIndexInRow < 0) return null;
        final rightSibs = <_CardRect>[];
        for (int i = middleRow.viewerIndexInRow + 1; i < b.middle.length; i++) {
          if (b.middle[i].relationCode == 'S') continue;
          rightSibs.add(middleRow.positionOf(b.middle[i].userId));
        }
        if (rightSibs.isEmpty) return null;
        return rightSibs
            .map((p) => p.left + p.width / 2)
            .reduce((a, b) => a > b ? a : b);
      }(),
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
              for (final row in presentRows) ...[
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
        if (b.extended.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
            child: _ExtendedList(
              members: b.extended,
              viewerId: viewerId,
              onRefresh: onRefresh,
              inline: true,
            ),
          ),
      ],
    );
  }

  // (helper kept for backward-compat — the canvas now computes the
  // total height from the running top inside _buildCanvas instead
  // of pre-computing it here)

  /// Build the bucket map from each member's `relationCode`.
  /// Anything we can't place in a row gets dropped into `extended`
  /// and shown as a list below the canvas.
  FamilyTreeBuckets _bucket(List<FamilyMemberVm> all) => bucketFamilyTreeMembers(all);

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
      final rowWidth = count * _cardWidth + (count - 1) * _hGap;
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
      final rightWidth = rightSibCount > 0
          ? rightSibCount * _cardWidth + (rightSibCount - 1) * _hGap
          : 0.0;
      final pairWidth = hasSpouse
          ? _cardWidth * 2 + _hGap
          : _cardWidth;
      final totalWidth = leftWidth +
          pairWidth +
          rightWidth +
          (leftSibCount > 0 ? _hGap : 0) +
          (rightSibCount > 0 ? _hGap : 0);
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
  final List<FamilyMemberVm> parents;
  final List<FamilyMemberVm> middle;
  final List<FamilyMemberVm> children;
  final List<FamilyMemberVm> extended;
  const FamilyTreeBuckets({
    required this.parents,
    required this.middle,
    required this.children,
    required this.extended,
  });
}

/// Public for the same reason as [FamilyTreeBuckets]. Pure function
/// — no widget context, no async, easy to drive from a unit test.
@visibleForTesting
FamilyTreeBuckets bucketFamilyTreeMembers(List<FamilyMemberVm> all) {
  final parents = <FamilyMemberVm>[];
  final middle = <FamilyMemberVm>[];
  final children = <FamilyMemberVm>[];
  final extended = <FamilyMemberVm>[];

  for (final m in all) {
    switch (m.relationCode) {
      case 'F':
        // Father pinned to the left of Gen -1
        parents.insert(0, m);
        break;
      case 'M':
        parents.add(m);
        break;
      case 'SELF':
      case 'S':
      case 'eB':
      case 'yB':
      case 'eZ':
      case 'yZ':
        middle.add(m);
        break;
      case 'Son':
      case 'Dau':
        children.add(m);
        break;
      default:
        extended.add(m);
        break;
    }
  }

  middle.sort((a, b) {
    // SELF first, then S (spouse pinned adjacent), then siblings
    // by relationCode so eB < yB < eZ < yZ in deterministic order.
    int rank(FamilyMemberVm m) {
      if (m.relationCode == 'SELF') return 0;
      if (m.relationCode == 'S') return 1;
      return 2;
    }

    final ra = rank(a);
    final rb = rank(b);
    if (ra != rb) return ra - rb;
    if (ra == 2) return a.relationCode.compareTo(b.relationCode);
    return 0;
  });

  children.sort((a, b) => a.relationCode.compareTo(b.relationCode));

  return FamilyTreeBuckets(
    parents: parents,
    middle: middle,
    children: children,
    extended: extended,
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
class _ConnectorLayout {
  final _CoupleMidpoint? parentCouple; // for Gen -1 marriage line
  final _CardRect? parentSingle; // single parent (no marriage line)
  final double? parentsRowBottomY;
  final double middleRowTopY;
  final double middleRowBottomY;
  final _CardRect viewerPos;
  final _CardRect? spousePos;
  final double? childrenRowTopY;
  final List<_CardRect> childrenPositions;
  final double? leftSiblingBracketX;
  final double? rightSiblingBracketX;

  const _ConnectorLayout({
    required this.parentCouple,
    required this.parentSingle,
    required this.parentsRowBottomY,
    required this.middleRowTopY,
    required this.middleRowBottomY,
    required this.viewerPos,
    required this.spousePos,
    required this.childrenRowTopY,
    required this.childrenPositions,
    required this.leftSiblingBracketX,
    required this.rightSiblingBracketX,
  });
}

/// Paints the family-tree connectors (marriage + parent→child drop
/// lines). Uses soft terracotta lines on top of the warm background
/// so the structure reads at a glance without competing with the
/// avatar circles.
class _FamilyTreePainter extends CustomPainter {
  final _ConnectorLayout c;
  static const double _strokeW = 1.4;
  static const double _dropGap = 24; // breathing room before each drop

  _FamilyTreePainter({required this.c});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = _strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Marriage line in Gen -1 (between Father & Mother)
    final couple = c.parentCouple;
    if (couple != null) {
      final y = (couple.left.bottom + couple.left.top) / 2 +
          _dropGap * 0.5;
      canvas.drawLine(
        Offset(couple.left.centerX, y),
        Offset(couple.right.centerX, y),
        paint,
      );
    }

    // 2. Drop from parents (or single parent) into the middle row.
    if (c.parentsRowBottomY != null &&
        (c.parentCouple != null || c.parentSingle != null)) {
      final startX = c.parentCouple?.x ?? c.parentSingle!.centerX;
      final startY = (c.parentCouple?.left.bottom ??
              c.parentSingle!.bottom) +
          _dropGap;
      final endY = c.middleRowTopY - _dropGap;
      // Drop to the bracket midpoint horizontally — but for the
      // middle row, we want to land at the bracket center if
      // siblings exist, otherwise at the viewer.
      final leftBracketX = c.leftSiblingBracketX;
      final rightBracketX = c.rightSiblingBracketX;
      double endX;
      if (leftBracketX != null && rightBracketX != null) {
        endX = (leftBracketX + rightBracketX) / 2;
      } else if (leftBracketX != null) {
        endX = leftBracketX;
      } else if (rightBracketX != null) {
        endX = rightBracketX;
      } else {
        endX = c.viewerPos.centerX;
      }
      // L-shape: vertical drop then horizontal spread.
      _drawL(canvas, paint, Offset(startX, startY), Offset(endX, endY));
    }

    // 3. Marriage line in Gen 0 (between viewer + spouse)
    if (c.spousePos != null) {
      final y = (c.viewerPos.bottom + c.viewerPos.top) / 2;
      final left = c.viewerPos.right < c.spousePos!.left
          ? c.viewerPos.right
          : c.viewerPos.centerX;
      final right = c.viewerPos.right < c.spousePos!.left
          ? c.spousePos!.left
          : c.spousePos!.centerX;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        paint,
      );
    }

    // 4. Drop from middle row down to the children row.
    if (c.childrenRowTopY != null && c.childrenPositions.isNotEmpty) {
      final startX = c.spousePos != null
          ? (c.viewerPos.centerX + c.spousePos!.centerX) / 2
          : c.viewerPos.centerX;
      final startY = c.viewerPos.bottom + _dropGap;
      final endY = c.childrenRowTopY! - _dropGap;
      // Fan out from startX to every child center via a single
      // horizontal bus + vertical drops.
      final childCenters =
          c.childrenPositions.map((p) => p.centerX).toList()..sort();
      final busY = endY - _dropGap / 2;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX, busY),
        paint,
      );
      if (childCenters.length == 1) {
        canvas.drawLine(
          Offset(startX, busY),
          Offset(childCenters.first, busY),
          paint,
        );
        canvas.drawLine(
          Offset(childCenters.first, busY),
          Offset(childCenters.first, endY),
          paint,
        );
      } else {
        final minX = childCenters.first;
        final maxX = childCenters.last;
        canvas.drawLine(
          Offset(startX, busY),
          Offset(minX, busY),
          paint,
        );
        canvas.drawLine(
          Offset(minX, busY),
          Offset(maxX, busY),
          paint,
        );
        for (final x in childCenters) {
          canvas.drawLine(
            Offset(x, busY),
            Offset(x, endY),
            paint,
          );
        }
      }
    }
  }

  void _drawL(Canvas canvas, Paint paint, Offset from, Offset to) {
    // Vertical down from `from`, then horizontal to `to.x`, then
    // vertical down to `to.y` — standard family-tree "L bracket".
    final midY = (from.dy + to.dy) / 2;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(from.dx, midY)
      ..lineTo(to.dx, midY)
      ..lineTo(to.dx, to.dy);
    canvas.drawPath(path, paint);
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
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isViewer
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 1),
          if (relationLabel != null)
            Text(
              relationLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isViewer
                    ? AppColors.primary
                    : AppColors.textHint,
                fontWeight: isViewer ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact list of "extended" relatives — in-laws, nieces/nephews,
/// cousins, great-grandparents — anything whose `relationCode` is
/// too complex to render on the canvas cleanly. Shows up under the
/// tree (or as the whole screen if the tree is empty).
class _ExtendedList extends StatelessWidget {
  final List<FamilyMemberVm> members;
  final int? viewerId;
  final Future<void> Function() onRefresh;
  final bool inline;

  const _ExtendedList({
    required this.members,
    required this.viewerId,
    required this.onRefresh,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale;
    final viewer = context.watch<AuthProvider>().currentUser;

    final body = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.diversity_3_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.familyTreeOtherFamily,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${members.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final m in members)
              _ExtendedTile(
                member: m,
                viewer: viewer,
                appLocale: locale,
              ),
          ],
        ),
      ),
    );

    if (inline) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                l10n.familyTreeOtherFamilyDesc(members.length),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ),
            body,
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [body],
      ),
    );
  }
}

class _ExtendedTile extends StatelessWidget {
  final FamilyMemberVm member;
  final AuthUser? viewer;
  final Locale appLocale;
  const _ExtendedTile({
    required this.member,
    required this.viewer,
    required this.appLocale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color =
        AppColors.avatarColorFor(member.userId, selfUserId: viewer?.userId);
    final label = relationLabelFor(
      relationCode: member.relationCode,
      targetGender: member.gender,
      viewerGender: genderFromString(viewer?.gender),
      appLocale: appLocale,
    );

    return ListTile(
      dense: true,
      leading: AvatarWidget(
        label: memberAvatarLabel(member.name),
        color: color,
        imageUrl: member.avatarUrl,
        radius: 18,
      ),
      title: Text(
        member.name,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        label ?? l10n.profileMe,
        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
      ),
      trailing: member.isOnline
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}