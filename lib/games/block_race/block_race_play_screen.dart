import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'block_race_config.dart';
import 'block_race_controller.dart';
import 'block_race_logic.dart';
import 'block_race_theme.dart';

class BlockRacePlayScreen extends StatefulWidget {
  const BlockRacePlayScreen({
    super.key,
    required this.config,
    this.demo = false,
  });

  final BlockRaceConfig config;
  final bool demo;

  @override
  State<BlockRacePlayScreen> createState() => _BlockRacePlayScreenState();
}

class _BlockRacePlayScreenState extends State<BlockRacePlayScreen> {
  late final BlockRaceGameController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _demoStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = BlockRaceGameController(config: widget.config)
      ..addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (widget.demo &&
        !_demoStarted &&
        _controller.stageReady &&
        _controller.game.phase == BlockRacePhase.ready) {
      _demoStarted = true;
      _controller.startGame();
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _controller.runDemoMove();
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _onRoll() async {
    if (_controller.game.phase == BlockRacePhase.ready) {
      _controller.startGame();
    }
    await _controller.rollDice();
  }

  @override
  Widget build(BuildContext context) {
    final game = _controller.game;
    final phase = game.phase;

    return Scaffold(
      backgroundColor: BlockRaceTheme.background,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.space) {
            if (phase == BlockRacePhase.ready ||
                (phase == BlockRacePhase.rolling && _controller.isHumanTurn)) {
              _onRoll();
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _controller.stage.build(),
            if (!_controller.stageReady)
              const ColoredBox(
                color: BlockRaceTheme.background,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (phase == BlockRacePhase.placingBarricade &&
                _controller.isHumanTurn)
              _BarricadePicker(
                validCells: game.validBarricadeCells(),
                onPick: _controller.placeBarricade,
              ),
            _HudOverlay(
              controller: _controller,
              onRoll: _onRoll,
              onSkipBarricade: _controller.skipBarricade,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: PointerInterceptor(
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: BlockRaceTheme.foreground,
                  ),
                ),
              ),
            ),
            if (phase == BlockRacePhase.gameOver)
              _WinnerOverlay(
                winner: game.winner!,
                onPlayAgain: _controller.startGame,
              ),
          ],
        ),
      ),
    );
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({
    required this.controller,
    required this.onRoll,
    required this.onSkipBarricade,
  });

  final BlockRaceGameController controller;
  final VoidCallback onRoll;
  final VoidCallback onSkipBarricade;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final phase = game.phase;
    final size = MediaQuery.sizeOf(context);
    final showRoll = (phase == BlockRacePhase.ready ||
            phase == BlockRacePhase.rolling) &&
        controller.isHumanTurn &&
        !controller.isBusy;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 48),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              game.statusMessage,
              key: ValueKey(game.statusMessage),
              textAlign: TextAlign.center,
              style: BlockRaceTheme.comfortaa(
                fontSize: size.width * 0.038,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DiceDisplay(
            value: controller.displayDice,
            rolling: controller.diceRolling,
            highlight: game.currentPlayer,
          ),
          const Spacer(),
          if (phase == BlockRacePhase.placingBarricade &&
              controller.isHumanTurn)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PointerInterceptor(
                child: TextButton(
                  onPressed: controller.isBusy ? null : onSkipBarricade,
                  child: Text(
                    'Skip barricade (${game.barricadesLeftFor(game.currentPlayer)} left)',
                    style: BlockRaceTheme.comfortaa(fontSize: 16),
                  ),
                ),
              ),
            ),
          if (showRoll)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: PointerInterceptor(
                child: FilledButton.icon(
                  onPressed: onRoll,
                  style: FilledButton.styleFrom(
                    backgroundColor: game.currentPlayer == BlockRacePlayer.blue
                        ? BlockRaceTheme.bluePlayer
                        : BlockRaceTheme.redPlayer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(
                    phase == BlockRacePhase.ready ? 'Start & Roll' : 'Roll Dice',
                    style: BlockRaceTheme.comfortaa(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiceDisplay extends StatelessWidget {
  const _DiceDisplay({
    required this.value,
    required this.rolling,
    required this.highlight,
  });

  final int value;
  final bool rolling;
  final BlockRacePlayer highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: rolling ? 1.12 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: highlight == BlockRacePlayer.blue
              ? BlockRaceTheme.bluePlayer
              : BlockRaceTheme.redPlayer,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$value',
          style: BlockRaceTheme.comfortaa(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _BarricadePicker extends StatelessWidget {
  const _BarricadePicker({
    required this.validCells,
    required this.onPick,
  });

  final List<BlockRaceCell> validCells;
  final Future<void> Function(BlockRaceCell cell) onPick;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final boardSide = size.width.clamp(260.0, 420.0);

    return Center(
      child: SizedBox(
        width: boardSide,
        height: boardSide,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: BlockRaceGame.boardCols,
          ),
          itemCount: BlockRaceGame.boardRows * BlockRaceGame.boardCols,
          itemBuilder: (context, index) {
            final row = index ~/ BlockRaceGame.boardCols;
            final col = index % BlockRaceGame.boardCols;
            final cell = BlockRaceCell(
              row: row,
              col: col,
              kind: BlockRaceGame.cellAt(row, col).kind,
            );
            final valid = validCells.any((c) => c.row == row && c.col == col);

            return PointerInterceptor(
              child: GestureDetector(
                onTap: valid ? () => onPick(cell) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: valid
                        ? BlockRaceTheme.barricade.withValues(alpha: 0.45)
                        : Colors.transparent,
                    border: valid
                        ? Border.all(color: BlockRaceTheme.barricade, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WinnerOverlay extends StatelessWidget {
  const _WinnerOverlay({
    required this.winner,
    required this.onPlayAgain,
  });

  final BlockRacePlayer winner;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final color = winner == BlockRacePlayer.blue
        ? BlockRaceTheme.bluePlayer
        : BlockRaceTheme.redPlayer;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: PointerInterceptor(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${winner == BlockRacePlayer.blue ? 'Blue' : 'Red'} Wins!',
                style: BlockRaceTheme.comfortaa(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onPlayAgain,
                style: FilledButton.styleFrom(backgroundColor: color),
                child: Text(
                  'Play Again',
                  style: BlockRaceTheme.comfortaa(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
