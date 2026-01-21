import 'package:flutter_test/flutter_test.dart';
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

    test('terminalEntityId is terminal', () {
      expect(GameConstants.terminalEntityId, 'terminal');
    });

    test('gamepadButtonPressThreshold is 0.5', () {
      expect(GameConstants.gamepadButtonPressThreshold, 0.5);
    });

    test('gamepadAnalogDeadzone is 0.3', () {
      expect(GameConstants.gamepadAnalogDeadzone, 0.3);
    });

    test('gamepadDpadCooldownSeconds is 0.15', () {
      expect(GameConstants.gamepadDpadCooldownSeconds, 0.15);
    });

    // Animation constants
    group('animation constants', () {
      test('deviceFlickerFrequency is 3.0', () {
        expect(GameConstants.deviceFlickerFrequency, 3.0);
      });

      test('deviceFlickerMin is 0.85', () {
        expect(GameConstants.deviceFlickerMin, 0.85);
      });

      test('deviceFlickerAmplitude is 0.15', () {
        expect(GameConstants.deviceFlickerAmplitude, 0.15);
      });

      test('doorGlowFrequency is 4.0', () {
        expect(GameConstants.doorGlowFrequency, 4.0);
      });

      test('terminalFlickerFrequency is 4.0', () {
        expect(GameConstants.terminalFlickerFrequency, 4.0);
      });

      test('terminalFlickerMin is 0.9', () {
        expect(GameConstants.terminalFlickerMin, 0.9);
      });

      test('terminalFlickerAmplitude is 0.1', () {
        expect(GameConstants.terminalFlickerAmplitude, 0.1);
      });

      test('placementBreatheFrequency is 3.0', () {
        expect(GameConstants.placementBreatheFrequency, 3.0);
      });

      test('placementBreatheMinOpacity is 0.4', () {
        expect(GameConstants.placementBreatheMinOpacity, 0.4);
      });

      test('placementBreatheAmplitude is 0.1', () {
        expect(GameConstants.placementBreatheAmplitude, 0.1);
      });

      test('placementBreatheBorderMinOpacity is 0.7', () {
        expect(GameConstants.placementBreatheBorderMinOpacity, 0.7);
      });

      test('placementBreatheBorderAmplitude is 0.3', () {
        expect(GameConstants.placementBreatheBorderAmplitude, 0.3);
      });
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

  group('countBy', () {
    test('returns empty map for empty list', () {
      final result = countBy<String, int>([], (s) => s.length);
      expect(result, isEmpty);
    });

    test('counts single item', () {
      final result = countBy(['apple'], (s) => s.length);
      expect(result, {5: 1});
    });

    test('counts multiple items with same key', () {
      final result = countBy(['cat', 'dog', 'cow'], (s) => s.length);
      expect(result, {3: 3});
    });

    test('counts items with different keys', () {
      final result = countBy(['a', 'bb', 'ccc', 'dd'], (s) => s.length);
      expect(result, {1: 1, 2: 2, 3: 1});
    });

    test('works with enum keys', () {
      final items = [
        (type: 'A', value: 1),
        (type: 'B', value: 2),
        (type: 'A', value: 3),
      ];
      final result = countBy(items, (i) => i.type);
      expect(result, {'A': 2, 'B': 1});
    });

    test('works with object field selector', () {
      final people = [
        _Person('Alice', 30),
        _Person('Bob', 25),
        _Person('Charlie', 30),
      ];
      final result = countBy(people, (p) => p.age);
      expect(result, {30: 2, 25: 1});
    });
  });

  group('groupBy', () {
    test('returns empty map for empty list', () {
      final result = groupBy<String, int>([], (s) => s.length);
      expect(result, isEmpty);
    });

    test('groups single item', () {
      final result = groupBy(['apple'], (s) => s.length);
      expect(result, {
        5: ['apple'],
      });
    });

    test('groups multiple items with same key', () {
      final result = groupBy(['cat', 'dog', 'cow'], (s) => s.length);
      expect(result, {
        3: ['cat', 'dog', 'cow'],
      });
    });

    test('groups items with different keys', () {
      final result = groupBy(['a', 'bb', 'ccc', 'dd'], (s) => s.length);
      expect(result, {
        1: ['a'],
        2: ['bb', 'dd'],
        3: ['ccc'],
      });
    });

    test('preserves order within groups', () {
      final result = groupBy(['apple', 'ant', 'banana', 'axe'], (s) => s[0]);
      expect(result['a'], ['apple', 'ant', 'axe']);
      expect(result['b'], ['banana']);
    });

    test('works with object field selector', () {
      final people = [
        _Person('Alice', 30),
        _Person('Bob', 25),
        _Person('Charlie', 30),
      ];
      final result = groupBy(people, (p) => p.age);
      expect(result[30]?.map((p) => p.name).toList(), ['Alice', 'Charlie']);
      expect(result[25]?.map((p) => p.name).toList(), ['Bob']);
    });
  });
}

class _Person {
  final String name;
  final int age;
  _Person(this.name, this.age);
}
