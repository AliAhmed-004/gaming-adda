import 'dart:math';

import 'package:flame/components.dart';

import 'components/actors.dart';
import 'components/bombs_and_items.dart';
import 'components/tile_map.dart';
import 'penguin_game.dart';
import 'penguin_logic.dart';

/// Simple AI partner (Turu): chase enemies, avoid blasts, grab key, go exit.
class PenguinAi {
  PenguinAi({Random? random}) : _rng = random ?? Random();

  final Random _rng;
  double _bombCd = 0;
  double _jumpCd = 0;

  void update(PenguinGame game, PenguinPlayer bot, double dt) {
    if (bot.dead) return;
    _bombCd = max(0, _bombCd - dt);
    _jumpCd = max(0, _jumpCd - dt);

    final map = game.worldMap;
    var moveX = 0.0;
    var jump = false;
    var throwBomb = false;

    // Avoid imminent bombs
    BombActor? danger;
    for (final b in game.bombs) {
      if (b.fuse < 0.55 && b.position.distanceTo(bot.position) < 70) {
        danger = b;
        break;
      }
    }
    if (danger != null) {
      moveX = (bot.position.x - danger.position.x).sign;
      if (_jumpCd <= 0 && bot.grounded) {
        jump = true;
        _jumpCd = 0.4;
      }
      bot.control(moveX, jump, dt);
      return;
    }

    // Carry key to exit
    if (bot.holdingKey && game.exitDoor != null) {
      final target = game.exitDoor!.position;
      moveX = (target.x - bot.position.x).sign;
      if ((target.y < bot.position.y - 8) && bot.grounded && _jumpCd <= 0) {
        jump = true;
        _jumpCd = 0.5;
      }
      bot.control(moveX, jump, dt);
      return;
    }

    // Grab key
    if (game.keyItem != null &&
        game.progress.phase == StagePhase.keyAvailable &&
        !game.progress.keyCollected) {
      final key = game.keyItem!;
      moveX = (key.position.x - bot.position.x).sign;
      if ((key.position.y < bot.position.y - 8) &&
          bot.grounded &&
          _jumpCd <= 0) {
        jump = true;
        _jumpCd = 0.5;
      }
      bot.control(moveX, jump, dt);
      return;
    }

    // Chase nearest enemy / boss
    Vector2? target;
    var best = double.infinity;
    for (final e in game.enemies) {
      final d = e.position.distanceTo(bot.position);
      if (d < best) {
        best = d;
        target = e.position;
      }
    }
    if (game.boss != null && !game.boss!.dead) {
      final d = game.boss!.position.distanceTo(bot.position);
      if (d < best) {
        best = d;
        target = game.boss!.position;
      }
    }

    if (target != null) {
      moveX = (target.x - bot.position.x).sign;
      final dist = best;
      if (dist < 70 && _bombCd <= 0 && bot.bombCooldown <= 0) {
        // Face target then bomb
        bot.facingRight = target.x >= bot.position.x;
        throwBomb = true;
        _bombCd = 1.2;
      }
      // Jump toward higher targets / gaps
      final aheadCol = ((bot.position.x + moveX * 18) / kTileSize).floor();
      final footRow = ((bot.position.y + bot.size.y / 2 + 2) / kTileSize)
          .floor();
      if (!map.isSolid(aheadCol, footRow) && bot.grounded && _jumpCd <= 0) {
        jump = true;
        _jumpCd = 0.55;
      } else if (target.y + 10 < bot.position.y &&
          bot.grounded &&
          _jumpCd <= 0 &&
          _rng.nextDouble() < 0.02) {
        jump = true;
        _jumpCd = 0.6;
      }
    } else {
      // Idle wander
      moveX = _rng.nextBool() ? 0.3 : -0.3;
    }

    bot.control(moveX, jump, dt);
    if (throwBomb) game.tryThrowBomb(bot);
  }
}
