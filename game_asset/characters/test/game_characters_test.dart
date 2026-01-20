import 'package:flutter_test/flutter_test.dart';
import 'package:game_asset_characters/game_asset_characters.dart';

void main() {
  group('CharacterSpriteSheet', () {
    const testSheet = CharacterSpriteSheet(
      path: 'test/path.png',
      frameWidth: 192,
      frameHeight: 256,
      columns: 8,
      rows: 4,
      idleRow: 0,
      walkRows: [1, 2, 3],
    );

    test('stores path correctly', () {
      expect(testSheet.path, 'test/path.png');
    });

    test('stores frame dimensions correctly', () {
      expect(testSheet.frameWidth, 192);
      expect(testSheet.frameHeight, 256);
    });

    test('stores grid dimensions correctly', () {
      expect(testSheet.columns, 8);
      expect(testSheet.rows, 4);
    });

    test('stores animation rows correctly', () {
      expect(testSheet.idleRow, 0);
      expect(testSheet.walkRows, [1, 2, 3]);
    });

    group('columnForDirection', () {
      test('returns 0 for down', () {
        expect(testSheet.columnForDirection(CharacterDirection.down), 0);
      });

      test('returns 1 for downLeft', () {
        expect(testSheet.columnForDirection(CharacterDirection.downLeft), 1);
      });

      test('returns 2 for left', () {
        expect(testSheet.columnForDirection(CharacterDirection.left), 2);
      });

      test('returns 3 for upLeft', () {
        expect(testSheet.columnForDirection(CharacterDirection.upLeft), 3);
      });

      test('returns 4 for up', () {
        expect(testSheet.columnForDirection(CharacterDirection.up), 4);
      });

      test('returns 5 for upRight', () {
        expect(testSheet.columnForDirection(CharacterDirection.upRight), 5);
      });

      test('returns 6 for right', () {
        expect(testSheet.columnForDirection(CharacterDirection.right), 6);
      });

      test('returns 7 for downRight', () {
        expect(testSheet.columnForDirection(CharacterDirection.downRight), 7);
      });
    });
  });

  group('GameCharacters', () {
    test('mainMale has correct path', () {
      expect(
        GameCharacters.mainMale.path,
        'packages/game_asset_characters/assets/boy.png',
      );
    });

    test('mainMale has correct frame size', () {
      expect(GameCharacters.mainMale.frameWidth, 192);
      expect(GameCharacters.mainMale.frameHeight, 256);
    });

    test('mainMale has correct grid layout', () {
      expect(GameCharacters.mainMale.columns, 8);
      expect(GameCharacters.mainMale.rows, 4);
    });

    test('mainMale has correct animation rows', () {
      expect(GameCharacters.mainMale.idleRow, 0);
      expect(GameCharacters.mainMale.walkRows, [1, 2, 3]);
    });

    test('mainFemale has correct path', () {
      expect(
        GameCharacters.mainFemale.path,
        'packages/game_asset_characters/assets/girl.png',
      );
    });

    test('mainFemale has correct frame size', () {
      expect(GameCharacters.mainFemale.frameWidth, 192);
      expect(GameCharacters.mainFemale.frameHeight, 256);
    });

    test('mainFemale has correct grid layout', () {
      expect(GameCharacters.mainFemale.columns, 8);
      expect(GameCharacters.mainFemale.rows, 4);
    });

    test('mainFemale has correct animation rows', () {
      expect(GameCharacters.mainFemale.idleRow, 0);
      expect(GameCharacters.mainFemale.walkRows, [1, 2, 3]);
    });
  });

  group('CharacterDirection', () {
    test('has all 8 directions', () {
      expect(CharacterDirection.values.length, 8);
    });

    test('includes cardinal directions', () {
      expect(CharacterDirection.values, contains(CharacterDirection.up));
      expect(CharacterDirection.values, contains(CharacterDirection.down));
      expect(CharacterDirection.values, contains(CharacterDirection.left));
      expect(CharacterDirection.values, contains(CharacterDirection.right));
    });

    test('includes diagonal directions', () {
      expect(CharacterDirection.values, contains(CharacterDirection.upLeft));
      expect(CharacterDirection.values, contains(CharacterDirection.upRight));
      expect(CharacterDirection.values, contains(CharacterDirection.downLeft));
      expect(CharacterDirection.values, contains(CharacterDirection.downRight));
    });
  });
}
