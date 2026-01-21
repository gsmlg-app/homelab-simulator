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

    test('direction indices are sequential', () {
      for (int i = 0; i < CharacterDirection.values.length; i++) {
        expect(CharacterDirection.values[i].index, i);
      }
    });

    test('all directions have unique indices', () {
      final indices = CharacterDirection.values.map((d) => d.index).toSet();
      expect(indices.length, CharacterDirection.values.length);
    });
  });

  group('CharacterSpriteSheet edge cases', () {
    const minimalSheet = CharacterSpriteSheet(
      path: 'minimal.png',
      frameWidth: 1,
      frameHeight: 1,
      columns: 1,
      rows: 1,
      idleRow: 0,
      walkRows: [0],
    );

    test('handles minimal dimensions', () {
      expect(minimalSheet.frameWidth, 1);
      expect(minimalSheet.frameHeight, 1);
    });

    test('handles minimal grid', () {
      expect(minimalSheet.columns, 1);
      expect(minimalSheet.rows, 1);
    });

    test('handles single walk row', () {
      expect(minimalSheet.walkRows.length, 1);
    });

    const largeSheet = CharacterSpriteSheet(
      path: 'large.png',
      frameWidth: 1024,
      frameHeight: 1024,
      columns: 100,
      rows: 100,
      idleRow: 0,
      walkRows: [1, 2, 3, 4, 5],
    );

    test('handles large dimensions', () {
      expect(largeSheet.frameWidth, 1024);
      expect(largeSheet.frameHeight, 1024);
    });

    test('handles large grid', () {
      expect(largeSheet.columns, 100);
      expect(largeSheet.rows, 100);
    });

    test('handles multiple walk rows', () {
      expect(largeSheet.walkRows.length, 5);
    });
  });

  group('CharacterSpriteSheet equality', () {
    const sheet1 = CharacterSpriteSheet(
      path: 'test.png',
      frameWidth: 192,
      frameHeight: 256,
      columns: 8,
      rows: 4,
      idleRow: 0,
      walkRows: [1, 2, 3],
    );

    const sheet2 = CharacterSpriteSheet(
      path: 'test.png',
      frameWidth: 192,
      frameHeight: 256,
      columns: 8,
      rows: 4,
      idleRow: 0,
      walkRows: [1, 2, 3],
    );

    const sheet3 = CharacterSpriteSheet(
      path: 'different.png',
      frameWidth: 192,
      frameHeight: 256,
      columns: 8,
      rows: 4,
      idleRow: 0,
      walkRows: [1, 2, 3],
    );

    test('same properties have same hashCode', () {
      expect(sheet1.hashCode, sheet2.hashCode);
    });

    test('different path has different hashCode', () {
      expect(sheet1.hashCode, isNot(sheet3.hashCode));
    });

    test('columnForDirection returns valid column for all directions', () {
      for (final direction in CharacterDirection.values) {
        final column = sheet1.columnForDirection(direction);
        expect(column, greaterThanOrEqualTo(0));
        expect(column, lessThan(sheet1.columns));
      }
    });
  });

  group('GameCharacters registry', () {
    test('mainMale and mainFemale have same dimensions', () {
      expect(GameCharacters.mainMale.frameWidth, GameCharacters.mainFemale.frameWidth);
      expect(GameCharacters.mainMale.frameHeight, GameCharacters.mainFemale.frameHeight);
    });

    test('mainMale and mainFemale have same grid layout', () {
      expect(GameCharacters.mainMale.columns, GameCharacters.mainFemale.columns);
      expect(GameCharacters.mainMale.rows, GameCharacters.mainFemale.rows);
    });

    test('mainMale and mainFemale have same animation rows', () {
      expect(GameCharacters.mainMale.idleRow, GameCharacters.mainFemale.idleRow);
      expect(GameCharacters.mainMale.walkRows.length, GameCharacters.mainFemale.walkRows.length);
    });

    test('mainMale and mainFemale have different paths', () {
      expect(GameCharacters.mainMale.path, isNot(GameCharacters.mainFemale.path));
    });
  });
}
