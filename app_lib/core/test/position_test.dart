import 'package:test/test.dart';
import 'package:app_lib_core/app_lib_core.dart';

void main() {
  group('GridPosition', () {
    group('constructors', () {
      test('creates with x and y', () {
        const pos = GridPosition(3, 5);
        expect(pos.x, 3);
        expect(pos.y, 5);
      });

      test('zero creates position at origin', () {
        const pos = GridPosition.zero();
        expect(pos.x, 0);
        expect(pos.y, 0);
      });
    });

    group('copyWith', () {
      test('copies with new x', () {
        const original = GridPosition(3, 5);
        final copy = original.copyWith(x: 10);
        expect(copy.x, 10);
        expect(copy.y, 5);
      });

      test('copies with new y', () {
        const original = GridPosition(3, 5);
        final copy = original.copyWith(y: 10);
        expect(copy.x, 3);
        expect(copy.y, 10);
      });

      test('copies with both x and y', () {
        const original = GridPosition(3, 5);
        final copy = original.copyWith(x: 10, y: 20);
        expect(copy.x, 10);
        expect(copy.y, 20);
      });

      test('preserves values when no changes', () {
        const original = GridPosition(3, 5);
        final copy = original.copyWith();
        expect(copy, original);
      });
    });

    group('operators', () {
      test('addition works correctly', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(2, 4);
        final result = a + b;
        expect(result.x, 5);
        expect(result.y, 9);
      });

      test('subtraction works correctly', () {
        const a = GridPosition(5, 8);
        const b = GridPosition(2, 3);
        final result = a - b;
        expect(result.x, 3);
        expect(result.y, 5);
      });

      test('addition with negative values', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(-2, -4);
        final result = a + b;
        expect(result.x, 1);
        expect(result.y, 1);
      });
    });

    group('distanceTo', () {
      test('returns 0 for same position', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(3, 5);
        expect(a.distanceTo(b), 0);
      });

      test('returns squared distance', () {
        const a = GridPosition(0, 0);
        const b = GridPosition(3, 4);
        // 3^2 + 4^2 = 9 + 16 = 25
        expect(a.distanceTo(b), 25);
      });

      test('is symmetric', () {
        const a = GridPosition(1, 2);
        const b = GridPosition(4, 6);
        expect(a.distanceTo(b), b.distanceTo(a));
      });
    });

    group('isAdjacentTo', () {
      test('returns false for same position', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(3, 5);
        expect(a.isAdjacentTo(b), isFalse);
      });

      test('returns true for horizontally adjacent', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(4, 5);
        expect(a.isAdjacentTo(b), isTrue);
      });

      test('returns true for vertically adjacent', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(3, 6);
        expect(a.isAdjacentTo(b), isTrue);
      });

      test('returns true for diagonally adjacent', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(4, 6);
        expect(a.isAdjacentTo(b), isTrue);
      });

      test('returns false for two cells away', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(5, 5);
        expect(a.isAdjacentTo(b), isFalse);
      });

      test('is symmetric', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(4, 6);
        expect(a.isAdjacentTo(b), b.isAdjacentTo(a));
      });
    });

    group('JSON serialization', () {
      test('toJson returns correct map', () {
        const pos = GridPosition(3, 5);
        expect(pos.toJson(), {'x': 3, 'y': 5});
      });

      test('fromJson creates correct position', () {
        final pos = GridPosition.fromJson({'x': 3, 'y': 5});
        expect(pos.x, 3);
        expect(pos.y, 5);
      });

      test('round trip preserves values', () {
        const original = GridPosition(7, 11);
        final json = original.toJson();
        final restored = GridPosition.fromJson(json);
        expect(restored, original);
      });
    });

    group('equality', () {
      test('equal positions are equal', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(3, 5);
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different positions are not equal', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(3, 6);
        expect(a, isNot(b));
      });
    });

    group('toString', () {
      test('returns readable format', () {
        const pos = GridPosition(3, 5);
        expect(pos.toString(), 'GridPosition(3, 5)');
      });
    });
  });
}
