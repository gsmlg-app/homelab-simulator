import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_asset_characters/game_asset_characters.dart';

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
        final modified = character.copyWith(
          outfitVariant: OutfitVariant.formal,
        );
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

    test('spriteSheet returns correct sprite sheet based on gender', () {
      final male = character.copyWith(gender: Gender.male);
      final female = character.copyWith(gender: Gender.female);

      expect(male.spriteSheet, GameCharacters.mainMale);
      expect(female.spriteSheet, GameCharacters.mainFemale);
    });

    test('spritePath returns correct path based on gender', () {
      final male = character.copyWith(gender: Gender.male);
      final female = character.copyWith(gender: Gender.female);

      expect(male.spritePath, contains('boy'));
      expect(female.spritePath, contains('girl'));
    });

    group('equality', () {
      test('equal characters are equal', () {
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

        expect(character, same);
      });

      test('different characters are not equal', () {
        final different = character.copyWith(name: 'Different');
        expect(character, isNot(different));
      });

      test('equal characters have same hashCode', () {
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

        expect(character.hashCode, same.hashCode);
      });

      test('characters can be used in Set collections', () {
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
        final different = character.copyWith(id: 'other-id');

        final characterSet = {character, same, different};
        expect(characterSet.length, 2);
        expect(characterSet.contains(character), isTrue);
        expect(characterSet.contains(different), isTrue);
      });

      test('characters can be used as Map keys', () {
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

        final characterMap = <CharacterModel, String>{character: 'first'};
        characterMap[same] = 'second';

        expect(characterMap.length, 1);
        expect(characterMap[character], 'second');
      });
    });

    group('edge cases', () {
      test('create factory with minimal parameters uses defaults', () {
        final minimal = CharacterModel.create(
          name: 'MinimalPlayer',
          gender: Gender.male,
        );

        expect(minimal.name, 'MinimalPlayer');
        expect(minimal.gender, Gender.male);
        expect(minimal.skinTone, SkinTone.medium);
        expect(minimal.hairStyle, HairStyle.short);
        expect(minimal.hairColor, HairColor.brown);
        expect(minimal.outfitVariant, OutfitVariant.casual);
        expect(minimal.level, 1);
        expect(minimal.credits, GameConstants.startingCredits);
        expect(minimal.totalPlayTime, 0);
        expect(minimal.createdAt, minimal.lastPlayedAt);
      });

      test('fromJson supports all Gender values', () {
        for (final gender in Gender.values) {
          final json = {
            'id': 'test-${gender.name}',
            'name': 'Test',
            'gender': gender.name,
            'createdAt': testTime.toIso8601String(),
            'lastPlayedAt': testTime.toIso8601String(),
          };
          final restored = CharacterModel.fromJson(json);
          expect(restored.gender, gender);
        }
      });

      test('fromJson supports all SkinTone values', () {
        for (final skinTone in SkinTone.values) {
          final json = {
            'id': 'test-${skinTone.name}',
            'name': 'Test',
            'gender': 'male',
            'skinTone': skinTone.name,
            'createdAt': testTime.toIso8601String(),
            'lastPlayedAt': testTime.toIso8601String(),
          };
          final restored = CharacterModel.fromJson(json);
          expect(restored.skinTone, skinTone);
        }
      });

      test('fromJson supports all HairStyle values', () {
        for (final hairStyle in HairStyle.values) {
          final json = {
            'id': 'test-${hairStyle.name}',
            'name': 'Test',
            'gender': 'male',
            'hairStyle': hairStyle.name,
            'createdAt': testTime.toIso8601String(),
            'lastPlayedAt': testTime.toIso8601String(),
          };
          final restored = CharacterModel.fromJson(json);
          expect(restored.hairStyle, hairStyle);
        }
      });

      test('fromJson supports all HairColor values', () {
        for (final hairColor in HairColor.values) {
          final json = {
            'id': 'test-${hairColor.name}',
            'name': 'Test',
            'gender': 'male',
            'hairColor': hairColor.name,
            'createdAt': testTime.toIso8601String(),
            'lastPlayedAt': testTime.toIso8601String(),
          };
          final restored = CharacterModel.fromJson(json);
          expect(restored.hairColor, hairColor);
        }
      });

      test('fromJson supports all OutfitVariant values', () {
        for (final outfit in OutfitVariant.values) {
          final json = {
            'id': 'test-${outfit.name}',
            'name': 'Test',
            'gender': 'male',
            'outfitVariant': outfit.name,
            'createdAt': testTime.toIso8601String(),
            'lastPlayedAt': testTime.toIso8601String(),
          };
          final restored = CharacterModel.fromJson(json);
          expect(restored.outfitVariant, outfit);
        }
      });

      test('fromJson handles missing gender with male default', () {
        final json = {
          'id': 'test-no-gender',
          'name': 'Test',
          'createdAt': testTime.toIso8601String(),
          'lastPlayedAt': testTime.toIso8601String(),
        };
        final restored = CharacterModel.fromJson(json);
        expect(restored.gender, Gender.male);
      });

      test('fromJson handles null gender with male default', () {
        final json = {
          'id': 'test-null-gender',
          'name': 'Test',
          'gender': null,
          'createdAt': testTime.toIso8601String(),
          'lastPlayedAt': testTime.toIso8601String(),
        };
        final restored = CharacterModel.fromJson(json);
        expect(restored.gender, Gender.male);
      });

      test('round-trip serialization preserves all data', () {
        final original = CharacterModel(
          id: 'round-trip-id',
          name: 'RoundTrip',
          gender: Gender.female,
          skinTone: SkinTone.dark,
          hairStyle: HairStyle.ponytail,
          hairColor: HairColor.purple,
          outfitVariant: OutfitVariant.formal,
          createdAt: testTime,
          lastPlayedAt: testTime.add(const Duration(days: 5)),
          totalPlayTime: 86400,
          level: 50,
          credits: 100000,
        );

        final json = original.toJson();
        final restored = CharacterModel.fromJson(json);

        expect(restored, original);
      });

      test('props includes all fields', () {
        expect(character.props.length, 12);
        expect(character.props, contains(character.id));
        expect(character.props, contains(character.name));
        expect(character.props, contains(character.gender));
        expect(character.props, contains(character.skinTone));
        expect(character.props, contains(character.hairStyle));
        expect(character.props, contains(character.hairColor));
        expect(character.props, contains(character.outfitVariant));
        expect(character.props, contains(character.createdAt));
        expect(character.props, contains(character.lastPlayedAt));
        expect(character.props, contains(character.totalPlayTime));
        expect(character.props, contains(character.level));
        expect(character.props, contains(character.credits));
      });

      test('create generates unique IDs', () {
        final ids = <String>{};
        for (var i = 0; i < 10; i++) {
          final created = CharacterModel.create(
            name: 'Test$i',
            gender: Gender.male,
          );
          ids.add(created.id);
        }
        expect(ids.length, 10);
      });
    });
  });
}
