import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_database/app_database.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameStorage', () {
    late GameStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = GameStorage();
    });

    group('save', () {
      test('should save game model to storage', () async {
        final game = GameModel.initial();
        await storage.save(game);

        final prefs = await SharedPreferences.getInstance();
        final json = prefs.getString('homelab_game_state');
        expect(json, isNotNull);

        final decoded = jsonDecode(json!) as Map<String, dynamic>;
        expect(decoded['currentRoomId'], game.currentRoomId);
        expect(decoded['credits'], game.credits);
      });

      test('should overwrite existing game state', () async {
        final game1 = GameModel.initial();
        await storage.save(game1);

        final game2 = game1.copyWith(credits: 9999);
        await storage.save(game2);

        final prefs = await SharedPreferences.getInstance();
        final json = prefs.getString('homelab_game_state');
        final decoded = jsonDecode(json!) as Map<String, dynamic>;
        expect(decoded['credits'], 9999);
      });
    });

    group('load', () {
      test('should return null when no saved state exists', () async {
        final result = await storage.load();
        expect(result, isNull);
      });

      test('should load saved game state', () async {
        final game = GameModel.initial();
        await storage.save(game);

        final loaded = await storage.load();
        expect(loaded, isNotNull);
        expect(loaded!.currentRoomId, game.currentRoomId);
        expect(loaded.credits, game.credits);
        expect(loaded.rooms.length, game.rooms.length);
      });

      test('should return null for corrupted JSON', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('homelab_game_state', 'not valid json');

        final result = await storage.load();
        expect(result, isNull);
      });

      test('should return null for invalid game data structure', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('homelab_game_state', '{"invalid": "data"}');

        final result = await storage.load();
        expect(result, isNull);
      });
    });

    group('clear', () {
      test('should remove saved game state', () async {
        final game = GameModel.initial();
        await storage.save(game);

        await storage.clear();

        final result = await storage.load();
        expect(result, isNull);
      });

      test('should not throw when clearing empty storage', () async {
        expect(() => storage.clear(), returnsNormally);
      });
    });

    group('persistence', () {
      test('should persist rooms correctly', () async {
        final game = GameModel.initial();
        final roomId = generateRoomId();
        final newRoom = RoomModel(
          id: roomId,
          name: 'Test Room',
          type: RoomType.custom,
        );
        final updatedGame = game.addRoom(newRoom);

        await storage.save(updatedGame);
        final loaded = await storage.load();

        expect(loaded!.rooms.length, 2);
        expect(loaded.rooms.any((r) => r.id == roomId), isTrue);
      });

      test('should persist player position correctly', () async {
        final game = GameModel.initial().copyWith(
          playerPosition: const GridPosition(5, 5),
        );

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded!.playerPosition.x, 5);
        expect(loaded.playerPosition.y, 5);
      });

      test('should persist game mode correctly', () async {
        final game = GameModel.initial().copyWith(gameMode: GameMode.live);

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded!.gameMode, GameMode.live);
      });
    });
  });
}
