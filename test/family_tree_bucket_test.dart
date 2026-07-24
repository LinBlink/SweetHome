import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/kinship/kinship_graph.dart';
import 'package:sweethome_flutter/models/family_member_vm.dart';
import 'package:sweethome_flutter/screens/family_tree_screen.dart';

/// Regression coverage for the family-tree bucketing that decides
/// which row each member lands in. The new (post-extension-removal)
/// design buckets purely by kinship GENERATION — every member finds a
/// row in [-N..+N] of the viewer, so cousins-of-uncle's-child,
/// great-grandparents, etc. all get their own row instead of being
/// hidden behind an "其他亲属" (Other relatives) bucket.
///
/// `bucketFamilyTreeMembers` is the pure data transform the canvas
/// feeds from. These tests pin down the bucket composition for every
/// family shape the screen needs to handle.
void main() {
  FamilyMemberVm vm(
    int id,
    String name,
    String code, {
    Gender g = Gender.male,
  }) {
    return FamilyMemberVm(
      userId: id,
      name: name,
      gender: g,
      relationCode: code,
      role: 'member',
    );
  }

  /// Resolve the [FamilyTreeRow] at [generation], or null if absent.
  FamilyTreeRow? rowAt(FamilyTreeBuckets b, int generation) {
    for (final r in b.rows) {
      if (r.generation == generation) return r;
    }
    return null;
  }

  /// Convenience: the userId list of the row at [generation].
  List<int> idsAt(FamilyTreeBuckets b, int generation) => [
        for (final m in rowAt(b, generation)?.members ?? const <FamilyMemberVm>[])
          m.userId,
      ];

  /// Convenience: the relationCode list of the row at [generation].
  List<String> codesAt(FamilyTreeBuckets b, int generation) => [
        for (final m in rowAt(b, generation)?.members ?? const <FamilyMemberVm>[])
          m.relationCode,
      ];

  group('bucketFamilyTreeMembers', () {
    test('SELF is at generation 0, parents at -1, children at +1', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '妻', 'S', g: Gender.female),
        vm(3, '父', 'F'),
        vm(4, '子', 'Son'),
      ]);
      // 3 generations present in the bucket list: -1 (father),
      // 0 (SELF + S), +1 (Son). The canvas paints index 0 at the
      // top, so index 0 = parents (most ancestral of those present),
      // index 1 = SELF's row, index 2 = children (most recent).
      expect(b.rows.map((r) => r.generation).toList(), [-1, 0, 1]);
      expect(idsAt(b, -1), [3]);
      // Generation 0 is sorted alphabetically by relationCode; 'S'
      // (1 char) < 'SELF' (4 chars) lexicographically, so the spouse
      // (userId 2) lands before SELF (userId 1). That's fine — the
      // canvas anchors SELF's X-position by relationCode, not by row
      // index, so the actual left-to-right visual order in the row
      // is fine; we only care that both ended up at gen 0.
      expect(idsAt(b, 0), containsAll([1, 2]));
      expect(idsAt(b, 1), [4]);
    });

    test('grandparents are at generation -2', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '母', 'M', g: Gender.female),
        vm(3, '父', 'F'),
        vm(4, '爷', 'F.F'),
        vm(5, '奶', 'F.M', g: Gender.female),
        vm(6, '公', 'M.F'),
        vm(7, '婆', 'M.M', g: Gender.female),
      ]);
      // Grandparents at -2 (F.F, F.M, M.F, M.M), parents at -1
      // (F, M), SELF at 0.
      expect(codesAt(b, -2), ['F.F', 'F.M', 'M.F', 'M.M']);
      expect(codesAt(b, -1), ['F', 'M']);
      expect(codesAt(b, 0), ['SELF']);
    });

    test('great-grandparents land at generation -3 (no "extended" '
        'fallback)', () {
      // The whole point of the refactor: nothing goes to "其他亲属"
      // anymore. F.F.F (paternal great-grandfather) lives in its own
      // row at generation -3.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '爷', 'F.F'),
        vm(3, '太爷', 'F.F.F'),
      ]);
      expect(codesAt(b, -3), ['F.F.F']);
      expect(codesAt(b, -2), ['F.F']);
      expect(codesAt(b, 0), ['SELF']);
      // Sanity: every member found a row, nothing is dropped.
      expect(b.rows.expand((r) => r.members).length, 3);
    });

    test('grandchildren (Son.Son, Son.Dau, Dau.Son, Dau.Dau) all '
        'land in their own row at generation +2', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '子', 'Son'),
        vm(3, '孙', 'Son.Son'),
        vm(4, '孙女', 'Son.Dau', g: Gender.female),
        vm(5, '女', 'Dau', g: Gender.female),
        vm(6, '外孙', 'Dau.Son'),
      ]);
      expect(codesAt(b, 1), ['Dau', 'Son']);
      expect(codesAt(b, 2), ['Dau.Son', 'Son.Dau', 'Son.Son']);
    });

    test('great-grandchildren land at generation +3 (no "extended")', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '孙', 'Son.Son'),
        vm(3, '曾孙', 'Son.Son.Son'),
      ]);
      expect(codesAt(b, 0), ['SELF']);
      expect(codesAt(b, 2), ['Son.Son']);
      expect(codesAt(b, 3), ['Son.Son.Son']);
    });

    test('in-laws at every depth land in the same generation as the '
        'blood relatives they share with — the S step is generation-'
        'neutral', () {
      // F.F.F + S.F.F.F = both great-grandparents, generation -3.
      // Spouse S doesn't shift the generation, just changes the path
      // through the family graph.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '爷', 'F.F'),
        vm(3, '太爷', 'F.F.F'),
        vm(4, '岳太爷', 'S.F.F.F'),
      ]);
      expect(codesAt(b, -3), ['F.F.F', 'S.F.F.F']);
    });

    test('spouse\'s siblings land in generation 0 (same as viewer) '
        'and nephews land in generation +1 (same as children) — both '
        'in their own rows, not "extended"', () {
      // Before the refactor:
      //   F.eB → extended  ("Gen -1 sibling — would need a fourth row")
      //   eB.Son → middle row
      // After the refactor: both find their own generation by
      // token-walking and end up at the right depth.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '妻', 'S', g: Gender.female),
        vm(3, '哥', 'eB'),
        vm(4, '大舅子', 'S.eB'),
        vm(5, '侄子', 'eB.Son', g: Gender.male),
        vm(6, '外甥', 'S.eB.Son'),
      ]);
      // SELF + S + eB + S.eB all at generation 0 (S and S.xB are
      // sibling-equivalent to eB, sharing F+M as a generation
      // anchor... wait, S.xB is the spouse's sibling, same gen as
      // viewer; eB is the viewer's sibling, same gen as viewer).
      // Both land in generation 0 along with SELF and S.
      expect(codesAt(b, 0), containsAll(['SELF', 'S', 'eB', 'S.eB']));
      // eB.Son is viewer's nephew (one gen down). S.eB.Son is
      // spouse's nephew (also one gen down). Both at generation +1.
      expect(codesAt(b, 1), containsAll(['eB.Son', 'S.eB.Son']));
    });

    test('F.eB (paternal uncle) lands in its own row at -1, not in '
        '"extended"', () {
      // The bug that motivated the refactor: F.eB is a sibling of
      // the viewer's father, so the generation is -1 (one above the
      // parents row). Pre-refactor, this fell into the catch-all
      // "extended" bucket and got hidden behind a list at the
      // bottom of the screen.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '叔叔', 'F.eB'),
      ]);
      expect(codesAt(b, -1), ['F.eB']);
      expect(codesAt(b, 0), ['SELF']);
    });

    test('a child\'s spouse (Son.S / Dau.S) lands in the children '
        'row at +1, not in "extended"', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '子', 'Son'),
        vm(3, '儿媳', 'Son.S', g: Gender.female),
        vm(4, '女', 'Dau', g: Gender.female),
        vm(5, '女婿', 'Dau.S'),
      ]);
      // Children row: SELF + 4 (Dau) + 5 (Dau.S) + 2 (Son) + 3 (Son.S)
      // — sorted by relationCode alphabetically: Dau, Dau.S, Son, Son.S.
      expect(codesAt(b, 1), ['Dau', 'Dau.S', 'Son', 'Son.S']);
    });

    test('an in-law spouse whose blood counterpart is missing still '
        'lands in the same generation (not in "extended")', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '女', 'Dau', g: Gender.female),
        // No 'Son' in this family, so this Son.S can't be paired.
        vm(3, '儿媳', 'Son.S', g: Gender.female),
      ]);
      expect(codesAt(b, 1), ['Dau', 'Son.S']);
    });

    test('every member lands in exactly one row, no "extended" '
        'fallback — the whole family gets a row', () {
      // Multigenerational family exercising every bucket case the
      // previous design had to special-case.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '妻', 'S', g: Gender.female),
        vm(3, '父', 'F'),
        vm(4, '母', 'M', g: Gender.female),
        vm(5, '岳父', 'S.F'),
        vm(6, '岳母', 'S.M', g: Gender.female),
        vm(7, '哥', 'eB'),
        vm(8, '姑', 'F.eZ', g: Gender.female),
        vm(9, '堂兄', 'F.eB.Son'),
        vm(10, '子', 'Son'),
        vm(11, '女', 'Dau', g: Gender.female),
        vm(12, '儿媳', 'Son.S', g: Gender.female),
        vm(13, '孙', 'Son.Son'),
        vm(14, '孙女', 'Son.Dau', g: Gender.female),
        vm(15, '外孙', 'Dau.Son'),
        vm(16, '曾孙', 'Son.Son.Son'),
      ]);
      // Every member should be in some row, no one is dropped.
      final totalMembers =
          b.rows.fold<int>(0, (acc, r) => acc + r.members.length);
      expect(totalMembers, 16);
      // Spot-check a few key rows. Note: this fixture doesn't have
      // F.F (great-grandparents), so gen -2 is empty. F.eZ is the
      // viewer's paternal aunt — same generation as the parents
      // (F.eZ token-walks to -1 + 0 = -1), NOT same as the viewer's
      // generation. F.eB.Son (cousin, the viewer's father's brother's
      // son) also walks to -1 + 0 + 1 = 0 — same gen as the viewer.
      expect(rowAt(b, -2), isNull);
      expect(codesAt(b, -1), containsAll(['F', 'M', 'S.F', 'S.M', 'F.eZ']));
      expect(codesAt(b, 0), containsAll(['SELF', 'S', 'eB', 'F.eB.Son']));
      expect(codesAt(b, 1), containsAll(['Dau', 'Son', 'Son.S']));
      expect(codesAt(b, 2), containsAll(['Dau.Son', 'Son.Dau', 'Son.Son']));
      expect(codesAt(b, 3), containsAll(['Son.Son.Son']));
    });

    test('rows are sorted by generation descending (ancestors '
        'first, descendants last)', () {
      // The canvas paints top-down, so the bucket list's order
      // must put great-grandparents at index 0 and great-grandchildren
      // at the last index.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '太爷', 'F.F.F'),
        vm(3, '爷', 'F.F'),
        vm(4, '孙', 'Son.Son'),
      ]);
      expect(b.rows.map((r) => r.generation).toList(), [-3, -2, 0, 2]);
    });
  });

  group('computeInterRowDropCodes', () {
    test('F→SELF drop is computed even though SELF has no relationCode', () {
      // Regression: previously the connector builder derived each
      // lower-row member's parent code by stripping the last
      // dot-segment of its relationCode. SELF has no relationCode
      // (it's empty), so the strip rule returned null and the
      // F→SELF trunk was never added — leaving the upper half of
      // the tree visually disconnected from the viewer card. The
      // builder now special-cases SELF to pick whichever blood
      // parent (F preferred, then M) sits in the upper row.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '父', 'F'),
        vm(3, '子', 'Son'),
      ]);
      // Three rows: F (gen -1), SELF (gen 0), Son (gen 1). Two
      // inter-row drops expected: F→SELF, SELF→Son.
      final drops = computeInterRowDropCodes(b.rows);
      expect(drops, hasLength(2));
      expect(drops[0].parent, 'F');
      expect(drops[0].children, ['SELF']);
      expect(drops[1].parent, 'SELF');
      expect(drops[1].children, ['Son']);
    });

    test('M is used as the SELF parent when F is absent in the upper row', () {
      // A single-mother family: M (gen -1) + SELF (gen 0). The
      // SELF connector should fall through to M.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '母', 'M', g: Gender.female),
      ]);
      final drops = computeInterRowDropCodes(b.rows);
      expect(drops, hasLength(1));
      expect(drops[0].parent, 'M');
      expect(drops[0].children, ['SELF']);
    });

    test('F is preferred over M when both are present in the upper row', () {
      // Both parents present in the upper row, both connected to
      // SELF. The builder picks F (the canonical "primary" parent)
      // to keep the trunk to a single source.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '父', 'F'),
        vm(3, '母', 'M', g: Gender.female),
      ]);
      final drops = computeInterRowDropCodes(b.rows);
      expect(drops, hasLength(1));
      expect(drops[0].parent, 'F');
      expect(drops[0].children, ['SELF']);
    });

    test('arbitrary-depth chains (F.F.F → F.F → F → SELF) each get a drop', () {
      // Five-row family exercising every step of the parent-code
      // strip rule (no SELF special-cases needed past the
      // SELF row, since every other member has a non-empty
      // relationCode).
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '父', 'F'),
        vm(3, '爷', 'F.F'),
        vm(4, '太爷', 'F.F.F'),
        vm(5, '高祖', 'F.F.F.F'),
      ]);
      final drops = computeInterRowDropCodes(b.rows);
      // Five-row pure ancestor chain: F.F.F.F (gen -4), F.F.F
      // (gen -3), F.F (gen -2), F (gen -1), SELF (gen 0). The
      // builder walks top-down and finds each row's direct parent
      // in the rows above. For ancestor chains the direct parent
      // has one MORE dot-segment than the child (the algorithm
      // appends another F/M token matching the chain direction),
      // so the expected drops are:
      //   F.F.F.F  →  F.F.F.F.F  (one gen older) — NOT in data, skip
      //   F.F.F.F  →  F.F.F      (append F)  ✓
      //   F.F.F    →  F.F.F.F    (append F)  ✓
      //   F.F      →  F.F.F      (append F)  ✓
      //   F        →  F.F        (append F)  ✓
      //   SELF     →  F          (special)  ✓
      // So 4 drops: F.F.F→F.F.F.F is the first; F→SELF is the
      // last. The very topmost row (F.F.F.F) has no parent in the
      // data (F.F.F.F.F is missing), so it gets no drop.
      expect(drops, hasLength(4));
      expect(drops[0].parent, 'F.F.F.F');
      expect(drops[0].children, ['F.F.F']);
      expect(drops[1].parent, 'F.F.F');
      expect(drops[1].children, ['F.F']);
      expect(drops[2].parent, 'F.F');
      expect(drops[2].children, ['F']);
      expect(drops[3].parent, 'F');
      expect(drops[3].children, ['SELF']);
    });

    test('S (spouse) is never treated as a child of the upper row', () {
      // The spouse S is at the viewer's generation. Its
      // relationCode is 'S' (no dot), and [_parentRelationCodeOf]
      // returns null for S because the single-token S/eB/yB/eZ/yZ
      // shapes have no parent above them in the family tree.
      // The builder must therefore NOT add an F→S drop, even
      // though it does add an F→SELF drop in the same data.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '妻', 'S', g: Gender.female),
        vm(3, '父', 'F'),
      ]);
      final drops = computeInterRowDropCodes(b.rows);
      expect(drops, hasLength(1));
      expect(drops[0].parent, 'F');
      // S is NOT in the children list — only SELF is.
      expect(drops[0].children, ['SELF']);
    });

    test('M↔M.F drop: maternal grandfather connects down to mother', () {
      // Regression: previously the ancestor-chain branch only
      // tried appending the SAME direction (so `M` looked for
      // `M.M` as its parent), missing the family-graph parent
      // `M.F` (the maternal grandfather) whenever the data only
      // carries that mixed-direction branch. The maternal-line
      // trunk from `M.F` down to `M` was therefore never drawn,
      // and `M` showed up as a floating card with no line up to
      // its grandparent.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '母', 'M', g: Gender.female),
        vm(3, '外公', 'M.F'),
      ]);
      // Three rows: M.F (gen -2), M (gen -1), SELF (gen 0). Two
      // drops expected: M.F → M, and M → SELF (per the standard
      // SELF-special-case rule).
      final drops = computeInterRowDropCodes(b.rows);
      expect(drops, hasLength(2));
      expect(drops[0].parent, 'M.F');
      expect(drops[0].children, ['M']);
      expect(drops[1].parent, 'M');
      expect(drops[1].children, ['SELF']);
    });

    test('mixed-direction chains: M.F.F connects up to M.F', () {
      // Same opposite-direction rule applies one level deeper:
      // M.F.F (great-grandfather on the maternal side) should
      // connect up to M.F (the maternal grandfather). The "direct
      // parent in the family graph" of M.F.F is M.F.F.F or
      // M.F.M; the candidate generator tries opposite first
      // (M.F.F.M) then same (M.F.F.F), and the caller-side
      // `upperCodes.contains` filter accepts whichever is in the
      // data. Here only M.F is in the data so no drop is drawn for
      // M.F.F's parent — but the M.F.F → M.F drop must still be
      // there because M.F is one generation above M.F.F.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '母', 'M', g: Gender.female),
        vm(3, '外公', 'M.F'),
        vm(4, '外曾祖', 'M.F.F'),
      ]);
      final drops = computeInterRowDropCodes(b.rows);
      // Drops top-down:
      //   M.F.F → M.F (yes — M.F in upper rows when M.F.F's row
      //              is processed)
      //   M.F → M   (yes — M's parent candidates M.M and M.F, the
      //              latter is in the upper rows)
      //   M → SELF  (yes — standard SELF special case)
      // M.F.F has no parent in the data above it (only M.F.F.F or
      // M.F.M would qualify, neither present).
      expect(drops, hasLength(3));
      expect(drops[0].parent, 'M.F.F');
      expect(drops[0].children, ['M.F']);
      expect(drops[1].parent, 'M.F');
      expect(drops[1].children, ['M']);
      expect(drops[2].parent, 'M');
      expect(drops[2].children, ['SELF']);
    });
  });
}
