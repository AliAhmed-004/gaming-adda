import 'dart:async';

import 'package:flutter/foundation.dart';

import 'block_race_ai.dart';
import 'block_race_config.dart';
import 'block_race_logic.dart';
import 'block_race_stage.dart';
import 'block_race_theme.dart';
import 'block_race_tween.dart';

class BlockRaceGameController extends ChangeNotifier {
  BlockRaceGameController({required this.config}) {
    _ai = BlockRaceAi(difficulty: config.difficulty);
    _stage = BlockRaceStage(
      onReady: _handleStageReady,
      onTick: _handleTick,
    );
    _stage.init();
  }

  final BlockRaceConfig config;
  late final BlockRaceAi _ai;
  late final BlockRaceStage _stage;
  final BlockRaceGame _game = BlockRaceGame();
  final BlockRaceTweenRunner _tweens = BlockRaceTweenRunner();

  bool _stageReady = false;
  bool _isBusy = false;
  int _displayDice = 1;
  bool _diceRolling = false;

  BlockRaceGame get game => _game;
  BlockRaceStage get stage => _stage;
  bool get stageReady => _stageReady;
  int get displayDice => _displayDice;
  bool get diceRolling => _diceRolling;
  bool get isBusy => _isBusy || _tweens.isAnimating;

  bool get isHumanTurn {
    if (config.mode == BlockRacePlayMode.localTwoPlayer) return true;
    return _game.currentPlayer == BlockRacePlayer.blue;
  }

  void _handleStageReady() {
    _stageReady = true;
    _game.phase = BlockRacePhase.ready;
    notifyListeners();
  }

  void _handleTick(double dt) {
    _tweens.update(dt);
  }

  void startGame() {
    if (!_stageReady || _isBusy) return;
    _game.startGame();
    notifyListeners();
  }

  Future<void> rollDice() async {
    if (!_stageReady || _isBusy) return;
    if (_game.phase != BlockRacePhase.rolling) return;
    if (!isHumanTurn && config.mode == BlockRacePlayMode.vsComputer) return;

    _isBusy = true;
    _diceRolling = true;
    notifyListeners();

    for (var i = 0; i < 8; i++) {
      _displayDice = _game.rollDice();
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }
    _displayDice = _game.rollDice();
    _game.diceValue = _displayDice;
    _diceRolling = false;
    _game.handleRollComplete();
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _resolveMove();
  }

  Future<void> _resolveMove() async {
    final player = _game.currentPlayer;
    final result = _game.applyMove();

    if (result == null) {
      _stage.syncPawnPositions(
        _game.pawnCell(BlockRacePlayer.blue),
        _game.pawnCell(BlockRacePlayer.red),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _game.finishAnimations();
      _isBusy = false;
      notifyListeners();
      await _maybeRunAiTurn();
      return;
    }

    final path = BlockRaceGame.pathFor(player);
    final steps = path.sublist(result.fromIndex, result.toIndex + 1);

    final moveDone = Completer<void>();
    _stage.animatePawnMove(
      player: player,
      steps: steps,
      tweens: _tweens,
      onComplete: moveDone.complete,
    );
    await moveDone.future;

    if (result.capturedOpponent) {
      final opponent = player == BlockRacePlayer.blue
          ? BlockRacePlayer.red
          : BlockRacePlayer.blue;
      final captureSteps = [
        path[result.toIndex],
        BlockRaceGame.pathFor(opponent).first,
      ];
      final captureDone = Completer<void>();
      _stage.animatePawnMove(
        player: opponent,
        steps: captureSteps,
        tweens: _tweens,
        onComplete: captureDone.complete,
      );
      await captureDone.future;
    }

    if (result.won) {
      _isBusy = false;
      notifyListeners();
      return;
    }

    if (_game.phase == BlockRacePhase.placingBarricade) {
      _isBusy = false;
      notifyListeners();
      if (!isHumanTurn) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await _aiPlaceBarricade();
      }
      return;
    }

    await _finishTurn();
  }

  Future<void> placeBarricade(BlockRaceCell cell) async {
    if (_isBusy || _game.phase != BlockRacePhase.placingBarricade) return;
    if (!isHumanTurn) return;
    if (!_game.placeBarricade(cell)) return;

    _isBusy = true;
    notifyListeners();
    _stage.addBarricade(cell, _tweens);
    _stage.pulseTile(cell, _tweens);
    await Future<void>.delayed(
      Duration(
        milliseconds:
            (BlockRaceTheme.barricadeAnimationDuration * 1000).round() + 100,
      ),
    );
    await _finishTurn();
  }

  Future<void> skipBarricade() async {
    if (_isBusy || _game.phase != BlockRacePhase.placingBarricade) return;
    if (!isHumanTurn) return;
    _game.skipBarricade();
    _isBusy = true;
    notifyListeners();
    await _finishTurn();
  }

  Future<void> _aiPlaceBarricade() async {
    if (_game.phase != BlockRacePhase.placingBarricade) return;
    final cell = _ai.chooseBarricade(_game);
    if (cell != null) {
      _game.placeBarricade(cell);
      _stage.addBarricade(cell, _tweens);
      _stage.pulseTile(cell, _tweens);
      await Future<void>.delayed(
        Duration(
          milliseconds:
              (BlockRaceTheme.barricadeAnimationDuration * 1000).round() + 100,
        ),
      );
    } else {
      _game.skipBarricade();
    }
    await _finishTurn();
  }

  Future<void> _finishTurn() async {
    _game.finishAnimations();
    _isBusy = false;
    notifyListeners();
    await _maybeRunAiTurn();
  }

  Future<void> _maybeRunAiTurn() async {
    if (_game.phase == BlockRacePhase.gameOver) return;
    if (_game.phase != BlockRacePhase.rolling) return;
    if (isHumanTurn) return;

    await Future<void>.delayed(const Duration(milliseconds: 600));
    await rollDice();
  }

  Future<void> runDemoMove() async {
    if (!_stageReady || _game.phase == BlockRacePhase.gameOver) return;
    if (_game.phase == BlockRacePhase.ready) {
      startGame();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (_game.phase == BlockRacePhase.rolling && isHumanTurn) {
      await rollDice();
    }
  }

  @override
  void dispose() {
    _stage.dispose();
    super.dispose();
  }
}
