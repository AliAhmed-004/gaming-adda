import 'package:flutter/material.dart';

import 'checkers_ai.dart';
import 'checkers_board.dart';
import 'checkers_config.dart';
import 'checkers_logic.dart';
import 'checkers_sounds.dart';
import 'checkers_theme.dart';

class CheckersPlayScreen extends StatefulWidget {
  const CheckersPlayScreen({super.key, required this.config});

  final CheckersConfig config;

  @override
  State<CheckersPlayScreen> createState() => _CheckersPlayScreenState();
}

class _CheckersPlayScreenState extends State<CheckersPlayScreen> {
  final _game = CheckersGame();
  final _ai = CheckersAi();
  late final CheckersSounds _sounds;

  Square? _selected;
  var _aiThinking = false;
  var _isAnimatingMove = false;
  CheckersBoardAnimation? _boardAnimation;

  CheckersConfig get _config => widget.config;

  Set<Square> get _targets {
    if (!_canInteract || _selected == null) return {};
    return _game.movesFrom(_selected!).map((m) => m.to).toSet();
  }

  bool get _canInteract {
    if (_aiThinking || _isAnimatingMove || _game.winner != null) return false;
    if (_config.isLocalTwoPlayer) return true;
    return _game.turn == Side.dark;
  }

  String get _statusText {
    if (_config.isLocalTwoPlayer) {
      if (_game.winner == Side.dark) return 'Dark wins';
      if (_game.winner == Side.light) return 'Light wins';
      return _game.turn == Side.dark ? "Dark's turn" : "Light's turn";
    }
    if (_game.winner == Side.dark) return 'You win!';
    if (_game.winner == Side.light) return 'AI wins';
    if (_aiThinking) return 'AI thinking…';
    return 'Your turn';
  }

  String get _darkLabel => _config.isVsComputer ? 'You' : 'Dark';
  String get _lightLabel => _config.isVsComputer ? 'AI' : 'Light';

  @override
  void initState() {
    super.initState();
    _sounds = CheckersSounds(enabled: _config.soundEnabled);
    _sounds.preload();
  }

  @override
  void dispose() {
    _sounds.dispose();
    super.dispose();
  }

  void _newGame() {
    setState(() {
      _game.reset();
      _selected = null;
      _aiThinking = false;
      _isAnimatingMove = false;
      _boardAnimation = null;
    });
  }

  Future<void> _playMoveSounds(CheckersMove move) async {
    if (move.isCapture) {
      await _sounds.capture();
    } else {
      await _sounds.move();
    }
    if (_game.winner != null) {
      await _sounds.win();
    }
  }

  Future<void> _onSquareTap(Square square) async {
    if (!_canInteract) return;

    final piece = _game.pieceAt(square);

    if (_selected != null && _targets.contains(square)) {
      final move = _game
          .movesFrom(_selected!)
          .firstWhere((m) => m.to == square);
      await _animateAndApplyMove(move, keepAiThinking: false);
      if (!mounted) return;
      if (_config.isVsComputer &&
          _game.winner == null &&
          _game.turn == Side.light) {
        await _runAiTurn();
      }
      return;
    }

    if (_game.turn.owns(piece)) {
      final moves = _game.movesFrom(square);
      setState(() {
        _selected = moves.isEmpty ? null : square;
      });
      if (moves.isNotEmpty) {
        await _sounds.select();
      }
      return;
    }

    setState(() => _selected = null);
  }

  Future<void> _runAiTurn() async {
    setState(() => _aiThinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final move = _ai.chooseMove(_game);
    if (move != null) {
      await _animateAndApplyMove(move, keepAiThinking: true);
      if (!mounted) return;
      setState(() => _aiThinking = false);
    } else {
      setState(() => _aiThinking = false);
    }
  }

  Future<void> _animateAndApplyMove(
    CheckersMove move, {
    required bool keepAiThinking,
  }) async {
    final movingPiece = _game.pieceAt(move.from);
    setState(() {
      _isAnimatingMove = true;
      _selected = null;
      _boardAnimation = CheckersBoardAnimation(
        id: DateTime.now().microsecondsSinceEpoch,
        from: move.from,
        to: move.to,
        movingPiece: movingPiece,
        capturedPieces: [
          for (final square in move.captured)
            CapturedGoti(
              square: square,
              piece: _game.pieceAt(square),
            ),
        ],
      );
      if (!keepAiThinking) {
        _aiThinking = false;
      }
    });

    await Future<void>.delayed(CheckersTheme.moveAnimationDuration);
    if (!mounted) return;

    setState(() {
      _game.applyMove(move);
      _boardAnimation = null;
      _isAnimatingMove = false;
    });
    await _playMoveSounds(move);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkers'),
        actions: [
          TextButton.icon(
            onPressed: _newGame,
            icon: const Icon(Icons.refresh),
            label: const Text('New game'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              AnimatedContainer(
                duration: CheckersTheme.uiAnimationDuration,
                curve: Curves.easeOutCubic,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _game.winner != null
                      ? scheme.primaryContainer
                      : (_aiThinking
                            ? scheme.secondaryContainer
                            : scheme.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: CheckersTheme.uiAnimationDuration,
                      child: Icon(
                        _game.winner == null
                            ? Icons.sports_esports
                            : Icons.emoji_events_outlined,
                        key: ValueKey<bool>(_game.winner != null),
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: CheckersTheme.uiAnimationDuration,
                        child: Text(
                          _statusText,
                          key: ValueKey(_statusText),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    _LegendToken(
                      asset: CheckersTheme.gotiDark,
                      label: _darkLabel,
                    ),
                    const SizedBox(width: 12),
                    _LegendToken(
                      asset: CheckersTheme.gotiLight,
                      label: _lightLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: CheckersBoard(
                    game: _game,
                    selected: _selected,
                    targets: _targets,
                    animation: _boardAnimation,
                    interactive: _canInteract,
                    onSquareTap: _onSquareTap,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: CheckersTheme.uiAnimationDuration,
                child: Text(
                  _aiThinking
                      ? 'AI is thinking about its next move.'
                      : 'Tap your goti, then a highlighted square.',
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
