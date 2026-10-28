import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/case_session.dart';
import '../game/progress.dart';

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
}

class PrefsProgressStore implements ProgressStore {
  PrefsProgressStore([SharedPreferencesAsync? prefs]) : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;
  static const _progressKey = 'progress.v${Progress.schemaVersion}';
  static const _noticeKey = 'notice.seen';

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
    final current = state.value ?? await future;
    final outcome = current.record(result);
    state = AsyncData(outcome.progress);
    await ref.read(progressStoreProvider).save(outcome.progress);
    return outcome;
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
