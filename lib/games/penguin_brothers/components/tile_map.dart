import 'dart:ui';

import 'package:flame/components.dart';

import '../levels/level_defs.dart';
import '../penguin_logic.dart';

const double kTileSize = 32;

class TileMapComponent extends PositionComponent {
  TileMapComponent({
    required this.level,
    required this.sprites,
  }) : super(
          size: Vector2(
            level.width * kTileSize,
            level.height * kTileSize,
          ),
        );

  final LevelDef level;
  final Map<TileKind, Sprite> sprites;

  late List<List<TileKind>> grid;

  @override
  Future<void> onLoad() async {
    grid = List.generate(
      level.height,
      (r) => List.generate(level.width, (c) {
        final ch = level.rows[r][c];
        return solidTileFromChar(ch) ?? TileKind.empty;
      }),
    );
  }

  bool inBounds(int col, int row) =>
      col >= 0 && row >= 0 && col < level.width && row < level.height;

  bool isSolid(int col, int row) {
    if (!inBounds(col, row)) return true;
    final t = grid[row][col];
    return t != TileKind.empty;
  }

  bool isBreakable(int col, int row) =>
      inBounds(col, row) && grid[row][col] == TileKind.breakable;

  void clearCell(int col, int row) {
    if (inBounds(col, row)) grid[row][col] = TileKind.empty;
  }

  (int, int) worldToCell(Vector2 world) {
    final col = (world.x / kTileSize).floor();
    final row = (world.y / kTileSize).floor();
    return (col, row);
  }

  Vector2 cellCenter(int col, int row) => Vector2(
        col * kTileSize + kTileSize / 2,
        row * kTileSize + kTileSize / 2,
      );

  Rect cellRect(int col, int row) => Rect.fromLTWH(
        col * kTileSize,
        row * kTileSize,
        kTileSize,
        kTileSize,
      );

  /// Resolve axis-aligned body against solid tiles. Returns grounded.
  bool resolve(Vector2 position, Vector2 size, Vector2 velocity) {
    var grounded = false;
    final half = size / 2;

    // Horizontal
    position.x += velocity.x;
    var left = position.x - half.x;
    var right = position.x + half.x;
    var top = position.y - half.y;
    var bottom = position.y + half.y;

    final minCol = (left / kTileSize).floor();
    final maxCol = (right / kTileSize).floor();
    final minRow = (top / kTileSize).floor();
    final maxRow = (bottom / kTileSize).floor();

    for (var r = minRow; r <= maxRow; r++) {
      for (var c = minCol; c <= maxCol; c++) {
        if (!isSolid(c, r)) continue;
        final tile = cellRect(c, r);
        if (velocity.x > 0 && right > tile.left && left < tile.left) {
          position.x = tile.left - half.x;
          velocity.x = 0;
          right = position.x + half.x;
          left = position.x - half.x;
        } else if (velocity.x < 0 && left < tile.right && right > tile.right) {
          position.x = tile.right + half.x;
          velocity.x = 0;
          right = position.x + half.x;
          left = position.x - half.x;
        }
      }
    }

    // Vertical
    position.y += velocity.y;
    left = position.x - half.x;
    right = position.x + half.x;
    top = position.y - half.y;
    bottom = position.y + half.y;

    final minCol2 = (left / kTileSize).floor();
    final maxCol2 = (right / kTileSize).floor();
    final minRow2 = (top / kTileSize).floor();
    final maxRow2 = (bottom / kTileSize).floor();

    for (var r = minRow2; r <= maxRow2; r++) {
      for (var c = minCol2; c <= maxCol2; c++) {
        if (!isSolid(c, r)) continue;
        final tile = cellRect(c, r);
        if (velocity.y > 0 && bottom > tile.top && top < tile.top) {
          position.y = tile.top - half.y;
          velocity.y = 0;
          grounded = true;
          bottom = position.y + half.y;
          top = position.y - half.y;
        } else if (velocity.y < 0 && top < tile.bottom && bottom > tile.bottom) {
          position.y = tile.bottom + half.y;
          velocity.y = 0;
          bottom = position.y + half.y;
          top = position.y - half.y;
        }
      }
    }
    return grounded;
  }

  @override
  void render(Canvas canvas) {
    for (var r = 0; r < level.height; r++) {
      for (var c = 0; c < level.width; c++) {
        final kind = grid[r][c];
        if (kind == TileKind.empty) continue;
        final sprite = sprites[kind];
        if (sprite == null) continue;
        sprite.render(
          canvas,
          position: Vector2(c * kTileSize, r * kTileSize),
          size: Vector2(kTileSize, kTileSize),
        );
      }
    }
  }
}
