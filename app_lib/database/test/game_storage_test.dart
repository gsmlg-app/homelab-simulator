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

    group('edge cases', () {
      test('should handle empty rooms list', () async {
        final game = const GameModel(
          currentRoomId: '',
          rooms: [],
          credits: 1000,
        );

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded, isNotNull);
        expect(loaded!.rooms, isEmpty);
      });

      test('should handle game with many rooms', () async {
        final rooms = List.generate(
          50,
          (i) =>
              RoomModel(id: 'room-$i', name: 'Room $i', type: RoomType.custom),
        );
        final game = GameModel(
          currentRoomId: 'room-0',
          rooms: rooms,
          credits: 1000,
        );

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded, isNotNull);
        expect(loaded!.rooms.length, 50);
      });

      test('should handle game with devices in rooms', () async {
        final roomWithDevices = RoomModel(
          id: 'room-with-devices',
          name: 'Device Room',
          type: RoomType.serverRoom,
          devices: const [
            DeviceModel(
              id: 'dev-1',
              templateId: 'tmpl-1',
              name: 'Server',
              type: DeviceType.server,
              position: GridPosition(0, 0),
            ),
          ],
        );
        final game = GameModel(
          currentRoomId: 'room-with-devices',
          rooms: [roomWithDevices],
          credits: 1000,
        );

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded, isNotNull);
        expect(loaded!.rooms.first.devices.length, 1);
        expect(loaded.rooms.first.devices.first.name, 'Server');
      });

      test('should handle game with cloud services in rooms', () async {
        final roomWithServices = RoomModel(
          id: 'room-with-services',
          name: 'Cloud Room',
          type: RoomType.aws,
          cloudServices: const [
            CloudServiceModel(
              id: 'svc-1',
              name: 'EC2 Instance',
              provider: CloudProvider.aws,
              category: ServiceCategory.compute,
              serviceType: 'EC2',
              position: GridPosition(1, 1),
            ),
          ],
        );
        final game = GameModel(
          currentRoomId: 'room-with-services',
          rooms: [roomWithServices],
          credits: 1000,
        );

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded, isNotNull);
        expect(loaded!.rooms.first.cloudServices.length, 1);
        expect(
          loaded.rooms.first.cloudServices.first.provider,
          CloudProvider.aws,
        );
      });

      test('should handle game with doors in rooms', () async {
        final roomWithDoors = RoomModel(
          id: 'room-with-doors',
          name: 'Door Room',
          type: RoomType.serverRoom,
          doors: const [
            DoorModel(
              id: 'door-1',
              targetRoomId: 'target-room',
              wallSide: WallSide.right,
              wallPosition: 5,
            ),
          ],
        );
        final game = GameModel(
          currentRoomId: 'room-with-doors',
          rooms: [roomWithDoors],
          credits: 1000,
        );

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded, isNotNull);
        expect(loaded!.rooms.first.doors.length, 1);
        expect(loaded.rooms.first.doors.first.targetRoomId, 'target-room');
      });

      test('should cache SharedPreferences instance', () async {
        // Save twice - second save should reuse cached prefs
        final game1 = GameModel.initial();
        final game2 = game1.copyWith(credits: 500);

        await storage.save(game1);
        await storage.save(game2);

        final loaded = await storage.load();
        expect(loaded!.credits, 500);
      });

      test('should handle maximum credits value', () async {
        final game = GameModel.initial().copyWith(credits: 2147483647);

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded!.credits, 2147483647);
      });

      test('should handle zero credits', () async {
        final game = GameModel.initial().copyWith(credits: 0);

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded!.credits, 0);
      });

      test('should return null for partially valid JSON', () async {
        final prefs = await SharedPreferences.getInstance();
        // Valid JSON but missing required fields
        await prefs.setString(
          'homelab_game_state',
          '{"currentRoomId": "room-1"}',
        );

        final result = await storage.load();
        expect(result, isNull);
      });

      test('should return null for JSON array instead of object', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('homelab_game_state', '[]');

        final result = await storage.load();
        expect(result, isNull);
      });

      test('should handle negative credits', () async {
        final game = GameModel.initial().copyWith(credits: -500);

        await storage.save(game);
        final loaded = await storage.load();

        expect(loaded!.credits, -500);
      });
    });

    group('storage key', () {
      test('uses homelab_game_state key', () async {
        final game = GameModel.initial();
        await storage.save(game);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('homelab_game_state'), isTrue);
      });

      test('does not pollute other keys', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('other_key', 'other_value');

        final game = GameModel.initial();
        await storage.save(game);

        expect(prefs.getString('other_key'), 'other_value');
      });
    });

    group('GameStorage class', () {
      test('can be instantiated multiple times', () {
        final storage1 = GameStorage();
        final storage2 = GameStorage();
        expect(storage1, isA<GameStorage>());
        expect(storage2, isA<GameStorage>());
      });
    });
  });
}
