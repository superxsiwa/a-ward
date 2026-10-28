import 'package:criticalcare/app/sfx.dart';
import 'package:criticalcare/game/case_session.dart';
import 'package:criticalcare/game/milestones.dart';
import 'package:criticalcare/game/progress.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/fake_store.dart';

void main() {
  const perfectBed1 = CaseResult(
    bedNum: 1,
    stars: 3,
    mistakes: 0,
    traysSorted: 0,
    flawlessSteps: 2,
    isEmergency: true,
  );
  const twoStarBed2 = CaseResult(
    bedNum: 2,
    stars: 2,
    mistakes: 1,
    traysSorted: 0,
    flawlessSteps: 1,
    isEmergency: true,
  );

  testWidgets('the progress tab: ring, counters, EXP and his 20 goals', (tester) async {
    final semantics = tester.ensureSemantics();
    final progress = Progress.empty
        .record(perfectBed1)
        .progress
        .record(twoStarBed2)
        .progress
        .played(1800);
    await pumpApp(
      tester,
      store: MemoryProgressStore(progress: progress),
      sfx: SilentSfx(),
    );
    await openTab(tester, 'ความก้าวหน้า');

    expect(find.text('ความก้าวหน้า & เป้าหมาย (Milestones)'), findsOneWidget);
    expect(find.text('จาก 24 ดาวเตียง'), findsOneWidget);
    // 5 bed stars; goals: hours 1, beds passed 1, bed 01 3, bed 02 2 = 7 (the rest are below
    // their first tier: kept small on purpose, so the sum can be counted by hand).
    expect(find.text('ผ่านแล้ว 2 / 8 เตียง · ดาวสะสมรวมทั้งหมด 12 ⭐'), findsOneWidget);
    expect(find.text('30 น.'), findsOneWidget);
    expect(find.text('2 ครั้ง'), findsWidgets);
    expect(find.text('7 / 60 ⭐'), findsOneWidget);
    expect(find.text('ปัจจุบัน: 0.5 ชม. (30 นาที)', findRichText: true), findsOneWidget);
    expect(find.text('เป้าดาวถัดไป (2⭐): 1.5 ชั่วโมง'), findsOneWidget);
    expect(find.text('✓ ได้ครบ 3 ดาวแล้ว!'), findsOneWidget, reason: 'bed 01');
    for (final g in milestones) {
      expect(find.text(g.title), findsOneWidget, reason: g.id);
    }
    // His EXP bar: 5 stars is level 2 and 2 of the 3 stars to level 3.
    expect(find.bySemanticsLabel(RegExp('EXP สู่เลเวลถัดไป 67%')), findsWidgets);
    expect(find.text('Lv.2 · ${ranks[1]}'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('play time counts only while the app is in the foreground', (tester) async {
    final store = MemoryProgressStore();
    await pumpApp(tester, store: store, sfx: SilentSfx());
    await tester.pump(const Duration(seconds: 10));
    expect(store.progress.stats.totalPlaySeconds, 10);

    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump(const Duration(seconds: 30));
    expect(store.progress.stats.totalPlaySeconds, 10, reason: 'in the background');

    for (final s in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump(const Duration(seconds: 5));
    expect(store.progress.stats.totalPlaySeconds, 15);
  });
}
