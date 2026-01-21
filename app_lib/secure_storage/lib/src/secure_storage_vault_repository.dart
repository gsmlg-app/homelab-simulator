import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

import 'vault_repository.dart';

final _log = Logger('SecureStorageVaultRepository');

/// Implementation of [VaultRepository] using flutter_secure_storage.
///
/// This implementation provides secure storage using platform-native
/// mechanisms:
/// - iOS/macOS: Keychain Services
/// - Android: EncryptedSharedPreferences with AES encryption
/// - Linux: libsecret
/// - Windows: Windows Credential Manager
/// - Web: Uses encrypted local storage (less secure than native platforms)
///
/// All methods handle exceptions gracefully by logging warnings and returning
/// sensible defaults (null for reads, false for containsKey, empty map for readAll).
class SecureStorageVaultRepository implements VaultRepository {
  /// Creates a [SecureStorageVaultRepository].
  ///
  /// [storage] - Optional custom FlutterSecureStorage instance for testing.
  /// [namespace] - Optional prefix for keys to avoid collisions between
  ///               different parts of the app.
  SecureStorageVaultRepository({FlutterSecureStorage? storage, this.namespace})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Optional namespace prefix for keys to avoid collisions.
  final String? namespace;

  /// Returns the namespaced key if a namespace is set.
  String _prefixedKey(String key) {
    if (namespace != null && namespace!.isNotEmpty) {
      return '${namespace}_$key';
    }
    return key;
  }

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: _prefixedKey(key), value: value);
    } catch (e, stackTrace) {
      _log.warning('Failed to write key "$key": $e', e, stackTrace);
    }
  }

  @override
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: _prefixedKey(key));
    } catch (e, stackTrace) {
      _log.warning('Failed to read key "$key": $e', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: _prefixedKey(key));
    } catch (e, stackTrace) {
      _log.warning('Failed to delete key "$key": $e', e, stackTrace);
    }
  }

  @override
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: _prefixedKey(key));
    } catch (e, stackTrace) {
      _log.warning('Failed to check containsKey "$key": $e', e, stackTrace);
      return false;
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      if (namespace != null && namespace!.isNotEmpty) {
        // Only delete keys with our namespace prefix
        final all = await _storage.readAll();
        for (final key in all.keys) {
          if (key.startsWith('${namespace}_')) {
            await _storage.delete(key: key);
          }
        }
      } else {
        await _storage.deleteAll();
      }
    } catch (e, stackTrace) {
      _log.warning('Failed to deleteAll: $e', e, stackTrace);
    }
  }

  @override
  Future<Map<String, String>> readAll() async {
    try {
      final all = await _storage.readAll();
      if (namespace != null && namespace!.isNotEmpty) {
        // Only return keys with our namespace prefix, stripped of prefix
        final prefix = '${namespace}_';
        return Map.fromEntries(
          all.entries
              .where((e) => e.key.startsWith(prefix))
              .map((e) => MapEntry(e.key.substring(prefix.length), e.value)),
        );
      }
      return all;
    } catch (e, stackTrace) {
      _log.warning('Failed to readAll: $e', e, stackTrace);
      return {};
    }
  }
}
