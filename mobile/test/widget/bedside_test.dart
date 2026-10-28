// The visual concept on bed 01 (Thanee 2026-10-28): the bedside scene, card icons instead of the
// emoji that gave the right step 4 cards away, the drop tray docked at the bottom.

import 'package:criticalcare/app/sfx.dart';
import 'package:criticalcare/features/game/task_views.dart';
import 'package:criticalcare/game/card_kinds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/cases.dart';
import '../support/fake_store.dart';
import 'bed01_play_test.dart' show playBed01Perfectly;

void main() {
  final b = bed(1);
  String shown(String id) =>
      withoutLeadingEmoji(b.stages[3].pool.firstWhere((p) => p.id == id).text);

  Future<void> openBed01(WidgetTester tester) async {
    await pumpApp(tester, store: MemoryProgressStore(), sfx: SilentSfx());
    await openTab(tester, 'วอร์ด');
    await tester.tap(find.text(b.caseTitle));
    await settle(tester);
  }

  Future<void> toStep4(WidgetTester tester) async {
    await openBed01(tester);
    await playBed01Perfectly(tester, stepsDone: 3);
    expect(find.text('ขั้นที่ 4/6'), findsOneWidget);
  }

  testWidgets('the knowledge box stays folded until tapped', (tester) async {
    await openBed01(tester);
    expect(find.text(b.stages[0].reading), findsNothing);
    await tapText(tester, 'สาระความรู้');
    await settle(tester);
    expect(find.text(b.stages[0].reading), findsOneWidget);
  });

  testWidgets('step 4: no emoji gives the answer away; the tray sits below the page', (
    tester,
  ) async {
    await toStep4(tester);
    for (final emoji in ['💓', '🦶', '🗣️', '🩸']) {
      expect(find.textContaining(emoji), findsNothing, reason: emoji);
    }
    expect(find.text(shown('fa1')), findsOneWidget);
    expect(find.byType(DropTray), findsOneWidget);
    expect(
      find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(DropTray)),
      findsNothing,
      reason: 'docked in the bottom bar, not in the scrolling page',
    );
    expect(find.text('0/4'), findsOneWidget);

    await tapText(tester, shown('fa1'));
    await settle(tester);
    expect(find.text('1/4'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(DropTray), matching: find.text(shown('fa1'))),
      findsOneWidget,
    );

    // A tap on the card in the tray takes it back.
    await tester.tap(find.descendant(of: find.byType(DropTray), matching: find.text(shown('fa1'))));
    await settle(tester);
    expect(find.text('0/4'), findsOneWidget);
  });

  testWidgets('a wrong check sets the monitor alarming; trying again calms it', (tester) async {
    await toStep4(tester);
    expect(find.text('ALARM'), findsNothing, reason: "bed 01's step 4 vitals are calm");
    for (final id in ['fa1', 'faw1', 'fa2', 'fa3']) {
      await tapText(tester, shown(id));
    }
    await tapText(tester, 'ตรวจคำตอบ');
    await settle(tester);
    expect(find.text('ยังไม่ถูกน้า (ครั้งที่ 1/3)'), findsOneWidget);
    expect(find.text('ALARM'), findsOneWidget);
    expect(find.text('68'), findsOneWidget, reason: 'the numbers stay the case\'s own');

    await tapText(tester, 'ลองอีกครั้ง');
    await settle(tester);
    expect(find.text('ALARM'), findsNothing);
  });
}
