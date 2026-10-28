// Content lint: every case shipped in the app loads, validates and can be passed.
// A failure here is a content problem in superxsiwa's cases; report it, never fix the content.

import 'dart:math';

import 'package:criticalcare/data/case_repository.dart';
import 'package:criticalcare/game/case_validation.dart';
import 'package:criticalcare/game/step_checker.dart';
import 'package:criticalcare/game/step_board.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 8 bundled cases load through the asset bundle, beds 1 to 8 in order', () async {
    final cases = await CaseRepository(rootBundle).loadBundled();
    expect([for (final c in cases) c.bedNum], [1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test('every bundled case passes validation, images included', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();
    bool imageExists(String img) => assets.contains(equipmentAsset(img));

    for (final c in await CaseRepository(rootBundle).loadBundled()) {
      expect(validateCase(c, imageExists: imageExists), isEmpty, reason: 'bed ${c.bedNum}');
    }
  });

  test('the shown answer of every step of every bundled case passes the check', () async {
    for (final c in await CaseRepository(rootBundle).loadBundled()) {
      for (final stage in c.stages) {
        final solved = StepBoard.fresh(stage, Random(1)).solved(stage);
        final result = checkStep(stage, solved);
        expect(
          result,
          isA<CheckDone>().having((r) => r.passed, 'passed', isTrue),
          reason: 'bed ${c.bedNum} step ${stage.id}',
        );
      }
    }
  });
}
