import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tic_tac_toe_ai.dart';
import 'tic_tac_toe_board.dart';
import 'tic_tac_toe_config.dart';
import 'tic_tac_toe_logic.dart';
import 'tic_tac_toe_theme.dart';

class TicTacToePlayScreen extends StatefulWidget {
  const TicTacToePlayScreen({super.key, required this.config});

  final TicTacToeConfig config;

  @override
  State<TicTacToePlayScreen> createState() => _TicTacToePlayScreenState();
}

class _TicTacToePlayScreenState extends State<TicTacToePlayScreen> {
  final _game = TicTacToeGame();
  late final TicTacToeAi _ai;

  var _aiThinking = false;
  var _isAnimating = false;
  var _showWinLine = false;
  var _showResult = false;
  int? _placingIndex;

  TicTacToeConfig get _config => widget.config;

  bool get _canInteract {
    if (_aiThinking || _isAnimating || _game.isOver || _showResult) {
      return false;
    }
    if (_config.isLocalTwoPlayer) return true;
    return _game.turn == Mark.x;
  }

  String get _statusText {
    if (_game.winner == Mark.x) {
      return _config.isVsComputer ? 'You win!' : 'X wins!';
    }
    if (_game.winner == Mark.o) {
      return _config.isVsComputer ? 'AI wins' : 'O wins!';
    }
    if (_game.isDraw) return 'Draw';
    if (_aiThinking) return 'AI thinking…';
    if (_config.isLocalTwoPlayer) {
      return _game.turn == Mark.x ? "X's turn" : "O's turn";
    }
    return 'Your turn';
  }

  String get _xLabel => _config.isVsComputer ? 'You' : 'X';
  String get _oLabel => _config.isVsComputer ? 'AI' : 'O';

  @override
  void initState() {
    super.initState();
    _ai = TicTacToeAi(difficulty: _config.difficulty);
  }

  void _newGame() {
    setState(() {
      _game.reset();
      _aiThinking = false;
      _isAnimating = false;
      _showWinLine = false;
      _showResult = false;
      _placingIndex = null;
    });
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _onCellTap(int index) async {
    if (!_canInteract) return;
    if (_game.markAt(index) != Mark.empty) return;

    await _animateAndPlace(index);
    if (!mounted) return;

    if (_config.isVsComputer &&
        !_game.isOver &&
        _game.turn == Mark.o) {
      await _runAiTurn();
    }
  }

  Future<void> _runAiTurn() async {
    setState(() => _aiThinking = true);
    await Future<void>.delayed(TicTacToeTheme.aiTurnDelay);
    if (!mounted) return;

    final move = _ai.chooseMove(_game);
    if (move != null) {
      await _animateAndPlace(move);
    }
    if (!mounted) return;
    setState(() => _aiThinking = false);
  }

  Future<void> _animateAndPlace(int index) async {
    setState(() {
      _isAnimating = true;
      _placingIndex = index;
      _game.place(index);
    });

    await Future<void>.delayed(TicTacToeTheme.placeAnimationDuration);
    if (!mounted) return;

    setState(() {
      _placingIndex = null;
      _isAnimating = false;
    });

    if (_game.winner != null) {
      setState(() => _showWinLine = true);
      await Future<void>.delayed(TicTacToeTheme.resultOverlayDelay);
      if (!mounted) return;
      setState(() => _showResult = true);
    } else if (_game.isDraw) {
      await Future<void>.delayed(TicTacToeTheme.uiAnimationDuration);
      if (!mounted) return;
      setState(() => _showResult = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic-Tac-Toe'),
        actions: [
          TextButton.icon(
            onPressed: _newGame,
            icon: const Icon(Icons.refresh),
            label: const Text('New game'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: TicTacToeTheme.uiAnimationDuration,
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _game.isOver
                          ? scheme.primaryContainer
                          : (_aiThinking
                                ? scheme.secondaryContainer
                                : scheme.surfaceContainerHigh),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: TicTacToeTheme.uiAnimationDuration,
                          child: Image.asset(
                            TicTacToeTheme.badgeAsset(
                              _game.isOver
                                  ? (_game.winner ?? Mark.x)
                                  : _game.turn,
                            ),
                            key: ValueKey(
                              '${_game.status}-${_game.turn}',
                            ),
                            width: 36,
                            height: 36,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: TicTacToeTheme.uiAnimationDuration,
                            child: Text(
                              _statusText,
                              key: ValueKey(_statusText),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        _LegendToken(
                          asset: TicTacToeTheme.markX,
                          label: _xLabel,
                        ),
                        const SizedBox(width: 12),
                        _LegendToken(
                          asset: TicTacToeTheme.markO,
                          label: _oLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: TicTacToeBoard(
                          game: _game,
                          interactive: _canInteract,
                          onCellTap: _onCellTap,
                          placingIndex: _placingIndex,
                          showWinLine: _showWinLine,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: TicTacToeTheme.uiAnimationDuration,
                    child: Text(
                      _aiThinking
                          ? 'AI is choosing a square…'
                          : 'Tap an empty square to place your mark.',
                      key: ValueKey(_aiThinking),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showResult) _ResultOverlay(
            status: _game.status,
            vsComputer: _config.isVsComputer,
            onPlayAgain: _newGame,
            onHome: _goHome,
          ),
        ],
      ),
    );
  }
}

class _LegendToken extends StatelessWidget {
  const _LegendToken({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.status,
    required this.vsComputer,
    required this.onPlayAgain,
    required this.onHome,
  });

  final GameStatus status;
  final bool vsComputer;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  String get _title => switch (status) {
        GameStatus.xWins => vsComputer ? 'You win!' : 'X wins!',
        GameStatus.oWins => vsComputer ? 'AI wins' : 'O wins!',
        GameStatus.draw => "It's a draw",
        GameStatus.playing => '',
      };

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: TicTacToeTheme.uiAnimationDuration,
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + 0.15 * t,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.black54,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready for another round?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onPlayAgain,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Play Again'),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: onHome,
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
