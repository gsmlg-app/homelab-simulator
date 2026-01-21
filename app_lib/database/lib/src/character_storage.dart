import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

import 'shared_preferences_mixin.dart';

/// Storage service for character persistence
class CharacterStorage with SharedPreferencesMixin {
  static const String _storageKey = 'homelab_characters';
  static final _log = Logger('CharacterStorage');

  /// Get all saved characters
  Future<List<CharacterModel>> loadAll() async {
    final prefs = await preferences;
    final json = prefs.getString(_storageKey);
    if (json == null) {
      _log.fine('No saved characters found');
      return [];
    }

    try {
      final list = jsonDecode(json) as List<dynamic>;
      final characters =
          list
              .map((e) => CharacterModel.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
      _log.fine('Loaded ${characters.length} characters');
      return characters;
    } catch (e, stackTrace) {
      _log.warning('Failed to load characters: $e', e, stackTrace);
      return [];
    }
  }

  /// Save a character (creates or updates)
  Future<void> save(CharacterModel character) async {
    final characters = await loadAll();
    final index = characters.indexWhere((c) => c.id == character.id);

    if (index >= 0) {
      characters[index] = character;
      _log.fine('Updated character: ${character.name}');
    } else {
      characters.add(character);
      _log.fine('Created character: ${character.name}');
    }

    try {
      await _saveAll(characters);
    } catch (e, stackTrace) {
      _log.warning('Failed to save character: $e', e, stackTrace);
    }
  }

  /// Delete a character by ID
  Future<void> delete(String characterId) async {
    final characters = await loadAll();
    characters.removeWhere((c) => c.id == characterId);
    try {
      await _saveAll(characters);
      _log.fine('Deleted character: $characterId');
    } catch (e, stackTrace) {
      _log.warning('Failed to delete character: $e', e, stackTrace);
    }
  }

  /// Get a single character by ID
  Future<CharacterModel?> load(String characterId) async {
    final characters = await loadAll();
    for (final character in characters) {
      if (character.id == characterId) {
        return character;
      }
    }
    _log.fine('Character not found: $characterId');
    return null;
  }

  Future<void> _saveAll(List<CharacterModel> characters) async {
    final prefs = await preferences;
    final json = jsonEncode(characters.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }
}
