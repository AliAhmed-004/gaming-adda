import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../penguin_game.dart';
import '../penguin_logic.dart';
import 'actors.dart';
import 'tile_map.dart';

class BombActor extends SpriteComponent {
  BombActor({
    required Sprite sprite,
    required Vector2 position,
    required this.owner,
    required this.rules,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(22, 22),
          anchor: Anchor.center,
          priority: 5,
        );

  final PenguinPlayer owner;
  final BombRules rules;
  double fuse = 0;

  PenguinGame get game => findGame()! as PenguinGame;

  @override
  Future<void> onLoad() async {
    fuse = rules.fuseSeconds;
  }

  @override
  void update(double dt) {
    super.update(dt);
    fuse -= dt;
    final pulse = 1 + 0.08 * sin(fuse * 20);
    scale.setValues(pulse, pulse);
    if (fuse <= 0) {
      game.detonate(this);
      removeFromParent();
    }
  }
}

class ExplosionFx extends SpriteComponent {
  ExplosionFx({
    required Sprite sprite,
    required Vector2 position,
    required this.radiusTiles,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(kTileSize * (radiusTiles * 2 + 1), kTileSize * 1.2),
          anchor: Anchor.center,
          priority: 20,
        );

  final int radiusTiles;
  double life = 0.35;

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    scale *= 1 + dt * 0.8;
    if (life <= 0) removeFromParent();
  }
}

class BarrelActor extends SpriteComponent {
  BarrelActor({
    required Sprite sprite,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(26, 26),
          anchor: Anchor.center,
        );

  bool broken = false;

  PenguinGame get game => findGame()! as PenguinGame;

  void breakOpen() {
    if (broken) return;
    broken = true;
    game.spawnPowerUpAt(position.clone());
    removeFromParent();
  }
}

class KeyItem extends SpriteComponent {
  KeyItem({
    required Sprite sprite,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(24, 24),
          anchor: Anchor.center,
          priority: 4,
        );

  PenguinGame get game => findGame()! as PenguinGame;

  @override
  void update(double dt) {
    super.update(dt);
    angle = sin(DateTime.now().millisecondsSinceEpoch / 200) * 0.15;
    for (final p in game.livingPlayers) {
      if (p.hitbox.overlaps(
        Rect.fromCenter(
          center: Offset(position.x, position.y),
          width: size.x,
          height: size.y,
        ),
      )) {
        game.collectKey(p);
        removeFromParent();
        break;
      }
    }
  }
}

class ExitDoor extends SpriteComponent {
  ExitDoor({
    required Sprite sprite,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(36, 40),
          anchor: Anchor.center,
          priority: 1,
        );

  PenguinGame get game => findGame()! as PenguinGame;

  @override
  void update(double dt) {
    super.update(dt);
    opacity = game.progress.exitOpen ? 1 : 0.45;
    if (!game.progress.exitOpen) return;
    for (final p in game.livingPlayers) {
      if (!p.holdingKey) continue;
      final door = Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: size.x * 0.7,
        height: size.y * 0.7,
      );
      if (p.hitbox.overlaps(door)) {
        game.onReachedExit(p);
        break;
      }
    }
  }
}

class FruitItem extends SpriteComponent {
  FruitItem({
    required Sprite sprite,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(20, 20),
          anchor: Anchor.center,
        );

  PenguinGame get game => findGame()! as PenguinGame;

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in game.livingPlayers) {
      if (p.hitbox.overlaps(
        Rect.fromCenter(
          center: Offset(position.x, position.y),
          width: size.x,
          height: size.y,
        ),
      )) {
        game.collectFruit();
        removeFromParent();
        break;
      }
    }
  }
}

class PowerUpItem extends SpriteComponent {
  PowerUpItem({
    required Sprite sprite,
    required Vector2 position,
    required this.kind,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(22, 22),
          anchor: Anchor.center,
          priority: 4,
        );

  final PowerUpKind kind;

  PenguinGame get game => findGame()! as PenguinGame;

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in game.livingPlayers) {
      if (p.hitbox.overlaps(
        Rect.fromCenter(
          center: Offset(position.x, position.y),
          width: size.x,
          height: size.y,
        ),
      )) {
        p.applyPower(kind);
        game.sounds.pickup();
        removeFromParent();
        break;
      }
    }
  }
}

class ComboPopup extends TextComponent {
  ComboPopup({
    required String text,
    required Vector2 position,
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          priority: 50,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFE566),
              shadows: [Shadow(color: Color(0xFF000000), blurRadius: 3)],
            ),
          ),
        );

  double life = 0.9;

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position.y -= 30 * dt;
    if (life <= 0) removeFromParent();
  }
}
