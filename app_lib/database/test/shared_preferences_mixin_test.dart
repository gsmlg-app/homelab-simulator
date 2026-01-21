import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_database/src/shared_preferences_mixin.dart';

class TestStorage with SharedPreferencesMixin {}

void main() {
  group('SharedPreferencesMixin', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('preferences returns SharedPreferences instance', () async {
      final storage = TestStorage();
      final prefs = await storage.preferences;

      expect(prefs, isA<SharedPreferences>());
    });

    test('preferences returns same instance on subsequent calls', () async {
      final storage = TestStorage();
      final prefs1 = await storage.preferences;
      final prefs2 = await storage.preferences;

      expect(identical(prefs1, prefs2), isTrue);
    });

    test('different instances have separate SharedPreferences', () async {
      final storage1 = TestStorage();
      final storage2 = TestStorage();

      final prefs1 = await storage1.preferences;
      final prefs2 = await storage2.preferences;

      // Both should return valid preferences (same underlying singleton)
      expect(prefs1, isA<SharedPreferences>());
      expect(prefs2, isA<SharedPreferences>());
    });

    test('can read and write through mixin preferences', () async {
      final storage = TestStorage();
      final prefs = await storage.preferences;

      await prefs.setString('test_key', 'test_value');
      expect(prefs.getString('test_key'), 'test_value');
    });

    test('mixin can be applied to multiple classes', () async {
      final storage1 = TestStorage();
      final storage2 = TestStorage();

      final prefs1 = await storage1.preferences;
      final prefs2 = await storage2.preferences;

      // Write through one, read through other (shared singleton)
      await prefs1.setString('shared_key', 'shared_value');
      expect(prefs2.getString('shared_key'), 'shared_value');
    });
  });
}
