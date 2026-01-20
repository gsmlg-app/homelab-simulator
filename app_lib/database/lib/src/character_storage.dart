import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

/// Storage service for character persistence
class CharacterStorage {
  static const String _storageKey = 'homelab_characters';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get all saved characters
  Future<List<CharacterModel>> loadAll() async {
    final prefs = await _preferences;
    final json = prefs.getString(_storageKey);
    if (json == null) return [];

    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CharacterModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    } catch (_) {
      return [];
    }
  }

  /// Save a character (creates or updates)
  Future<void> save(CharacterModel character) async {
    final characters = await loadAll();
    final index = characters.indexWhere((c) => c.id == character.id);

    if (index >= 0) {
      characters[index] = character;
    } else {
      characters.add(character);
    }

    await _saveAll(characters);
  }

  /// Delete a character by ID
  Future<void> delete(String characterId) async {
    final characters = await loadAll();
    characters.removeWhere((c) => c.id == characterId);
    await _saveAll(characters);
  }

  /// Get a single character by ID
  Future<CharacterModel?> load(String characterId) async {
    final characters = await loadAll();
    try {
      return characters.firstWhere((c) => c.id == characterId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveAll(List<CharacterModel> characters) async {
    final prefs = await _preferences;
    final json = jsonEncode(characters.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }
}
