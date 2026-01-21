import 'package:flutter_test/flutter_test.dart';
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

    group('squaredDistanceTo', () {
      test('returns 0 for same position', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(3, 5);
        expect(a.squaredDistanceTo(b), 0);
      });

      test('returns squared distance', () {
        const a = GridPosition(0, 0);
        const b = GridPosition(3, 4);
        // 3^2 + 4^2 = 9 + 16 = 25
        expect(a.squaredDistanceTo(b), 25);
      });

      test('is symmetric', () {
        const a = GridPosition(1, 2);
        const b = GridPosition(4, 6);
        expect(a.squaredDistanceTo(b), b.squaredDistanceTo(a));
      });
    });

    group('distanceTo', () {
      test('returns 0 for same position', () {
        const a = GridPosition(3, 5);
        const b = GridPosition(3, 5);
        expect(a.distanceTo(b), 0);
      });

      test('returns Euclidean distance', () {
        const a = GridPosition(0, 0);
        const b = GridPosition(3, 4);
        // sqrt(3^2 + 4^2) = sqrt(25) = 5
        expect(a.distanceTo(b), 5);
      });

      test('is symmetric', () {
        const a = GridPosition(1, 2);
        const b = GridPosition(4, 6);
        expect(a.distanceTo(b), b.distanceTo(a));
      });

      test('returns correct distance for diagonal', () {
        const a = GridPosition(0, 0);
        const b = GridPosition(1, 1);
        // sqrt(1^2 + 1^2) = sqrt(2) ≈ 1.414
        expect(a.distanceTo(b), closeTo(1.414, 0.001));
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

  group('GridOccupancy', () {
    // Test implementation using a simple mock class
    late _TestGridOccupancy subject;

    group('occupiedCells', () {
      test('returns single cell for 1x1 object', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(5, 5),
          width: 1,
          height: 1,
        );

        expect(subject.occupiedCells, [const GridPosition(5, 5)]);
      });

      test('returns all cells for 2x2 object', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(3, 4),
          width: 2,
          height: 2,
        );

        expect(subject.occupiedCells, [
          const GridPosition(3, 4),
          const GridPosition(3, 5),
          const GridPosition(4, 4),
          const GridPosition(4, 5),
        ]);
      });

      test('returns all cells for wide object (3x1)', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(0, 0),
          width: 3,
          height: 1,
        );

        expect(subject.occupiedCells, [
          const GridPosition(0, 0),
          const GridPosition(1, 0),
          const GridPosition(2, 0),
        ]);
      });

      test('returns all cells for tall object (1x3)', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(2, 2),
          width: 1,
          height: 3,
        );

        expect(subject.occupiedCells, [
          const GridPosition(2, 2),
          const GridPosition(2, 3),
          const GridPosition(2, 4),
        ]);
      });

      test('returns empty list for zero dimensions', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(5, 5),
          width: 0,
          height: 0,
        );

        expect(subject.occupiedCells, isEmpty);
      });
    });

    group('occupiesCell', () {
      test('returns true for cell at position', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(5, 5),
          width: 1,
          height: 1,
        );

        expect(subject.occupiesCell(const GridPosition(5, 5)), isTrue);
      });

      test('returns false for cell outside object', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(5, 5),
          width: 1,
          height: 1,
        );

        expect(subject.occupiesCell(const GridPosition(4, 5)), isFalse);
        expect(subject.occupiesCell(const GridPosition(6, 5)), isFalse);
        expect(subject.occupiesCell(const GridPosition(5, 4)), isFalse);
        expect(subject.occupiesCell(const GridPosition(5, 6)), isFalse);
      });

      test('returns true for all cells in 2x2 object', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(3, 4),
          width: 2,
          height: 2,
        );

        expect(subject.occupiesCell(const GridPosition(3, 4)), isTrue);
        expect(subject.occupiesCell(const GridPosition(4, 4)), isTrue);
        expect(subject.occupiesCell(const GridPosition(3, 5)), isTrue);
        expect(subject.occupiesCell(const GridPosition(4, 5)), isTrue);
      });

      test('returns false for cells adjacent to 2x2 object', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(3, 4),
          width: 2,
          height: 2,
        );

        // Left edge
        expect(subject.occupiesCell(const GridPosition(2, 4)), isFalse);
        // Right edge
        expect(subject.occupiesCell(const GridPosition(5, 4)), isFalse);
        // Top edge
        expect(subject.occupiesCell(const GridPosition(3, 3)), isFalse);
        // Bottom edge
        expect(subject.occupiesCell(const GridPosition(3, 6)), isFalse);
      });

      test('handles object at origin', () {
        subject = _TestGridOccupancy(
          position: const GridPosition(0, 0),
          width: 2,
          height: 2,
        );

        expect(subject.occupiesCell(const GridPosition(0, 0)), isTrue);
        expect(subject.occupiesCell(const GridPosition(1, 1)), isTrue);
        expect(subject.occupiesCell(const GridPosition(-1, 0)), isFalse);
        expect(subject.occupiesCell(const GridPosition(0, -1)), isFalse);
      });
    });
  });
}

/// Test implementation of GridOccupancy mixin
class _TestGridOccupancy with GridOccupancy {
  @override
  final GridPosition position;
  @override
  final int width;
  @override
  final int height;

  _TestGridOccupancy({
    required this.position,
    required this.width,
    required this.height,
  });
}
