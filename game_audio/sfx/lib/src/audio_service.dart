import 'package:app_lib_core/app_lib_core.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:logging/logging.dart';

import 'sfx_type.dart';

final _log = Logger('AudioService');

/// Service for managing game audio including sound effects and background music.
///
/// This service wraps Flame's audio capabilities and provides a simple
/// interface for playing sound effects in the game.
class AudioService {
  /// Creates an [AudioService] instance.
  ///
  /// Use [AudioService.instance] for the shared singleton.
  AudioService();

  /// Shared singleton instance for global audio management.
  static final AudioService instance = AudioService();

  bool _initialized = false;
  bool _sfxEnabled = true;
  double _sfxVolume = GameConstants.audioSfxVolumeDefault;
  bool _musicEnabled = true;
  double _musicVolume = GameConstants.audioMusicVolumeDefault;

  /// Whether the audio service has been initialized.
  bool get isInitialized => _initialized;

  /// Whether sound effects are enabled.
  bool get sfxEnabled => _sfxEnabled;

  /// Current sound effects volume (0.0 to 1.0).
  double get sfxVolume => _sfxVolume;

  /// Whether background music is enabled.
  bool get musicEnabled => _musicEnabled;

  /// Current music volume (0.0 to 1.0).
  double get musicVolume => _musicVolume;

  /// Initializes the audio service and preloads common sound effects.
  ///
  /// This should be called once during app startup. If preloading fails,
  /// the service will still be marked as initialized but audio playback
  /// may fail for specific sounds.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Preload common sound effects for faster playback
      await FlameAudio.audioCache.loadAll([
        for (final sfx in SfxType.values) sfx.assetPath,
      ]);
      _log.fine(
        'Audio service initialized with ${SfxType.values.length} sounds',
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to preload audio assets: $e', e, stackTrace);
    }

    _initialized = true;
  }

  /// Plays a sound effect.
  ///
  /// Does nothing if sound effects are disabled or the service is not initialized.
  /// Logs a warning if playback fails but does not throw.
  Future<void> playSfx(SfxType sfx) async {
    if (!_sfxEnabled || !_initialized) return;

    try {
      await FlameAudio.play(sfx.assetPath, volume: _sfxVolume);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to play sound effect ${sfx.name}: $e',
        e,
        stackTrace,
      );
    }
  }

  /// Enables or disables sound effects.
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  /// Sets the sound effects volume.
  ///
  /// [volume] must be between 0.0 and 1.0.
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Enables or disables background music.
  ///
  /// If [enabled] is false and the service is initialized, stops any playing music.
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled && _initialized) {
      FlameAudio.bgm.stop();
    }
  }

  /// Sets the background music volume.
  ///
  /// [volume] must be between 0.0 and 1.0.
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    // Note: Flame BGM volume can be set when playing
  }

  /// Starts playing background music in a loop.
  ///
  /// [filename] is the asset path relative to the audio folder.
  /// Logs a warning if playback fails but does not throw.
  Future<void> playBackgroundMusic(String filename) async {
    if (!_musicEnabled || !_initialized) return;

    try {
      await FlameAudio.bgm.play(filename, volume: _musicVolume);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to play background music $filename: $e',
        e,
        stackTrace,
      );
    }
  }

  /// Stops the current background music.
  ///
  /// Does nothing if the service is not initialized.
  /// Logs a warning if stopping fails but does not throw.
  Future<void> stopBackgroundMusic() async {
    if (!_initialized) return;
    try {
      await FlameAudio.bgm.stop();
    } catch (e, stackTrace) {
      _log.warning('Failed to stop background music: $e', e, stackTrace);
    }
  }

  /// Pauses the current background music.
  ///
  /// Does nothing if the service is not initialized.
  void pauseBackgroundMusic() {
    if (!_initialized) return;
    FlameAudio.bgm.pause();
  }

  /// Resumes the paused background music.
  ///
  /// Does nothing if the service is not initialized.
  void resumeBackgroundMusic() {
    if (!_initialized) return;
    FlameAudio.bgm.resume();
  }

  /// Disposes of audio resources.
  ///
  /// Call this when the game is shutting down.
  /// Does nothing if the service is not initialized.
  /// Logs a warning if cleanup fails but does not throw.
  Future<void> dispose() async {
    if (!_initialized) return;
    try {
      await FlameAudio.bgm.stop();
      FlameAudio.audioCache.clearAll();
      _log.fine('Audio service disposed');
    } catch (e, stackTrace) {
      _log.warning('Failed to dispose audio resources: $e', e, stackTrace);
    }
    _initialized = false;
  }
}
