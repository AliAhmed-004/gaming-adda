import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:three_js/three_js.dart' as three;

import 'stack_logic.dart';
import 'stack_stage.dart';
import 'stack_tween.dart';

class StackGameController extends ChangeNotifier {
  StackGameController() {
    _stage = StackStage(
      onReady: _handleStageReady,
      onTick: _handleTick,
    );
    _stage.init();
  }

  late final StackStage _stage;
  final StackGame _game = StackGame();
  final StackTweenRunner _tweens = StackTweenRunner();

  three.Mesh? _activeMesh;
  int _displayScore = 0;
  bool _restartScheduled = false;

  StackGameState get state => _game.state;
  int get displayScore => _displayScore;
  bool get hideInstructions => _game.hideInstructions;
  bool get stageReady => _stage.ready;
  StackStage get stage => _stage;

  void _handleStageReady() {
    _game.setState(StackGameState.ready);
    _syncBaseBlockMesh();
    _displayScore = 0;
    notifyListeners();
  }

  void _handleTick(double dt) {
    _tweens.update(dt);
    final active = _game.activeBlock;
    if (active != null && active.state == StackBlockState.active) {
      active.tick();
      _syncActiveMesh(active);
    }
  }

  void onAction() {
    switch (_game.state) {
      case StackGameState.ready:
        startGame();
      case StackGameState.playing:
        placeBlock();
      case StackGameState.ended:
        restartGame();
      case StackGameState.loading:
      case StackGameState.resetting:
        break;
    }
  }

  void startGame() {
    if (_game.state == StackGameState.playing) return;
    _displayScore = 0;
    _game.setState(StackGameState.playing);
    _addBlock();
    notifyListeners();
  }

  void placeBlock() {
    if (_game.state != StackGameState.playing) return;

    final current = _game.activeBlock;
    if (current == null) return;

    final result = _game.placeCurrentBlock();
    if (result == null) return;

    if (_activeMesh != null) {
      _stage.newBlocks.remove(_activeMesh!);
      _activeMesh = null;
    }

    if (result.missed) {
      endGame();
      return;
    }

    final placed = result.placedDimensions!;
    final placedPos = result.placedPosition!;
    final placedMesh = _stage.createMesh(
      dimensions: placed,
      position: placedPos,
      colorHex: current.colorHex,
    );
    _stage.placedBlocks.add(placedMesh);

    if (result.choppedDimensions != null && result.choppedPosition != null) {
      final choppedMesh = _stage.createMesh(
        dimensions: result.choppedDimensions!,
        position: result.choppedPosition!,
        colorHex: current.colorHex,
      );
      _stage.choppedBlocks.add(choppedMesh);
      _animateChoppedBlock(
        choppedMesh,
        result.plane,
        result.direction,
        placedPos,
      );
    }

    if (!_game.addBlock()) {
      endGame();
      return;
    }

    _displayScore = _game.score;
    _spawnActiveMesh();
    _stage.setCameraY(_game.blocks.length * 2.0, 0.3, _tweens);
    notifyListeners();
  }

  void _animateChoppedBlock(
    three.Mesh chopped,
    StackAxis plane,
    double direction,
    StackPosition placedPosition,
  ) {
    const rotateRandomness = 10.0;
    final axis = plane == StackAxis.x ? 'x' : 'z';
    final chopAxisValue = axis == 'x' ? chopped.position.x : chopped.position.z;
    final placedAxisValue =
        axis == 'x' ? placedPosition.x : placedPosition.z;
    final slide = 40 * direction.abs() * (direction.sign == 0 ? 1 : direction.sign);

    final targetY = chopped.position.y - 30;
    final startY = chopped.position.y;
    final startAxis = chopAxisValue;
    final targetAxis = chopAxisValue > placedAxisValue
        ? startAxis + slide
        : startAxis - slide;

    final rotX = plane == StackAxis.z
        ? (math.Random().nextDouble() * rotateRandomness) - rotateRandomness / 2
        : 0.1;
    final rotZ = plane == StackAxis.x
        ? (math.Random().nextDouble() * rotateRandomness) - rotateRandomness / 2
        : 0.1;
    final rotY = math.Random().nextDouble() * 0.1;
    final startRotX = chopped.rotation.x;
    final startRotY = chopped.rotation.y;
    final startRotZ = chopped.rotation.z;

    _tweens.add(
      StackTween(
        from: 0,
        to: 1,
        duration: 1,
        delay: 0.05,
        onUpdate: (t) {
          chopped.position.y = startY + (targetY - startY) * t;
          if (axis == 'x') {
            chopped.position.x = startAxis + (targetAxis - startAxis) * t;
          } else {
            chopped.position.z = startAxis + (targetAxis - startAxis) * t;
          }
          chopped.rotation.x = startRotX + rotX * t;
          chopped.rotation.y = startRotY + rotY * t;
          chopped.rotation.z = startRotZ + rotZ * t;
        },
        onComplete: () => _stage.choppedBlocks.remove(chopped),
      ),
    );
  }

  void endGame() {
    _game.setState(StackGameState.ended);
    notifyListeners();
  }

  void restartGame() {
    if (_restartScheduled) return;
    _game.setState(StackGameState.resetting);
    notifyListeners();

    final oldBlocks = List<three.Object3D>.from(_stage.placedBlocks.children);
    const removeSpeed = 0.2;
    const delayAmount = 0.02;

    for (var i = 0; i < oldBlocks.length; i++) {
      final mesh = oldBlocks[i];
      final delay = (oldBlocks.length - i) * delayAmount;
      final startScaleX = mesh.scale.x;
      final startScaleY = mesh.scale.y;
      final startScaleZ = mesh.scale.z;
      final startRotY = mesh.rotation.y;

      _tweens.add(
        StackTween(
          from: 0,
          to: 1,
          duration: removeSpeed,
          delay: delay,
          ease: StackEase.easeIn,
          onUpdate: (t) {
            final scale = 1 - t;
            mesh.scale.setValues(
              startScaleX * scale,
              startScaleY * scale,
              startScaleZ * scale,
            );
            mesh.rotation.y = startRotY + 0.5 * t;
          },
          onComplete: () => _stage.placedBlocks.remove(mesh),
        ),
      );
    }

    final cameraMoveSpeed = removeSpeed * 2 + oldBlocks.length * delayAmount;
    _stage.setCameraY(2, cameraMoveSpeed, _tweens);

    final countdownStart = _game.blocks.length - 1.0;
    _tweens.add(
      StackTween(
        from: countdownStart,
        to: 0,
        duration: cameraMoveSpeed,
        onUpdate: (value) {
          _displayScore = value.round();
          notifyListeners();
        },
      ),
    );

    if (_activeMesh != null) {
      _stage.newBlocks.remove(_activeMesh!);
      _activeMesh = null;
    }
    _stage.choppedBlocks.clear();

    _game.trimToBase();
    _restartScheduled = true;

    _tweens.add(
      StackTween(
        from: 0,
        to: 1,
        duration: cameraMoveSpeed,
        onComplete: () {
          _restartScheduled = false;
          _syncBaseBlockMesh();
          startGame();
        },
      ),
    );
  }

  /// Builds a plausible mid-game tower by programmatically placing blocks
  /// slightly off-center. Used by the `?game=stack&demo=1` screenshot deep
  /// link, where frame-based tap timing is unreliable.
  Future<void> runDemoTower(int count) async {
    if (_game.state != StackGameState.ready) return;
    startGame();
    final random = math.Random(7);
    for (var i = 0; i < count; i++) {
      await Future.delayed(const Duration(milliseconds: 450));
      final active = _game.activeBlock;
      if (active == null || active.state != StackBlockState.active) break;
      final target = active.targetBlock!;
      final offset = (random.nextDouble() - 0.5) * 1.6;
      active.position.x = target.position.x;
      active.position.z = target.position.z;
      if (active.workingPlane == StackAxis.x) {
        active.position.x += offset;
      } else {
        active.position.z += offset;
      }
      placeBlock();
    }
  }

  void _addBlock() {
    if (!_game.addBlock()) {
      endGame();
      return;
    }
    _displayScore = _game.score;
    _spawnActiveMesh();
    _stage.setCameraY(_game.blocks.length * 2.0, 0.3, _tweens);
  }

  void _syncBaseBlockMesh() {
    _stage.placedBlocks.clear();
    final base = _game.blocks.first;
    final mesh = _stage.createMesh(
      dimensions: base.dimension,
      position: base.position,
      colorHex: base.colorHex,
    );
    _stage.placedBlocks.add(mesh);
  }

  void _spawnActiveMesh() {
    final active = _game.activeBlock;
    if (active == null || active.state != StackBlockState.active) return;

    _activeMesh = _stage.createMesh(
      dimensions: active.dimension,
      position: active.position,
      colorHex: active.colorHex,
    );
    _stage.newBlocks.add(_activeMesh!);
  }

  void _syncActiveMesh(StackBlock active) {
    if (_activeMesh == null) return;
    _activeMesh!.position.setValues(
      active.position.x,
      active.position.y,
      active.position.z,
    );
  }

  @override
  void dispose() {
    _stage.dispose();
    super.dispose();
  }
}
