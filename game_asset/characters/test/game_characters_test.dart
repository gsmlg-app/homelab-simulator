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
    test('MainMale has correct path', () {
      expect(
        GameCharacters.MainMale.path,
        'packages/game_asset_characters/assets/boy.png',
      );
    });

    test('MainMale has correct frame size', () {
      expect(GameCharacters.MainMale.frameWidth, 192);
      expect(GameCharacters.MainMale.frameHeight, 256);
    });

    test('MainMale has correct grid layout', () {
      expect(GameCharacters.MainMale.columns, 8);
      expect(GameCharacters.MainMale.rows, 4);
    });

    test('MainMale has correct animation rows', () {
      expect(GameCharacters.MainMale.idleRow, 0);
      expect(GameCharacters.MainMale.walkRows, [1, 2, 3]);
    });

    test('MainFemale has correct path', () {
      expect(
        GameCharacters.MainFemale.path,
        'packages/game_asset_characters/assets/girl.png',
      );
    });

    test('MainFemale has correct frame size', () {
      expect(GameCharacters.MainFemale.frameWidth, 192);
      expect(GameCharacters.MainFemale.frameHeight, 256);
    });

    test('MainFemale has correct grid layout', () {
      expect(GameCharacters.MainFemale.columns, 8);
      expect(GameCharacters.MainFemale.rows, 4);
    });

    test('MainFemale has correct animation rows', () {
      expect(GameCharacters.MainFemale.idleRow, 0);
      expect(GameCharacters.MainFemale.walkRows, [1, 2, 3]);
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
