import 'dart:convert';
import 'dart:io';

import 'package:criticalcare/data/case_repository.dart';
import 'package:criticalcare/game/case_import.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cases.dart';

void main() {
  final assets = {for (final f in Directory('assets/equipment').listSync()) f.path};
  bool imageExists(String img) => assets.contains(equipmentAsset(img));
  final all = [for (var n = 1; n <= 8; n++) bedJson(n)];

  CaseImport read(Object json) => readCaseFile(jsonEncode(json), imageExists: imageExists);
  List<String> problems(CaseImport r) => r is CasesRejected ? r.problems : const [];

  test('the 8 shipped cases go out and come back unchanged', () {
    final text = writeCaseFile(all);
    expect(text, startsWith('[\n  {\n    "'), reason: 'indented by two, like his export');
    final r = readCaseFile(text, imageExists: imageExists);
    expect(r, isA<CasesRead>());
    r as CasesRead;
    expect([for (final c in r.cases) c.bedNum], [1, 2, 3, 4, 5, 6, 7, 8]);
    expect(r.json, all);
  });

  test('his backend also takes {"cases": [...]}; cases come back in bed order', () {
    final r = read({
      'cases': [bedJson(2), bedJson(1)],
    });
    expect([for (final c in (r as CasesRead).cases) c.bedNum], [1, 2]);
  });

  test('a missing or unreadable bed number takes the case\'s place, like his', () {
    final a = copyJson(bedJson(1))..remove('bedNum');
    final b = copyJson(bedJson(2))..['bedNum'] = '5';
    final c = copyJson(bedJson(3))..['bedNum'] = 0;
    final r = read([a, b, c]) as CasesRead;
    expect([for (final x in r.cases) x.bedNum], [1, 3, 5]);
    expect(r.json.first['bedNum'], 1, reason: 'kept for the next export');
  });

  test('a byte order mark at the start is fine', () {
    expect(readCaseFile('﻿${jsonEncode(all)}', imageExists: imageExists), isA<CasesRead>());
  });

  test('not JSON, or no cases, is turned away', () {
    expect(problems(readCaseFile('{oops')).single, startsWith('not JSON'));
    expect(problems(read(<Object>[])), hasLength(1));
    expect(problems(read({'beds': all})), hasLength(1));
    expect(problems(read(['bed'])).single, 'case 1: expected an object');
  });

  test('one unplayable case turns the whole file away, and says where', () {
    final bad = copyJson(bedJson(2));
    (bad['stageData'] as List).removeLast();
    final p = problems(read([bedJson(1), bad]));
    expect(p, ['case 2 (bed 2): \$.stageData: has 5 steps, expected 6']);
  });

  test('a field of the wrong type names its path', () {
    final bad = copyJson(bedJson(1))..['caseTitle'] = 7;
    expect(problems(read([bad])).single, 'case 1: \$.caseTitle: expected text');
  });

  test('the same bed twice is turned away', () {
    expect(problems(read([bedJson(1), bedJson(1)])), ['bed 1 is in the file twice']);
  });

  test('a picture the app does not ship is turned away', () {
    final bad = copyJson(bedJson(1));
    final trays = stageOf(bad, 1)['traysTask'] as Map<String, Object?>;
    final pool = (trays['pool'] as List).first as Map<String, Object?>;
    pool['img'] = './assets/equipment/unicorn.png';
    expect(problems(read([bad])), isNotEmpty);
  });

  test('the export is named like his', () {
    expect(caseFileName(DateTime(2026, 3, 7, 23)), 'award_ccu_cases_2026-03-07.json');
  });
}
