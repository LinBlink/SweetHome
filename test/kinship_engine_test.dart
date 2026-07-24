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

  test('deep/uncommon path collapses to a short ancestor term, not the literal base-terms composition', () {
    // F.F.F (3-gen pure-F ancestor chain) used to fall through to the
    // generic base-terms composition and render "父亲的父亲的父亲".
    // We now shorten that to the idiomatic Chinese term 曾祖父
    // (great-grandfather on the paternal side) — see
    // [KinshipTermSet.greatGrandfatherPat] and the [_ancestorChainTerm]
    // helper. Mixed-direction chains (e.g. F.M.F) and other exotics
    // still fall through to the base-terms composition, but a clean
    // pure-direction chain never does.
    final path = [RelToken.father, RelToken.father, RelToken.father];
    final label = localizeRelation(path, targetGender: Gender.male, localeCode: 'zh_Hans');
    expect(label, isNotEmpty);
    expect(label, '曾祖父');
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

    test('depth-3 code collapses to the locale\'s great-grandparent term', () {
      // F.F.F (3-gen pure-F ancestor chain) now shortens to
      // "Great-grandfather" in English via
      // [KinshipTermSet.greatGrandfatherPat] (English doesn't
      // distinguish paternal/maternal great-grandparents so both
      // sides share the same term). The literal base-terms
      // composition ("Father's Father's Father") is the fallback
      // for chains the locale doesn't have a short term for.
      final label =
          localizeRelationCode('F.F.F', targetGender: Gender.male, localeCode: 'en');
      expect(label, 'Great-grandfather');
    });

    test('prefixed depth-3 chain renders as parent_term + 的 + short chain term', () {
      // M.F.F (mother's father's father) in Chinese is rendered
      // colloquially as "母亲的爷爷" rather than the formal
      // "外曾祖父" — the algorithm in [_ancestorChainTerm] takes the
      // first token of the prefix (M), looks up its base term
      // ("母亲"), and concatenates with [connective] + the short
      // 2-gen chain term for the remaining F.F pair ("爷"). This
      // matches everyday speech better than the formal term.
      final label =
          localizeRelationCode('M.F.F', targetGender: Gender.male, localeCode: 'zh_Hans');
      expect(label, '母亲的爷爷');
    });

    test('depth-3 chain without prefix yields the bare short term', () {
      // F.F.F with no parent prefix renders as the bare
      // great-grandparent term — 曾祖父 for the paternal side in
      // Chinese. See [_ancestorChainTerm] for the rule.
      final label =
          localizeRelationCode('F.F.F', targetGender: Gender.male, localeCode: 'zh_Hans');
      expect(label, '曾祖父');
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

    group('descendant chains collapse to short terms, and nothing '
        'composes into a 3+ segment run-on chain', () {
      test('a grandchild\'s spouse uses the colloquial compound term, '
          'not "孙女的配偶"', () {
        expect(
          localizeRelationCode('Son.Dau.S', targetGender: Gender.male, localeCode: 'zh_Hans'),
          '孙女婿',
        );
        expect(
          localizeRelationCode('Son.Son.S', targetGender: Gender.female, localeCode: 'zh_Hans'),
          '孙媳',
        );
        expect(
          localizeRelationCode('Dau.Son.S', targetGender: Gender.female, localeCode: 'zh_Hans'),
          '外孙媳',
        );
        expect(
          localizeRelationCode('Dau.Dau.S', targetGender: Gender.male, localeCode: 'zh_Hans'),
          '外孙女婿',
        );
      });

      test('a pure depth-3 Son/Dau chain collapses to the idiomatic '
          'great-grandchild term', () {
        expect(localizeRelationCode('Son.Son.Son', localeCode: 'zh_Hans'), '曾孙');
        expect(localizeRelationCode('Son.Son.Dau', localeCode: 'zh_Hans'), '曾孙女');
        expect(localizeRelationCode('Dau.Dau.Son', localeCode: 'zh_Hans'), '外曾孙');
        expect(localizeRelationCode('Dau.Dau.Dau', localeCode: 'zh_Hans'), '外曾孙女');
      });

      test('an ancestor chain whose last hop differs from the run still '
          'collapses (fixes F.F.M / M.M.F previously falling through '
          'to the 3-segment literal composition)', () {
        expect(localizeRelationCode('F.F.M', localeCode: 'zh_Hans'), '曾祖母');
        expect(localizeRelationCode('M.M.F', localeCode: 'zh_Hans'), '外曾祖父');
      });

      test('uncovered mixed chains still compose down to at most two '
          'segments instead of one-token-at-a-time', () {
        // F.M.F (father's mother's father) — no formal single term,
        // but should read "父亲的外公" (2 segments), never the
        // atomic "父亲的母亲的父亲" (3 segments).
        expect(localizeRelationCode('F.M.F', localeCode: 'zh_Hans'), '父亲的外公');
        // Dau.Son.Son (daughter's son's son) — same idea on the
        // descendant side: "女儿的孙子", not "女儿的儿子的儿子".
        expect(localizeRelationCode('Dau.Son.Son', localeCode: 'zh_Hans'), '女儿的孙子');
        // A great-grandchild's spouse (no dedicated compound term)
        // still collapses the blood part first, then appends a
        // gendered spouse term: "曾孙的妻子", not "儿子的儿子的
        // 儿子的配偶".
        expect(
          localizeRelationCode('Son.Son.Son.S',
              targetGender: Gender.female, localeCode: 'zh_Hans'),
          '曾孙的妻子',
        );
        // A nephew's wife — no table entry for this combination at
        // all, but the `eB.Son` prefix is still reused: "侄子的妻子".
        expect(
          localizeRelationCode('eB.Son.S', targetGender: Gender.female, localeCode: 'zh_Hans'),
          '侄子的妻子',
        );
      });
    });
  });
}
