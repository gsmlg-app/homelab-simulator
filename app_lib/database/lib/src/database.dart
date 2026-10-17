import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class CloudConfigurations extends Table {
  TextColumn get id => text()();
  TextColumn get backendUrl => text()();
  TextColumn get authContext => text()();
  TextColumn get mode => text()();
  TextColumn get selectedConnectionId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class CloudCacheEntries extends Table {
  TextColumn get namespace => text()();
  TextColumn get queryKey => text()();
  TextColumn get payload => text()();
  TextColumn get revision => text()();
  IntColumn get schemaVersion => integer()();
  DateTimeColumn get savedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {namespace, queryKey};
}

@DriftDatabase(tables: [CloudConfigurations, CloudCacheEntries])
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/setup/
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // Add this factory for tests
  factory AppDatabase.forTesting() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cloudConfigurations);
        await m.createTable(cloudCacheEntries);
      }
    },
  );

  Future<void> saveCloudConfiguration({
    required String id,
    required String backendUrl,
    required String authContext,
    required String mode,
    String? selectedConnectionId,
  }) => into(cloudConfigurations)
      .insertOnConflictUpdate(
        CloudConfigurationsCompanion.insert(
          id: id,
          backendUrl: backendUrl,
          authContext: authContext,
          mode: mode,
          selectedConnectionId: Value(selectedConnectionId),
        ),
      )
      .then((_) {});

  Future<List<Map<String, dynamic>>> loadCloudConfigurations() async =>
      (await select(cloudConfigurations).get())
          .map(
            (c) => {
              'id': c.id,
              'backendUrl': c.backendUrl,
              'authContext': c.authContext,
              'mode': c.mode,
              'selectedConnectionId': c.selectedConnectionId,
            },
          )
          .toList();

  /// Namespace includes backend instance, authorization context and data mode.
  Future<void> writeCloudCache({
    required String namespace,
    required String queryKey,
    required String payload,
    required String revision,
  }) async {
    if (utf8.encode(payload).length > 1048576) {
      throw ArgumentError('Cloud cache entry exceeds 1 MiB');
    }
    await transaction(() async {
      await into(cloudCacheEntries).insertOnConflictUpdate(
        CloudCacheEntriesCompanion.insert(
          namespace: namespace,
          queryKey: queryKey,
          payload: payload,
          revision: revision,
          schemaVersion: 1,
          savedAt: DateTime.now().toUtc(),
        ),
      );
      await customStatement(
        'DELETE FROM cloud_cache_entries WHERE namespace = ? AND rowid NOT IN '
        '(SELECT rowid FROM cloud_cache_entries WHERE namespace = ? '
        'ORDER BY saved_at DESC, rowid DESC LIMIT 50)',
        [namespace, namespace],
      );
    });
  }

  Future<String?> readCloudCache({
    required String namespace,
    required String queryKey,
  }) async {
    final query = select(cloudCacheEntries)
      ..where(
        (c) =>
            c.namespace.equals(namespace) &
            c.queryKey.equals(queryKey) &
            c.schemaVersion.equals(1),
      );
    return (await query.getSingleOrNull())?.payload;
  }

  Future<int> cloudCacheCount(String namespace) async {
    final count = cloudCacheEntries.queryKey.count();
    final query = selectOnly(cloudCacheEntries)
      ..addColumns([count])
      ..where(cloudCacheEntries.namespace.equals(namespace));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<void> clearCloudSession(String namespace) async {
    await (delete(
      cloudCacheEntries,
    )..where((c) => c.namespace.equals(namespace))).go();
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'homelab_simulator',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        databaseDirectory: getApplicationSupportDirectory,
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  }
}
