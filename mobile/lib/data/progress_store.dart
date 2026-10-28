import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/case_session.dart';
import '../game/progress.dart';
import '../game/roster.dart';

/// The player's settings (his SettingsPage): both on by default.
class GameSettings {
  const GameSettings({this.sound = true, this.haptics = true});

  final bool sound;
  final bool haptics;

  GameSettings copyWith({bool? sound, bool? haptics}) =>
      GameSettings(sound: sound ?? this.sound, haptics: haptics ?? this.haptics);
}

/// Where progress lives on the device. Today one small JSON value in shared_preferences
/// (localStorage on the web); a database can replace it behind this interface when sync comes.
abstract interface class ProgressStore {
  Future<Progress> load();
  Future<void> save(Progress progress);

  /// Whether the player has seen the "for training only" notice.
  Future<bool> noticeSeen();
  Future<void> markNoticeSeen();

  Future<GameSettings> loadSettings();
  Future<void> saveSettings(GameSettings settings);

  Future<Roster> loadRoster();
  Future<void> saveRoster(Roster roster);
}

class PrefsProgressStore implements ProgressStore {
  PrefsProgressStore([SharedPreferencesAsync? prefs]) : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;
  static const _progressKey = 'progress.v${Progress.schemaVersion}';
  static const _noticeKey = 'notice.seen';
  static const _rosterKey = 'roster.v${Roster.schemaVersion}';

  @override
  Future<Progress> load() async {
    final raw = await _prefs.getString(_progressKey);
    if (raw == null) return Progress.empty;
    try {
      return Progress.fromJson(jsonDecode(raw));
    } on FormatException {
      return Progress.empty;
    }
  }

  @override
  Future<void> save(Progress progress) =>
      _prefs.setString(_progressKey, jsonEncode(progress.toJson()));

  @override
  Future<Roster> loadRoster() async {
    final raw = await _prefs.getString(_rosterKey);
    if (raw == null) return Roster.empty;
    try {
      return Roster.fromJson(jsonDecode(raw));
    } on FormatException {
      return Roster.empty;
    }
  }

  @override
  Future<void> saveRoster(Roster roster) =>
      _prefs.setString(_rosterKey, jsonEncode(roster.toJson()));

  @override
  Future<bool> noticeSeen() async => await _prefs.getBool(_noticeKey) ?? false;

  @override
  Future<void> markNoticeSeen() => _prefs.setBool(_noticeKey, true);

  @override
  Future<GameSettings> loadSettings() async => GameSettings(
    sound: await _prefs.getBool('settings.sound') ?? true,
    haptics: await _prefs.getBool('settings.haptics') ?? true,
  );

  @override
  Future<void> saveSettings(GameSettings settings) async {
    await _prefs.setBool('settings.sound', settings.sound);
    await _prefs.setBool('settings.haptics', settings.haptics);
  }
}

final progressStoreProvider = Provider<ProgressStore>((ref) => PrefsProgressStore());

class ProgressNotifier extends AsyncNotifier<Progress> {
  @override
  Future<Progress> build() => ref.watch(progressStoreProvider).load();

  /// Saves a finished case and says what it changed.
  Future<RecordOutcome> record(CaseResult result) async {
    if (state.value == null) await future;
    final current = state.value ?? Progress.empty;
    final outcome = current.record(result);
    state = AsyncData(outcome.progress);
    await ref.read(progressStoreProvider).save(outcome.progress);
    return outcome;
  }

  /// Adds play time (the play clock calls it every few seconds).
  Future<void> addPlayTime(int seconds) async {
    if (state.value == null) await future;
    final current = state.value ?? Progress.empty;
    final next = current.played(seconds);
    state = AsyncData(next);
    await ref.read(progressStoreProvider).save(next);
  }

  /// "Reset progress" in settings: every bed and counter back to zero.
  Future<void> reset() async {
    state = const AsyncData(Progress.empty);
    await ref.read(progressStoreProvider).save(Progress.empty);
  }
}

final progressProvider = AsyncNotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);

class SettingsNotifier extends AsyncNotifier<GameSettings> {
  @override
  Future<GameSettings> build() => ref.watch(progressStoreProvider).loadSettings();

  Future<void> set(GameSettings settings) async {
    state = AsyncData(settings);
    await ref.read(progressStoreProvider).saveSettings(settings);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, GameSettings>(
  SettingsNotifier.new,
);

/// Draws the roster's shifts; tests override it with a seeded one.
final randomProvider = Provider<Random>((ref) => Random());

class RosterNotifier extends AsyncNotifier<Roster> {
  @override
  Future<Roster> build() => ref.watch(progressStoreProvider).loadRoster();

  /// Waits for the saved roster. Each method reads `state` only AFTER this await, so two calls in
  /// a row (two screens asking for the same month) never both draw a schedule.
  Future<void> _loaded() async {
    if (state.value == null) await future;
  }

  Future<void> _save(Roster roster) async {
    state = AsyncData(roster);
    await ref.read(progressStoreProvider).saveRoster(roster);
  }

  /// Gives [month] its random schedule the first time it is shown.
  Future<void> ensure(RosterMonth month) async {
    await _loaded();
    final roster = state.value ?? Roster.empty;
    if (!roster.has(month)) await _save(roster.roll(month, ref.read(randomProvider)));
  }

  /// "🎲 สุ่มเวรใหม่": new shifts from the playable day on. Ends a duty in that month.
  Future<void> reroll(RosterMonth month) async {
    await _loaded();
    if (ref.read(dutyProvider)?.month == month) ref.read(dutyProvider.notifier).end();
    await _save((state.value ?? Roster.empty).roll(month, ref.read(randomProvider)));
  }

  /// Counts a finished bed towards the current duty; true when it cleared the day, which ends
  /// the duty.
  Future<bool> recordBed(int bedNum, List<int> bedNums) async {
    final duty = ref.read(dutyProvider);
    if (duty == null) return false;
    await _loaded();
    final roster = state.value ?? Roster.empty;
    final r = roster.recordBed(duty, bedNum, bedNums);
    if (identical(r.roster, roster)) return false;
    await _save(r.roster);
    if (r.cleared) ref.read(dutyProvider.notifier).end();
    return r.cleared;
  }

  /// "Reset progress": every day unplayed again, the schedules kept.
  Future<void> reset() async {
    ref.read(dutyProvider.notifier).end();
    await _loaded();
    await _save((state.value ?? Roster.empty).withoutProgress());
  }
}

final rosterProvider = AsyncNotifierProvider<RosterNotifier, Roster>(RosterNotifier.new);

/// The roster day the player is on duty for, if any (kept in memory, like his ward filter).
class DutyNotifier extends Notifier<Duty?> {
  @override
  Duty? build() => null;

  void start(Duty duty) => state = duty;
  void end() => state = null;
}

final dutyProvider = NotifierProvider<DutyNotifier, Duty?>(DutyNotifier.new);
