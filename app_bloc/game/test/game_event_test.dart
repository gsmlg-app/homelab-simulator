import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_bloc_game/app_bloc_game.dart';

void main() {
  group('GameEvent', () {
    group('GameInitialize', () {
      test('creates instance', () {
        const event = GameInitialize();
        expect(event, isA<GameEvent>());
      });

      test('has empty props', () {
        const event = GameInitialize();
        expect(event.props, isEmpty);
      });

      test('two instances are equal', () {
        const event1 = GameInitialize();
        const event2 = GameInitialize();
        expect(event1, equals(event2));
      });
    });

    group('GameMovePlayer', () {
      test('creates instance with direction', () {
        const event = GameMovePlayer(Direction.up);
        expect(event, isA<GameEvent>());
        expect(event.direction, Direction.up);
      });

      test('has direction in props', () {
        const event = GameMovePlayer(Direction.down);
        expect(event.props, [Direction.down]);
      });

      test('two instances with same direction are equal', () {
        const event1 = GameMovePlayer(Direction.left);
        const event2 = GameMovePlayer(Direction.left);
        expect(event1, equals(event2));
      });

      test('two instances with different directions are not equal', () {
        const event1 = GameMovePlayer(Direction.up);
        const event2 = GameMovePlayer(Direction.down);
        expect(event1, isNot(equals(event2)));
      });

      test('supports all directions', () {
        for (final direction in Direction.values) {
          final event = GameMovePlayer(direction);
          expect(event.direction, direction);
        }
      });
    });

    group('GameMovePlayerTo', () {
      test('creates instance with position', () {
        const pos = GridPosition(5, 10);
        const event = GameMovePlayerTo(pos);
        expect(event, isA<GameEvent>());
        expect(event.position, pos);
      });

      test('has position in props', () {
        const pos = GridPosition(3, 7);
        const event = GameMovePlayerTo(pos);
        expect(event.props, [pos]);
      });

      test('two instances with same position are equal', () {
        const pos = GridPosition(5, 5);
        const event1 = GameMovePlayerTo(pos);
        const event2 = GameMovePlayerTo(pos);
        expect(event1, equals(event2));
      });

      test('two instances with different positions are not equal', () {
        const event1 = GameMovePlayerTo(GridPosition(1, 1));
        const event2 = GameMovePlayerTo(GridPosition(2, 2));
        expect(event1, isNot(equals(event2)));
      });
    });

    group('GameToggleShop', () {
      test('creates instance with isOpen true', () {
        const event = GameToggleShop(isOpen: true);
        expect(event, isA<GameEvent>());
        expect(event.isOpen, true);
      });

      test('creates instance with isOpen false', () {
        const event = GameToggleShop(isOpen: false);
        expect(event.isOpen, false);
      });

      test('creates instance with isOpen null (toggle)', () {
        const event = GameToggleShop();
        expect(event.isOpen, isNull);
      });

      test('has isOpen in props', () {
        const event = GameToggleShop(isOpen: true);
        expect(event.props, [true]);
      });

      test('two instances with same isOpen are equal', () {
        const event1 = GameToggleShop(isOpen: true);
        const event2 = GameToggleShop(isOpen: true);
        expect(event1, equals(event2));
      });

      test('two instances with different isOpen are not equal', () {
        const event1 = GameToggleShop(isOpen: true);
        const event2 = GameToggleShop(isOpen: false);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('GameSelectTemplate', () {
      late DeviceTemplate template;

      setUp(() {
        template = const DeviceTemplate(
          id: 'test-template',
          name: 'Test Device',
          description: 'A test device',
          type: DeviceType.server,
          cost: 100,
        );
      });

      test('creates instance with template', () {
        final event = GameSelectTemplate(template);
        expect(event, isA<GameEvent>());
        expect(event.template, template);
      });

      test('has template in props', () {
        final event = GameSelectTemplate(template);
        expect(event.props, [template]);
      });

      test('two instances with same template are equal', () {
        final event1 = GameSelectTemplate(template);
        final event2 = GameSelectTemplate(template);
        expect(event1, equals(event2));
      });
    });

    group('GameCancelPlacement', () {
      test('creates instance', () {
        const event = GameCancelPlacement();
        expect(event, isA<GameEvent>());
      });

      test('has empty props', () {
        const event = GameCancelPlacement();
        expect(event.props, isEmpty);
      });

      test('two instances are equal', () {
        const event1 = GameCancelPlacement();
        const event2 = GameCancelPlacement();
        expect(event1, equals(event2));
      });
    });

    group('GamePlaceDevice', () {
      test('creates instance with position', () {
        const pos = GridPosition(5, 5);
        const event = GamePlaceDevice(pos);
        expect(event, isA<GameEvent>());
        expect(event.position, pos);
      });

      test('has position in props', () {
        const pos = GridPosition(3, 7);
        const event = GamePlaceDevice(pos);
        expect(event.props, [pos]);
      });

      test('two instances with same position are equal', () {
        const pos = GridPosition(5, 5);
        const event1 = GamePlaceDevice(pos);
        const event2 = GamePlaceDevice(pos);
        expect(event1, equals(event2));
      });
    });

    group('GameRemoveDevice', () {
      test('creates instance with deviceId', () {
        const event = GameRemoveDevice('device-123');
        expect(event, isA<GameEvent>());
        expect(event.deviceId, 'device-123');
      });

      test('has deviceId in props', () {
        const event = GameRemoveDevice('device-456');
        expect(event.props, ['device-456']);
      });

      test('two instances with same deviceId are equal', () {
        const event1 = GameRemoveDevice('device-123');
        const event2 = GameRemoveDevice('device-123');
        expect(event1, equals(event2));
      });

      test('two instances with different deviceIds are not equal', () {
        const event1 = GameRemoveDevice('device-1');
        const event2 = GameRemoveDevice('device-2');
        expect(event1, isNot(equals(event2)));
      });
    });

    group('GameChangeMode', () {
      test('creates instance with mode', () {
        const event = GameChangeMode(GameMode.sim);
        expect(event, isA<GameEvent>());
        expect(event.mode, GameMode.sim);
      });

      test('has mode in props', () {
        const event = GameChangeMode(GameMode.live);
        expect(event.props, [GameMode.live]);
      });

      test('supports all game modes', () {
        for (final mode in GameMode.values) {
          final event = GameChangeMode(mode);
          expect(event.mode, mode);
        }
      });
    });

    group('GameSave', () {
      test('creates instance', () {
        const event = GameSave();
        expect(event, isA<GameEvent>());
      });

      test('has empty props', () {
        const event = GameSave();
        expect(event.props, isEmpty);
      });

      test('two instances are equal', () {
        const event1 = GameSave();
        const event2 = GameSave();
        expect(event1, equals(event2));
      });
    });

    group('GameEnterRoom', () {
      test('creates instance with roomId and spawnPosition', () {
        const event = GameEnterRoom(
          roomId: 'room-123',
          spawnPosition: GridPosition(5, 5),
        );
        expect(event, isA<GameEvent>());
        expect(event.roomId, 'room-123');
        expect(event.spawnPosition, const GridPosition(5, 5));
      });

      test('has roomId and spawnPosition in props', () {
        const event = GameEnterRoom(
          roomId: 'room-456',
          spawnPosition: GridPosition(3, 7),
        );
        expect(event.props, ['room-456', const GridPosition(3, 7)]);
      });

      test('two instances with same parameters are equal', () {
        const event1 = GameEnterRoom(
          roomId: 'room-123',
          spawnPosition: GridPosition(5, 5),
        );
        const event2 = GameEnterRoom(
          roomId: 'room-123',
          spawnPosition: GridPosition(5, 5),
        );
        expect(event1, equals(event2));
      });

      test('two instances with different roomId are not equal', () {
        const event1 = GameEnterRoom(
          roomId: 'room-1',
          spawnPosition: GridPosition(5, 5),
        );
        const event2 = GameEnterRoom(
          roomId: 'room-2',
          spawnPosition: GridPosition(5, 5),
        );
        expect(event1, isNot(equals(event2)));
      });
    });

    group('GameAddRoom', () {
      test('creates instance with all required parameters', () {
        const event = GameAddRoom(
          name: 'New Room',
          type: RoomType.aws,
          doorSide: WallSide.bottom,
          doorPosition: 5,
        );
        expect(event, isA<GameEvent>());
        expect(event.name, 'New Room');
        expect(event.type, RoomType.aws);
        expect(event.doorSide, WallSide.bottom);
        expect(event.doorPosition, 5);
        expect(event.regionCode, isNull);
      });

      test('creates instance with optional regionCode', () {
        const event = GameAddRoom(
          name: 'AWS Region',
          type: RoomType.aws,
          regionCode: 'us-east-1',
          doorSide: WallSide.top,
          doorPosition: 3,
        );
        expect(event.regionCode, 'us-east-1');
      });

      test('has all parameters in props', () {
        const event = GameAddRoom(
          name: 'Test Room',
          type: RoomType.gcp,
          regionCode: 'europe-west1',
          doorSide: WallSide.right,
          doorPosition: 7,
        );
        expect(event.props, [
          'Test Room',
          RoomType.gcp,
          'europe-west1',
          WallSide.right,
          7,
        ]);
      });
    });

    group('GameRemoveRoom', () {
      test('creates instance with roomId', () {
        const event = GameRemoveRoom('room-to-remove');
        expect(event, isA<GameEvent>());
        expect(event.roomId, 'room-to-remove');
      });

      test('has roomId in props', () {
        const event = GameRemoveRoom('room-123');
        expect(event.props, ['room-123']);
      });
    });

    group('GameSelectCloudService', () {
      late CloudServiceTemplate template;

      setUp(() {
        template = const CloudServiceTemplate(
          name: 'Test Service',
          description: 'A test service',
          provider: CloudProvider.aws,
          serviceType: 'ec2',
          category: ServiceCategory.compute,
        );
      });

      test('creates instance with template', () {
        final event = GameSelectCloudService(template);
        expect(event, isA<GameEvent>());
        expect(event.template, template);
      });

      test('has template in props', () {
        final event = GameSelectCloudService(template);
        expect(event.props, [template]);
      });
    });

    group('GamePlaceCloudService', () {
      test('creates instance with position', () {
        const pos = GridPosition(8, 8);
        const event = GamePlaceCloudService(pos);
        expect(event, isA<GameEvent>());
        expect(event.position, pos);
      });

      test('has position in props', () {
        const pos = GridPosition(4, 6);
        const event = GamePlaceCloudService(pos);
        expect(event.props, [pos]);
      });
    });

    group('GameRemoveCloudService', () {
      test('creates instance with serviceId', () {
        const event = GameRemoveCloudService('service-123');
        expect(event, isA<GameEvent>());
        expect(event.serviceId, 'service-123');
      });

      test('has serviceId in props', () {
        const event = GameRemoveCloudService('service-456');
        expect(event.props, ['service-456']);
      });

      test('two instances with same serviceId are equal', () {
        const event1 = GameRemoveCloudService('service-123');
        const event2 = GameRemoveCloudService('service-123');
        expect(event1, equals(event2));
      });

      test('two instances with different serviceIds are not equal', () {
        const event1 = GameRemoveCloudService('service-1');
        const event2 = GameRemoveCloudService('service-2');
        expect(event1, isNot(equals(event2)));
      });
    });

    group('edge cases', () {
      test('singleton events can be used in Set collections', () {
        const init1 = GameInitialize();
        const init2 = GameInitialize();
        const cancel = GameCancelPlacement();
        const save = GameSave();

        // ignore: equal_elements_in_set - intentional duplicate to test deduplication
        final eventSet = <GameEvent>{init1, init2, cancel, save};
        expect(eventSet.length, 3);
        expect(eventSet.contains(init1), isTrue);
        expect(eventSet.contains(cancel), isTrue);
        expect(eventSet.contains(save), isTrue);
      });

      test('parameterized events can be used as Map keys', () {
        const event1 = GameMovePlayer(Direction.up);
        const event2 = GameMovePlayer(Direction.up);

        final eventMap = <GameEvent, String>{event1: 'first'};
        eventMap[event2] = 'second';

        expect(eventMap.length, 1);
        expect(eventMap[event1], 'second');
      });

      test('mixed event types can be used in Set', () {
        const init = GameInitialize();
        const move = GameMovePlayer(Direction.up);
        const moveTo = GameMovePlayerTo(GridPosition(5, 5));
        const toggle = GameToggleShop();
        const cancel = GameCancelPlacement();
        const save = GameSave();

        final eventSet = <GameEvent>{init, move, moveTo, toggle, cancel, save};
        expect(eventSet.length, 6);
      });

      test('events with same type but different values deduplicate correctly', () {
        const move1 = GameMovePlayer(Direction.up);
        const move2 = GameMovePlayer(Direction.up);
        const move3 = GameMovePlayer(Direction.down);

        // ignore: equal_elements_in_set - intentional duplicate to test deduplication
        final moveSet = <GameEvent>{move1, move2, move3};
        expect(moveSet.length, 2);
      });
    });
  });
}
