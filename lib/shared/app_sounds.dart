// lib/shared/app_sounds.dart
//
// Interaction feedback: a short sound plus a light haptic on the moments that
// matter while studying — revealing an answer, judging a question «سهل» /
// «جيد», saving one to the library, finishing a lesson.
//
// DESIGN RULES, so feedback stays pleasant over a long session:
//   - Only meaningful moments. No sound on ordinary taps, scrolling or
//     navigation — that is what turns feedback into fatigue.
//   - Nothing negative. «جيد» is a neutral "noted", never a buzzer; a failed
//     request is announced by its snack bar, not by an error sound.
//   - Never interrupts the student's own audio. Many students study with a
//     recitation playing: the sounds MIX with it (no audio focus taken) and
//     are silent when the phone is on silent.
//   - One switch turns it all off (حسابي → أصوات التفاعل), remembered on the
//     device.
//
// The sounds are synthesised for this app (assets/sounds/, ~110 KB in all):
// soft marimba / bell tones in one key — calm, not game-like.
//
// Like PushService, this NEVER throws: a missing audio device, a platform
// error or a test environment must never break the lesson flow.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSound {
  /// «إظهار الإجابة» — an airy page-turn, barely there.
  reveal('reveal.wav', 0.6, _Haptic.selection),

  /// «سهل» — two rising notes, a small "yes".
  easy('easy.wav', 0.7, _Haptic.light),

  /// «جيد» — one mellow note: noted, it will come back.
  good('good.wav', 0.6, _Haptic.selection),

  /// Saved to the library — a light tick-up.
  saved('saved.wav', 0.6, _Haptic.light),

  /// Lesson finished — a warm arpeggio, the one longer sound.
  lessonComplete('lesson_complete.wav', 0.75, _Haptic.medium);

  const AppSound(this.file, this.volume, this.haptic);

  final String file;
  final double volume;
  final _Haptic haptic;

  String get assetPath => 'sounds/$file';
}

enum _Haptic { selection, light, medium }

class AppSounds {
  AppSounds._();

  /// shared_preferences key. Not sensitive — a user preference, like the theme.
  static const String prefKey = 'interaction_sounds_enabled';

  /// On by default; the switch in حسابي writes it.
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  /// Observes every play request that passed the switch — for tests.
  @visibleForTesting
  static void Function(AppSound sound)? debugOnPlay;

  static final Map<AppSound, AudioPlayer> _players = {};
  static Future<void>? _ready;

  /// No audio plugin under `flutter test` (or on the web, which this app does
  /// not ship): playing there would only produce MissingPluginException noise.
  static bool get _audioAvailable =>
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  /// Reads the saved switch and warms the sounds up. Call once at start-up;
  /// never throws.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(prefKey) ?? true;
    } catch (_) {
      // Keep the default.
    }

    if (_audioAvailable) _ready ??= _warmUp();
  }

  /// Turns all interaction feedback on or off, and remembers it.
  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, value);
    } catch (_) {
      // The switch still works for this session.
    }
  }

  /// Fire-and-forget. Does nothing when the switch is off.
  static void play(AppSound sound) {
    if (!enabled.value) return;

    debugOnPlay?.call(sound);
    _vibrate(sound.haptic);

    if (_audioAvailable) unawaited(_play(sound));
  }

  static void _vibrate(_Haptic haptic) {
    try {
      switch (haptic) {
        case _Haptic.selection:
          unawaited(HapticFeedback.selectionClick());
        case _Haptic.light:
          unawaited(HapticFeedback.lightImpact());
        case _Haptic.medium:
          unawaited(HapticFeedback.mediumImpact());
      }
    } catch (_) {
      // A device without a vibrator is not an error.
    }
  }

  static Future<void> _play(AppSound sound) async {
    try {
      await (_ready ??= _warmUp());

      final player = _players[sound] ??= await _newPlayer();
      // Restart rather than queue: a quick double tap should not stack sounds.
      await player.stop();
      await player.play(AssetSource(sound.assetPath), volume: sound.volume);
    } catch (_) {
      // Never let feedback break the lesson flow.
    }
  }

  static Future<AudioPlayer> _newPlayer() async {
    final player = AudioPlayer();
    // Short clips: the low-latency path (Android SoundPool) starts instantly.
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    return player;
  }

  /// The audio context, and the clips copied into the cache so the first one
  /// plays without a delay.
  static Future<void> _warmUp() async {
    try {
      await AudioPlayer.global.setAudioContext(_context);
      await AudioCache.instance.loadAll(
        AppSound.values.map((s) => s.assetPath).toList(),
      );
    } catch (_) {
      // Playback will try again on demand.
    }
  }

  /// UI sounds that coexist with whatever else is playing:
  ///  - Android: "sonification" usage (follows the system/ringer volume, so it
  ///    is silent when the phone is), and NO audio focus — a recitation
  ///    playing in the background is neither paused nor ducked.
  ///  - iOS: the ambient category — mixes with other audio and honours the
  ///    silent switch.
  static AudioContext get _context => AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );
}
