import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_secure_storage/app_secure_storage.dart';

/// Mock implementation of FlutterSecureStorage for testing.
class MockFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  // Expose raw storage for test verification
  Map<String, String> get rawStorage => Map.from(_storage);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Handle any other methods that might be called
    return null;
  }
}

void main() {
  group('SecureStorageVaultRepository', () {
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    group('without namespace', () {
      late SecureStorageVaultRepository vault;

      setUp(() {
        vault = SecureStorageVaultRepository(storage: mockStorage);
      });

      test('write stores value with original key', () async {
        await vault.write(key: 'api_token', value: 'secret123');
        expect(mockStorage.rawStorage['api_token'], equals('secret123'));
      });

      test('read retrieves value with original key', () async {
        await vault.write(key: 'api_token', value: 'secret123');
        final result = await vault.read(key: 'api_token');
        expect(result, equals('secret123'));
      });

      test('delete removes value with original key', () async {
        await vault.write(key: 'api_token', value: 'secret123');
        await vault.delete(key: 'api_token');
        expect(mockStorage.rawStorage.containsKey('api_token'), isFalse);
      });

      test('containsKey checks original key', () async {
        await vault.write(key: 'api_token', value: 'secret123');
        expect(await vault.containsKey(key: 'api_token'), isTrue);
        expect(await vault.containsKey(key: 'other'), isFalse);
      });

      test('deleteAll clears all storage', () async {
        await vault.write(key: 'key1', value: 'value1');
        await vault.write(key: 'key2', value: 'value2');
        await vault.deleteAll();
        expect(mockStorage.rawStorage, isEmpty);
      });

      test('readAll returns all values', () async {
        await vault.write(key: 'key1', value: 'value1');
        await vault.write(key: 'key2', value: 'value2');
        final all = await vault.readAll();
        expect(all, equals({'key1': 'value1', 'key2': 'value2'}));
      });
    });

    group('with namespace', () {
      late SecureStorageVaultRepository vault;

      setUp(() {
        vault = SecureStorageVaultRepository(
          storage: mockStorage,
          namespace: 'myapp',
        );
      });

      test('write stores value with prefixed key', () async {
        await vault.write(key: 'api_token', value: 'secret123');
        expect(mockStorage.rawStorage['myapp_api_token'], equals('secret123'));
        expect(mockStorage.rawStorage.containsKey('api_token'), isFalse);
      });

      test('read retrieves value with prefixed key', () async {
        await vault.write(key: 'api_token', value: 'secret123');
        final result = await vault.read(key: 'api_token');
        expect(result, equals('secret123'));
      });

      test('delete removes value with prefixed key', () async {
        await vault.write(key: 'api_token', value: 'secret123');
        await vault.delete(key: 'api_token');
        expect(mockStorage.rawStorage.containsKey('myapp_api_token'), isFalse);
      });

      test('containsKey checks prefixed key', () async {
        await vault.write(key: 'api_token', value: 'secret123');
        expect(await vault.containsKey(key: 'api_token'), isTrue);
        expect(await vault.containsKey(key: 'other'), isFalse);
      });

      test('deleteAll only clears namespaced keys', () async {
        // Add a key with namespace prefix
        await vault.write(key: 'key1', value: 'value1');
        // Add a key without namespace prefix directly to storage
        mockStorage._storage['other_key'] = 'other_value';

        await vault.deleteAll();

        // Namespaced key should be deleted
        expect(mockStorage.rawStorage.containsKey('myapp_key1'), isFalse);
        // Other key should remain
        expect(mockStorage.rawStorage['other_key'], equals('other_value'));
      });

      test(
        'readAll only returns namespaced keys with prefix stripped',
        () async {
          // Add keys with namespace prefix
          await vault.write(key: 'key1', value: 'value1');
          await vault.write(key: 'key2', value: 'value2');
          // Add a key without namespace prefix directly to storage
          mockStorage._storage['other_key'] = 'other_value';

          final all = await vault.readAll();

          expect(all, equals({'key1': 'value1', 'key2': 'value2'}));
          expect(all.containsKey('other_key'), isFalse);
          expect(all.containsKey('myapp_key1'), isFalse);
        },
      );
    });

    group('with empty namespace', () {
      late SecureStorageVaultRepository vault;

      setUp(() {
        vault = SecureStorageVaultRepository(
          storage: mockStorage,
          namespace: '',
        );
      });

      test('treats empty namespace like no namespace', () async {
        await vault.write(key: 'api_token', value: 'secret123');
        expect(mockStorage.rawStorage['api_token'], equals('secret123'));
        expect(mockStorage.rawStorage.containsKey('_api_token'), isFalse);
      });

      test('deleteAll clears all storage', () async {
        await vault.write(key: 'key1', value: 'value1');
        await vault.deleteAll();
        expect(mockStorage.rawStorage, isEmpty);
      });

      test('readAll returns all values without filtering', () async {
        await vault.write(key: 'key1', value: 'value1');
        final all = await vault.readAll();
        expect(all, equals({'key1': 'value1'}));
      });
    });

    group('namespace isolation', () {
      test('multiple namespaces are isolated from each other', () async {
        final vault1 = SecureStorageVaultRepository(
          storage: mockStorage,
          namespace: 'app1',
        );
        final vault2 = SecureStorageVaultRepository(
          storage: mockStorage,
          namespace: 'app2',
        );

        await vault1.write(key: 'key', value: 'value1');
        await vault2.write(key: 'key', value: 'value2');

        expect(await vault1.read(key: 'key'), equals('value1'));
        expect(await vault2.read(key: 'key'), equals('value2'));

        // Both stored with different prefixes
        expect(mockStorage.rawStorage['app1_key'], equals('value1'));
        expect(mockStorage.rawStorage['app2_key'], equals('value2'));
      });

      test('deleteAll only affects own namespace', () async {
        final vault1 = SecureStorageVaultRepository(
          storage: mockStorage,
          namespace: 'app1',
        );
        final vault2 = SecureStorageVaultRepository(
          storage: mockStorage,
          namespace: 'app2',
        );

        await vault1.write(key: 'key', value: 'value1');
        await vault2.write(key: 'key', value: 'value2');

        await vault1.deleteAll();

        expect(await vault1.containsKey(key: 'key'), isFalse);
        expect(await vault2.read(key: 'key'), equals('value2'));
      });
    });

    group('edge cases', () {
      test('handles keys with underscores', () async {
        final vault = SecureStorageVaultRepository(
          storage: mockStorage,
          namespace: 'myapp',
        );

        await vault.write(key: 'my_api_token', value: 'secret');
        expect(mockStorage.rawStorage['myapp_my_api_token'], equals('secret'));

        final result = await vault.read(key: 'my_api_token');
        expect(result, equals('secret'));
      });

      test('handles empty key', () async {
        final vault = SecureStorageVaultRepository(
          storage: mockStorage,
          namespace: 'myapp',
        );

        await vault.write(key: '', value: 'secret');
        expect(mockStorage.rawStorage['myapp_'], equals('secret'));
      });

      test('handles special characters in namespace', () async {
        final vault = SecureStorageVaultRepository(
          storage: mockStorage,
          namespace: 'my-app.v1',
        );

        await vault.write(key: 'key', value: 'value');
        expect(mockStorage.rawStorage['my-app.v1_key'], equals('value'));
      });
    });
  });
}
