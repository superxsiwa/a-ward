import 'package:criticalcare/game/case_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cases.dart';

void main() {
  test('bed 01 parses into 6 steps with every task kind', () {
    final b = bed(1);
    expect(b.bedNum, 1);
    expect(b.status, CaseStatus.alert);
    expect(b.stages, hasLength(6));
    expect(b.stages.first.id, '1');
    expect(b.stages[0].choices!.options, hasLength(4));
    expect(b.stages[0].sequence!.correctOrder, ['fs1', 'fs2', 'fs3', 'fs4']);
    expect(b.stages[1].trays!.ordered, isFalse);
    expect(b.stages[2].trays!.ordered, isTrue);
    expect(b.stages[3].unorderedDrop!.expectedIds, hasLength(4));
    expect(b.stages[1].pool.first.img, './assets/equipment/scissors_forceps.png');
    expect(b.stages[0].vitals.bp, '126/78');
  });

  test('the step pool is the pool of its card task', () {
    final b = bed(1);
    expect(b.stages[0].pool.map((p) => p.id), containsAll(['fs1', 'fs4']));
    expect(b.stages[3].pool, hasLength(6));
  });

  test('tray names lose their colour marker for display', () {
    expect(bed(1).stages[1].trays!.trays.first.displayName, 'ถาดทำแผลและกดห้ามเลือด (Sterile Tray)');
  });

  test('a type error names where it is', () {
    final json = copyJson(bedJson(1));
    final trays = (stageOf(json, 1)['traysTask'] as Map)['trays'] as List;
    (trays[0] as Map)['expectedIds'] = 'fe1';
    expect(
      () => BedCase.fromJson(json),
      throwsA(
        isA<CaseFormatException>().having(
          (e) => e.path,
          'path',
          r'$.stageData[1].traysTask.trays[0].expectedIds',
        ),
      ),
    );
  });

  test('a missing field and an unknown status are format errors', () {
    final noTitle = copyJson(bedJson(1))..remove('caseTitle');
    expect(
      () => BedCase.fromJson(noTitle),
      throwsA(isA<CaseFormatException>().having((e) => e.path, 'path', r'$.caseTitle')),
    );
    final badStatus = copyJson(bedJson(1))..['status'] = 'fine';
    expect(() => BedCase.fromJson(badStatus), throwsA(isA<CaseFormatException>()));
    expect(() => BedCase.fromJson([]), throwsA(isA<CaseFormatException>()));
  });

  test('a step id may be text, and whole-number doubles read as ints', () {
    final json = copyJson(bedJson(1));
    stageOf(json, 0)['id'] = 'prep';
    (stageOf(json, 0)['vitals'] as Map)['hr'] = 78.0;
    final b = BedCase.fromJson(json);
    expect(b.stages.first.id, 'prep');
    expect(b.stages.first.vitals.hr, 78);
  });
}
