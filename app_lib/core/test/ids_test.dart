import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';

void main() {
  group('ID generators', () {
    group('generateEntityId', () {
      test('generates non-empty string', () {
        final id = generateEntityId();
        expect(id, isNotEmpty);
      });

      test('generates unique IDs', () {
        final ids = List.generate(100, (_) => generateEntityId());
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, ids.length);
      });

      test('generates valid UUID format', () {
        final id = generateEntityId();
        // UUID v4 format: 8-4-4-4-12 hex characters
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        expect(uuidRegex.hasMatch(id), isTrue);
      });
    });

    group('generateDeviceId', () {
      test('generates non-empty string', () {
        final id = generateDeviceId();
        expect(id, isNotEmpty);
      });

      test('starts with device_ prefix', () {
        final id = generateDeviceId();
        expect(id.startsWith('device_'), isTrue);
      });

      test('generates unique IDs', () {
        final ids = List.generate(100, (_) => generateDeviceId());
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, ids.length);
      });
    });

    group('generateRoomId', () {
      test('generates non-empty string', () {
        final id = generateRoomId();
        expect(id, isNotEmpty);
      });

      test('starts with room_ prefix', () {
        final id = generateRoomId();
        expect(id.startsWith('room_'), isTrue);
      });

      test('generates unique IDs', () {
        final ids = List.generate(100, (_) => generateRoomId());
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, ids.length);
      });
    });

    group('generateDoorId', () {
      test('generates non-empty string', () {
        final id = generateDoorId();
        expect(id, isNotEmpty);
      });

      test('starts with door_ prefix', () {
        final id = generateDoorId();
        expect(id.startsWith('door_'), isTrue);
      });

      test('generates unique IDs', () {
        final ids = List.generate(100, (_) => generateDoorId());
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, ids.length);
      });
    });

    group('generateCharacterId', () {
      test('generates non-empty string', () {
        final id = generateCharacterId();
        expect(id, isNotEmpty);
      });

      test('starts with char_ prefix', () {
        final id = generateCharacterId();
        expect(id.startsWith('char_'), isTrue);
      });

      test('generates unique IDs', () {
        final ids = List.generate(100, (_) => generateCharacterId());
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, ids.length);
      });
    });

    group('cross-generator uniqueness', () {
      test('different generators produce different prefixes', () {
        final deviceId = generateDeviceId();
        final roomId = generateRoomId();
        final doorId = generateDoorId();
        final charId = generateCharacterId();

        expect(deviceId.split('_')[0], 'device');
        expect(roomId.split('_')[0], 'room');
        expect(doorId.split('_')[0], 'door');
        expect(charId.split('_')[0], 'char');
      });

      test('IDs from different generators are unique', () {
        final allIds = <String>{};
        allIds.addAll(List.generate(25, (_) => generateDeviceId()));
        allIds.addAll(List.generate(25, (_) => generateRoomId()));
        allIds.addAll(List.generate(25, (_) => generateDoorId()));
        allIds.addAll(List.generate(25, (_) => generateCharacterId()));

        expect(allIds.length, 100);
      });
    });

    group('ID format consistency', () {
      test('all prefixed IDs contain underscore', () {
        expect(generateDeviceId().contains('_'), isTrue);
        expect(generateRoomId().contains('_'), isTrue);
        expect(generateDoorId().contains('_'), isTrue);
        expect(generateCharacterId().contains('_'), isTrue);
      });

      test('entityId does not have prefix', () {
        final id = generateEntityId();
        // Entity ID is a raw UUID without prefix
        expect(id.startsWith('device_'), isFalse);
        expect(id.startsWith('room_'), isFalse);
        expect(id.startsWith('door_'), isFalse);
        expect(id.startsWith('char_'), isFalse);
      });

      test('all generators produce IDs with reasonable length', () {
        expect(generateEntityId().length, greaterThan(10));
        expect(generateDeviceId().length, greaterThan(10));
        expect(generateRoomId().length, greaterThan(10));
        expect(generateDoorId().length, greaterThan(10));
        expect(generateCharacterId().length, greaterThan(10));
      });
    });

    group('rapid generation', () {
      test('generates 1000 unique entity IDs rapidly', () {
        final ids = List.generate(1000, (_) => generateEntityId());
        expect(ids.toSet().length, 1000);
      });

      test('generates 1000 unique device IDs rapidly', () {
        final ids = List.generate(1000, (_) => generateDeviceId());
        expect(ids.toSet().length, 1000);
      });
    });
  });
}
