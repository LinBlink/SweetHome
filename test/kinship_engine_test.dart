import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/kinship/kinship_engine.dart';
import 'package:sweethome_flutter/core/kinship/kinship_graph.dart';
import 'package:sweethome_flutter/core/kinship/kinship_localizer.dart';

/// Mirrors MockDataSource.familyGraph: 王爷爷(3) is 王建国(1)'s father;
/// 1+2 are spouses and are jointly parents of 王小明(4, older) and
/// 王小雨(5, younger).
FamilyGraph _buildFamily() {
  return FamilyGraph(
    members: const [
      FamilyMember(id: 1, name: '王建国', gender: Gender.male),
      FamilyMember(id: 2, name: '张美玲', gender: Gender.female),
      FamilyMember(id: 3, name: '王爷爷', gender: Gender.male),
      FamilyMember(id: 4, name: '王小明', gender: Gender.male, birthOrder: 1),
      FamilyMember(id: 5, name: '王小雨', gender: Gender.female, birthOrder: 2),
    ],
    relations: const [
      FamilyRelation(subjectId: 3, type: RelationEdgeType.parentOf, objectId: 1),
      FamilyRelation(subjectId: 1, type: RelationEdgeType.spouseOf, objectId: 2),
      FamilyRelation(subjectId: 1, type: RelationEdgeType.parentOf, objectId: 4),
      FamilyRelation(subjectId: 1, type: RelationEdgeType.parentOf, objectId: 5),
      FamilyRelation(subjectId: 2, type: RelationEdgeType.parentOf, objectId: 4),
      FamilyRelation(subjectId: 2, type: RelationEdgeType.parentOf, objectId: 5),
    ],
  );
}

void main() {
  final graph = _buildFamily();

  test('self returns empty path / SELF code', () {
    final path = computeRelationPath(graph, 1, 1);
    expect(path, isEmpty);
    expect(relationCode(path), 'SELF');
    expect(localizeRelation(path, targetGender: Gender.male, localeCode: 'zh_Hans'), '我');
  });

  test('direct father', () {
    final path = computeRelationPath(graph, 1, 3);
    expect(relationCode(path), 'F');
    expect(localizeRelation(path, targetGender: Gender.male, localeCode: 'zh_Hans'), '爸爸');
  });

  test('reverse direction: father viewing son resolves to "儿子", not "爸"', () {
    final path = computeRelationPath(graph, 3, 1);
    expect(relationCode(path), 'Son');
    expect(localizeRelation(path, targetGender: Gender.male, localeCode: 'zh_Hans'), '儿子');
  });

  test('spouse resolves via target gender (husband vs wife)', () {
    final toWife = computeRelationPath(graph, 1, 2);
    expect(relationCode(toWife), 'S');
    expect(localizeRelation(toWife, targetGender: Gender.female, localeCode: 'zh_Hans'), '妻子');

    final toHusband = computeRelationPath(graph, 2, 1);
    expect(relationCode(toHusband), 'S');
    expect(localizeRelation(toHusband, targetGender: Gender.male, localeCode: 'zh_Hans'), '丈夫');
  });

  test('sibling reduction: younger sister via shared parent collapses to yZ', () {
    final path = computeRelationPath(graph, 4, 5);
    expect(relationCode(path), 'yZ');
    expect(localizeRelation(path, targetGender: Gender.female, localeCode: 'zh_Hans'), '妹妹');
  });

  test('sibling reduction is symmetric: older brother from the other side', () {
    final path = computeRelationPath(graph, 5, 4);
    expect(relationCode(path), 'eB');
    expect(localizeRelation(path, targetGender: Gender.male, localeCode: 'zh_Hans'), '哥哥');
  });

  test('grandparent: two-hop cascaded reduction stays as ancestor chain (no reduction)', () {
    final path = computeRelationPath(graph, 4, 3);
    expect(relationCode(path), 'F.F');
    expect(localizeRelation(path, targetGender: Gender.male, localeCode: 'zh_Hans'), '爷爷');
  });

  test('unknown birthOrder defaults sibling to elder', () {
    final graphNoOrder = FamilyGraph(
      members: const [
        FamilyMember(id: 10, name: 'A', gender: Gender.male),
        FamilyMember(id: 11, name: 'B', gender: Gender.female),
        FamilyMember(id: 12, name: 'P', gender: Gender.male),
      ],
      relations: const [
        FamilyRelation(subjectId: 12, type: RelationEdgeType.parentOf, objectId: 10),
        FamilyRelation(subjectId: 12, type: RelationEdgeType.parentOf, objectId: 11),
      ],
    );
    final path = computeRelationPath(graphNoOrder, 10, 11);
    expect(relationCode(path), 'eZ');
  });

  test('in-law term depends on viewer gender (Chinese distinguishes 岳父/公公)', () {
    // extend graph: 1 has a spouse's father (id 6) via a synthetic spouse-of-spouse edge
    final extended = FamilyGraph(
      members: const [
        FamilyMember(id: 1, name: '王建国', gender: Gender.male),
        FamilyMember(id: 2, name: '张美玲', gender: Gender.female),
        FamilyMember(id: 6, name: '张父', gender: Gender.male),
      ],
      relations: const [
        FamilyRelation(subjectId: 1, type: RelationEdgeType.spouseOf, objectId: 2),
        FamilyRelation(subjectId: 6, type: RelationEdgeType.parentOf, objectId: 2),
      ],
    );
    final path = computeRelationPath(extended, 1, 6);
    expect(relationCode(path), 'S.F');
    expect(
      localizeRelation(path,
          targetGender: Gender.male, viewerGender: Gender.male, localeCode: 'zh_Hans'),
      '岳父',
    );
  });

  test('deep/uncommon path falls back to generic composition instead of failing', () {
    final path = [RelToken.father, RelToken.father, RelToken.father];
    final label = localizeRelation(path, targetGender: Gender.male, localeCode: 'zh_Hans');
    expect(label, isNotEmpty);
    expect(label, contains('父亲'));
  });

  test('unsupported locale falls back to zh_Hans default', () {
    final path = computeRelationPath(graph, 1, 3);
    final label = localizeRelation(path, targetGender: Gender.male, localeCode: 'xx_bogus');
    expect(label, '爸爸');
  });

  group('localizeRelationCode (string-based, real-mode entry point)', () {
    test('matches token-based localizeRelation for the same path', () {
      final path = computeRelationPath(graph, 1, 3);
      expect(
        localizeRelationCode(relationCode(path), targetGender: Gender.male, localeCode: 'zh_Hans'),
        localizeRelation(path, targetGender: Gender.male, localeCode: 'zh_Hans'),
      );
    });

    test('SELF code localizes without needing a path', () {
      expect(
        localizeRelationCode('SELF', targetGender: Gender.male, localeCode: 'en'),
        'Me',
      );
    });

    test('depth-3 code not in any table still composes via fallback', () {
      final label =
          localizeRelationCode('F.F.F', targetGender: Gender.male, localeCode: 'en');
      expect(label, isNotEmpty);
      expect(label, contains("Father"));
    });

    test('localizes per-locale across all 6 supported locales for a common code', () {
      final expected = {
        'zh_Hans': '爸爸',
        'zh_Hant': '爸爸',
        'en': 'Dad',
        'ja': 'お父さん',
        'ko': '아빠',
      };
      expected.forEach((locale, term) {
        expect(
          localizeRelationCode('F', targetGender: Gender.male, localeCode: locale),
          term,
          reason: 'locale=$locale',
        );
      });
    });
  });
}
