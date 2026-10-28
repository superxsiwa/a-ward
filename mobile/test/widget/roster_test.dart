import 'package:clock/clock.dart';
import 'package:criticalcare/app/sfx.dart';
import 'package:criticalcare/game/roster.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/fake_store.dart';
import 'bed01_play_test.dart' show playBed01Perfectly;

void main() {
  const oct = RosterMonth(2026, 10);

  /// October 2026: off on the 1st, a morning shift on the 2nd, an afternoon on the 3rd, then
  /// mornings.
  Roster october({Set<String> cleared = const {}, Map<String, Set<int>> doneBeds = const {}}) =>
      Roster(
        months: {
          oct.key: [
            Shift.off,
            Shift.morning,
            Shift.afternoon,
            for (var d = 4; d <= 31; d++) Shift.morning,
          ],
        },
        cleared: cleared,
        doneBeds: doneBeds,
      );

  late MemoryProgressStore store;
  late SilentSfx sfx;

  /// The app on 28 October 2026 with [roster] saved.
  void rosterTest(String name, Roster roster, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        store = MemoryProgressStore(roster: roster);
        sfx = SilentSfx();
        await withClock(Clock.fixed(DateTime(2026, 10, 28, 9)), () async {
          await pumpApp(tester, store: store, sfx: sfx);
          await body(tester);
        });
      });

  Finder day(String label) => find.bySemanticsLabel(label);

  rosterTest('opens on this month with the playable day chosen', october(), (tester) async {
    final semantics = tester.ensureSemantics();
    expect(find.text('ตุลาคม 2569'), findsOneWidget);
    expect(find.text('วันศุกร์ที่ 2 ตุลาคม 2569'), findsOneWidget);
    expect(find.text('เวรของคุณวันนี้: 🌅 เวรเช้า (Morning Shift)'), findsOneWidget);
    expect(find.text('เข้าวอร์ดเวรนี้'), findsOneWidget);
    expect(day('1 OFF ผ่านเวรนี้แล้ว'), findsOneWidget, reason: 'a day off clears itself');
    expect(day('2 เช้า เล่นวันนี้ได้ (เวรปัจจุบัน)'), findsOneWidget);
    expect(day('3 บ่าย ยังไม่ถึงวันเข้าเวร'), findsOneWidget);
    semantics.dispose();
  });

  rosterTest('a locked day says which day to play first', october(), (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.tap(day('3 บ่าย ยังไม่ถึงวันเข้าเวร'));
    await settle(tester);
    expect(find.text('ยังเข้าเวรนี้ไม่ได้! กรุณาผ่านเวรวันที่ 2 ให้สำเร็จก่อน'), findsOneWidget);
    expect(sfx.played, contains(Sound.bad));
    expect(find.text('วันศุกร์ที่ 2 ตุลาคม 2569'), findsOneWidget, reason: 'still on day 2');
    semantics.dispose();
  });

  rosterTest('a day off: the whole ward, no duty', october(), (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.tap(day('1 OFF ผ่านเวรนี้แล้ว'));
    await settle(tester);
    expect(find.text('วันนี้เป็นวันหยุดของคุณ (Off)'), findsOneWidget);
    expect(find.text('✓ ผ่านเวรนี้แล้ว'), findsOneWidget);
    expect(find.text('เข้าวอร์ดเวรนี้'), findsNothing);
    semantics.dispose();
    await tapText(tester, 'ดูวอร์ดทั้งหมด');
    await settle(tester);
    expect(find.text('วอร์ดหัวใจ 8 เตียง'), findsOneWidget);
    expect(find.textContaining('ประจำการ'), findsNothing);
  });

  rosterTest(
    'on duty the ward shows the shift, and finishing its last bed unlocks the next day',
    october(
      doneBeds: {
        oct.dayKey(2): {2},
      },
    ),
    (tester) async {
      expect(
        find.text('หัวหน้าเวร: พว. ณิชาภา (RN) · คนไข้ในความรับผิดชอบ (1/2 เคส)'),
        findsOneWidget,
      );
      await tapText(tester, 'เข้าวอร์ดเวรนี้');
      await settle(tester);
      expect(find.text('ประจำการ: 🌅 เวรเช้า (Morning Shift)'), findsOneWidget);
      expect(find.text('เน้นเตียงที่ได้รับมอบหมายในเวร (เตียง 1, เตียง 2)'), findsOneWidget);
      expect(find.text('วันที่ 2: ทำแล้ว 1/2 เคส'), findsOneWidget);

      // The gold button opens the shift's bed still to do: bed 01.
      await tapText(tester, 'เริ่มเลย');
      await settle(tester);
      await playBed01Perfectly(tester);

      expect(
        find.text(
          '🎉 ยินดีด้วย! ปฏิบัติหน้าที่ครบในเวรเช้า (Morning Shift)แล้ว ปลดล็อกวันที่ 3 เรียบร้อย!',
        ),
        findsOneWidget,
      );
      expect(find.text('เตียงถัดไป ▶'), findsNothing);
      expect(store.roster.cleared, {oct.dayKey(2)});
      expect(store.roster.doneBeds, isEmpty);

      await tapText(tester, 'กลับตารางเวร');
      await settle(tester);
      expect(find.text('วันเสาร์ที่ 3 ตุลาคม 2569'), findsOneWidget);
      expect(find.text('เวรของคุณวันนี้: ☀️ เวรบ่าย (Afternoon Shift)'), findsOneWidget);

      await openTab(tester, 'วอร์ด');
      expect(find.textContaining('ประจำการ'), findsNothing, reason: 'the duty ended with the day');
    },
  );

  rosterTest('"show all beds" ends the duty', october(), (tester) async {
    await tapText(tester, 'เข้าวอร์ดเวรนี้');
    await settle(tester);
    await tapText(tester, 'แสดงทุกเตียง ✕');
    await settle(tester);
    expect(find.textContaining('ประจำการ'), findsNothing);
  });

  rosterTest('another month gets its own shifts', october(), (tester) async {
    await tester.tap(find.byTooltip('เดือนถัดไป'));
    await settle(tester);
    expect(find.text('พฤศจิกายน 2569'), findsOneWidget);
    expect(store.roster.has(const RosterMonth(2026, 11)), isTrue);
    expect(store.roster.months[oct.key]![1], Shift.morning, reason: 'October untouched');
    await tester.tap(find.byTooltip('เดือนก่อนหน้า'));
    await settle(tester);
    expect(find.text('ตุลาคม 2569'), findsOneWidget);
  });

  rosterTest('a reroll keeps the days already done', october(cleared: {oct.dayKey(2)}), (
    tester,
  ) async {
    await tapText(tester, '🎲 สุ่มเวรใหม่');
    await settle(tester);
    expect(find.text('สุ่มเวรใหม่ประจำเดือนแล้ว 🎲'), findsOneWidget);
    expect(store.roster.shiftOn(oct, 1), Shift.off);
    expect(store.roster.shiftOn(oct, 2), Shift.morning);
    expect(store.roster.cleared, {oct.dayKey(2)});
  });

  rosterTest(
    'reset in settings clears the days played, not the shifts',
    october(cleared: {oct.dayKey(2)}),
    (tester) async {
      await openTab(tester, 'ตั้งค่า');
      await tapText(tester, 'ล้างความก้าวหน้า');
      await settle(tester);
      await tapText(tester, 'ล้างข้อมูล');
      await settle(tester);
      expect(store.roster.cleared, isEmpty);
      expect(store.roster.shiftOn(oct, 3), Shift.afternoon);
    },
  );
}
