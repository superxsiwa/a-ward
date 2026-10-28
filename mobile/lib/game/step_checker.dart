import 'case_model.dart';
import 'step_state.dart';

/// Why a step cannot be checked yet. Only the first reason is reported, as in his code.
sealed class Incomplete {
  const Incomplete();
}

/// The choices task has nothing selected.
class NoOptionSelected extends Incomplete {
  const NoOptionSelected();
}

/// A sequence slot is still empty.
class EmptySlots extends Incomplete {
  const EmptySlots();
}

/// Cards are still in the pool of a trays task.
class CardsLeftInPool extends Incomplete {
  const CardsLeftInPool();
}

/// The drop box holds fewer cards than the task needs.
class TooFewInDropBox extends Incomplete {
  const TooFewInDropBox(this.needed);

  final int needed;
}

/// One message shown after a failed check.
sealed class StepError {
  const StepError();
}

/// An option that should not be picked is selected.
class WrongOptionSelected extends StepError {
  const WrongOptionSelected();
}

/// Not every correct option is selected (reported only when no wrong one is).
class MissingOptions extends StepError {
  const MissingOptions();
}

/// At least one sequence slot holds the wrong card or none.
class WrongSequence extends StepError {
  const WrongSequence();
}

/// A tray holds a wrong card, or (ordered) a card in the wrong place, or the wrong count.
class WrongTray extends StepError {
  const WrongTray(this.tray, {required this.ordered});

  final Tray tray;
  final bool ordered;
}

/// The drop box holds an unsafe card or not exactly the safe ones.
class UnsafeAction extends StepError {
  const UnsafeAction();
}

sealed class CheckResult {
  const CheckResult();
}

/// Not ready to check; no mistake is counted.
class CheckIncomplete extends CheckResult {
  const CheckIncomplete(this.reason);

  final Incomplete reason;
}

/// Checked. [passed] when there are no [errors]; [wrongItems] and [wrongOptions] turn red.
class CheckDone extends CheckResult {
  const CheckDone({required this.errors, required this.wrongItems, required this.wrongOptions});

  final List<StepError> errors;
  final Set<String> wrongItems;
  final Set<String> wrongOptions;

  bool get passed => errors.isEmpty;
}

/// Checks [s] against [stage] (`EvaluationStrategyContext.evaluateStep`).
CheckResult checkStep(Stage stage, StepState s) {
  final choices = stage.choices;
  final slots = s.slots;
  final trayCards = s.trays;
  final dropBox = s.dropBox;
  final drop = stage.unorderedDrop;

  final Incomplete? incomplete = switch (true) {
    _ when choices != null && s.selected.isEmpty => const NoOptionSelected(),
    _ when slots != null && slots.contains(null) => const EmptySlots(),
    _ when trayCards != null && s.pool.isNotEmpty => const CardsLeftInPool(),
    _ when dropBox != null && drop != null && dropBox.length < drop.expectedIds.length =>
      TooFewInDropBox(drop.expectedIds.length),
    _ => null,
  };
  if (incomplete != null) return CheckIncomplete(incomplete);

  final errors = <StepError>[];
  final wrongItems = <String>{};
  final wrongOptions = <String>{};

  if (choices != null) {
    for (final o in choices.options) {
      if (s.selected.contains(o.id) && !o.correct) wrongOptions.add(o.id);
    }
    final missing = choices.options.any((o) => o.correct && !s.selected.contains(o.id));
    if (wrongOptions.isNotEmpty) {
      errors.add(const WrongOptionSelected());
    } else if (missing) {
      errors.add(const MissingOptions());
    }
  }

  final sequence = stage.sequence;
  if (sequence != null && slots != null) {
    var bad = false;
    for (final (i, id) in slots.indexed) {
      if (id != (i < sequence.correctOrder.length ? sequence.correctOrder[i] : null)) {
        if (id != null) wrongItems.add(id);
        bad = true;
      }
    }
    if (bad) errors.add(const WrongSequence());
  }

  final trays = stage.trays;
  if (trays != null && trayCards != null) {
    for (final tray in trays.trays) {
      final cards = trayCards[tray.id] ?? const <String>[];
      final expectedOrder = tray.expectedOrder;
      final expectedIds = tray.expectedIds;
      var bad = false;
      if (trays.ordered && expectedOrder != null) {
        for (final (i, id) in cards.indexed) {
          if (i >= expectedOrder.length || id != expectedOrder[i]) {
            wrongItems.add(id);
            bad = true;
          }
        }
      } else if (expectedIds != null) {
        for (final id in cards) {
          if (!expectedIds.contains(id)) {
            wrongItems.add(id);
            bad = true;
          }
        }
      }
      final need = (trays.ordered ? expectedOrder : expectedIds)?.length ?? 0;
      if (!bad && cards.length != need) bad = true;
      if (bad) errors.add(WrongTray(tray, ordered: trays.ordered));
    }
  }

  if (drop != null && dropBox != null) {
    var bad = false;
    for (final id in dropBox) {
      if (!drop.expectedIds.contains(id)) {
        wrongItems.add(id);
        bad = true;
      }
    }
    if (!bad &&
        (dropBox.length != drop.expectedIds.length ||
            drop.expectedIds.any((id) => !dropBox.contains(id)))) {
      bad = true;
    }
    if (bad) errors.add(const UnsafeAction());
  }

  return CheckDone(errors: errors, wrongItems: wrongItems, wrongOptions: wrongOptions);
}
