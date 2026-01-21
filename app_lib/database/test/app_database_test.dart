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
    });
  });
}
