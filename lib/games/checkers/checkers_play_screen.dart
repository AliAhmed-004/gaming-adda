import 'package:flutter/material.dart';

import 'checkers_ai.dart';
import 'checkers_board.dart';
import 'checkers_config.dart';
import 'checkers_logic.dart';
import 'checkers_sounds.dart';

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

  CheckersConfig get _config => widget.config;

  Set<Square> get _targets {
    if (_selected == null) return {};
    return _game.movesFrom(_selected!).map((m) => m.to).toSet();
  }

  bool get _canInteract {
    if (_aiThinking || _game.winner != null) return false;
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
      setState(() {
        _game.applyMove(move);
        _selected = null;
      });
      await _playMoveSounds(move);
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
      setState(() {
        _game.applyMove(move);
        _aiThinking = false;
      });
      await _playMoveSounds(move);
    } else {
      setState(() => _aiThinking = false);
    }
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _game.winner == null
                          ? Icons.sports_esports
                          : Icons.emoji_events_outlined,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _LegendDot(
                      color: const Color(0xFF0F766E),
                      label: _darkLabel,
                    ),
                    const SizedBox(width: 12),
                    _LegendDot(
                      color: const Color(0xFFE7E5E4),
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
                    interactive: _canInteract,
                    onSquareTap: _onSquareTap,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap a piece, then a highlighted square. Captures are mandatory.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
