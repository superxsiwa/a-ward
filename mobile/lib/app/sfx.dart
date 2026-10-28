import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/progress_store.dart';

/// His SFXEngine sounds, rendered into assets/sounds by tool/make_sounds.py.
enum Sound { pick, drop, ok, bad, win, star0, star1, star2 }

/// Vibrations, after his `SFX.haptic` patterns: a tick on drag and drop, a light one on a right
/// check, a strong one on a wrong check or a timeout, a medium one when a case is finished.
enum Buzz { tick, success, error, win }

abstract interface class Sfx {
  void play(Sound sound);
  void buzz(Buzz buzz);
}

/// Plays through audioplayers, honouring the sound and vibration settings. Sounds mix with
/// whatever else is playing instead of pausing it.
class AudioSfx implements Sfx {
  AudioSfx(this._ref) {
    AudioPlayer.global.setAudioContext(
      AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
        respectSilence: true,
      ).build(),
    );
  }

  final Ref _ref;
  final _players = <Sound, AudioPlayer>{};

  GameSettings get _settings => _ref.read(settingsProvider).value ?? const GameSettings();

  @override
  void play(Sound sound) {
    if (!_settings.sound) return;
    final player = _players.putIfAbsent(sound, AudioPlayer.new);
    player
        .play(
          AssetSource('sounds/${sound.name}.wav'),
          mode: kIsWeb ? PlayerMode.mediaPlayer : PlayerMode.lowLatency,
        )
        .ignore();
  }

  @override
  void buzz(Buzz buzz) {
    if (!_settings.haptics) return;
    switch (buzz) {
      case Buzz.tick:
        HapticFeedback.selectionClick();
      case Buzz.success:
        HapticFeedback.lightImpact();
      case Buzz.error:
        HapticFeedback.heavyImpact();
      case Buzz.win:
        HapticFeedback.mediumImpact();
    }
  }
}

/// No sound, no vibration: for tests.
class SilentSfx implements Sfx {
  final played = <Sound>[];

  @override
  void play(Sound sound) => played.add(sound);

  @override
  void buzz(Buzz buzz) {}
}

final sfxProvider = Provider<Sfx>((ref) => AudioSfx(ref));
