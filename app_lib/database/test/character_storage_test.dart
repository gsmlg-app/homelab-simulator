
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_database/app_database.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CharacterStorage', () {
    late CharacterStorage storage;
    final testTime = DateTime(2024, 1, 15, 12, 0, 0);

    CharacterModel createTestCharacter({
      String? id,
      String name = 'TestChar',
      DateTime? lastPlayedAt,
    }) {
      return CharacterModel(
        id: id ?? 'test-id-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        gender: Gender.male,
        createdAt: testTime,
        lastPlayedAt: lastPlayedAt ?? testTime,
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = CharacterStorage();
    });

    group('loadAll', () {
      test('should return empty list when no characters exist', () async {
        final result = await storage.loadAll();
        expect(result, isEmpty);
      });

      test('should return saved characters', () async {
        final char1 = createTestCharacter(id: 'char-1', name: 'Alice');
        final char2 = createTestCharacter(id: 'char-2', name: 'Bob');

        await storage.save(char1);
        await storage.save(char2);

        final result = await storage.loadAll();
        expect(result.length, 2);
      });

      test('should sort characters by lastPlayedAt descending', () async {
        final older = createTestCharacter(
          id: 'char-1',
          name: 'OldChar',
          lastPlayedAt: DateTime(2024, 1, 1),
        );
        final newer = createTestCharacter(
          id: 'char-2',
          name: 'NewChar',
          lastPlayedAt: DateTime(2024, 1, 15),
        );

        await storage.save(older);
        await storage.save(newer);

        final result = await storage.loadAll();
        expect(result.first.name, 'NewChar');
        expect(result.last.name, 'OldChar');
      });

      test('should return empty list for corrupted JSON', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('homelab_characters', 'not valid json');

        final result = await storage.loadAll();
        expect(result, isEmpty);
      });

      test('should return empty list for invalid data structure', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('homelab_characters', '{"not": "a list"}');

        final result = await storage.loadAll();
        expect(result, isEmpty);
      });
    });

    group('save', () {
      test('should save new character', () async {
        final char = createTestCharacter(id: 'char-1', name: 'Alice');

        await storage.save(char);

        final result = await storage.loadAll();
        expect(result.length, 1);
        expect(result.first.name, 'Alice');
      });

      test('should update existing character', () async {
        final char = createTestCharacter(id: 'char-1', name: 'Alice');
        await storage.save(char);

        final updated = char.copyWith(name: 'AliceUpdated');
        await storage.save(updated);

        final result = await storage.loadAll();
        expect(result.length, 1);
        expect(result.first.name, 'AliceUpdated');
      });

      test('should preserve other characters when updating', () async {
        final char1 = createTestCharacter(id: 'char-1', name: 'Alice');
        final char2 = createTestCharacter(id: 'char-2', name: 'Bob');
        await storage.save(char1);
        await storage.save(char2);

        final updated = char1.copyWith(name: 'AliceUpdated');
        await storage.save(updated);

        final result = await storage.loadAll();
        expect(result.length, 2);
        expect(result.any((c) => c.name == 'AliceUpdated'), isTrue);
        expect(result.any((c) => c.name == 'Bob'), isTrue);
      });
    });

    group('delete', () {
      test('should delete character by ID', () async {
        final char = createTestCharacter(id: 'char-1', name: 'Alice');
        await storage.save(char);

        await storage.delete('char-1');

        final result = await storage.loadAll();
        expect(result, isEmpty);
      });

      test('should preserve other characters when deleting', () async {
        final char1 = createTestCharacter(id: 'char-1', name: 'Alice');
        final char2 = createTestCharacter(id: 'char-2', name: 'Bob');
        await storage.save(char1);
        await storage.save(char2);

        await storage.delete('char-1');

        final result = await storage.loadAll();
        expect(result.length, 1);
        expect(result.first.name, 'Bob');
      });

      test('should not throw when deleting non-existent character', () async {
        expect(() => storage.delete('non-existent'), returnsNormally);
      });
    });

    group('load', () {
      test('should return character by ID', () async {
        final char = createTestCharacter(id: 'char-1', name: 'Alice');
        await storage.save(char);

        final result = await storage.load('char-1');
        expect(result, isNotNull);
        expect(result!.name, 'Alice');
      });

      test('should return null for non-existent character', () async {
        final result = await storage.load('non-existent');
        expect(result, isNull);
      });

      test('should return correct character among multiple', () async {
        final char1 = createTestCharacter(id: 'char-1', name: 'Alice');
        final char2 = createTestCharacter(id: 'char-2', name: 'Bob');
        await storage.save(char1);
        await storage.save(char2);

        final result = await storage.load('char-2');
        expect(result, isNotNull);
        expect(result!.name, 'Bob');
      });
    });

    group('persistence', () {
      test('should persist all character fields', () async {
        final char = CharacterModel(
          id: 'char-1',
          name: 'TestChar',
          gender: Gender.female,
          skinTone: SkinTone.dark,
          hairStyle: HairStyle.long,
          hairColor: HairColor.blonde,
          outfitVariant: OutfitVariant.formal,
          createdAt: testTime,
          lastPlayedAt: testTime,
          totalPlayTime: 3600,
          level: 5,
          credits: 1000,
        );

        await storage.save(char);
        final loaded = await storage.load('char-1');

        expect(loaded!.name, 'TestChar');
        expect(loaded.gender, Gender.female);
        expect(loaded.skinTone, SkinTone.dark);
        expect(loaded.hairStyle, HairStyle.long);
        expect(loaded.hairColor, HairColor.blonde);
        expect(loaded.outfitVariant, OutfitVariant.formal);
        expect(loaded.totalPlayTime, 3600);
        expect(loaded.level, 5);
        expect(loaded.credits, 1000);
      });
    });
  });
}
