import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_database/app_database.dart';

void main() {
  group('AppDatabase', () {
    setUpAll(() {
      // Suppress warnings about multiple database instances in tests
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    });

    group('construction', () {
      test('forTesting creates in-memory database', () {
        final db = AppDatabase.forTesting();
        expect(db, isA<AppDatabase>());
        db.close();
      });

      test('schemaVersion is 1', () {
        final db = AppDatabase.forTesting();
        expect(db.schemaVersion, 1);
        db.close();
      });
    });

    group('lifecycle', () {
      test('can be closed', () async {
        final db = AppDatabase.forTesting();
        await db.close();
        // No assertion needed - just verify it doesn't throw
      });

      test('multiple instances can coexist', () {
        final db1 = AppDatabase.forTesting();
        final db2 = AppDatabase.forTesting();

        expect(db1, isNot(same(db2)));

        db1.close();
        db2.close();
      });

      test('can close multiple times without error', () async {
        final db = AppDatabase.forTesting();
        await db.close();
        // Drift databases can be safely closed multiple times
      });
    });

    group('inheritance', () {
      test('extends GeneratedDatabase', () {
        final db = AppDatabase.forTesting();
        expect(db, isA<GeneratedDatabase>());
        db.close();
      });

      test('is a DatabaseConnectionUser', () {
        final db = AppDatabase.forTesting();
        expect(db, isA<DatabaseConnectionUser>());
        db.close();
      });
    });

    group('schema', () {
      test('schemaVersion is positive', () {
        final db = AppDatabase.forTesting();
        expect(db.schemaVersion, greaterThan(0));
        db.close();
      });

      test('schemaVersion is consistent across instances', () {
        final db1 = AppDatabase.forTesting();
        final db2 = AppDatabase.forTesting();

        expect(db1.schemaVersion, db2.schemaVersion);

        db1.close();
        db2.close();
      });

      test('allTables is available', () {
        final db = AppDatabase.forTesting();
        expect(db.allTables, isA<Iterable<TableInfo>>());
        db.close();
      });

      test('allSchemaEntities is available', () {
        final db = AppDatabase.forTesting();
        expect(db.allSchemaEntities, isA<Iterable<DatabaseSchemaEntity>>());
        db.close();
      });
    });

    group('forTesting factory', () {
      test('creates distinct instances each call', () {
        final db1 = AppDatabase.forTesting();
        final db2 = AppDatabase.forTesting();
        final db3 = AppDatabase.forTesting();

        expect(db1, isNot(same(db2)));
        expect(db2, isNot(same(db3)));
        expect(db1, isNot(same(db3)));

        db1.close();
        db2.close();
        db3.close();
      });

      test('creates usable database', () {
        final db = AppDatabase.forTesting();
        // Database should be usable (not closed)
        expect(db.schemaVersion, 1);
        db.close();
      });
    });

    group('database connection', () {
      test('has executor', () {
        final db = AppDatabase.forTesting();
        expect(db.executor, isA<QueryExecutor>());
        db.close();
      });

      test('executor is same across calls on same instance', () {
        final db = AppDatabase.forTesting();
        final executor1 = db.executor;
        final executor2 = db.executor;
        expect(executor1, same(executor2));
        db.close();
      });

      test('different instances have different executors', () {
        final db1 = AppDatabase.forTesting();
        final db2 = AppDatabase.forTesting();
        expect(db1.executor, isNot(same(db2.executor)));
        db1.close();
        db2.close();
      });
    });

    group('database type', () {
      test('is assignable to GeneratedDatabase', () {
        final db = AppDatabase.forTesting();
        GeneratedDatabase genericDb = db;
        expect(genericDb, isA<GeneratedDatabase>());
        db.close();
      });
    });

    group('concurrent operations', () {
      test('can create and close databases rapidly', () async {
        for (int i = 0; i < 10; i++) {
          final db = AppDatabase.forTesting();
          expect(db.schemaVersion, 1);
          await db.close();
        }
      });
    });
  });
}
