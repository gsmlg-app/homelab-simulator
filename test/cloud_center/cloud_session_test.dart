import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_cloud/app_cloud.dart';
import 'package:app_cloud_client/app_cloud_client.dart';
import 'package:app_database/app_database.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homelab_simulator/cloud_center/cloud_center_session.dart';

class _Vault implements VaultRepository {
  final entries = <String, String>{};
  Future<void> Function(String key)? beforeRead;
  Future<void> Function(String key)? beforeWrite;
  @override
  Future<void> write({required String key, required String value}) async {
    await beforeWrite?.call(key);
    entries[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    final value = entries[key];
    await beforeRead?.call(key);
    return value;
  }

  @override
  Future<void> delete({required String key}) async {
    entries.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    entries.clear();
  }

  @override
  Future<bool> containsKey({required String key}) async =>
      entries.containsKey(key);
  @override
  Future<Map<String, String>> readAll() async => Map.from(entries);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'logout without cloud interaction never initializes the platform database',
    () async {
      final vault = _Vault();
      final session = CloudCenterSession(
        vault: vault,
        onClose: () {},
        onSummaries: (_) {},
      );
      // No database injection or native plugin mocks: ordinary logout must stay lazy.
      await session.signOut().timeout(const Duration(seconds: 2));
      await session.signOut().timeout(const Duration(seconds: 2));
      expect(session.repository, isNull);
      expect(session.cubit, isNull);
      expect(vault.entries, isEmpty);
      session.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );
  test(
    'connection preference restores, persists, and cannot cross providers',
    () async {
      final fixture = jsonDecode(
        File('docs/cloud-center/fixtures/demo-v1.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final extra = Map<String, dynamic>.from(
        (fixture['connections'] as List).firstWhere(
          (c) => c['id'] == 'aws-main',
        ),
      )..['id'] = 'aws-second';
      (fixture['connections'] as List).add(extra);
      final database = AppDatabase.forTesting();
      await database.saveCloudConfiguration(
        id: 'default',
        backendUrl: '',
        authContext: '',
        mode: 'demo',
        selectedConnectionId: 'aws-second',
      );
      final session = CloudCenterSession(
        database: database,
        vault: _Vault(),
        loadDemo: () async => fixture,
        onClose: () {},
        onSummaries: (_) {},
      );
      CloudConsoleModel target(CloudProvider provider) => CloudConsoleModel(
        id: provider.name,
        roomId: 'cloud',
        position: const GridPosition(3, 3),
        target: ProviderConsoleTarget(provider),
      );
      await session.open(target(CloudProvider.aws));
      expect(session.cubit!.state.selectedId, 'aws-second');
      final saved = database
          .select(database.cloudConfigurations)
          .watchSingle()
          .firstWhere((c) => c.selectedConnectionId == 'aws-main');
      await session.cubit!.selectConnection('aws-main');
      await saved.timeout(const Duration(seconds: 3));
      await session.open(target(CloudProvider.gcp));
      expect(
        session.cubit!.state.selectedConnection!.provider,
        CloudProvider.gcp,
      );
      await session.signOut();
      session.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );
  test(
    'configuration stores only app token in vault; signout clears real cache',
    () async {
      final database = AppDatabase.forTesting();
      final vault = _Vault();
      var closes = 0;
      final session = CloudCenterSession(
        database: database,
        vault: vault,
        onClose: () => closes++,
        onSummaries: (_) {},
      );
      await session.configure(
        mode: CloudMode.real,
        backendUrl: 'https://cloud.example',
        authContext: 'local-user',
        appToken: 'app-only-token',
      );
      expect(session.repository, isA<HttpCloudRepository>());
      expect(vault.entries.values, contains('app-only-token'));
      expect(
        jsonEncode(await database.loadCloudConfigurations()),
        isNot(contains('app-only-token')),
      );
      final namespace = session.repository!.cacheNamespace;
      await database.writeCloudCache(
        namespace: namespace,
        queryKey: 'private',
        payload: 'cached',
        revision: '1',
      );
      await session.signOut();
      expect(await database.cloudCacheCount(namespace), 0);
      expect(vault.entries, isEmpty);
      expect(session.repository, isNull);
      expect(closes, greaterThan(0));
      session.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );
  test(
    'Demo is selected explicitly and mode changes close the panel',
    () async {
      final fixture = jsonDecode(
        File('docs/cloud-center/fixtures/demo-v1.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final session = CloudCenterSession(
        database: AppDatabase.forTesting(),
        vault: _Vault(),
        loadDemo: () async => fixture,
        onClose: () {},
        onSummaries: (_) {},
      );
      const target = CloudConsoleModel(
        id: 'demo-console',
        roomId: 'cloud',
        position: GridPosition(3, 3),
        target: ProviderConsoleTarget(CloudProvider.aws),
      );
      await session.open(target);
      expect(session.configuring, isTrue);
      expect(session.repository, isNull);
      await session.configure(mode: CloudMode.demo);
      expect(session.isOpen, isFalse);
      await session.open(target);
      expect(
        session.cubit!.state.selectedConnection!.provider,
        CloudProvider.aws,
      );
      expect(session.mode, CloudMode.demo);
      await session.configure(
        mode: CloudMode.real,
        backendUrl: 'https://cloud.example',
        authContext: 'a',
        appToken: 'x',
      );
      expect(session.isOpen, isFalse);
      expect(session.cubit!.state.costs, isEmpty);
      await session.signOut();
      session.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );
  final demoFixture = jsonDecode(
    File('docs/cloud-center/fixtures/demo-v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  const awsConsole = CloudConsoleModel(
    id: 'aws',
    roomId: 'cloud',
    position: GridPosition(3, 3),
    target: ProviderConsoleTarget(CloudProvider.aws),
  );
  for (final restoring in [false, true]) {
    test(
      'delayed Demo ${restoring ? 'restore' : 'configure'} cannot survive logout',
      () async {
        final database = AppDatabase.forTesting();
        if (restoring) {
          await database.saveCloudConfiguration(
            id: 'default',
            backendUrl: '',
            authContext: '',
            mode: 'demo',
          );
        }
        final entered = Completer<void>();
        final release = Completer<Map<String, dynamic>>();
        final session = CloudCenterSession(
          database: database,
          vault: _Vault(),
          loadDemo: () {
            entered.complete();
            return release.future;
          },
          onClose: () {},
          onSummaries: (_) {},
        );
        addTearDown(() async {
          await session.signOut();
          session.dispose();
          await Future<void>.delayed(Duration.zero);
        });
        final pending = restoring
            ? session.open(awsConsole)
            : session.configure(mode: CloudMode.demo);
        await entered.future;
        await session.signOut();
        release.complete(demoFixture);
        await pending;
        expect(session.repository, isNull);
        expect(session.cubit, isNull);
        expect(session.isOpen, isFalse);
        expect(await database.loadCloudConfigurations(), isEmpty);
      },
    );
  }
  test('newer configuration wins over delayed Demo configuration', () async {
    final database = AppDatabase.forTesting();
    final vault = _Vault();
    final entered = Completer<void>();
    final release = Completer<Map<String, dynamic>>();
    final session = CloudCenterSession(
      database: database,
      vault: vault,
      loadDemo: () {
        entered.complete();
        return release.future;
      },
      onClose: () {},
      onSummaries: (_) {},
    );
    addTearDown(() async {
      await session.signOut();
      session.dispose();
      await Future<void>.delayed(Duration.zero);
    });
    final older = session.configure(mode: CloudMode.demo);
    await entered.future;
    await session.configure(
      mode: CloudMode.real,
      backendUrl: 'https://new.example',
      authContext: 'new',
      appToken: 'new-token',
    );
    release.complete(demoFixture);
    await older;
    expect(session.mode, CloudMode.real);
    expect(session.backendUrl, 'https://new.example');
    expect((await database.loadCloudConfigurations()).single['mode'], 'real');
    expect(vault.entries.values, ['new-token']);
  });
  for (final logout in [true, false]) {
    test(
      'in-flight token write is isolated from ${logout ? 'logout' : 'new configuration'}',
      () async {
        final database = AppDatabase.forTesting();
        final vault = _Vault();
        final entered = Completer<void>();
        final release = Completer<void>();
        vault.beforeWrite = (key) async {
          if (key.contains('old.example')) {
            entered.complete();
            await release.future;
          }
        };
        final session = CloudCenterSession(
          database: database,
          vault: vault,
          onClose: () {},
          onSummaries: (_) {},
        );
        addTearDown(() async {
          await session.signOut();
          session.dispose();
          await Future<void>.delayed(Duration.zero);
        });
        final older = session.configure(
          mode: CloudMode.real,
          backendUrl: 'https://old.example',
          authContext: 'old',
          appToken: 'old-token',
        );
        await entered.future;
        final newer = logout
            ? session.signOut()
            : session.configure(
                mode: CloudMode.real,
                backendUrl: 'https://new.example',
                authContext: 'new',
                appToken: 'new-token',
              );
        release.complete();
        await Future.wait([older, newer]);
        if (logout) {
          expect(session.repository, isNull);
          expect(vault.entries, isEmpty);
          expect(await database.loadCloudConfigurations(), isEmpty);
        } else {
          expect(session.backendUrl, 'https://new.example');
          expect(session.mode, CloudMode.real);
          expect(vault.entries.values, ['new-token']);
          expect(
            (await database.loadCloudConfigurations()).single['backendUrl'],
            'https://new.example',
          );
        }
      },
    );
  }
  test('delayed real restore cannot reinstall deleted application token after logout', () async {
    final database = AppDatabase.forTesting();
    final vault = _Vault();
    final session = CloudCenterSession(
      database: database,
      vault: vault,
      onClose: () {},
      onSummaries: (_) {},
    );
    addTearDown(() async {
      await session.signOut();
      session.dispose();
      await Future<void>.delayed(Duration.zero);
    });
    await session.configure(
      mode: CloudMode.real,
      backendUrl: 'https://old.example',
      authContext: 'old',
      appToken: 'old-token',
    );
    // A second session models restoring the saved connection on application startup.
    final restored = CloudCenterSession(
      database: database,
      vault: vault,
      onClose: () {},
      onSummaries: (_) {},
    );
    final entered = Completer<void>();
    final release = Completer<void>();
    vault.beforeRead = (_) async {
      entered.complete();
      await release.future;
    };
    final opening = restored.open(awsConsole);
    await entered.future;
    await restored.signOut();
    release.complete();
    await opening;
    expect(restored.repository, isNull);
    expect(vault.entries, isEmpty);
    expect(await database.loadCloudConfigurations(), isEmpty);
    // Both instances share the injected test database; only the first owns disposal.
    await restored.signOut();
  });
  testWidgets(
    'session writes cross widget test async zones without waiting for a frame',
    (tester) async {
      final session = CloudCenterSession(
        database: AppDatabase.forTesting(),
        vault: _Vault(),
        loadDemo: () async => demoFixture,
        onClose: () {},
        onSummaries: (_) {},
      );
      await tester.runAsync(
        () => session
            .configure(mode: CloudMode.demo)
            .timeout(const Duration(seconds: 2)),
      );
      expect(session.mode, CloudMode.demo);
      await tester.runAsync(session.signOut);
      session.dispose();
      await tester.pump();
      await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    },
  );
}
