import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/kinship/kinship_graph.dart';
import 'package:sweethome_flutter/models/family_member_vm.dart';
import 'package:sweethome_flutter/screens/family_tree_screen.dart';

/// Regression coverage for the family-tree bucketing that decides
/// which row each member lands in. Before this test the
/// `_buildCanvas` indexing went `rows[0] / rows[1] / rows[2]` in
/// list order, so a family with no parents would route the
/// middle row to `rows[0]` while the connector code still treated
/// `rows[1]` as the middle — a layout that hid the children row
/// entirely. The fix is to track rows by semantic role
/// (parents / middle / children), each nullable.
///
/// `bucketFamilyTreeMembers` is the pure data transform the
/// canvas feeds from. These tests pin down the buckets
/// composition for every family shape the screen needs to
/// handle.
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

  group('bucketFamilyTreeMembers', () {
    test('standard 4-person family puts each member in the right row', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '妻', 'S', g: Gender.female),
        vm(3, '父', 'F'),
        vm(4, '子', 'Son'),
      ]);
      expect(b.parents.map((m) => m.userId), [3]);
      expect(b.middle.map((m) => m.userId), [1, 2]);
      expect(b.children.map((m) => m.userId), [4]);
      expect(b.extended, isEmpty);
    });

    test('both parents in the family: father on the left, mother on '
        'the right', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '母', 'M', g: Gender.female),
        vm(3, '父', 'F'),
      ]);
      expect(b.parents.map((m) => m.userId), [3, 2]);
    });

    test('middle row puts SELF before S before any siblings', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '妹', 'yZ', g: Gender.female),
        vm(3, '妻', 'S', g: Gender.female),
        vm(4, '哥', 'eB'),
        vm(5, '弟', 'yB'),
      ]);
      expect(b.middle.map((m) => m.relationCode).toList(),
          ['SELF', 'S', 'eB', 'yB', 'yZ']);
    });

    test('family with only SELF (no parents, no children, no spouse)', () {
      // The lowest-case family — bucket still produces a valid
      // canvas input (middle = [SELF], everything else empty),
      // and the canvas must still render without crashing.
      final b = bucketFamilyTreeMembers([vm(1, '我', 'SELF')]);
      expect(b.parents, isEmpty);
      expect(b.children, isEmpty);
      expect(b.extended, isEmpty);
      expect(b.middle.map((m) => m.userId), [1]);
    });

    test('family without parents but with children still buckets the '
        'children row', () {
      // The original bug: a family with no parents but with kids
      // would route the middle row to `rows[0]` while the
      // children row was hidden because the painter gated
      // `hasChildrenRow = rows.length >= 3`. After the fix the
      // children row is independent of whether parents exist.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '妻', 'S', g: Gender.female),
        vm(3, '子', 'Son'),
        vm(4, '女', 'Dau', g: Gender.female),
      ]);
      expect(b.parents, isEmpty);
      expect(b.middle.map((m) => m.userId), [1, 2]);
      // Children are sorted alphabetically by relationCode
      // (D < S), so Dau lands at index 0 and Son at index 1.
      expect(b.children.map((m) => m.relationCode).toList(),
          ['Dau', 'Son']);
    });

    test('children row is sorted by relationCode (Dau before Son '
        'alphabetically)', () {
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '女', 'Dau', g: Gender.female),
        vm(3, '子', 'Son'),
      ]);
      // The sort is alphabetical on the relationCode string,
      // not birth-order — Dau < Son by char code ('D' < 'S').
      expect(b.children.map((m) => m.relationCode).toList(),
          ['Dau', 'Son']);
    });

    test('relations outside the row taxonomy go to extended', () {
      // In-laws (S.F), cousins (F.eB), etc. all land in extended
      // rather than forcing them into a row they don't fit.
      final b = bucketFamilyTreeMembers([
        vm(1, '我', 'SELF'),
        vm(2, '妻', 'S', g: Gender.female),
        vm(3, '岳父', 'S.F'),
        vm(4, '叔叔', 'F.eB'),
        vm(5, '侄子', 'eB.Son'),
      ]);
      expect(b.extended.map((m) => m.userId), [3, 4, 5]);
      expect(b.parents, isEmpty);
      expect(b.children, isEmpty);
    });
  });
}
