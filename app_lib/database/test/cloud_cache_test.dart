import 'dart:io';
import 'package:app_database/app_database.dart';
import 'package:drift/drift.dart'
    show QueryExecutorUser, QueryExecutor, OpeningDetails;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1 upgrades without changing unrelated stored data', () async {
    final dir = await Directory.systemTemp.createTemp('cloud-migration');
    final file = File('${dir.path}/test.sqlite');
    final old = NativeDatabase(file);
    await old.ensureOpen(_User());
    await old.runCustom('CREATE TABLE legacy_marker(value TEXT)');
    await old.runCustom("INSERT INTO legacy_marker VALUES ('preserved')");
    await old.runCustom('PRAGMA user_version = 1');
    await old.close();
    final db = AppDatabase(NativeDatabase(file));
    expect(
      (await db.customSelect('SELECT value FROM legacy_marker').getSingle())
          .read<String>('value'),
      'preserved',
    );
    await db.saveCloudConfiguration(
      id: 'default',
      backendUrl: 'https://cloud.example',
      authContext: 'user-a',
      mode: 'real',
    );
    expect(
      (await db.loadCloudConfigurations()).single['authContext'],
      'user-a',
    );
    await db.close();
    await dir.delete(recursive: true);
  });

  test('cache is isolated, bounded, versioned and cleared on logout', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    for (final namespace in [
      'backend-a:user-a:real',
      'backend-a:user-a:demo',
      'backend-a:user-b:real',
    ]) {
      await db.writeCloudCache(
        namespace: namespace,
        queryKey: 'overview',
        payload: namespace,
        revision: '1',
      );
    }
    expect(
      await db.readCloudCache(
        namespace: 'backend-a:user-a:real',
        queryKey: 'overview',
      ),
      'backend-a:user-a:real',
    );
    expect(
      await db.readCloudCache(
        namespace: 'backend-b:user-a:real',
        queryKey: 'overview',
      ),
      isNull,
    );
    await db.clearCloudSession('backend-a:user-a:real');
    expect(
      await db.readCloudCache(
        namespace: 'backend-a:user-a:real',
        queryKey: 'overview',
      ),
      isNull,
    );
    expect(
      await db.readCloudCache(
        namespace: 'backend-a:user-a:demo',
        queryKey: 'overview',
      ),
      isNotNull,
    );
    for (var i = 0; i < 55; i++) {
      await db.writeCloudCache(
        namespace: 'bounded',
        queryKey: 'page-$i',
        payload: '$i',
        revision: '1',
      );
    }
    expect(await db.cloudCacheCount('bounded'), 50);
    expect(
      await db.readCloudCache(namespace: 'bounded', queryKey: 'page-0'),
      isNull,
    );
    expect(
      () => db.writeCloudCache(
        namespace: 'bounded',
        queryKey: 'large',
        payload: 'x' * 1048577,
        revision: '1',
      ),
      throwsArgumentError,
    );
    await db.customStatement(
      "UPDATE cloud_cache_entries SET schema_version = 99 WHERE namespace = 'bounded'",
    );
    expect(
      await db.readCloudCache(namespace: 'bounded', queryKey: 'page-54'),
      isNull,
    );
  });
}

class _User extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
