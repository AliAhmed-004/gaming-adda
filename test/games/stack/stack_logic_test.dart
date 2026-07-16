import 'package:gaming_adda/games/stack/stack_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StackBlock.place', () {
    test('perfect placement snaps to target dimensions', () {
      final base = StackBlock();
      final moving = StackBlock(target: base);
      moving.position.z = base.position.z;

      final result = moving.place();

      expect(result.missed, isFalse);
      expect(result.bonus, isTrue);
      expect(result.choppedDimensions, isNull);
      expect(moving.dimension.width, base.dimension.width);
      expect(moving.dimension.depth, base.dimension.depth);
    });

    test('partial overlap trims the working dimension', () {
      final base = StackBlock();
      final moving = StackBlock(target: base);
      moving.position.z = base.position.z + 2;

      final result = moving.place();

      expect(result.missed, isFalse);
      expect(result.bonus, isFalse);
      expect(result.placedDimensions, isNotNull);
      expect(result.choppedDimensions, isNotNull);
      expect(result.placedDimensions!.depth, lessThan(base.dimension.depth));
      expect(result.choppedDimensions!.depth, greaterThan(0));
      expect(
        result.placedDimensions!.depth + result.choppedDimensions!.depth,
        closeTo(base.dimension.depth, 0.001),
      );
    });

    test('zero overlap marks block as missed', () {
      final base = StackBlock();
      final moving = StackBlock(target: base);
      moving.position.z = base.position.z + base.dimension.depth + 1;

      final result = moving.place();

      expect(result.missed, isTrue);
      expect(moving.state, StackBlockState.missed);
    });
  });

  group('StackBlock speed', () {
    test('caps speed at -4 for high indexes', () {
      expect(StackBlock.cappedSpeed(800), -4);
      expect(StackBlock.cappedSpeed(10), greaterThan(-4));
    });
  });

  group('StackGame', () {
    test('score equals number of placed blocks above the base', () {
      final game = StackGame();
      expect(game.score, 0);
      game.addBlock();
      expect(game.score, 1);
    });
  });
}
