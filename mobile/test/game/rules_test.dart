import 'package:criticalcare/game/case_model.dart';
import 'package:criticalcare/game/rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cases.dart';

void main() {
  test('stars: no mistakes 3, one or two 2, more 1', () {
    expect([for (var m = 0; m <= 5; m++) starsForMistakes(m)], [3, 2, 2, 1, 1, 1]);
  });

  test('the 1st mistake dims star 3, the 3rd dims star 2, others dim none', () {
    expect([for (var m = 0; m <= 4; m++) starLostAt(m)], [null, 3, null, 2, null]);
  });

  group('monitor alarm', () {
    Vitals v({int hr = 80, String spo2 = '98%', int map = 80}) =>
        Vitals(hr: hr, bp: '120/80', spo2: spo2, map: map);

    test('normal vitals do not alarm', () => expect(isAlarmVitals(v()), isFalse));

    test('alarms at HR 120 and above or below 50', () {
      expect(isAlarmVitals(v(hr: 119)), isFalse);
      expect(isAlarmVitals(v(hr: 120)), isTrue);
      expect(isAlarmVitals(v(hr: 50)), isFalse);
      expect(isAlarmVitals(v(hr: 49)), isTrue);
    });

    test('alarms at SpO2 90% or less and MAP below 65', () {
      expect(isAlarmVitals(v(spo2: '91%')), isFalse);
      expect(isAlarmVitals(v(spo2: '90%')), isTrue);
      expect(isAlarmVitals(v(map: 65)), isFalse);
      expect(isAlarmVitals(v(map: 64)), isTrue);
    });

    test('an SpO2 that is not a number does not alarm (JavaScript NaN <= 90 is false)', () {
      expect(isAlarmVitals(v(spo2: 'n/a')), isFalse);
    });
  });

  test('the timed step is the equipment step (unordered trays), wherever it sits (Q-B)', () {
    final stages = bed(1).stages;
    expect([for (final st in stages) isTimedStage(st)], [false, true, false, false, false, false]);
  });
}
