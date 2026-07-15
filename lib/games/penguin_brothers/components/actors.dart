import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../penguin_game.dart';
import '../penguin_logic.dart';
import 'tile_map.dart';

const double kGravity = 980;
const double kMoveSpeed = 120;
const double kJumpSpeed = 320;

abstract class Actor extends SpriteComponent {
  Actor({
    required super.sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  final Vector2 velocity = Vector2.zero();
  bool grounded = false;
  bool facingRight = true;
  bool dead = false;
  double invuln = 0;

  PenguinGame get game => findGame()! as PenguinGame;

  Rect get hitbox {
    final shrink = size * 0.2;
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x - shrink.x,
      height: size.y - shrink.y,
    );
  }

  void stepPhysics(double dt, TileMapComponent map, {double? bodyScale}) {
    final beforeY = velocity.y;
    velocity.y = (velocity.y + kGravity * dt).clamp(-600.0, 600.0);
    final bodyPos = position.clone();
    final bodyVel = Vector2(velocity.x * dt, velocity.y * dt);
    grounded = map.resolve(bodyPos, size * (bodyScale ?? 0.75), bodyVel);
    position.setFrom(bodyPos);
    if (grounded && beforeY >= 0) {
      velocity.y = 0;
    } else if (bodyVel.y.abs() < 0.0001 && velocity.y < 0) {
      velocity.y = 0;
    }
  }

  bool overlaps(Actor other) => hitbox.overlaps(other.hitbox);

  bool overlapsRect(Rect r) => hitbox.overlaps(r);
}

class PenguinPlayer extends Actor {
  PenguinPlayer({
    required this.isHuman,
    required this.isDonfi,
    required Sprite sprite,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(28, 28),
        );

  final bool isHuman;
  final bool isDonfi;

  bool holdingKey = false;
  bool longRangeBombs = false;
  double invincibleTimer = 0;
  double speedBoostTimer = 0;
  double bombCooldown = 0;
  double blink = 0;

  double get moveSpeed =>
      kMoveSpeed * (speedBoostTimer > 0 ? 1.45 : 1.0);

  bool get isInvincible => invincibleTimer > 0 || invuln > 0;

  void control(double moveX, bool jump, double dt) {
    if (dead) return;
    velocity.x = moveX * moveSpeed;
    if (moveX > 0.1) facingRight = true;
    if (moveX < -0.1) facingRight = false;
    if (jump && grounded) {
      velocity.y = -kJumpSpeed;
      grounded = false;
    }
  }

  void tickTimers(double dt) {
    if (bombCooldown > 0) bombCooldown -= dt;
    if (invincibleTimer > 0) invincibleTimer -= dt;
    if (speedBoostTimer > 0) speedBoostTimer -= dt;
    if (invuln > 0) invuln -= dt;
    blink += dt;
  }

  void takeHit() {
    if (dead || isInvincible) return;
    game.onPlayerHit(this);
  }

  void applyPower(PowerUpKind kind) {
    switch (kind) {
      case PowerUpKind.longRange:
        longRangeBombs = true;
      case PowerUpKind.invincibilityFish:
        invincibleTimer = 6;
      case PowerUpKind.speedSkates:
        speedBoostTimer = 8;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dead) return;
    tickTimers(dt);
    stepPhysics(dt, game.worldMap);
    scale.x = facingRight ? 1 : -1;
    opacity = (invuln > 0 && (blink * 12).floor().isOdd) ? 0.4 : 1;
  }

  @override
  void render(Canvas canvas) {
    if (holdingKey) {
      final paint = Paint()..color = const Color(0x88FFE566);
      canvas.drawCircle(Offset(size.x / 2, -4), 6, paint);
    }
    super.render(canvas);
  }
}

class EnemyActor extends Actor {
  EnemyActor({
    required this.kind,
    required Sprite sprite,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(26, 26),
        );

  final EnemyKind kind;
  double fireCooldown = 1.5 + Random().nextDouble();
  double patrolDir = 1;
  Rect? hazardRect;
  double hazardLife = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (dead) return;
    final map = game.worldMap;
    final players = game.livingPlayers;
    if (players.isEmpty) return;

    PenguinPlayer? nearest;
    var best = double.infinity;
    for (final p in players) {
      final d = p.position.distanceTo(position);
      if (d < best) {
        best = d;
        nearest = p;
      }
    }
    nearest!;

    switch (kind) {
      case EnemyKind.chaser:
        final dx = nearest.position.x - position.x;
        velocity.x = dx.sign * (kMoveSpeed * 0.55);
        facingRight = velocity.x >= 0;
        if (grounded && (dx.abs() < 20 || Random().nextDouble() < 0.01)) {
          // small hops over gaps feel livelier
        }
      case EnemyKind.fireSpitter:
        velocity.x = 0;
        facingRight = nearest.position.x >= position.x;
        fireCooldown -= dt;
        if (fireCooldown <= 0) {
          fireCooldown = 2.2;
          final dir = facingRight ? 1.0 : -1.0;
          hazardRect = Rect.fromLTWH(
            position.x + dir * 10,
            position.y - 10,
            36,
            20,
          );
          hazardLife = 0.45;
        }
      case EnemyKind.skittish:
        final bombNear = game.bombs.any(
          (b) => b.position.distanceTo(position) < 70,
        );
        if (bombNear) {
          final bomb = game.bombs.reduce(
            (a, b) => a.position.distanceTo(position) <
                    b.position.distanceTo(position)
                ? a
                : b,
          );
          velocity.x = (position.x - bomb.position.x).sign * kMoveSpeed * 0.9;
        } else {
          velocity.x = patrolDir * kMoveSpeed * 0.4;
          final footCol =
              ((position.x + patrolDir * 14) / kTileSize).floor();
          final footRow = ((position.y + size.y / 2 + 2) / kTileSize).floor();
          if (!map.isSolid(footCol, footRow) ||
              map.isSolid(
                ((position.x + patrolDir * 12) / kTileSize).floor(),
                (position.y / kTileSize).floor(),
              )) {
            patrolDir *= -1;
          }
        }
        facingRight = velocity.x >= 0;
    }

    stepPhysics(dt, map);
    scale.x = facingRight ? 1 : -1;

    if (hazardLife > 0) {
      hazardLife -= dt;
      if (hazardLife <= 0) hazardRect = null;
      if (hazardRect != null) {
        for (final p in players) {
          if (p.overlapsRect(hazardRect!)) p.takeHit();
        }
      }
    }

    for (final p in players) {
      if (overlaps(p)) p.takeHit();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (hazardRect != null && hazardLife > 0) {
      final local = hazardRect!.translate(-position.x + size.x / 2, -position.y + size.y / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(local, const Radius.circular(4)),
        Paint()..color = const Color(0xCCFF5722),
      );
    }
  }

  void die() {
    if (dead) return;
    dead = true;
    game.onEnemyKilled(this);
    removeFromParent();
  }
}

class BossActor extends Actor {
  BossActor({
    required Sprite sprite,
    required Vector2 position,
  }) : super(
          sprite: sprite,
          position: position,
          size: Vector2(64, 48),
        );

  int hp = 8;
  double attackTimer = 2;
  double telegraph = 0;
  double slamLife = 0;
  Rect? slamRect;

  @override
  void update(double dt) {
    super.update(dt);
    if (dead) return;
    final map = game.worldMap;
    final players = game.livingPlayers;

    // Slow patrol
    if (telegraph <= 0) {
      velocity.x = facingRight ? 40 : -40;
      if (position.x < 80) facingRight = true;
      if (position.x > map.size.x - 80) facingRight = false;
    } else {
      velocity.x = 0;
    }

    stepPhysics(dt, map, bodyScale: 0.8);
    scale.x = facingRight ? 1 : -1;

    attackTimer -= dt;
    if (telegraph > 0) {
      telegraph -= dt;
      if (telegraph <= 0) {
        slamRect = Rect.fromCenter(
          center: Offset(position.x, position.y + 8),
          width: 90,
          height: 40,
        );
        slamLife = 0.25;
        for (final p in players) {
          if (p.overlapsRect(slamRect!)) p.takeHit();
        }
      }
    } else if (attackTimer <= 0) {
      attackTimer = 2.8;
      telegraph = 0.7;
    }

    if (slamLife > 0) {
      slamLife -= dt;
      if (slamLife <= 0) slamRect = null;
    }

    for (final p in players) {
      if (overlaps(p)) p.takeHit();
    }
  }

  @override
  void render(Canvas canvas) {
    if (telegraph > 0) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        30 + telegraph * 20,
        Paint()..color = const Color(0x55FF0000),
      );
    }
    super.render(canvas);
  }

  void hit() {
    if (dead) return;
    hp--;
    invuln = 0.3;
    if (hp <= 0) {
      dead = true;
      game.onBossDefeated(this);
      removeFromParent();
    }
  }
}
