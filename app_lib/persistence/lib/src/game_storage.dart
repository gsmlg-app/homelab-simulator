import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

/// Storage service for saving and loading game state
class GameStorage {
  static const _saveFileName = 'save.json';

  /// Get the save file path
  Future<File> _getSaveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_saveFileName');
  }

  /// Save game state to file
  Future<void> save(GameModel model) async {
    final file = await _getSaveFile();
    final json = jsonEncode(model.toJson());
    await file.writeAsString(json);
  }

  /// Load game state from file
  Future<GameModel?> load() async {
    try {
      final file = await _getSaveFile();
      if (!await file.exists()) {
        return null;
      }
      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;
      return GameModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Check if a save file exists
  Future<bool> hasSaveFile() async {
    final file = await _getSaveFile();
    return file.exists();
  }

  /// Delete the save file
  Future<void> deleteSave() async {
    final file = await _getSaveFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
