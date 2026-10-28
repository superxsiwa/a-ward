// Plays bed 01 through the real screens with taps only, the way a player without drag would.

import 'package:criticalcare/app/sfx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/cases.dart';
import '../support/fake_store.dart';

void main() {
  final b = bed(1);
  String card(int step, String id) => b.stages[step].pool.firstWhere((p) => p.id == id).text;
  String option(String id) => b.stages[0].choices!.options.firstWhere((o) => o.id == id).text;
  String tray(int step, String id) =>
      b.stages[step].trays!.trays.firstWhere((t) => t.id == id).displayName;

  late MemoryProgressStore store;
  late SilentSfx sfx;

  Future<void> openBed01(WidgetTester tester) async {
    store = MemoryProgressStore();
    sfx = SilentSfx();
    await pumpApp(tester, store: store, sfx: sfx);
    await openTab(tester, 'วอร์ด');
    await tester.tap(find.text(b.caseTitle));
    await settle(tester);
  }

  testWidgets('bed 01 played perfectly by taps ends with 3 stars', (tester) async {
    await openBed01(tester);
    expect(find.text('ขั้นที่ 1/6'), findsOneWidget);

    await playBed01Perfectly(tester);

    expect(find.text('เสร็จสิ้นเคส!'), findsOneWidget);
    expect(find.text('สุดยอด! ตอบเป๊ะทุกข้อ ได้ครบ 3 ดาวเลย'), findsOneWidget);
    expect(store.progress.bed(1).stars, 3, reason: 'saved on the device');
    expect(find.text('เตียงถัดไป ▶'), findsOneWidget, reason: 'bed 02 is next');
    // His sounds: cards land and are picked, each pass plays "ok", the case "win" and 3 stars.
    await tester.pump(const Duration(seconds: 2));
    expect(sfx.played.where((x) => x == Sound.ok), hasLength(5));
    expect(sfx.played, containsAll([Sound.drop, Sound.pick, Sound.win]));
    expect(sfx.played.sublist(sfx.played.indexOf(Sound.win)), [
      Sound.win,
      Sound.star0,
      Sound.star1,
      Sound.star2,
    ]);
    // Behind the dialog the page keeps its height; the last step's bottom bar once took the
    // whole screen (walk finding F1).
    expect(tester.getSize(find.byType(SingleChildScrollView).first).height, greaterThan(400));
  });

  testWidgets('a wrong pick shows strike 1/3 and the reason, and costs a star', (tester) async {
    await openBed01(tester);
    for (final id in ['fc1', 'fc2', 'fc3', 'fc4']) {
      await tapText(tester, option(id));
    }
    for (final id in ['fs1', 'fs2', 'fs3', 'fs4']) {
      await tapText(tester, card(0, id));
    }
    await tapText(tester, 'ตรวจคำตอบ');
    await settle(tester);
    expect(find.text('ยังไม่ถูกน้า (ครั้งที่ 1/3)'), findsOneWidget);
    expect(find.text('มีข้อที่ไม่ควรเลือกอยู่ (ข้อสีแดง)'), findsOneWidget);
    expect(find.bySemanticsLabel('ดาวที่ได้ตอนนี้ 2 ดวง'), findsOneWidget);
  });

  testWidgets('after 3 mistakes both check and show answer are offered (Q-A)', (tester) async {
    await openBed01(tester);
    for (final id in ['fc1', 'fc2', 'fc3', 'fc4']) {
      await tapText(tester, option(id));
    }
    for (final id in ['fs1', 'fs2', 'fs3', 'fs4']) {
      await tapText(tester, card(0, id));
    }
    for (var i = 1; i <= 3; i++) {
      await tapText(tester, 'ตรวจคำตอบ');
      await settle(tester);
      await tapText(tester, i < 3 ? 'ลองอีกครั้ง' : 'ลองอีกที');
      await settle(tester);
    }
    expect(find.text('ตรวจคำตอบ'), findsOneWidget);
    expect(find.text('💡 ดูเฉลย & ไปต่อ'), findsOneWidget);
    // Fixing the pick and checking again passes: the retry is real.
    await tapText(tester, option('fc4'));
    await tapText(tester, 'ตรวจคำตอบ');
    await settle(tester);
    expect(find.text('ผ่านขั้นตอนนี้แล้ว ถูกต้องตามหลักความปลอดภัย'), findsOneWidget);
  });

  testWidgets('checking too early shows what is missing and counts nothing', (tester) async {
    await openBed01(tester);
    await tapText(tester, 'ตรวจคำตอบ');
    await settle(tester);
    expect(find.text('ยังไม่ครบ: เลือกตัวเลือกอย่างน้อย 1 ข้อ'), findsOneWidget);
    expect(find.bySemanticsLabel('ดาวที่ได้ตอนนี้ 3 ดวง'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('step 2 times out after 20 seconds and offers a timed retry', (tester) async {
    await openBed01(tester);
    for (final id in ['fc1', 'fc2', 'fc3']) {
      await tapText(tester, option(id));
    }
    for (final id in ['fs1', 'fs2', 'fs3', 'fs4']) {
      await tapText(tester, card(0, id));
    }
    await checkAndGoOn(tester);
    for (var i = 0; i < 21; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('หมดเวลา 20 วินาที! (ครั้งที่ 1/3)'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง (จับเวลา 20 วิ)'), findsOneWidget);
    // The cards wait for retry (Q-C): picking a card and tapping a tray leaves both trays at 0.
    await tapText(tester, card(1, 'fe1'));
    await tapText(tester, tray(1, 'ftr1'));
    expect(find.text('1'), findsNothing, reason: 'no tray count went to 1');
    await tapText(tester, 'ลองอีกครั้ง (จับเวลา 20 วิ)');
    expect(find.text('⏱️ 20s'), findsOneWidget);
    await tapText(tester, card(1, 'fe1'));
    await tapText(tester, tray(1, 'ftr1'));
    expect(find.text('1'), findsOneWidget, reason: 'after retry the card lands');
    // Leave the step so its timer stops before the test ends.
    await tapText(tester, 'ย้อนกลับ');
  });
}

/// Pumps long enough for routes, dialogs and panels to finish moving. The ECG and the step
/// timer never settle, so pumpAndSettle cannot be used.
Future<void> checkAndGoOn(WidgetTester tester) async {
  await tapText(tester, 'ตรวจคำตอบ');
  await settle(tester);
  expect(find.text('ผ่านขั้นตอนนี้แล้ว ถูกต้องตามหลักความปลอดภัย'), findsOneWidget);
  await tapText(tester, 'ไปต่อ');
  await settle(tester);
}

/// Plays bed 01 from its first step to the result dialog without a mistake, by taps only.
Future<void> playBed01Perfectly(WidgetTester tester) async {
  final b = bed(1);
  String card(int step, String id) => b.stages[step].pool.firstWhere((p) => p.id == id).text;
  String option(String id) => b.stages[0].choices!.options.firstWhere((o) => o.id == id).text;
  String tray(int step, String id) =>
      b.stages[step].trays!.trays.firstWhere((t) => t.id == id).displayName;

  // Step 1: pick the three checks, then fill the slots in order.
  for (final id in ['fc1', 'fc2', 'fc3']) {
    await tapText(tester, option(id));
  }
  for (final id in ['fs1', 'fs2', 'fs3', 'fs4']) {
    await tapText(tester, card(0, id));
  }
  await checkAndGoOn(tester);

  // Step 2: pick each card up and tap its tray; the countdown runs.
  expect(find.textContaining('⏱️'), findsOneWidget);
  for (final (ids, t) in [
    (['fe1', 'fe2', 'fe3', 'fe4'], 'ftr1'),
    (['fe5', 'fe6', 'fe7'], 'ftr2'),
  ]) {
    for (final id in ids) {
      await tapText(tester, card(1, id));
      await tapText(tester, tray(1, t));
    }
  }
  await checkAndGoOn(tester);
  expect(find.textContaining('⏱️'), findsNothing);

  // Step 3: the same, in order.
  for (final (ids, t) in [
    (['fd1', 'fd2', 'fd3'], 'fdtr1'),
    (['fd4', 'fd5', 'fd6'], 'fdtr2'),
  ]) {
    for (final id in ids) {
      await tapText(tester, card(2, id));
      await tapText(tester, tray(2, t));
    }
  }
  await checkAndGoOn(tester);

  // Step 4: tap the four safe actions into the box.
  for (final id in ['fa1', 'fa2', 'fa3', 'fa4']) {
    await tapText(tester, card(3, id));
  }
  await checkAndGoOn(tester);

  // Steps 5 and 6: sequences.
  for (final id in ['fp1', 'fp2', 'fp3', 'fp4']) {
    await tapText(tester, card(4, id));
  }
  await checkAndGoOn(tester);
  for (final id in ['fis1', 'fis2', 'fis3', 'fis4']) {
    await tapText(tester, card(5, id));
  }
  await tapText(tester, 'ตรวจคำตอบ');
  await settle(tester);
}
