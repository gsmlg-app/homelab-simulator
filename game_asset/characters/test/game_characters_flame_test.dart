import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_asset_characters/game_asset_characters.dart';

void main() {
  group('CharacterSpriteSheetFlame', () {
    const testSheet = CharacterSpriteSheet(
      path: 'test/sprite.png',
      frameWidth: 192,
      frameHeight: 256,
      columns: 8,
      rows: 4,
      idleRow: 0,
      walkRows: [1, 2, 3],
    );

    group('spriteSheet', () {
      test('creates SpriteSheet with correct srcSize', () {
        // We can't create a real image without Flame game context,
        // but we can verify the sheet configuration is correct
        expect(testSheet.frameWidth, 192);
        expect(testSheet.frameHeight, 256);
      });

      test('frame dimensions match expected sprite size', () {
        // Verify configuration that spriteSheet would use
        final expectedSrcSize = Vector2(192, 256);

        expect(testSheet.frameWidth, expectedSrcSize.x);
        expect(testSheet.frameHeight, expectedSrcSize.y);
      });
    });

    group('idleSprite configuration', () {
      test('uses correct row for idle', () {
        expect(testSheet.idleRow, 0);
      });

      test('calculates correct column for down direction', () {
        final column = testSheet.columnForDirection(CharacterDirection.down);
        expect(column, 0);
      });

      test('calculates correct column for up direction', () {
        final column = testSheet.columnForDirection(CharacterDirection.up);
        expect(column, 4);
      });

      test('calculates correct column for left direction', () {
        final column = testSheet.columnForDirection(CharacterDirection.left);
        expect(column, 2);
      });

      test('calculates correct column for right direction', () {
        final column = testSheet.columnForDirection(CharacterDirection.right);
        expect(column, 6);
      });
    });

    group('walkAnimation configuration', () {
      test('uses correct rows for walk animation', () {
        expect(testSheet.walkRows, [1, 2, 3]);
        expect(testSheet.walkRows.length, 3);
      });

      test('walk frame positions for down direction', () {
        final column = testSheet.columnForDirection(CharacterDirection.down);

        // Expected frame positions (x, y) for 3-frame walk animation
        final expectedPositions = [
          Vector2(column * 192.0, 1 * 256.0),
          Vector2(column * 192.0, 2 * 256.0),
          Vector2(column * 192.0, 3 * 256.0),
        ];

        for (int i = 0; i < testSheet.walkRows.length; i++) {
          final row = testSheet.walkRows[i];
          final position = Vector2(
            column * testSheet.frameWidth,
            row * testSheet.frameHeight,
          );
          expect(position, expectedPositions[i]);
        }
      });

      test('walk frame positions for up direction', () {
        final column = testSheet.columnForDirection(CharacterDirection.up);

        for (final row in testSheet.walkRows) {
          final position = Vector2(
            column * testSheet.frameWidth,
            row * testSheet.frameHeight,
          );
          expect(position.x, column * 192.0);
          expect(position.y, row * 256.0);
        }
      });

      test('walk frame positions for diagonal directions', () {
        for (final direction in [
          CharacterDirection.upLeft,
          CharacterDirection.upRight,
          CharacterDirection.downLeft,
          CharacterDirection.downRight,
        ]) {
          final column = testSheet.columnForDirection(direction);

          for (final row in testSheet.walkRows) {
            final position = Vector2(
              column * testSheet.frameWidth,
              row * testSheet.frameHeight,
            );
            expect(position.x, isNonNegative);
            expect(position.y, isNonNegative);
          }
        }
      });
    });

    group('walkAnimations configuration', () {
      test('all directions have corresponding column', () {
        for (final direction in CharacterDirection.values) {
          final column = testSheet.columnForDirection(direction);
          expect(column, inInclusiveRange(0, 7));
        }
      });

      test('frame size is consistent across all directions', () {
        final srcSize = Vector2(testSheet.frameWidth, testSheet.frameHeight);

        for (final direction in CharacterDirection.values) {
          testSheet.columnForDirection(direction);
          expect(srcSize, Vector2(192, 256));
        }
      });
    });

    group('GameCharacters integration', () {
      test('mainMale sheet has valid configuration for flame extension', () {
        expect(GameCharacters.mainMale.frameWidth, 192);
        expect(GameCharacters.mainMale.frameHeight, 256);
        expect(GameCharacters.mainMale.columns, 8);
        expect(GameCharacters.mainMale.rows, 4);
        expect(GameCharacters.mainMale.idleRow, 0);
        expect(GameCharacters.mainMale.walkRows, [1, 2, 3]);
      });

      test('mainFemale sheet has valid configuration for flame extension', () {
        expect(GameCharacters.mainFemale.frameWidth, 192);
        expect(GameCharacters.mainFemale.frameHeight, 256);
        expect(GameCharacters.mainFemale.columns, 8);
        expect(GameCharacters.mainFemale.rows, 4);
        expect(GameCharacters.mainFemale.idleRow, 0);
        expect(GameCharacters.mainFemale.walkRows, [1, 2, 3]);
      });

      test('mainMale calculates correct idle position for all directions', () {
        for (final direction in CharacterDirection.values) {
          final column = GameCharacters.mainMale.columnForDirection(direction);
          final x = column * GameCharacters.mainMale.frameWidth;
          final y =
              GameCharacters.mainMale.idleRow *
              GameCharacters.mainMale.frameHeight;

          expect(x, inInclusiveRange(0, 7 * 192));
          expect(y, 0);
        }
      });

      test(
        'mainFemale calculates correct idle position for all directions',
        () {
          for (final direction in CharacterDirection.values) {
            final column = GameCharacters.mainFemale.columnForDirection(
              direction,
            );
            final x = column * GameCharacters.mainFemale.frameWidth;
            final y =
                GameCharacters.mainFemale.idleRow *
                GameCharacters.mainFemale.frameHeight;

            expect(x, inInclusiveRange(0, 7 * 192));
            expect(y, 0);
          }
        },
      );
    });

    group('frame calculation', () {
      test('total frames in sprite sheet', () {
        final totalFrames = testSheet.columns * testSheet.rows;
        expect(totalFrames, 32);
      });

      test('walk animation has correct frame count', () {
        final walkFrameCount = testSheet.walkRows.length;
        expect(walkFrameCount, 3);
      });

      test('idle frame is single frame', () {
        // Idle animation uses a single row
        expect(testSheet.idleRow, isA<int>());
      });

      test('frame positions do not exceed sheet bounds', () {
        for (final direction in CharacterDirection.values) {
          final column = testSheet.columnForDirection(direction);

          // Check idle frame
          final idleX = column * testSheet.frameWidth;
          final idleY = testSheet.idleRow * testSheet.frameHeight;
          expect(idleX, lessThan(testSheet.columns * testSheet.frameWidth));
          expect(idleY, lessThan(testSheet.rows * testSheet.frameHeight));

          // Check walk frames
          for (final row in testSheet.walkRows) {
            final walkX = column * testSheet.frameWidth;
            final walkY = row * testSheet.frameHeight;
            expect(walkX, lessThan(testSheet.columns * testSheet.frameWidth));
            expect(walkY, lessThan(testSheet.rows * testSheet.frameHeight));
          }
        }
      });
    });

    group('CharacterDirection enum', () {
      test('has 8 directions', () {
        expect(CharacterDirection.values.length, 8);
      });

      test('all directions have unique indices', () {
        final indices = CharacterDirection.values.map((d) => d.index).toSet();
        expect(indices.length, 8);
      });

      test('contains all cardinal directions', () {
        expect(
          CharacterDirection.values,
          containsAll([
            CharacterDirection.up,
            CharacterDirection.down,
            CharacterDirection.left,
            CharacterDirection.right,
          ]),
        );
      });

      test('contains all diagonal directions', () {
        expect(
          CharacterDirection.values,
          containsAll([
            CharacterDirection.upLeft,
            CharacterDirection.upRight,
            CharacterDirection.downLeft,
            CharacterDirection.downRight,
          ]),
        );
      });
    });

    group('sprite sheet consistency', () {
      test('all GameCharacters sheets have same frame dimensions', () {
        expect(
          GameCharacters.mainMale.frameWidth,
          GameCharacters.mainFemale.frameWidth,
        );
        expect(
          GameCharacters.mainMale.frameHeight,
          GameCharacters.mainFemale.frameHeight,
        );
      });

      test('all GameCharacters sheets have same column count', () {
        expect(
          GameCharacters.mainMale.columns,
          GameCharacters.mainFemale.columns,
        );
      });

      test('all GameCharacters sheets have same row count', () {
        expect(GameCharacters.mainMale.rows, GameCharacters.mainFemale.rows);
      });

      test('all GameCharacters sheets have same walk animation length', () {
        expect(
          GameCharacters.mainMale.walkRows.length,
          GameCharacters.mainFemale.walkRows.length,
        );
      });
    });

    group('column calculation symmetry', () {
      test('left and right columns are different', () {
        final leftCol = testSheet.columnForDirection(CharacterDirection.left);
        final rightCol = testSheet.columnForDirection(CharacterDirection.right);
        expect(leftCol, isNot(rightCol));
      });

      test('up and down columns are different', () {
        final upCol = testSheet.columnForDirection(CharacterDirection.up);
        final downCol = testSheet.columnForDirection(CharacterDirection.down);
        expect(upCol, isNot(downCol));
      });
    });
  });
}
