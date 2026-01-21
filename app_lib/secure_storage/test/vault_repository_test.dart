import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory implementation of VaultRepository for testing.
class InMemoryVaultRepository implements VaultRepository {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map.from(_storage);
  }
}

void main() {
  group('VaultRepository', () {
    late VaultRepository vault;

    setUp(() {
      vault = InMemoryVaultRepository();
    });

    test('write and read a secret', () async {
      await vault.write(key: 'api_token', value: 'secret123');
      final result = await vault.read(key: 'api_token');
      expect(result, equals('secret123'));
    });

    test('read returns null for non-existent key', () async {
      final result = await vault.read(key: 'non_existent');
      expect(result, isNull);
    });

    test('write overwrites existing value', () async {
      await vault.write(key: 'token', value: 'first');
      await vault.write(key: 'token', value: 'second');
      final result = await vault.read(key: 'token');
      expect(result, equals('second'));
    });

    test('delete removes a secret', () async {
      await vault.write(key: 'to_delete', value: 'value');
      await vault.delete(key: 'to_delete');
      final result = await vault.read(key: 'to_delete');
      expect(result, isNull);
    });

    test('delete does nothing for non-existent key', () async {
      // Should not throw
      await vault.delete(key: 'non_existent');
    });

    test('containsKey returns true for existing key', () async {
      await vault.write(key: 'exists', value: 'value');
      final result = await vault.containsKey(key: 'exists');
      expect(result, isTrue);
    });

    test('containsKey returns false for non-existent key', () async {
      final result = await vault.containsKey(key: 'non_existent');
      expect(result, isFalse);
    });

    test('deleteAll clears all secrets', () async {
      await vault.write(key: 'key1', value: 'value1');
      await vault.write(key: 'key2', value: 'value2');
      await vault.deleteAll();
      expect(await vault.containsKey(key: 'key1'), isFalse);
      expect(await vault.containsKey(key: 'key2'), isFalse);
    });

    test('readAll returns all stored secrets', () async {
      await vault.write(key: 'a', value: '1');
      await vault.write(key: 'b', value: '2');
      final all = await vault.readAll();
      expect(all, equals({'a': '1', 'b': '2'}));
    });

    test('readAll returns empty map when no secrets', () async {
      final all = await vault.readAll();
      expect(all, isEmpty);
    });

    group('edge cases', () {
      test('write handles empty string key', () async {
        await vault.write(key: '', value: 'value');
        final result = await vault.read(key: '');
        expect(result, 'value');
      });

      test('write handles empty string value', () async {
        await vault.write(key: 'empty_value', value: '');
        final result = await vault.read(key: 'empty_value');
        expect(result, '');
      });

      test('write handles unicode keys', () async {
        await vault.write(key: '键名_🔑', value: 'secret');
        final result = await vault.read(key: '键名_🔑');
        expect(result, 'secret');
      });

      test('write handles unicode values', () async {
        await vault.write(key: 'unicode', value: '秘密🔐value');
        final result = await vault.read(key: 'unicode');
        expect(result, '秘密🔐value');
      });

      test('write handles long values', () async {
        final longValue = 'x' * 10000;
        await vault.write(key: 'long', value: longValue);
        final result = await vault.read(key: 'long');
        expect(result, longValue);
      });

      test('containsKey returns false after delete', () async {
        await vault.write(key: 'temp', value: 'data');
        expect(await vault.containsKey(key: 'temp'), isTrue);
        await vault.delete(key: 'temp');
        expect(await vault.containsKey(key: 'temp'), isFalse);
      });

      test('containsKey returns false after deleteAll', () async {
        await vault.write(key: 'key1', value: 'value1');
        await vault.write(key: 'key2', value: 'value2');
        await vault.deleteAll();
        expect(await vault.containsKey(key: 'key1'), isFalse);
        expect(await vault.containsKey(key: 'key2'), isFalse);
      });

      test('readAll returns defensive copy', () async {
        await vault.write(key: 'test', value: 'original');
        final all = await vault.readAll();

        // Modifying the returned map should not affect storage
        all['test'] = 'modified';

        final result = await vault.read(key: 'test');
        expect(result, 'original');
      });
    });

    group('sequential operations', () {
      test('write then read then delete then read', () async {
        await vault.write(key: 'sequence', value: 'data');
        expect(await vault.read(key: 'sequence'), 'data');
        await vault.delete(key: 'sequence');
        expect(await vault.read(key: 'sequence'), isNull);
      });

      test('multiple writes to same key preserve only last', () async {
        await vault.write(key: 'multi', value: 'first');
        await vault.write(key: 'multi', value: 'second');
        await vault.write(key: 'multi', value: 'third');
        expect(await vault.read(key: 'multi'), 'third');
      });

      test('readAll after multiple operations', () async {
        await vault.write(key: 'a', value: '1');
        await vault.write(key: 'b', value: '2');
        await vault.delete(key: 'a');
        await vault.write(key: 'c', value: '3');

        final all = await vault.readAll();
        expect(all, {'b': '2', 'c': '3'});
      });
    });

    group('concurrent operations', () {
      test('handles multiple writes to different keys', () async {
        await Future.wait([
          vault.write(key: 'key1', value: 'value1'),
          vault.write(key: 'key2', value: 'value2'),
          vault.write(key: 'key3', value: 'value3'),
        ]);

        expect(await vault.read(key: 'key1'), 'value1');
        expect(await vault.read(key: 'key2'), 'value2');
        expect(await vault.read(key: 'key3'), 'value3');
      });
    });
  });
}
