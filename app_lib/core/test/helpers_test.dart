import 'package:test/test.dart';
import 'package:app_lib_core/app_lib_core.dart';

void main() {
  group('GameConstants', () {
    test('tileSize is 32', () {
      expect(GameConstants.tileSize, 32.0);
    });

    test('roomWidth is 20', () {
      expect(GameConstants.roomWidth, 20);
    });

    test('roomHeight is 12', () {
      expect(GameConstants.roomHeight, 12);
    });

    test('terminalPosition is at (2, 2)', () {
      expect(GameConstants.terminalPosition, const GridPosition(2, 2));
    });

    test('playerStartPosition is at (10, 6)', () {
      expect(GameConstants.playerStartPosition, const GridPosition(10, 6));
    });

    test('startingCredits is 1000', () {
      expect(GameConstants.startingCredits, 1000);
    });
  });

  group('gridToPixel', () {
    test('converts origin correctly', () {
      final result = gridToPixel(const GridPosition(0, 0));
      expect(result.$1, 0.0);
      expect(result.$2, 0.0);
    });

    test('converts positive coordinates', () {
      final result = gridToPixel(const GridPosition(3, 5));
      expect(result.$1, 96.0); // 3 * 32
      expect(result.$2, 160.0); // 5 * 32
    });

    test('converts with tileSize 32', () {
      final result = gridToPixel(const GridPosition(1, 1));
      expect(result.$1, 32.0);
      expect(result.$2, 32.0);
    });

    test('converts negative grid coordinates', () {
      final result = gridToPixel(const GridPosition(-2, -3));
      expect(result.$1, -64.0); // -2 * 32
      expect(result.$2, -96.0); // -3 * 32
    });

    test('converts large grid coordinates', () {
      final result = gridToPixel(const GridPosition(1000, 2000));
      expect(result.$1, 32000.0); // 1000 * 32
      expect(result.$2, 64000.0); // 2000 * 32
    });
  });

  group('pixelToGrid', () {
    test('converts origin correctly', () {
      final result = pixelToGrid(0, 0);
      expect(result.x, 0);
      expect(result.y, 0);
    });

    test('converts exact tile boundaries', () {
      final result = pixelToGrid(64, 96);
      expect(result.x, 2); // 64 / 32
      expect(result.y, 3); // 96 / 32
    });

    test('floors fractional tiles', () {
      final result = pixelToGrid(50, 70);
      expect(result.x, 1); // floor(50 / 32) = floor(1.5625) = 1
      expect(result.y, 2); // floor(70 / 32) = floor(2.1875) = 2
    });

    test('handles values just before next tile', () {
      final result = pixelToGrid(31, 63);
      expect(result.x, 0);
      expect(result.y, 1);
    });

    test('handles negative pixel values', () {
      final result = pixelToGrid(-32, -64);
      expect(result.x, -1); // floor(-32 / 32) = -1
      expect(result.y, -2); // floor(-64 / 32) = -2
    });

    test('handles fractional negative values', () {
      final result = pixelToGrid(-10, -50);
      expect(result.x, -1); // floor(-10 / 32) = floor(-0.3125) = -1
      expect(result.y, -2); // floor(-50 / 32) = floor(-1.5625) = -2
    });

    test('handles very large pixel values', () {
      final result = pixelToGrid(1000000, 2000000);
      expect(result.x, 31250); // 1000000 / 32
      expect(result.y, 62500); // 2000000 / 32
    });

    test('handles values at exact tile boundary', () {
      final result = pixelToGrid(32.0, 64.0);
      expect(result.x, 1);
      expect(result.y, 2);
    });
  });

  group('isWithinBounds', () {
    test('origin is within bounds', () {
      expect(isWithinBounds(const GridPosition(0, 0)), isTrue);
    });

    test('max valid position is within bounds', () {
      expect(
        isWithinBounds(
          const GridPosition(
            GameConstants.roomWidth - 1,
            GameConstants.roomHeight - 1,
          ),
        ),
        isTrue,
      );
    });

    test('negative x is out of bounds', () {
      expect(isWithinBounds(const GridPosition(-1, 5)), isFalse);
    });

    test('negative y is out of bounds', () {
      expect(isWithinBounds(const GridPosition(5, -1)), isFalse);
    });

    test('x at room width is out of bounds', () {
      expect(
        isWithinBounds(const GridPosition(GameConstants.roomWidth, 5)),
        isFalse,
      );
    });

    test('y at room height is out of bounds', () {
      expect(
        isWithinBounds(const GridPosition(5, GameConstants.roomHeight)),
        isFalse,
      );
    });

    test('center of room is within bounds', () {
      expect(isWithinBounds(const GridPosition(10, 6)), isTrue);
    });

    test('playerStartPosition is within bounds', () {
      expect(isWithinBounds(GameConstants.playerStartPosition), isTrue);
    });

    test('terminalPosition is within bounds', () {
      expect(isWithinBounds(GameConstants.terminalPosition), isTrue);
    });
  });
}
