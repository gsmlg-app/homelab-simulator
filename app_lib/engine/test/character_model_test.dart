import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

void main() {
  group('CharacterModel', () {
    late CharacterModel character;
    late DateTime testTime;

    setUp(() {
      testTime = DateTime(2026, 1, 20, 12, 0, 0);
      character = CharacterModel(
        id: 'test-id',
        name: 'TestPlayer',
        gender: Gender.female,
        skinTone: SkinTone.tan,
        hairStyle: HairStyle.long,
        hairColor: HairColor.red,
        outfitVariant: OutfitVariant.tech,
        createdAt: testTime,
        lastPlayedAt: testTime,
        totalPlayTime: 3600,
        level: 5,
        credits: 500,
      );
    });

    test('toJson produces correct map', () {
      final json = character.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'TestPlayer');
      expect(json['gender'], 'female');
      expect(json['skinTone'], 'tan');
      expect(json['hairStyle'], 'long');
      expect(json['hairColor'], 'red');
      expect(json['outfitVariant'], 'tech');
      expect(json['totalPlayTime'], 3600);
      expect(json['level'], 5);
      expect(json['credits'], 500);
    });

    test('fromJson produces correct model', () {
      final json = character.toJson();
      final restored = CharacterModel.fromJson(json);

      expect(restored.id, character.id);
      expect(restored.name, character.name);
      expect(restored.gender, character.gender);
      expect(restored.skinTone, character.skinTone);
      expect(restored.hairStyle, character.hairStyle);
      expect(restored.hairColor, character.hairColor);
      expect(restored.outfitVariant, character.outfitVariant);
      expect(restored.totalPlayTime, character.totalPlayTime);
      expect(restored.level, character.level);
      expect(restored.credits, character.credits);
    });

    test('fromJson handles missing appearance fields with defaults', () {
      final json = {
        'id': 'old-id',
        'name': 'OldPlayer',
        'gender': 'male',
        'createdAt': testTime.toIso8601String(),
        'lastPlayedAt': testTime.toIso8601String(),
      };

      final restored = CharacterModel.fromJson(json);

      expect(restored.skinTone, SkinTone.medium);
      expect(restored.hairStyle, HairStyle.short);
      expect(restored.hairColor, HairColor.brown);
      expect(restored.outfitVariant, OutfitVariant.casual);
      expect(restored.totalPlayTime, 0);
      expect(restored.level, 1);
    });

    group('copyWith', () {
      test('creates modified copy with basic fields', () {
        final modified = character.copyWith(
          name: 'NewName',
          hairColor: HairColor.blue,
          level: 10,
        );

        expect(modified.name, 'NewName');
        expect(modified.hairColor, HairColor.blue);
        expect(modified.level, 10);
        expect(modified.id, character.id);
        expect(modified.gender, character.gender);
        expect(modified.skinTone, character.skinTone);
      });

      test('copies id', () {
        final modified = character.copyWith(id: 'new-id');
        expect(modified.id, 'new-id');
        expect(modified.name, character.name);
      });

      test('copies gender', () {
        final modified = character.copyWith(gender: Gender.male);
        expect(modified.gender, Gender.male);
        expect(modified.skinTone, character.skinTone);
      });

      test('copies skinTone', () {
        final modified = character.copyWith(skinTone: SkinTone.dark);
        expect(modified.skinTone, SkinTone.dark);
        expect(modified.hairStyle, character.hairStyle);
      });

      test('copies hairStyle', () {
        final modified = character.copyWith(hairStyle: HairStyle.buzz);
        expect(modified.hairStyle, HairStyle.buzz);
        expect(modified.hairColor, character.hairColor);
      });

      test('copies outfitVariant', () {
        final modified = character.copyWith(outfitVariant: OutfitVariant.formal);
        expect(modified.outfitVariant, OutfitVariant.formal);
        expect(modified.gender, character.gender);
      });

      test('copies createdAt', () {
        final newTime = DateTime(2025, 6, 15);
        final modified = character.copyWith(createdAt: newTime);
        expect(modified.createdAt, newTime);
        expect(modified.lastPlayedAt, character.lastPlayedAt);
      });

      test('copies lastPlayedAt', () {
        final newTime = DateTime(2025, 6, 15);
        final modified = character.copyWith(lastPlayedAt: newTime);
        expect(modified.lastPlayedAt, newTime);
        expect(modified.createdAt, character.createdAt);
      });

      test('copies totalPlayTime', () {
        final modified = character.copyWith(totalPlayTime: 7200);
        expect(modified.totalPlayTime, 7200);
        expect(modified.level, character.level);
      });

      test('copies credits', () {
        final modified = character.copyWith(credits: 9999);
        expect(modified.credits, 9999);
        expect(modified.totalPlayTime, character.totalPlayTime);
      });

      test('preserves all fields when copying single field', () {
        final modified = character.copyWith(name: 'Changed');
        expect(modified.id, character.id);
        expect(modified.gender, character.gender);
        expect(modified.skinTone, character.skinTone);
        expect(modified.hairStyle, character.hairStyle);
        expect(modified.hairColor, character.hairColor);
        expect(modified.outfitVariant, character.outfitVariant);
        expect(modified.createdAt, character.createdAt);
        expect(modified.lastPlayedAt, character.lastPlayedAt);
        expect(modified.totalPlayTime, character.totalPlayTime);
        expect(modified.level, character.level);
        expect(modified.credits, character.credits);
      });
    });

    test('create factory produces valid model', () {
      final created = CharacterModel.create(
        name: 'NewHero',
        gender: Gender.male,
        skinTone: SkinTone.dark,
        hairStyle: HairStyle.buzz,
        hairColor: HairColor.black,
        outfitVariant: OutfitVariant.sporty,
      );

      expect(created.id, isNotEmpty);
      expect(created.name, 'NewHero');
      expect(created.gender, Gender.male);
      expect(created.skinTone, SkinTone.dark);
      expect(created.hairStyle, HairStyle.buzz);
      expect(created.hairColor, HairColor.black);
      expect(created.outfitVariant, OutfitVariant.sporty);
      expect(created.level, 1);
      expect(created.credits, GameConstants.startingCredits);
    });

    test('spritePath returns correct path based on gender', () {
      final male = character.copyWith(gender: Gender.male);
      final female = character.copyWith(gender: Gender.female);

      expect(male.spritePath, contains('boy'));
      expect(female.spritePath, contains('girl'));
    });

    test('equality works correctly', () {
      final same = CharacterModel(
        id: 'test-id',
        name: 'TestPlayer',
        gender: Gender.female,
        skinTone: SkinTone.tan,
        hairStyle: HairStyle.long,
        hairColor: HairColor.red,
        outfitVariant: OutfitVariant.tech,
        createdAt: testTime,
        lastPlayedAt: testTime,
        totalPlayTime: 3600,
        level: 5,
        credits: 500,
      );

      final different = character.copyWith(name: 'Different');

      expect(character, same);
      expect(character, isNot(different));
    });
  });
}
