import 'dart:math';

import 'package:criticalcare/game/case_model.dart';
import 'package:criticalcare/game/step_checker.dart';
import 'package:criticalcare/game/step_board.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cases.dart';

void main() {
  final b = bed(1);
  final prep = b.stages[0];
  final trays = b.stages[1];
  final ordered = b.stages[2];
  final safe = b.stages[3];

  StepBoard fresh(Stage stage) => StepBoard.fresh(stage, Random(3));

  StepBoard fill(Stage stage, List<String> order) {
    var s = fresh(stage);
    for (final (i, id) in order.indexed) {
      s = s.move(id, SlotZone(i));
    }
    return s;
  }

  CheckDone done(CheckResult r) => r as CheckDone;

  group('not ready', () {
    test('reports the first gap only: options before slots', () {
      expect(
        checkStep(prep, fresh(prep)),
        isA<CheckIncomplete>().having((r) => r.reason, 'reason', isA<NoOptionSelected>()),
      );
      final picked = fresh(prep).toggleOption('fc1');
      expect((checkStep(prep, picked) as CheckIncomplete).reason, isA<EmptySlots>());
    });

    test('trays need an empty pool; the drop box needs as many cards as safe actions', () {
      final oneInTray = fresh(trays).move('fe1', const TrayZone('ftr1'));
      expect((checkStep(trays, oneInTray) as CheckIncomplete).reason, isA<CardsLeftInPool>());
      final three = fresh(safe).tapCard('fa1').tapCard('fa2').tapCard('faw1');
      expect(
        (checkStep(safe, three) as CheckIncomplete).reason,
        isA<TooFewInDropBox>().having((r) => r.needed, 'needed', 4),
      );
    });
  });

  group('choices', () {
    final rightOrder = ['fs1', 'fs2', 'fs3', 'fs4'];

    test('a wrong option is reported and marked, before missing ones', () {
      final s = fill(prep, rightOrder).toggleOption('fc1').toggleOption('fc4');
      final r = done(checkStep(prep, s));
      expect(r.errors, [isA<WrongOptionSelected>()]);
      expect(r.wrongOptions, {'fc4'});
    });

    test('missing correct options are reported without red marks', () {
      final s = fill(prep, rightOrder).toggleOption('fc1');
      final r = done(checkStep(prep, s));
      expect(r.errors, [isA<MissingOptions>()]);
      expect(r.wrongOptions, isEmpty);
    });
  });

  group('sequence', () {
    test('cards in the wrong slot are marked red; right ones are not', () {
      final s = fill(prep, [
        'fs1',
        'fs3',
        'fs2',
        'fs4',
      ]).toggleOption('fc1').toggleOption('fc2').toggleOption('fc3');
      final r = done(checkStep(prep, s));
      expect(r.errors, [isA<WrongSequence>()]);
      expect(r.wrongItems, {'fs2', 'fs3'});
    });

    test('both tasks of a step report together', () {
      final s = fill(prep, ['fs2', 'fs1', 'fs3', 'fs4']).toggleOption('fc4');
      expect(done(checkStep(prep, s)).errors, [isA<WrongOptionSelected>(), isA<WrongSequence>()]);
    });
  });

  group('trays', () {
    StepBoard place(Stage stage, Map<String, List<String>> layout) {
      var s = fresh(stage);
      layout.forEach((tray, ids) {
        for (final id in ids) {
          s = s.move(id, TrayZone(tray));
        }
      });
      return s;
    }

    test('unordered: a card in the wrong tray is marked; that tray is reported', () {
      final s = place(trays, {
        'ftr1': ['fe1', 'fe2', 'fe3', 'fe5'],
        'ftr2': ['fe4', 'fe6', 'fe7'],
      });
      final r = done(checkStep(trays, s));
      expect(r.wrongItems, {'fe5', 'fe4'});
      expect([for (final e in r.errors) (e as WrongTray).tray.id], ['ftr1', 'ftr2']);
      expect((r.errors.first as WrongTray).ordered, isFalse);
    });

    test('unordered: order inside a tray does not matter', () {
      final s = place(trays, {
        'ftr1': ['fe4', 'fe3', 'fe2', 'fe1'],
        'ftr2': ['fe7', 'fe5', 'fe6'],
      });
      expect(done(checkStep(trays, s)).passed, isTrue);
    });

    test('ordered: a card out of place is marked', () {
      final s = place(ordered, {
        'fdtr1': ['fd1', 'fd3', 'fd2'],
        'fdtr2': ['fd4', 'fd5', 'fd6'],
      });
      final r = done(checkStep(ordered, s));
      expect(r.wrongItems, {'fd3', 'fd2'});
      expect(r.errors, [isA<WrongTray>().having((e) => e.ordered, 'ordered', isTrue)]);
    });

    test('ordered: a short tray fails without marks when its cards sit at the end of another', () {
      final s = place(ordered, {
        'fdtr1': ['fd1', 'fd2'],
        'fdtr2': ['fd4', 'fd5', 'fd6', 'fd3'],
      });
      final r = done(checkStep(ordered, s));
      expect(r.wrongItems, {'fd3'});
      expect([for (final e in r.errors) (e as WrongTray).tray.id], ['fdtr1', 'fdtr2']);
    });
  });

  group('unordered drop', () {
    test('an unsafe card is marked and reported', () {
      final s = fresh(safe).tapCard('fa1').tapCard('fa2').tapCard('fa3').tapCard('faw2');
      final r = done(checkStep(safe, s));
      expect(r.errors, [isA<UnsafeAction>()]);
      expect(r.wrongItems, {'faw2'});
    });

    test('too many cards fail even when the safe ones are all there', () {
      final s = fresh(safe)
          .tapCard('fa1')
          .tapCard('fa2')
          .tapCard('fa3')
          .tapCard('fa4')
          .tapCard('faw1');
      expect(done(checkStep(safe, s)).errors, [isA<UnsafeAction>()]);
    });

    test('the safe cards in any order pass', () {
      final s = fresh(safe).tapCard('fa4').tapCard('fa2').tapCard('fa1').tapCard('fa3');
      expect(done(checkStep(safe, s)).passed, isTrue);
    });
  });
}
