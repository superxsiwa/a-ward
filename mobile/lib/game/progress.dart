/// The player's progress, kept on the device: best stars per bed and the counters the
/// milestones use. Ported from `progress`, `playerStats` and `finishCase` in superxsiwa's App.tsx.
library;

import 'case_session.dart';

/// His rank names (`RANKS` in MilestoneDefs.ts), one per level.
const ranks = [
  'นักศึกษาพยาบาลฝึกหัด',
  'พยาบาลฝึกงาน',
  'พยาบาลน้องใหม่ CCU',
  'พยาบาล CCU ฝีมือดี',
  'พยาบาลชำนาญการ',
  'หัวหน้าเวร CCU',
  'พยาบาล CCU ดาวเด่น',
  'ผู้เชี่ยวชาญ CCU',
  'ตำนานแห่งหอผู้ป่วยวิกฤต',
];

/// Level from total stars: one level per 3 stars, capped at the last rank (`levelOfStars`).
int levelOfStars(int stars) {
  final level = stars ~/ 3 + 1;
  return level > ranks.length ? ranks.length : level;
}

class BedRecord {
  const BedRecord({required this.passed, required this.stars});

  final bool passed;

  /// Best stars over every play.
  final int stars;

  Map<String, Object?> toJson() => {'passed': passed, 'stars': stars};

  factory BedRecord.fromJson(Map<String, Object?> j) =>
      BedRecord(passed: j['passed'] == true, stars: (j['stars'] as num?)?.toInt() ?? 0);
}

/// His `PlayerStats`. Shifts worked are counted by the roster.
class PlayerStats {
  const PlayerStats({
    this.totalPlaySeconds = 0,
    this.totalCompletedCases = 0,
    this.perfectCases = 0,
    this.emergencyCasesDone = 0,
    this.replayedCases = 0,
    this.trayItemsSorted = 0,
    this.stepsWithoutMistake = 0,
  });

  /// Time with the app open in the foreground (his playtime tracker).
  final int totalPlaySeconds;
  final int totalCompletedCases;
  final int perfectCases;
  final int emergencyCasesDone;
  final int replayedCases;
  final int trayItemsSorted;
  final int stepsWithoutMistake;

  static const _keys = [
    'totalPlaySeconds',
    'totalCompletedCases',
    'perfectCases',
    'emergencyCasesDone',
    'replayedCases',
    'trayItemsSorted',
    'stepsWithoutMistake',
  ];

  List<int> get _values => [
    totalPlaySeconds,
    totalCompletedCases,
    perfectCases,
    emergencyCasesDone,
    replayedCases,
    trayItemsSorted,
    stepsWithoutMistake,
  ];

  Map<String, Object?> toJson() => {for (final (i, k) in _keys.indexed) k: _values[i]};

  factory PlayerStats.fromJson(Map<String, Object?> j) {
    int v(String k) => (j[k] as num?)?.toInt() ?? 0;
    return PlayerStats(
      totalPlaySeconds: v('totalPlaySeconds'),
      totalCompletedCases: v('totalCompletedCases'),
      perfectCases: v('perfectCases'),
      emergencyCasesDone: v('emergencyCasesDone'),
      replayedCases: v('replayedCases'),
      trayItemsSorted: v('trayItemsSorted'),
      stepsWithoutMistake: v('stepsWithoutMistake'),
    );
  }
}

/// What a finished case changed, for the result dialog.
class RecordOutcome {
  const RecordOutcome({required this.progress, required this.gainedStars, required this.levelUp});

  final Progress progress;

  /// Stars added to the bed's best (0 when this play did not beat it).
  final int gainedStars;

  /// The new level when the total crossed one, else null.
  final int? levelUp;
}

class Progress {
  const Progress({this.beds = const {}, this.stats = const PlayerStats()});

  static const empty = Progress();
  static const schemaVersion = 1;

  final Map<int, BedRecord> beds;
  final PlayerStats stats;

  int get totalStars => beds.values.fold(0, (n, b) => n + b.stars);
  int get passedCount => beds.values.where((b) => b.passed).length;
  int get level => levelOfStars(totalStars);
  String get rank => ranks[level - 1];
  BedRecord bed(int bedNum) => beds[bedNum] ?? const BedRecord(passed: false, stars: 0);

  /// The bed to play next: the first not yet passed, else the first under 3 stars, else none
  /// (his `nxt` / `fallbackNxt`).
  int? nextBed(List<int> bedNums) {
    for (final n in bedNums) {
      if (!bed(n).passed) return n;
    }
    for (final n in bedNums) {
      if (bed(n).stars < 3) return n;
    }
    return null;
  }

  /// Only the records of the ward's beds [bedNums] (his totals count the beds in the ward: after a
  /// case file import, records of beds no longer there must not count). The counters stay.
  Progress within(Iterable<int> bedNums) {
    final keep = bedNums.toSet();
    if (beds.keys.every(keep.contains)) return this;
    return Progress(
      beds: {
        for (final e in beds.entries)
          if (keep.contains(e.key)) e.key: e.value,
      },
      stats: stats,
    );
  }

  /// Adds a finished case (`finishCase`): the bed keeps its best stars; the counters grow. A level
  /// up is judged on the ward's beds [ward] when given.
  RecordOutcome record(CaseResult r, {Iterable<int>? ward}) {
    final before = bed(r.bedNum);
    final best = r.stars > before.stars ? r.stars : before.stars;
    final s = stats;
    final next = Progress(
      beds: {
        ...beds,
        r.bedNum: BedRecord(passed: true, stars: best),
      },
      stats: PlayerStats(
        totalPlaySeconds: s.totalPlaySeconds,
        totalCompletedCases: s.totalCompletedCases + 1,
        perfectCases: s.perfectCases + (r.stars == 3 ? 1 : 0),
        emergencyCasesDone: s.emergencyCasesDone + (r.isEmergency ? 1 : 0),
        replayedCases: s.replayedCases + (before.passed ? 1 : 0),
        trayItemsSorted: s.trayItemsSorted + r.traysSorted,
        stepsWithoutMistake: s.stepsWithoutMistake + r.flawlessSteps,
      ),
    );
    final was = ward == null ? level : within(ward).level;
    final now = ward == null ? next.level : next.within(ward).level;
    return RecordOutcome(
      progress: next,
      gainedStars: best - before.stars,
      levelUp: now > was ? now : null,
    );
  }

  /// [seconds] more play time.
  Progress played(int seconds) {
    final s = stats;
    return Progress(
      beds: beds,
      stats: PlayerStats(
        totalPlaySeconds: s.totalPlaySeconds + seconds,
        totalCompletedCases: s.totalCompletedCases,
        perfectCases: s.perfectCases,
        emergencyCasesDone: s.emergencyCasesDone,
        replayedCases: s.replayedCases,
        trayItemsSorted: s.trayItemsSorted,
        stepsWithoutMistake: s.stepsWithoutMistake,
      ),
    );
  }

  Map<String, Object?> toJson() => {
    'version': schemaVersion,
    'beds': {for (final e in beds.entries) '${e.key}': e.value.toJson()},
    'stats': stats.toJson(),
  };

  /// Reads saved progress; anything unreadable starts over rather than crashing the app.
  factory Progress.fromJson(Object? json) {
    if (json is! Map<String, Object?>) return empty;
    final beds = <int, BedRecord>{};
    final raw = json['beds'];
    if (raw is Map<String, Object?>) {
      for (final e in raw.entries) {
        final n = int.tryParse(e.key);
        final v = e.value;
        if (n != null && v is Map<String, Object?>) beds[n] = BedRecord.fromJson(v);
      }
    }
    final stats = json['stats'];
    return Progress(
      beds: beds,
      stats: stats is Map<String, Object?> ? PlayerStats.fromJson(stats) : const PlayerStats(),
    );
  }
}
