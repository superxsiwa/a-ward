import 'dart:convert';

import 'package:criticalcare/game/case_session.dart';
import 'package:criticalcare/game/progress.dart';
import 'package:flutter_test/flutter_test.dart';

CaseResult result(int bed, int stars, {int trays = 0, int flawless = 0, bool emergency = true}) =>
    CaseResult(
      bedNum: bed,
      stars: stars,
      mistakes: 3 - stars,
      traysSorted: trays,
      flawlessSteps: flawless,
      isEmergency: emergency,
    );

void main() {
  test('a bed keeps its best stars; gained counts only an improvement', () {
    var p = Progress.empty;
    var out = p.record(result(1, 2));
    expect(out.gainedStars, 2);
    p = out.progress;
    out = p.record(result(1, 1));
    expect(out.gainedStars, 0);
    expect(out.progress.bed(1).stars, 2, reason: 'a worse replay keeps the best');
    out = out.progress.record(result(1, 3));
    expect(out.gainedStars, 1);
    expect(out.progress.bed(1).stars, 3);
  });

  test('the counters follow his finishCase', () {
    var p = Progress.empty.record(result(1, 3, trays: 13, flawless: 6)).progress;
    p = p.record(result(1, 2, trays: 13, flawless: 4, emergency: false)).progress;
    final s = p.stats;
    expect(s.totalCompletedCases, 2);
    expect(s.perfectCases, 1);
    expect(s.emergencyCasesDone, 1);
    expect(s.replayedCases, 1);
    expect(s.trayItemsSorted, 26);
    expect(s.stepsWithoutMistake, 10);
  });

  test('levels: one per 3 stars, capped at the last rank; a crossing is reported', () {
    expect([0, 2, 3, 5, 6, 24, 30].map(levelOfStars), [1, 1, 2, 2, 3, 9, 9]);
    var p = Progress.empty.record(result(1, 2)).progress;
    final out = p.record(result(2, 1));
    expect(out.levelUp, 2);
    expect(out.progress.rank, ranks[1]);
    expect(p.record(result(1, 2)).levelUp, isNull);
  });

  test('next bed: the first unpassed, then the first under 3 stars, then none', () {
    final beds = [1, 2, 3];
    var p = Progress.empty;
    expect(p.nextBed(beds), 1);
    p = p.record(result(1, 2)).progress;
    expect(p.nextBed(beds), 2);
    p = p.record(result(2, 3)).progress.record(result(3, 3)).progress;
    expect(p.nextBed(beds), 1, reason: 'bed 1 has 2 stars');
    p = p.record(result(1, 3)).progress;
    expect(p.nextBed(beds), isNull);
  });

  test('saved JSON reads back, and unreadable data starts over', () {
    final p = Progress.empty.record(result(4, 2, trays: 7)).progress;
    final back = Progress.fromJson(jsonDecode(jsonEncode(p.toJson())));
    expect(back.bed(4).stars, 2);
    expect(back.stats.trayItemsSorted, 7);
    expect(Progress.fromJson('nonsense').totalStars, 0);
    expect(
      Progress.fromJson({
        'beds': {'x': 1, '2': 'y'},
      }).beds,
      isEmpty,
    );
  });
}
