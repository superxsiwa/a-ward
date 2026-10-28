import 'package:criticalcare/app/sfx.dart';
import 'package:criticalcare/game/case_session.dart';
import 'package:criticalcare/features/ward/ward_screen.dart';
import 'package:criticalcare/game/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart' hide pumpApp;
import '../support/app.dart' as app;
import '../support/cases.dart';
import '../support/fake_store.dart';

void main() {
  final sfx = SilentSfx();

  /// The app, then its ward tab ([ward] false stays on the roster).
  Future<void> pumpApp(WidgetTester tester, MemoryProgressStore store, {bool ward = true}) async {
    await app.pumpApp(tester, store: store, sfx: sfx);
    if (ward) await openTab(tester, 'วอร์ด');
  }

  testWidgets('the training notice shows on first launch only', (tester) async {
    final store = MemoryProgressStore(seen: false);
    await pumpApp(tester, store, ward: false);
    expect(find.text('⚠️ สำหรับการฝึกเท่านั้น'), findsOneWidget);
    await tapText(tester, 'เข้าใจแล้ว');
    await settle(tester);
    expect(store.seen, isTrue);
    expect(find.text('⚠️ สำหรับการฝึกเท่านั้น'), findsNothing);
  });

  testWidgets('the ward shows saved progress', (tester) async {
    const done = CaseResult(
      bedNum: 1,
      stars: 3,
      mistakes: 0,
      traysSorted: 13,
      flawlessSteps: 6,
      isEmergency: true,
    );
    final store = MemoryProgressStore(progress: Progress.empty.record(done).progress);
    await pumpApp(tester, store);
    expect(find.text('วอร์ดหัวใจ 8 เตียง'), findsOneWidget);
    expect(find.text('ผ่านแล้ว 1/8 เตียง'), findsOneWidget);
    expect(find.bySemanticsLabel('ดาวทั้งหมด 3/24'), findsOneWidget);
    expect(find.text('ผ่านแล้ว'), findsOneWidget, reason: "bed 01's status");
    expect(find.text('เล่นต่อ'), findsOneWidget);
    expect(find.text('Lv.2 · ${ranks[1]}'), findsOneWidget);
  });

  testWidgets('the case sheet lists the answers', (tester) async {
    await pumpApp(tester, MemoryProgressStore());
    await tapText(tester, '📖 ชีทเฉลยเคส');
    await settle(tester);
    await tapText(tester, bed(1).caseTitle);
    await settle(tester);
    expect(find.text('ชีทเฉลย เตียง 01 CCU'), findsOneWidget);
    final wrong = bed(1).stages[0].choices!.options.firstWhere((o) => !o.correct);
    expect(find.textContaining('${wrong.text}  (ไม่ควรเลือก)'), findsOneWidget);
  });

  testWidgets('settings: sound and vibration switches are saved; reset asks first', (tester) async {
    const done = CaseResult(
      bedNum: 2,
      stars: 2,
      mistakes: 1,
      traysSorted: 0,
      flawlessSteps: 0,
      isEmergency: true,
    );
    final store = MemoryProgressStore(progress: Progress.empty.record(done).progress);
    await pumpApp(tester, store, ward: false);
    await openTab(tester, 'ตั้งค่า');
    await tapText(tester, '🔊 เสียงเอฟเฟกต์');
    await settle(tester);
    expect(store.settings.sound, isFalse);
    expect(store.settings.haptics, isTrue);
    await tapText(tester, 'ล้างความก้าวหน้า');
    await settle(tester);
    await tapText(tester, 'ยกเลิก');
    await settle(tester);
    expect(store.progress.totalStars, 2, reason: 'cancel keeps it');
    await tapText(tester, 'ล้างความก้าวหน้า');
    await settle(tester);
    await tapText(tester, 'ล้างข้อมูล');
    await settle(tester);
    expect(store.progress.totalStars, 0);
    expect(find.text('ล้างความก้าวหน้าแล้ว'), findsOneWidget);
  });

  testWidgets('a wide screen: the bar lines up with the ward, text is 20% larger', (tester) async {
    await app.pumpApp(
      tester,
      store: MemoryProgressStore(),
      sfx: sfx,
      size: const Size(2000, 1100),
      pixelRatio: 1.0,
    );
    await openTab(tester, 'วอร์ด');
    expect(find.text('วอร์ดหัวใจ 8 เตียง'), findsOneWidget);
    final title = find.descendant(
      of: find.byType(WardScreen),
      matching: find.text('Critical Care'),
    );
    expect(tester.getTopLeft(title).dx, greaterThanOrEqualTo(500));
    final scaler = MediaQuery.textScalerOf(tester.element(title));
    expect(scaler.scale(10), closeTo(12, 0.01));
  });
}
