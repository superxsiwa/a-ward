import 'package:criticalcare/app/app.dart';
import 'package:criticalcare/app/sfx.dart';
import 'package:criticalcare/data/progress_store.dart';
import 'package:criticalcare/data/providers.dart';
import 'package:criticalcare/game/case_session.dart';
import 'package:criticalcare/game/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cases.dart';
import '../support/fake_store.dart';
import 'bed01_play_test.dart' show settle, tapText;

void main() {
  final sfx = SilentSfx();

  Future<void> pumpApp(WidgetTester tester, MemoryProgressStore store) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bundledCasesProvider.overrideWith((ref) async => [for (var n = 1; n <= 8; n++) bed(n)]),
          progressStoreProvider.overrideWithValue(store),
          sfxProvider.overrideWithValue(sfx),
        ],
        child: const CriticalCareApp(),
      ),
    );
    await settle(tester);
  }

  testWidgets('the training notice shows on first launch only', (tester) async {
    final store = MemoryProgressStore(seen: false);
    await pumpApp(tester, store);
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
    await pumpApp(tester, store);
    await tester.tap(find.byTooltip('ตั้งค่า'));
    await settle(tester);
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
}
