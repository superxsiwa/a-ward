import 'dart:math';

import 'package:criticalcare/game/case_model.dart';
import 'package:criticalcare/game/step_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/cases.dart';

void main() {
  final b = bed(1);
  final prep = b.stages[0]; // choices + sequence fs1..fs4
  final trays = b.stages[1]; // unordered trays ftr1 (fe1-fe4), ftr2 (fe5-fe7)
  final ordered = b.stages[2]; // ordered trays fdtr1, fdtr2
  final safe = b.stages[3]; // drop box fa1-fa4, unsafe faw1, faw2

  StepState fresh(Stage stage) => StepState.fresh(stage, Random(7));

  group('fresh', () {
    test('shuffles the whole pool with the given random; slots, trays and box start empty', () {
      final s = fresh(prep);
      expect(s.pool, unorderedEquals(['fs1', 'fs2', 'fs3', 'fs4']));
      expect(fresh(prep).pool, s.pool, reason: 'same seed, same order');
      expect(s.slots, [null, null, null, null]);
      expect(s.trays, isNull);
      expect(fresh(trays).trays, {'ftr1': <String>[], 'ftr2': <String>[]});
      expect(fresh(safe).dropBox, isEmpty);
      expect(s.locked, isFalse);
    });
  });

  group('tapCard', () {
    test('fills the first empty slot, and a placed card goes back to the pool', () {
      var s = fresh(prep).tapCard('fs3').tapCard('fs1');
      expect(s.slots, ['fs3', 'fs1', null, null]);
      s = s.tapCard('fs3');
      expect(s.slots, [null, 'fs1', null, null]);
      expect(s.pool.last, 'fs3');
      s = s.tapCard('fs2');
      expect(s.slots, ['fs2', 'fs1', null, null], reason: 'the first empty slot again');
    });

    test('does nothing to a pool card when every slot is full', () {
      final json = copyJson(bedJson(1));
      final sequence = stageOf(json, 0)['sequenceTask'] as Map<String, Object?>;
      (sequence['pool'] as List).add({'id': 'fsx', 'text': 'extra card'});
      final stage = BedCase.fromJson(json).stages[0];
      var s = StepState.fresh(stage, Random(7));
      for (final id in ['fs1', 'fs2', 'fs3', 'fs4']) {
        s = s.tapCard(id);
      }
      expect(s.pool, ['fsx']);
      expect(s.tapCard('fsx'), same(s));
    });

    test('drops into the box on an unordered drop task', () {
      final s = fresh(safe).tapCard('faw1');
      expect(s.dropBox, ['faw1']);
      expect(s.pool, isNot(contains('faw1')));
    });

    test('picks up and puts down on a trays task; another tap switches the picked card', () {
      var s = fresh(trays).tapCard('fe1');
      expect(s.picked, 'fe1');
      expect(s.pool, contains('fe1'), reason: 'picking does not move it');
      s = s.tapCard('fe2');
      expect(s.picked, 'fe2');
      expect(s.tapCard('fe2').picked, isNull);
    });
  });

  group('tapZone', () {
    test('a picked card goes into the tapped tray; the pool puts it down', () {
      var s = fresh(trays).tapCard('fe5').tapZone(const TrayZone('ftr2'));
      expect(s.trays!['ftr2'], ['fe5']);
      expect(s.picked, isNull);
      s = s.tapCard('fe1').tapZone(const PoolZone());
      expect(s.picked, isNull);
      expect(s.pool, contains('fe1'));
    });

    test('nothing happens without a picked card', () {
      final s = fresh(trays);
      expect(s.tapZone(const TrayZone('ftr1')), same(s));
    });
  });

  group('move', () {
    test('from the pool onto a filled slot sends the old card back to the pool', () {
      var s = fresh(prep).move('fs1', const SlotZone(0));
      s = s.move('fs2', const SlotZone(0));
      expect(s.slots, ['fs2', null, null, null]);
      expect(s.pool.last, 'fs1');
    });

    test('from slot to slot swaps the two cards', () {
      var s = fresh(prep).move('fs1', const SlotZone(0)).move('fs2', const SlotZone(1));
      s = s.move('fs2', const SlotZone(0));
      expect(s.slots, ['fs2', 'fs1', null, null]);
    });

    test('into a tray goes in front of the card it lands on, or last', () {
      var s = fresh(ordered)
          .move('fd1', const TrayZone('fdtr1'))
          .move('fd3', const TrayZone('fdtr1'))
          .move('fd2', const TrayZone('fdtr1', before: 'fd3'));
      expect(s.trays!['fdtr1'], ['fd1', 'fd2', 'fd3']);
      s = s.move('fd3', const TrayZone('fdtr1', before: 'fd1'));
      expect(s.trays!['fdtr1'], ['fd3', 'fd1', 'fd2'], reason: 'reorder inside one tray');
      expect(s.move('fd1', const TrayZone('fdtr1', before: 'fd1')), same(s));
    });

    test('between trays takes the card out of the old tray', () {
      final s = fresh(trays).move('fe1', const TrayZone('ftr2')).move('fe1', const TrayZone('ftr1'));
      expect(s.trays, {'ftr1': ['fe1'], 'ftr2': <String>[]});
      expect(s.whereIs('fe1'), isA<TrayZone>().having((z) => z.trayId, 'tray', 'ftr1'));
    });

    test('clears red cards but not red options', () {
      final s = fresh(prep).markWrong({'fs1'}, {'fc4'}).move('fs2', const SlotZone(3));
      expect(s.wrongItems, isEmpty);
      expect(s.wrongOptions, {'fc4'});
    });

    test('ignores unknown cards and zones the step does not have', () {
      final s = fresh(prep);
      expect(s.move('nope', const SlotZone(0)), same(s));
      expect(s.move('fs1', const TrayZone('ftr1')), same(s));
      expect(s.move('fs1', const SlotZone(9)), same(s));
    });
  });

  group('options', () {
    test('toggle on and off and clear red options only', () {
      var s = fresh(prep).markWrong({'fs1'}, {'fc4'}).toggleOption('fc1');
      expect(s.selected, {'fc1'});
      expect(s.wrongOptions, isEmpty);
      expect(s.wrongItems, {'fs1'});
      s = s.toggleOption('fc1');
      expect(s.selected, isEmpty);
    });
  });

  group('locked', () {
    test('a locked state ignores every move', () {
      final s = fresh(prep).toggleOption('fc1').move('fs1', const SlotZone(0)).lock();
      expect(s.locked, isTrue);
      expect(s.tapCard('fs1'), same(s));
      expect(s.move('fs2', const SlotZone(1)), same(s));
      expect(s.toggleOption('fc2'), same(s));
    });

    test('lock clears every red mark', () {
      final s = fresh(prep).markWrong({'fs1'}, {'fc4'}).lock();
      expect(s.wrongItems, isEmpty);
      expect(s.wrongOptions, isEmpty);
    });
  });

  group('solved', () {
    test('lays out the answer of choices + sequence and locks', () {
      final s = fresh(prep).toggleOption('fc4').move('fs4', const SlotZone(0)).solved(prep);
      expect(s.selected, {'fc1', 'fc2', 'fc3'});
      expect(s.slots, ['fs1', 'fs2', 'fs3', 'fs4']);
      expect(s.pool, isEmpty);
      expect(s.locked, isTrue);
    });

    test('fills each tray in its expected order', () {
      final s = fresh(ordered).solved(ordered);
      expect(s.trays, {
        'fdtr1': ['fd1', 'fd2', 'fd3'],
        'fdtr2': ['fd4', 'fd5', 'fd6'],
      });
    });

    test('leaves the unsafe cards of a drop task in the pool, in case order', () {
      final s = fresh(safe).tapCard('faw2').solved(safe);
      expect(s.dropBox, ['fa1', 'fa2', 'fa3', 'fa4']);
      expect(s.pool, ['faw1', 'faw2']);
    });
  });
}
