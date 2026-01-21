import 'package:flame_audio/flame_audio.dart';

import 'sfx_type.dart';

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
  double _sfxVolume = 1.0;
  bool _musicEnabled = true;
  double _musicVolume = 0.5;

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
  /// This should be called once during app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    // Preload common sound effects for faster playback
    await FlameAudio.audioCache.loadAll([
      for (final sfx in SfxType.values) sfx.assetPath,
    ]);

    _initialized = true;
  }

  /// Plays a sound effect.
  ///
  /// Does nothing if sound effects are disabled or the service is not initialized.
  Future<void> playSfx(SfxType sfx) async {
    if (!_sfxEnabled || !_initialized) return;

    await FlameAudio.play(sfx.assetPath, volume: _sfxVolume);
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
  Future<void> playBackgroundMusic(String filename) async {
    if (!_musicEnabled || !_initialized) return;

    await FlameAudio.bgm.play(filename, volume: _musicVolume);
  }

  /// Stops the current background music.
  ///
  /// Does nothing if the service is not initialized.
  Future<void> stopBackgroundMusic() async {
    if (!_initialized) return;
    await FlameAudio.bgm.stop();
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
  Future<void> dispose() async {
    if (!_initialized) return;
    await FlameAudio.bgm.stop();
    FlameAudio.audioCache.clearAll();
    _initialized = false;
  }
}
