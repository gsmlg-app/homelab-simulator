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

    // Drawing constants
    group('drawing constants', () {
      test('deviceBodyPadding is 4.0', () {
        expect(GameConstants.deviceBodyPadding, 4.0);
      });

      test('deviceCornerRadius is 4.0', () {
        expect(GameConstants.deviceCornerRadius, 4.0);
      });

      test('deviceSelectionInset is 2.0', () {
        expect(GameConstants.deviceSelectionInset, 2.0);
      });

      test('deviceLedRadius is 3.0', () {
        expect(GameConstants.deviceLedRadius, 3.0);
      });

      test('deviceLedOffset is 10.0', () {
        expect(GameConstants.deviceLedOffset, 10.0);
      });
    });

    // Audio constants
    group('audio constants', () {
      test('audioSfxVolumeDefault is 1.0', () {
        expect(GameConstants.audioSfxVolumeDefault, 1.0);
      });

      test('audioMusicVolumeDefault is 0.5', () {
        expect(GameConstants.audioMusicVolumeDefault, 0.5);
      });
    });

    // Component drawing constants
    group('component drawing constants', () {
      test('componentFramePadding is 2.0', () {
        expect(GameConstants.componentFramePadding, 2.0);
      });

      test('componentInnerPadding is 6.0', () {
        expect(GameConstants.componentInnerPadding, 6.0);
      });

      test('componentFrameWidth is 4.0', () {
        expect(GameConstants.componentFrameWidth, 4.0);
      });

      test('componentCornerRadius is 4.0', () {
        expect(GameConstants.componentCornerRadius, 4.0);
      });

      test('terminalScreenBottomOffset is 4.0', () {
        expect(GameConstants.terminalScreenBottomOffset, 4.0);
      });

      test('doorHandleOffset is 8.0', () {
        expect(GameConstants.doorHandleOffset, 8.0);
      });

      test('doorHandleRadius is 3.0', () {
        expect(GameConstants.doorHandleRadius, 3.0);
      });

      test('arrowBaseOffset is 6.0', () {
        expect(GameConstants.arrowBaseOffset, 6.0);
      });

      test('arrowTipOffset is 5.0', () {
        expect(GameConstants.arrowTipOffset, 5.0);
      });

      test('arrowPerpOffset is 3.0', () {
        expect(GameConstants.arrowPerpOffset, 3.0);
      });
    });

    // Glow animation constants
    group('glow animation constants', () {
      test('glowStrokeBase is 2.0', () {
        expect(GameConstants.glowStrokeBase, 2.0);
      });

      test('glowStrokeAmplitude is 2.0', () {
        expect(GameConstants.glowStrokeAmplitude, 2.0);
      });

      test('glowOpacityBase is 0.6', () {
        expect(GameConstants.glowOpacityBase, 0.6);
      });

      test('glowOpacityAmplitude is 0.4', () {
        expect(GameConstants.glowOpacityAmplitude, 0.4);
      });

      test('highlightBorderInset is 1.0', () {
        expect(GameConstants.highlightBorderInset, 1.0);
      });

      test('glowIntensityCenter is 0.5', () {
        expect(GameConstants.glowIntensityCenter, 0.5);
      });
    });

    // Player character drawing constants
    group('player character drawing constants', () {
      test('playerHeadYOffset is 4.0', () {
        expect(GameConstants.playerHeadYOffset, 4.0);
      });

      test('playerHeadRadius is 8.0', () {
        expect(GameConstants.playerHeadRadius, 8.0);
      });

      test('playerBodyYOffset is 8.0', () {
        expect(GameConstants.playerBodyYOffset, 8.0);
      });

      test('playerBodyWidth is 12.0', () {
        expect(GameConstants.playerBodyWidth, 12.0);
      });

      test('playerBodyHeight is 14.0', () {
        expect(GameConstants.playerBodyHeight, 14.0);
      });

      test('playerBodyRadius is 3.0', () {
        expect(GameConstants.playerBodyRadius, 3.0);
      });

      test('playerOutlineStrokeWidth is 2.0', () {
        expect(GameConstants.playerOutlineStrokeWidth, 2.0);
      });

      test('playerMoveSpeed is 150.0', () {
        expect(GameConstants.playerMoveSpeed, 150.0);
      });

      test('playerMovementThreshold is 1.0', () {
        expect(GameConstants.playerMovementThreshold, 1.0);
      });
    });

    // Cloud service component drawing constants
    group('cloud service component drawing constants', () {
      test('cloudServiceBgPadding is 4.0', () {
        expect(GameConstants.cloudServiceBgPadding, 4.0);
      });

      test('cloudServiceBodyPadding is 8.0', () {
        expect(GameConstants.cloudServiceBodyPadding, 8.0);
      });

      test('cloudServiceSelectionPadding is 2.0', () {
        expect(GameConstants.cloudServiceSelectionPadding, 2.0);
      });

      test('cloudServiceBgRadius is 6.0', () {
        expect(GameConstants.cloudServiceBgRadius, 6.0);
      });

      test('cloudServiceBodyRadius is 4.0', () {
        expect(GameConstants.cloudServiceBodyRadius, 4.0);
      });

      test('cloudServiceProviderDotXOffset is 12.0', () {
        expect(GameConstants.cloudServiceProviderDotXOffset, 12.0);
      });

      test('cloudServiceProviderDotYOffset is 12.0', () {
        expect(GameConstants.cloudServiceProviderDotYOffset, 12.0);
      });

      test('cloudServiceProviderDotRadius is 5.0', () {
        expect(GameConstants.cloudServiceProviderDotRadius, 5.0);
      });

      test('cloudServiceIconScaleDivisor is 40.0', () {
        expect(GameConstants.cloudServiceIconScaleDivisor, 40.0);
      });

      test('cloudIconHorizontalOffset is 5.0', () {
        expect(GameConstants.cloudIconHorizontalOffset, 5.0);
      });

      test('cloudIconMainRadius is 6.0', () {
        expect(GameConstants.cloudIconMainRadius, 6.0);
      });

      test('cloudIconTopYOffset is 3.0', () {
        expect(GameConstants.cloudIconTopYOffset, 3.0);
      });

      test('cloudIconTopRadius is 5.0', () {
        expect(GameConstants.cloudIconTopRadius, 5.0);
      });

      test('cloudIconRectHalfWidth is 10.0', () {
        expect(GameConstants.cloudIconRectHalfWidth, 10.0);
      });

      test('cloudIconRectHeight is 5.0', () {
        expect(GameConstants.cloudIconRectHeight, 5.0);
      });
    });

    // Animation constants
    group('animation constants', () {
      test('animationPeriod equals 2π', () {
        // Animation period should equal 2π (approximately 6.283185...)
        expect(GameConstants.animationPeriod, closeTo(6.283185, 0.000001));
      });

      test('animationPeriod equals pi times 2', () {
        // Verify the constant matches the mathematical value
        expect(
          GameConstants.animationPeriod,
          closeTo(3.141592653589793 * 2, 0.0000001),
        );
      });
    });

    // Gamepad key constants
    group('gamepad key constants', () {
      test('dpadUpKeys contains expected keys', () {
        expect(GameConstants.dpadUpKeys, contains('dpad up'));
        expect(GameConstants.dpadUpKeys, contains('up'));
        expect(GameConstants.dpadUpKeys.length, 2);
      });

      test('dpadDownKeys contains expected keys', () {
        expect(GameConstants.dpadDownKeys, contains('dpad down'));
        expect(GameConstants.dpadDownKeys, contains('down'));
        expect(GameConstants.dpadDownKeys.length, 2);
      });

      test('dpadLeftKeys contains expected keys', () {
        expect(GameConstants.dpadLeftKeys, contains('dpad left'));
        expect(GameConstants.dpadLeftKeys, contains('left'));
        expect(GameConstants.dpadLeftKeys.length, 2);
      });

      test('dpadRightKeys contains expected keys', () {
        expect(GameConstants.dpadRightKeys, contains('dpad right'));
        expect(GameConstants.dpadRightKeys, contains('right'));
        expect(GameConstants.dpadRightKeys.length, 2);
      });

      test('buttonSouthKeys contains expected keys', () {
        expect(GameConstants.buttonSouthKeys, contains('a'));
        expect(GameConstants.buttonSouthKeys, contains('button south'));
        expect(GameConstants.buttonSouthKeys, contains('cross'));
        expect(GameConstants.buttonSouthKeys.length, 3);
      });

      test('buttonEastKeys contains expected keys', () {
        expect(GameConstants.buttonEastKeys, contains('b'));
        expect(GameConstants.buttonEastKeys, contains('button east'));
        expect(GameConstants.buttonEastKeys, contains('circle'));
        expect(GameConstants.buttonEastKeys.length, 3);
      });

      test('buttonWestKeys contains expected keys', () {
        expect(GameConstants.buttonWestKeys, contains('x'));
        expect(GameConstants.buttonWestKeys, contains('button west'));
        expect(GameConstants.buttonWestKeys, contains('square'));
        expect(GameConstants.buttonWestKeys.length, 3);
      });

      test('buttonNorthKeys contains expected keys', () {
        expect(GameConstants.buttonNorthKeys, contains('y'));
        expect(GameConstants.buttonNorthKeys, contains('button north'));
        expect(GameConstants.buttonNorthKeys, contains('triangle'));
        expect(GameConstants.buttonNorthKeys.length, 3);
      });

      test('buttonStartKeys contains expected keys', () {
        expect(GameConstants.buttonStartKeys, contains('start'));
        expect(GameConstants.buttonStartKeys, contains('options'));
        expect(GameConstants.buttonStartKeys, contains('menu'));
        expect(GameConstants.buttonStartKeys.length, 3);
      });

      test('buttonSelectKeys contains expected keys', () {
        expect(GameConstants.buttonSelectKeys, contains('select'));
        expect(GameConstants.buttonSelectKeys, contains('back'));
        expect(GameConstants.buttonSelectKeys, contains('share'));
        expect(GameConstants.buttonSelectKeys.length, 3);
      });

      test('leftBumperKeys contains expected keys', () {
        expect(GameConstants.leftBumperKeys, contains('left bumper'));
        expect(GameConstants.leftBumperKeys, contains('lb'));
        expect(GameConstants.leftBumperKeys, contains('l1'));
        expect(GameConstants.leftBumperKeys.length, 3);
      });

      test('rightBumperKeys contains expected keys', () {
        expect(GameConstants.rightBumperKeys, contains('right bumper'));
        expect(GameConstants.rightBumperKeys, contains('rb'));
        expect(GameConstants.rightBumperKeys, contains('r1'));
        expect(GameConstants.rightBumperKeys.length, 3);
      });

      test('leftTriggerKeys contains expected keys', () {
        expect(GameConstants.leftTriggerKeys, contains('left trigger'));
        expect(GameConstants.leftTriggerKeys, contains('lt'));
        expect(GameConstants.leftTriggerKeys, contains('l2'));
        expect(GameConstants.leftTriggerKeys.length, 3);
      });

      test('rightTriggerKeys contains expected keys', () {
        expect(GameConstants.rightTriggerKeys, contains('right trigger'));
        expect(GameConstants.rightTriggerKeys, contains('rt'));
        expect(GameConstants.rightTriggerKeys, contains('r2'));
        expect(GameConstants.rightTriggerKeys.length, 3);
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

  group('parseEnum', () {
    test('returns value for valid enum name', () {
      expect(parseEnum(Gender.values, 'male', Gender.female), Gender.male);
    });

    test('returns value for another valid enum name', () {
      expect(parseEnum(Gender.values, 'female', Gender.male), Gender.female);
    });

    test('returns default for null name', () {
      expect(parseEnum(Gender.values, null, Gender.male), Gender.male);
    });

    test('returns default for invalid name', () {
      expect(
        parseEnum(Gender.values, 'invalid_gender', Gender.female),
        Gender.female,
      );
    });

    test('returns default for empty string', () {
      expect(parseEnum(Gender.values, '', Gender.male), Gender.male);
    });

    test('returns default for case mismatch', () {
      expect(parseEnum(Gender.values, 'MALE', Gender.female), Gender.female);
    });

    test('works with DeviceType enum', () {
      expect(
        parseEnum(DeviceType.values, 'server', DeviceType.router),
        DeviceType.server,
      );
    });

    test('works with RoomType enum', () {
      expect(
        parseEnum(RoomType.values, 'aws', RoomType.serverRoom),
        RoomType.aws,
      );
    });

    test('works with CloudProvider enum', () {
      expect(
        parseEnum(CloudProvider.values, 'gcp', CloudProvider.none),
        CloudProvider.gcp,
      );
    });

    test('returns default for typo in enum value', () {
      expect(
        parseEnum(DeviceType.values, 'servr', DeviceType.router),
        DeviceType.router,
      );
    });
  });

  group('parseDateTime', () {
    test('returns parsed DateTime for valid ISO 8601 string', () {
      final result = parseDateTime('2024-01-15T10:30:00.000Z', DateTime(2000));
      expect(result.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
      expect(result.hour, 10);
      expect(result.minute, 30);
    });

    test('returns default for null value', () {
      final defaultDate = DateTime(2000, 6, 15);
      final result = parseDateTime(null, defaultDate);
      expect(result, defaultDate);
    });

    test('returns default for empty string', () {
      final defaultDate = DateTime(2000, 6, 15);
      final result = parseDateTime('', defaultDate);
      expect(result, defaultDate);
    });

    test('returns default for invalid date string', () {
      final defaultDate = DateTime(2000, 6, 15);
      final result = parseDateTime('not-a-date', defaultDate);
      expect(result, defaultDate);
    });

    test('returns default for partial date string', () {
      final defaultDate = DateTime(2000, 6, 15);
      // 'abc-12-34' is truly invalid and can't be parsed
      final result = parseDateTime('abc-12-34', defaultDate);
      expect(result, defaultDate);
    });

    test('parses date without time', () {
      final result = parseDateTime('2024-01-15', DateTime(2000));
      expect(result.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
    });

    test('parses date with timezone offset', () {
      final result = parseDateTime('2024-01-15T10:30:00+05:00', DateTime(2000));
      expect(result.year, 2024);
    });
  });
}

class _Person {
  final String name;
  final int age;
  _Person(this.name, this.age);
}
