/// The monthly shift roster, after superxsiwa's RosterPage and the roster logic in App.tsx: every
/// day of a month gets a random shift, days are played in order, a worked day clears when each
/// bed of its shift has been finished on that day, and a day off clears itself when it is reached.
library;

import 'dart:math';

enum Shift {
  morning('m'),
  afternoon('a'),
  night('n'),
  off('o');

  const Shift(this.code);

  /// One letter per day in the saved month.
  final String code;
}

/// One of his three working shifts (`SHIFTS` in MilestoneDefs.ts). [bedIndices] point into the
/// ward's bed list, so they follow whatever cases the ward holds.
class ShiftDef {
  const ShiftDef({
    required this.shift,
    required this.name,
    required this.time,
    required this.icon,
    required this.chargeNurse,
    required this.bedIndices,
  });

  final Shift shift;
  final String name;
  final String time;
  final String icon;
  final String chargeNurse;
  final List<int> bedIndices;

  /// The bed numbers this shift looks after in a ward whose beds are [bedNums], in ward order.
  List<int> bedsIn(List<int> bedNums) => [
    for (final i in bedIndices)
      if (i < bedNums.length) bedNums[i],
  ];
}

const shiftDefs = [
  ShiftDef(
    shift: Shift.morning,
    name: 'เวรเช้า (Morning Shift)',
    time: '07:00 - 15:00 น.',
    icon: '🌅',
    chargeNurse: 'พว. ณิชาภา (RN)',
    bedIndices: [0, 1],
  ),
  ShiftDef(
    shift: Shift.afternoon,
    name: 'เวรบ่าย (Afternoon Shift)',
    time: '15:00 - 23:00 น.',
    icon: '☀️',
    chargeNurse: 'พว. กานดา (RN)',
    bedIndices: [2, 3, 4],
  ),
  ShiftDef(
    shift: Shift.night,
    name: 'เวรดึก (Night Shift)',
    time: '23:00 - 07:00 น.',
    icon: '🌙',
    chargeNurse: 'พว. ปวีณา (RN)',
    bedIndices: [5, 6, 7],
  ),
];

/// The working shift's definition; null for a day off.
ShiftDef? shiftDef(Shift shift) {
  for (final d in shiftDefs) {
    if (d.shift == shift) return d;
  }
  return null;
}

/// His `SHIFT_POOL`: each working shift is twice as likely as a day off.
const shiftPool = [
  Shift.morning,
  Shift.afternoon,
  Shift.night,
  Shift.morning,
  Shift.afternoon,
  Shift.night,
  Shift.off,
];

/// A calendar month ([month] 1 to 12).
class RosterMonth {
  const RosterMonth(this.year, this.month);

  factory RosterMonth.of(DateTime t) => RosterMonth(t.year, t.month);

  final int year;
  final int month;

  int get days => DateTime(year, month + 1, 0).day;

  /// The weekday of the 1st, Sunday = 0 (his calendar weeks start on Sunday).
  int get firstWeekday => DateTime(year, month).weekday % 7;

  RosterMonth get next => month == 12 ? RosterMonth(year + 1, 1) : RosterMonth(year, month + 1);
  RosterMonth get previous => month == 1 ? RosterMonth(year - 1, 12) : RosterMonth(year, month - 1);

  bool contains(DateTime t) => t.year == year && t.month == month;

  String get key => '$year-${month.toString().padLeft(2, '0')}';
  String dayKey(int day) => '$key-${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is RosterMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

/// The day the player went on duty for from the roster (his `filterShift` + `selectedDay`): the
/// ward highlights the shift's beds, and beds finished then count towards clearing the day.
class Duty {
  const Duty(this.month, this.day, this.shift);

  final RosterMonth month;
  final int day;
  final ShiftDef shift;
}

enum DayState { done, playable, locked }

class Roster {
  const Roster({this.months = const {}, this.cleared = const {}, this.doneBeds = const {}});

  static const empty = Roster();
  static const schemaVersion = 1;

  /// The shift of each day, for every month seen, by month key.
  final Map<String, List<Shift>> months;

  /// Worked days cleared, by day key.
  final Set<String> cleared;

  /// Beds finished on the playable day of a month, by day key, until the day clears.
  final Map<String, Set<int>> doneBeds;

  bool has(RosterMonth m) => months.containsKey(m.key);

  /// The shift on [day]; a morning shift when the month has no schedule (his default).
  Shift shiftOn(RosterMonth m, int day) {
    final days = months[m.key];
    return days != null && day >= 1 && day <= days.length ? days[day - 1] : Shift.morning;
  }

  /// The day to play: the first that is neither cleared nor off. Null once the month is done.
  int? playableDay(RosterMonth m) {
    for (var d = 1; d <= m.days; d++) {
      if (shiftOn(m, d) != Shift.off && !cleared.contains(m.dayKey(d))) return d;
    }
    return null;
  }

  DayState stateOf(RosterMonth m, int day) {
    final p = playableDay(m);
    if (p == null || day < p) return DayState.done;
    return day == p ? DayState.playable : DayState.locked;
  }

  /// Beds finished so far on [day] (only the playable day has any).
  Set<int> doneOn(RosterMonth m, int day) => doneBeds[m.dayKey(day)] ?? const {};

  /// Worked days cleared, days off not counted (for the milestones).
  int get shiftsCleared => cleared.length;

  /// A random schedule for [m] (his `generateMonthSchedule`). When [m] already has one, only the
  /// days from the playable day on are drawn again: days already done keep their shift.
  Roster roll(RosterMonth m, Random random) {
    final old = months[m.key];
    final from = old == null ? 1 : playableDay(m) ?? m.days + 1;
    return Roster(
      months: {
        ...months,
        m.key: [
          for (var d = 1; d <= m.days; d++)
            d < from ? shiftOn(m, d) : shiftPool[random.nextInt(shiftPool.length)],
        ],
      },
      cleared: cleared,
      doneBeds: {
        for (final e in doneBeds.entries)
          if (!e.key.startsWith('${m.key}-')) e.key: e.value,
      },
    );
  }

  /// Whether [duty] is for the day that can still be cleared.
  bool counts(Duty duty) =>
      playableDay(duty.month) == duty.day && shiftOn(duty.month, duty.day) == duty.shift.shift;

  /// Counts bed [bedNum] as finished on [duty]'s day (in a ward whose beds are [bedNums]). Only the
  /// playable day and the beds of its shift count; the day clears once every bed is done.
  ({Roster roster, bool cleared}) recordBed(Duty duty, int bedNum, List<int> bedNums) {
    final beds = duty.shift.bedsIn(bedNums);
    if (!counts(duty) || (beds.isNotEmpty && !beds.contains(bedNum))) {
      return (roster: this, cleared: false);
    }
    final key = duty.month.dayKey(duty.day);
    final done = {...doneOn(duty.month, duty.day), bedNum};
    if (beds.every(done.contains)) {
      return (
        roster: Roster(
          months: months,
          cleared: {...cleared, key},
          doneBeds: {...doneBeds}..remove(key),
        ),
        cleared: true,
      );
    }
    return (
      roster: Roster(months: months, cleared: cleared, doneBeds: {...doneBeds, key: done}),
      cleared: false,
    );
  }

  /// The first bed of [duty]'s shift not finished yet that day; null when none is left or the
  /// day no longer counts.
  int? nextDutyBed(Duty duty, List<int> bedNums) {
    if (!counts(duty)) return null;
    final done = doneOn(duty.month, duty.day);
    for (final n in duty.shift.bedsIn(bedNums)) {
      if (!done.contains(n)) return n;
    }
    return null;
  }

  /// "Reset progress" (his reset): every day back to unplayed; the schedules stay.
  Roster withoutProgress() => Roster(months: months);

  Map<String, Object?> toJson() => {
    'version': schemaVersion,
    'months': {for (final e in months.entries) e.key: e.value.map((s) => s.code).join()},
    'cleared': [...cleared]..sort(),
    'doneBeds': {
      for (final e in doneBeds.entries) e.key: [...e.value]..sort(),
    },
  };

  /// Reads a saved roster; anything unreadable is dropped (a month without a schedule gets a new
  /// one) rather than crashing the app.
  factory Roster.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return empty;
    final months = <String, List<Shift>>{};
    if (json['months'] case final Map<String, Object?> raw) {
      for (final MapEntry(:key, :value) in raw.entries) {
        if (value is! String) continue;
        final days = [
          for (final c in value.split(''))
            for (final s in Shift.values)
              if (s.code == c) s,
        ];
        if (days.length == value.length) months[key] = days;
      }
    }
    final cleared = <String>{
      if (json['cleared'] case final List<Object?> raw) ...raw.whereType<String>(),
    };
    final doneBeds = <String, Set<int>>{};
    if (json['doneBeds'] case final Map<String, Object?> raw) {
      for (final MapEntry(:key, :value) in raw.entries) {
        if (value is List<Object?>) {
          doneBeds[key] = {for (final n in value.whereType<num>()) n.toInt()};
        }
      }
    }
    return Roster(months: months, cleared: cleared, doneBeds: doneBeds);
  }
}
