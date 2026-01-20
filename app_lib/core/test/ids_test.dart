import 'package:test/test.dart';
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
  });
}
