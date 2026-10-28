import 'dart:convert';
import 'dart:math';

import 'package:criticalcare/game/roster.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const oct = RosterMonth(2026, 10);
  final bedNums = [for (var n = 1; n <= 8; n++) n];
  final morning = shiftDef(Shift.morning)!;
  final afternoon = shiftDef(Shift.afternoon)!;

  /// October 2026 with the given shifts from the 1st on (one letter a day), mornings after.
  Roster octWith(String codes, {Set<String> cleared = const {}}) => Roster(
    months: {
      oct.key: [
        for (var d = 0; d < oct.days; d++)
          Shift.values.firstWhere((s) => s.code == (d < codes.length ? codes[d] : 'm')),
      ],
    },
    cleared: cleared,
  );

  group('RosterMonth', () {
    test('knows its length, first weekday and neighbours', () {
      expect(oct.days, 31);
      expect(oct.firstWeekday, 4, reason: '1 October 2026 is a Thursday');
      expect(const RosterMonth(2028, 2).days, 29);
      expect(const RosterMonth(2026, 12).next, const RosterMonth(2027, 1));
      expect(const RosterMonth(2027, 1).previous, const RosterMonth(2026, 12));
      expect(oct.dayKey(5), '2026-10-05');
      expect(RosterMonth.of(DateTime(2026, 10, 28)), oct);
    });
  });

  group('shifts', () {
    test('his three shifts look after beds 1-2, 3-5 and 6-8', () {
      expect(morning.bedsIn(bedNums), [1, 2]);
      expect(afternoon.bedsIn(bedNums), [3, 4, 5]);
      expect(shiftDef(Shift.night)!.bedsIn(bedNums), [6, 7, 8]);
      expect(shiftDef(Shift.off), isNull);
      expect(shiftDef(Shift.night)!.bedsIn([1, 2, 3, 4, 5, 6]), [6], reason: 'a smaller ward');
    });
  });

  group('roll', () {
    test('draws a shift for every day from his pool', () {
      final r = Roster.empty.roll(oct, Random(1));
      expect(r.has(oct), isTrue);
      expect(r.months[oct.key], hasLength(31));
      final seen = r.months[oct.key]!.toSet();
      expect(seen, containsAll([Shift.morning, Shift.afternoon, Shift.night]));
    });

    test('a month without a schedule reads as mornings', () {
      expect(Roster.empty.shiftOn(oct, 3), Shift.morning);
    });

    test('a reroll keeps the days already done and drops the playable day\'s beds', () {
      final r = octWith(
        'mo',
        cleared: {oct.dayKey(1)},
      ).recordBed(Duty(oct, 3, morning), 1, bedNums).roster;
      expect(r.playableDay(oct), 3);
      expect(r.doneOn(oct, 3), {1});
      final again = r.roll(oct, Random(7));
      expect(again.shiftOn(oct, 1), Shift.morning);
      expect(again.shiftOn(oct, 2), Shift.off);
      expect(again.doneOn(oct, 3), isEmpty);
      expect(again.cleared, {oct.dayKey(1)});
    });
  });

  group('playing the days in order', () {
    test('the first day not done is playable, later ones locked', () {
      final r = octWith('mam');
      expect(r.playableDay(oct), 1);
      expect(r.stateOf(oct, 1), DayState.playable);
      expect(r.stateOf(oct, 2), DayState.locked);
    });

    test('days off clear themselves when reached', () {
      final r = octWith('oom');
      expect(r.playableDay(oct), 3);
      expect(r.stateOf(oct, 1), DayState.done);
      expect(r.stateOf(oct, 2), DayState.done);
    });

    test('a day off ahead of the playable day stays locked', () {
      expect(octWith('mo').stateOf(oct, 2), DayState.locked);
    });

    test('a worked day clears once each bed of its shift is finished that day', () {
      final duty = Duty(oct, 1, morning);
      var r = octWith('moa');
      expect(r.nextDutyBed(duty, bedNums), 1);

      final first = r.recordBed(duty, 2, bedNums);
      expect(first.cleared, isFalse);
      r = first.roster;
      expect(r.doneOn(oct, 1), {2});
      expect(r.nextDutyBed(duty, bedNums), 1);

      final second = r.recordBed(duty, 1, bedNums);
      expect(second.cleared, isTrue);
      r = second.roster;
      expect(r.cleared, {oct.dayKey(1)});
      expect(r.doneBeds, isEmpty);
      expect(r.playableDay(oct), 3, reason: 'day 2 is off');
      expect(r.shiftsCleared, 1, reason: 'days off are not shifts worked');
      expect(r.nextDutyBed(duty, bedNums), isNull);
    });

    test('a bed of another shift does not count', () {
      final r = octWith('m');
      expect(identical(r.recordBed(Duty(oct, 1, morning), 3, bedNums).roster, r), isTrue);
    });

    test('a duty for a day that is not playable does not count', () {
      final r = octWith('mm', cleared: {oct.dayKey(1)});
      expect(identical(r.recordBed(Duty(oct, 1, morning), 1, bedNums).roster, r), isTrue);
      expect(identical(r.recordBed(Duty(oct, 3, morning), 1, bedNums).roster, r), isTrue);
    });

    test('a duty whose shift no longer matches the day does not count', () {
      final r = octWith('a');
      expect(identical(r.recordBed(Duty(oct, 1, morning), 1, bedNums).roster, r), isTrue);
    });

    test('the month is done when every day is', () {
      final all = {for (var d = 1; d <= 31; d++) oct.dayKey(d)};
      final r = octWith('', cleared: all);
      expect(r.playableDay(oct), isNull);
      expect(r.stateOf(oct, 31), DayState.done);
    });

    test('reset forgets the days played but keeps the shifts', () {
      final r = octWith(
        'am',
        cleared: {oct.dayKey(1)},
      ).recordBed(Duty(oct, 2, morning), 1, bedNums).roster.withoutProgress();
      expect(r.cleared, isEmpty);
      expect(r.doneBeds, isEmpty);
      expect(r.shiftOn(oct, 1), Shift.afternoon);
    });
  });

  group('saving', () {
    test('survives a JSON round trip', () {
      final r = Roster.empty
          .roll(oct, Random(3))
          .roll(oct.next, Random(4))
          .recordBed(Duty(oct, 1, morning), 1, bedNums)
          .roster;
      final back = Roster.fromJson(jsonDecode(jsonEncode(r.toJson())));
      expect(back.months, r.months);
      expect(back.cleared, r.cleared);
      expect(back.doneBeds, r.doneBeds);
    });

    test('unreadable parts are dropped, not fatal', () {
      final r = Roster.fromJson({
        'months': {'2026-10': 'mmx', '2026-11': 'mao', '2026-12': 7},
        'cleared': ['2026-11-01', 3],
        'doneBeds': {
          '2026-11-02': [1, 'x'],
          'bad': 'y',
        },
      });
      expect(r.months.keys, ['2026-11']);
      expect(r.cleared, {'2026-11-01'});
      expect(r.doneBeds, {
        '2026-11-02': {1},
      });
      expect(Roster.fromJson('nonsense').months, isEmpty);
    });
  });
}
