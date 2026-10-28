import 'dart:math';

import 'case_model.dart';

/// Where a card can be dropped.
sealed class Zone {
  const Zone();
}

/// The shuffled pile cards start in.
class PoolZone extends Zone {
  const PoolZone();
}

/// One numbered slot of a sequence task.
class SlotZone extends Zone {
  const SlotZone(this.index);

  final int index;
}

/// A tray; the card goes in front of [before], or last when it is null.
class TrayZone extends Zone {
  const TrayZone(this.trayId, {this.before});

  final String trayId;
  final String? before;
}

/// The single box of an unordered drop task.
class DropBoxZone extends Zone {
  const DropBoxZone();
}

/// What the player has done on one step so far (his `StepRuntimeState`).
///
/// Immutable: every move returns a new state. A locked state (step passed or answer shown)
/// ignores every move.
class StepState {
  const StepState._({
    required this.items,
    required this.pool,
    required this.slots,
    required this.trays,
    required this.dropBox,
    required this.selected,
    required this.picked,
    required this.wrongItems,
    required this.wrongOptions,
    required this.locked,
  });

  /// A new step: the pool shuffled with [random], every slot, tray and box empty.
  factory StepState.fresh(Stage stage, Random random) {
    final pool = [for (final p in stage.pool) p.id]..shuffle(random);
    return StepState._(
      items: {for (final p in stage.pool) p.id: p},
      pool: List.unmodifiable(pool),
      slots: stage.sequence == null
          ? null
          : List.unmodifiable(List<String?>.filled(stage.sequence!.correctOrder.length, null)),
      trays: stage.trays == null
          ? null
          : Map.unmodifiable({for (final t in stage.trays!.trays) t.id: const <String>[]}),
      dropBox: stage.unorderedDrop == null ? null : const [],
      selected: const {},
      picked: null,
      wrongItems: const {},
      wrongOptions: const {},
      locked: false,
    );
  }

  final Map<String, PoolItem> items;
  final List<String> pool;

  /// Sequence slots, null where empty; null when the step has no sequence task.
  final List<String?>? slots;

  /// Cards per tray id, in tray order; null when the step has no trays task.
  final Map<String, List<String>>? trays;

  /// Cards in the unordered drop box; null when the step has no such task.
  final List<String>? dropBox;

  /// Selected option ids of the choices task.
  final Set<String> selected;

  /// The card picked up by a tap, waiting for a tap on a tray.
  final String? picked;

  /// Cards marked red by the last check; cleared by the next card move.
  final Set<String> wrongItems;

  /// Options marked red by the last check; cleared by the next option tap.
  final Set<String> wrongOptions;
  final bool locked;

  /// Where card [id] is now, or null for an unknown id.
  Zone? whereIs(String id) {
    if (pool.contains(id)) return const PoolZone();
    final slot = slots?.indexOf(id) ?? -1;
    if (slot > -1) return SlotZone(slot);
    for (final MapEntry(:key, :value) in (trays ?? const {}).entries) {
      if (value.contains(id)) return TrayZone(key);
    }
    if (dropBox?.contains(id) ?? false) return const DropBoxZone();
    return null;
  }

  /// Moves card [id] to [dest] (`moveItemInState`). Dropping on a filled slot swaps the two
  /// cards when the moved card came from a slot, and sends the old card back to the pool
  /// otherwise. Any move clears the red marks on cards and drops the picked card.
  StepState move(String id, Zone dest) {
    if (locked || !items.containsKey(id)) return this;
    if (dest is TrayZone && dest.before == id) return this;
    final d = _Draft(this);
    final from = d.remove(id);
    d.wrongItems.clear();
    d.picked = null;
    switch (dest) {
      case PoolZone():
        d.pool.add(id);
      case SlotZone(:final index):
        final slots = d.slots;
        if (slots == null || index < 0 || index >= slots.length) return this;
        final old = slots[index];
        slots[index] = id;
        if (old != null) {
          if (from is SlotZone) {
            slots[from.index] = old;
          } else {
            d.pool.add(old);
          }
        }
      case TrayZone(:final trayId, :final before):
        final tray = d.trays?[trayId];
        if (tray == null) return this;
        final at = before == null ? -1 : tray.indexOf(before);
        tray.insert(at < 0 ? tray.length : at, id);
      case DropBoxZone():
        final box = d.dropBox;
        if (box == null) return this;
        box.add(id);
    }
    return d.build();
  }

  /// A tap on card [id] (`handleTap`). From the pool it fills the first empty slot, or goes
  /// into the drop box, or (trays) is picked up or put down again. A placed card goes back to
  /// the pool.
  StepState tapCard(String id) {
    if (locked || !items.containsKey(id)) return this;
    if (!pool.contains(id)) return move(id, const PoolZone());
    if (slots != null) {
      final empty = slots!.indexOf(null);
      return empty < 0 ? this : move(id, SlotZone(empty));
    }
    if (dropBox != null) return move(id, const DropBoxZone());
    return (_Draft(this)..picked = picked == id ? null : id).build();
  }

  /// A tap on a zone while a card is picked up (`handleDropZoneClick`): the pool puts the card
  /// down, any other zone receives it.
  StepState tapZone(Zone zone) {
    final id = picked;
    if (locked || id == null) return this;
    if (zone is PoolZone) return (_Draft(this)..picked = null).build();
    return move(id, zone);
  }

  /// Selects or unselects option [id] and clears the red marks on options.
  StepState toggleOption(String id) {
    if (locked) return this;
    final d = _Draft(this);
    d.wrongOptions.clear();
    if (!d.selected.remove(id)) d.selected.add(id);
    return d.build();
  }

  /// The state after a failed check: [items] and [options] turn red.
  StepState markWrong(Set<String> items, Set<String> options) {
    final d = _Draft(this);
    d.wrongItems
      ..clear()
      ..addAll(items);
    d.wrongOptions
      ..clear()
      ..addAll(options);
    return d.build();
  }

  /// The state after a passed check: locked, no red marks.
  StepState lock() {
    final d = _Draft(this)..locked = true;
    d.wrongItems.clear();
    d.wrongOptions.clear();
    return d.build();
  }

  /// The correct answer laid out and locked (`populateCorrectSolution`, the mercy rule).
  /// Unsafe cards of an unordered drop task stay in the pool; other pools end up empty.
  StepState solved(Stage stage) {
    final d = _Draft(this)
      ..picked = null
      ..locked = true;
    d.pool.clear();
    d.wrongItems.clear();
    d.wrongOptions.clear();
    final choices = stage.choices;
    if (choices != null) {
      d.selected
        ..clear()
        ..addAll([for (final o in choices.options) if (o.correct) o.id]);
    }
    final sequence = stage.sequence;
    if (sequence != null) d.slots = [...sequence.correctOrder];
    final trays = stage.trays;
    if (trays != null) {
      d.trays = {
        for (final t in trays.trays)
          t.id: [...?(trays.ordered ? t.expectedOrder : t.expectedIds)],
      };
    }
    final drop = stage.unorderedDrop;
    if (drop != null) {
      d.dropBox = [...drop.expectedIds];
      d.pool.addAll([for (final p in drop.pool) if (!drop.expectedIds.contains(p.id)) p.id]);
    }
    return d.build();
  }
}

/// Mutable copy used to build the next [StepState].
class _Draft {
  _Draft(StepState s)
    : items = s.items,
      pool = [...s.pool],
      slots = s.slots == null ? null : [...s.slots!],
      trays = s.trays?.map((k, v) => MapEntry(k, [...v])),
      dropBox = s.dropBox == null ? null : [...s.dropBox!],
      selected = {...s.selected},
      picked = s.picked,
      wrongItems = {...s.wrongItems},
      wrongOptions = {...s.wrongOptions},
      locked = s.locked;

  final Map<String, PoolItem> items;
  final List<String> pool;
  List<String?>? slots;
  Map<String, List<String>>? trays;
  List<String>? dropBox;
  final Set<String> selected;
  String? picked;
  final Set<String> wrongItems;
  final Set<String> wrongOptions;
  bool locked;

  /// Takes [id] out of wherever it is and says where that was (`removeFromState`).
  Zone? remove(String id) {
    if (pool.remove(id)) return const PoolZone();
    final slot = slots?.indexOf(id) ?? -1;
    if (slot > -1) {
      slots![slot] = null;
      return SlotZone(slot);
    }
    for (final MapEntry(:key, :value) in (trays ?? const <String, List<String>>{}).entries) {
      if (value.remove(id)) return TrayZone(key);
    }
    if (dropBox?.remove(id) ?? false) return const DropBoxZone();
    return null;
  }

  StepState build() => StepState._(
    items: items,
    pool: List.unmodifiable(pool),
    slots: slots == null ? null : List.unmodifiable(slots!),
    trays: trays == null
        ? null
        : Map.unmodifiable(trays!.map((k, v) => MapEntry(k, List<String>.unmodifiable(v)))),
    dropBox: dropBox == null ? null : List.unmodifiable(dropBox!),
    selected: Set.unmodifiable(selected),
    picked: picked,
    wrongItems: Set.unmodifiable(wrongItems),
    wrongOptions: Set.unmodifiable(wrongOptions),
    locked: locked,
  );
}
