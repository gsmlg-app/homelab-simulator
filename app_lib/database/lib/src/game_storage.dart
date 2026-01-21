import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

import 'shared_preferences_mixin.dart';

/// Storage service for game state persistence
class GameStorage with SharedPreferencesMixin {
  static const String _storageKey = 'homelab_game_state';
  static final _log = Logger('GameStorage');

  /// Save game state to persistent storage.
  ///
  /// Logs a warning if save fails but does not throw, allowing the app
  /// to continue functioning even if persistence is unavailable.
  Future<void> save(GameModel model) async {
    try {
      final prefs = await preferences;
      final json = jsonEncode(model.toJson());
      await prefs.setString(_storageKey, json);
      _log.fine('Game state saved');
    } catch (e, stackTrace) {
      _log.warning('Failed to save game state: $e', e, stackTrace);
    }
  }

  /// Load game state from persistent storage
  Future<GameModel?> load() async {
    final prefs = await preferences;
    final json = prefs.getString(_storageKey);
    if (json == null) {
      _log.fine('No saved game state found');
      return null;
    }

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      _log.fine('Game state loaded');
      return GameModel.fromJson(data);
    } catch (e, stackTrace) {
      _log.warning('Failed to load game state: $e', e, stackTrace);
      return null;
    }
  }

  /// Clear saved game state
  Future<void> clear() async {
    final prefs = await preferences;
    await prefs.remove(_storageKey);
    _log.fine('Game state cleared');
  }
}
