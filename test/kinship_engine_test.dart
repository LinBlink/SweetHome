import 'dart:math';

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

  test('spouse gender lives in the code itself (Wi vs Hu)', () {
    // These two directions used to produce the same code 'S', so the
    // spouse's gender had to be supplied separately for the localizer to
    // pick 妻子 vs 丈夫 — and rendered blank whenever it wasn't known.
    final toWife = computeRelationPath(graph, 1, 2);
    expect(relationCode(toWife), 'Wi');
    expect(localizeRelation(toWife, localeCode: 'zh_Hans'), '妻子');

    final toHusband = computeRelationPath(graph, 2, 1);
    expect(relationCode(toHusband), 'Hu');
    expect(localizeRelation(toHusband, localeCode: 'zh_Hans'), '丈夫');
  });

  test('spouse label no longer needs a gender argument to render', () {
    // The old contract returned null for 'S' with no targetGender, which is
    // why spouse labels showed up empty in chat.
    expect(localizeRelationCode('Wi', localeCode: 'zh_Hans'), '妻子');
    expect(localizeRelationCode('Hu', localeCode: 'zh_Hans'), '丈夫');
    // Gender genuinely unknown still yields a neutral term rather than null.
    expect(localizeRelationCode('S', localeCode: 'zh_Hans'), '配偶');
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

  group('path selection is deterministic and blood-first', () {
    // Mirrors KinshipEngineTest.resultIsIndependentOfRelationOrder on the
    // backend: the relation list order must not affect the result, because
    // the query that produces it has no ORDER BY and the database is free to
    // return rows however it likes.
    //
    // The fixture is a child with two recorded fathers (biological + adoptive)
    // — an ordinary situation, and the sharpest probe of the old algorithm.
    // The old code asked the graph for "the" father via a first-matching-row
    // scan, so whichever PARENT_OF row came back first won and *the other
    // father disappeared from the tree entirely*, along with everything above
    // him. Shuffling this fixture through the old engine yields two different
    // outcomes, one of which drops 生父+his father, the other 养父+his father.
    const members = [
      FamilyMember(id: 1, name: '我', gender: Gender.male),
      FamilyMember(id: 2, name: '生父', gender: Gender.male),
      FamilyMember(id: 3, name: '养父', gender: Gender.male),
      FamilyMember(id: 4, name: '生父的爸爸', gender: Gender.male),
      FamilyMember(id: 5, name: '养父的爸爸', gender: Gender.male),
    ];
    const relations = [
      FamilyRelation(subjectId: 2, type: RelationEdgeType.parentOf, objectId: 1),
      FamilyRelation(subjectId: 3, type: RelationEdgeType.parentOf, objectId: 1),
      FamilyRelation(subjectId: 4, type: RelationEdgeType.parentOf, objectId: 2),
      FamilyRelation(subjectId: 5, type: RelationEdgeType.parentOf, objectId: 3),
    ];

    test('every permutation of the relation list yields the same codes', () {
      String codesFor(List<FamilyRelation> rels) {
        final g = FamilyGraph(members: members, relations: rels);
        return members.map((m) => relationCode(computeRelationPath(g, 1, m.id))).join('|');
      }

      // Both fathers and both grandfathers must resolve — the old engine
      // reached only one branch and left the other unreachable.
      expect(codesFor(relations), 'SELF|F|F|F.F|F.F');

      final shuffled = List<FamilyRelation>.from(relations);
      for (var seed = 0; seed < 200; seed++) {
        shuffled.shuffle(Random(seed));
        expect(codesFor(shuffled), 'SELF|F|F|F.F|F.F', reason: 'permutation seed=$seed');
      }
    });

    test('a blood path beats an equal-length path through a marriage', () {
      // The child (3) is reachable directly (Son) or via the spouse (Wi.Son).
      final g = FamilyGraph(
        members: const [
          FamilyMember(id: 1, name: 'me', gender: Gender.male),
          FamilyMember(id: 2, name: 'spouse', gender: Gender.female),
          FamilyMember(id: 3, name: 'child', gender: Gender.male),
        ],
        relations: const [
          FamilyRelation(subjectId: 1, type: RelationEdgeType.spouseOf, objectId: 2),
          FamilyRelation(subjectId: 2, type: RelationEdgeType.parentOf, objectId: 3),
          FamilyRelation(subjectId: 1, type: RelationEdgeType.parentOf, objectId: 3),
        ],
      );
      expect(relationCode(computeRelationPath(g, 1, 3)), 'Son');
    });

    test('a child\'s other parent collapses to a spouse token', () {
      // No SPOUSE_OF row at all — reachable only as Son.M, which must fold to
      // Wi rather than rendering "my son's mother".
      final g = FamilyGraph(
        members: const [
          FamilyMember(id: 1, name: 'me', gender: Gender.male),
          FamilyMember(id: 2, name: 'co-parent', gender: Gender.female),
          FamilyMember(id: 3, name: 'son', gender: Gender.male),
        ],
        relations: const [
          FamilyRelation(subjectId: 1, type: RelationEdgeType.parentOf, objectId: 3),
          FamilyRelation(subjectId: 2, type: RelationEdgeType.parentOf, objectId: 3),
        ],
      );
      expect(relationCode(computeRelationPath(g, 1, 2)), 'Wi');
    });
  });

  group('sibling seniority: birth date first, birthOrder as fallback', () {
    // Must match KinshipEngine.endIsElder on the backend exactly.
    FamilyGraph siblingGraph({
      DateTime? aBirth,
      DateTime? bBirth,
      int? aOrder,
      int? bOrder,
    }) =>
        FamilyGraph(
          members: [
            FamilyMember(
                id: 10, name: 'A', gender: Gender.male, birthDate: aBirth, birthOrder: aOrder),
            FamilyMember(
                id: 11, name: 'B', gender: Gender.male, birthDate: bBirth, birthOrder: bOrder),
            const FamilyMember(id: 12, name: 'P', gender: Gender.male),
          ],
          relations: const [
            FamilyRelation(subjectId: 12, type: RelationEdgeType.parentOf, objectId: 10),
            FamilyRelation(subjectId: 12, type: RelationEdgeType.parentOf, objectId: 11),
          ],
        );

    test('birth date decides when both are known', () {
      final g = siblingGraph(aBirth: DateTime(1995, 8, 20), bBirth: DateTime(1990, 3, 1));
      expect(relationCode(computeRelationPath(g, 10, 11)), 'eB');
      expect(relationCode(computeRelationPath(g, 11, 10)), 'yB');
    });

    test('birth date wins over a contradicting birthOrder', () {
      final g = siblingGraph(
        aBirth: DateTime(1995, 8, 20),
        bBirth: DateTime(1990, 3, 1),
        aOrder: 1,
        bOrder: 2,
      );
      expect(relationCode(computeRelationPath(g, 10, 11)), 'eB');
    });

    test('falls back to birthOrder when only one birth date is known', () {
      final g = siblingGraph(aBirth: DateTime(1995, 8, 20), aOrder: 2, bOrder: 1);
      expect(relationCode(computeRelationPath(g, 10, 11)), 'eB');
    });

    test('identical birth dates fall through to birthOrder, then to elder', () {
      final twins = DateTime(1990, 3, 1);
      final withOrder = siblingGraph(aBirth: twins, bBirth: twins, aOrder: 2, bOrder: 1);
      expect(relationCode(computeRelationPath(withOrder, 10, 11)), 'eB');

      final withoutOrder = siblingGraph(aBirth: twins, bBirth: twins);
      expect(relationCode(computeRelationPath(withoutOrder, 10, 11)), 'eB');
      expect(relationCode(computeRelationPath(withoutOrder, 11, 10)), 'eB');
    });
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

  test('in-law side is encoded in the path, not inferred from viewer gender '
      '(Chinese distinguishes 岳父/公公)', () {
    // 王建国(1, male) — 张美玲(2, female) married; 张父(6) is 张美玲's father,
    // and 王父(7) is 王建国's father.
    final extended = FamilyGraph(
      members: const [
        FamilyMember(id: 1, name: '王建国', gender: Gender.male),
        FamilyMember(id: 2, name: '张美玲', gender: Gender.female),
        FamilyMember(id: 6, name: '张父', gender: Gender.male),
        FamilyMember(id: 7, name: '王父', gender: Gender.male),
      ],
      relations: const [
        FamilyRelation(subjectId: 1, type: RelationEdgeType.spouseOf, objectId: 2),
        FamilyRelation(subjectId: 6, type: RelationEdgeType.parentOf, objectId: 2),
        FamilyRelation(subjectId: 7, type: RelationEdgeType.parentOf, objectId: 1),
      ],
    );

    // Wife's father = 岳父. Previously this was 'S.F' plus a viewer-gender
    // suffix, which only worked by assuming the marriage was heterosexual.
    final toWifesFather = computeRelationPath(extended, 1, 6);
    expect(relationCode(toWifesFather), 'Wi.F');
    expect(localizeRelation(toWifesFather, localeCode: 'zh_Hans'), '岳父');

    // Husband's father = 公公. Same shape, different code — no viewer gender
    // needed to tell them apart any more.
    final toHusbandsFather = computeRelationPath(extended, 2, 7);
    expect(relationCode(toHusbandsFather), 'Hu.F');
    expect(localizeRelation(toHusbandsFather, localeCode: 'zh_Hans'), '公公');
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
        // The spouse's gender is in the code now, so these need no
        // targetGender argument at all.
        expect(localizeRelationCode('Son.Dau.Hu', localeCode: 'zh_Hans'), '孙女婿');
        expect(localizeRelationCode('Son.Son.Wi', localeCode: 'zh_Hans'), '孙媳');
        expect(localizeRelationCode('Dau.Son.Wi', localeCode: 'zh_Hans'), '外孙媳');
        expect(localizeRelationCode('Dau.Dau.Hu', localeCode: 'zh_Hans'), '外孙女婿');
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
          localizeRelationCode('Son.Son.Son.Wi', localeCode: 'zh_Hans'),
          '曾孙的妻子',
        );
        // A nephew's wife — no table entry for this combination at
        // all, but the `eB.Son` prefix is still reused: "侄子的妻子".
        expect(
          localizeRelationCode('eB.Son.Wi', localeCode: 'zh_Hans'),
          '侄子的妻子',
        );
      });
    });
  });
}
