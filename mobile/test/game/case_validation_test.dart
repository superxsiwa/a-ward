import 'package:criticalcare/game/case_model.dart';
import 'package:criticalcare/game/case_validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cases.dart';

/// Validates bed 01 after [edit] changed its JSON.
List<String> issuesAfter(void Function(Map<String, Object?> json) edit, {Set<String>? images}) {
  final json = copyJson(bedJson(1));
  edit(json);
  return [
    for (final i in validateCase(
      BedCase.fromJson(json),
      imageExists: images?.contains,
    ))
      '$i',
  ];
}

Map<String, Object?> task(Map<String, Object?> json, int step, String key) =>
    stageOf(json, step)[key] as Map<String, Object?>;

List<Object?> pool(Map<String, Object?> json, int step, String key) =>
    task(json, step, key)['pool'] as List<Object?>;

void main() {
  test('bed 01 as shipped has no issues', () {
    expect(issuesAfter((_) {}), isEmpty);
  });

  test('a case needs 6 steps with distinct ids', () {
    expect(
      issuesAfter((j) => (j['stageData'] as List).removeLast()),
      [r'$.stageData: has 5 steps, expected 6'],
    );
    expect(
      issuesAfter((j) => stageOf(j, 1)['id'] = 1),
      [r'$.stageData[1].id: step id 1 is used twice'],
    );
  });

  test('vitals must read as numbers', () {
    expect(
      issuesAfter((j) {
        final v = stageOf(j, 0)['vitals'] as Map<String, Object?>;
        v['bp'] = '126-78';
        v['spo2'] = '99';
        v['hr'] = 0;
      }),
      [
        r'$.stageData[0].vitals.hr: must be above 0',
        r'$.stageData[0].vitals.bp: "126-78" is not systolic/diastolic',
        r'$.stageData[0].vitals.spo2: "99" is not a percentage',
      ],
    );
  });

  test('a step shows one card task and at least one task', () {
    expect(
      issuesAfter((j) => stageOf(j, 3)['sequenceTask'] = stageOf(j, 4)['sequenceTask']),
      [r'$.stageData[3]: has sequenceTask and unorderedDropTask; a step can show one of them'],
    );
    expect(
      issuesAfter((j) => stageOf(j, 4).remove('sequenceTask')),
      [r'$.stageData[4]: has no task'],
    );
  });

  test('a choices task needs a correct option and distinct ids', () {
    expect(
      issuesAfter((j) {
        for (final o in task(j, 0, 'choices1toN')['options'] as List) {
          (o as Map)['correct'] = false;
        }
      }),
      [r'$.stageData[0].choices1toN.options: has no correct option'],
    );
  });

  test('a sequence answer must name pool cards, once each', () {
    expect(
      issuesAfter((j) => task(j, 4, 'sequenceTask')['correctOrder'] = ['fp1', 'fp1', 'fp9', 'fp4']),
      [
        r'$.stageData[4].sequenceTask.correctOrder: "fp1" appears twice',
        r'$.stageData[4].sequenceTask.correctOrder: "fp9" is not in the pool',
      ],
    );
  });

  test('every tray card must belong to exactly one tray', () {
    expect(
      issuesAfter((j) {
        final trays = task(j, 1, 'traysTask')['trays'] as List;
        (trays[1] as Map)['expectedIds'] = ['fe5', 'fe6'];
      }),
      [r'$.stageData[1].traysTask.pool: "fe7" belongs in no tray, so the step cannot be passed'],
    );
    expect(
      issuesAfter((j) {
        final trays = task(j, 1, 'traysTask')['trays'] as List;
        (trays[1] as Map)['expectedIds'] = ['fe1', 'fe5', 'fe6', 'fe7'];
      }),
      [r'$.stageData[1].traysTask.trays (all expected ids): "fe1" appears twice'],
    );
  });

  test('an ordered trays task needs expectedOrder on every tray', () {
    expect(
      issuesAfter((j) {
        final trays = task(j, 2, 'traysTask')['trays'] as List;
        (trays[0] as Map).remove('expectedOrder');
      }),
      [
        r'$.stageData[2].traysTask.trays[0]: has no expectedOrder',
        // In pool order.
        r'$.stageData[2].traysTask.pool: "fd3" belongs in no tray, so the step cannot be passed',
        r'$.stageData[2].traysTask.pool: "fd1" belongs in no tray, so the step cannot be passed',
        r'$.stageData[2].traysTask.pool: "fd2" belongs in no tray, so the step cannot be passed',
      ],
    );
  });

  test('the safe actions must be pool cards', () {
    expect(
      issuesAfter((j) => task(j, 3, 'unorderedDropTask')['expectedIds'] = ['fa1', 'fa5']),
      [r'$.stageData[3].unorderedDropTask.expectedIds: "fa5" is not in the pool'],
    );
  });

  test('pool cards need distinct ids, text, and an image that exists', () {
    expect(
      issuesAfter((j) {
        final p = pool(j, 3, 'unorderedDropTask');
        (p[1] as Map)['id'] = 'fa1';
        (p[2] as Map)['text'] = ' ';
      }),
      contains(r'$.stageData[3].unorderedDropTask.pool: "fa1" appears twice'),
    );
    expect(
      issuesAfter((_) {}, images: {'./assets/equipment/syringe.png'}),
      contains(
        r'$.stageData[1].traysTask.pool[0].img: "./assets/equipment/scissors_forceps.png" '
        'is not a bundled image',
      ),
    );
  });
}
