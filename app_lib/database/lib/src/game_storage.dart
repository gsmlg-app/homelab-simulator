import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

/// Storage service for game state persistence
class GameStorage {
  static const String _storageKey = 'homelab_game_state';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save game state to persistent storage
  Future<void> save(GameModel model) async {
    final prefs = await _preferences;
    final json = jsonEncode(model.toJson());
    await prefs.setString(_storageKey, json);
  }

  /// Load game state from persistent storage
  Future<GameModel?> load() async {
    final prefs = await _preferences;
    final json = prefs.getString(_storageKey);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return GameModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Clear saved game state
  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.remove(_storageKey);
  }
}
