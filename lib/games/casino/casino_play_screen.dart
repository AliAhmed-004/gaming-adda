import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'casino_ai.dart';
import 'casino_config.dart';
import 'casino_logic.dart';
import 'casino_sounds.dart';
import 'casino_table.dart';
import 'casino_theme.dart';

class CasinoPlayScreen extends StatefulWidget {
  const CasinoPlayScreen({super.key, required this.config});

  final CasinoConfig config;

  @override
  State<CasinoPlayScreen> createState() => _CasinoPlayScreenState();
}

class _CasinoPlayScreenState extends State<CasinoPlayScreen> {
  late final CasinoGame _game;
  late final CasinoAi _ai;
  late final CasinoSounds _sounds;

  var _aiThinking = false;
  var _showGameEndOverlay = false;

  CasinoConfig get _config => widget.config;

  bool get _isHumanTurn => _game.turn == PlayerId.human;

  bool get _canInteract =>
      !_aiThinking &&
      !_showGameEndOverlay &&
      _game.phase == GamePhase.awaitingPlay &&
      _isHumanTurn;

  String get _statusText {
    if (_game.phase == GamePhase.gameEnd) {
      if (_game.isTie) return "It's a tie!";
      final winner = _game.winner;
      return winner == PlayerId.human ? 'You win!' : 'AI wins!';
    }
    if (_aiThinking) return 'AI thinking…';
    if (_game.phase == GamePhase.awaitingPlay && _isHumanTurn) {
      if (_game.selectedCard == null) {
        return 'Select a card — match keeps your turn';
      }
      if (_game.selectionHasMatch) {
        return 'Tap a glowing match to collect (you go again)';
      }
      return 'Tap the floor to drop and end your turn';
    }
    return _game.turn == PlayerId.human ? 'Your turn' : "AI's turn";
  }

  @override
  void initState() {
    super.initState();
    _game = CasinoGame();
    _ai = CasinoAi();
    _sounds = CasinoSounds(enabled: _config.soundEnabled);
    _sounds.preload();
    _game.newGame();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runTurnFlow());
  }

  @override
  void dispose() {
    _sounds.dispose();
    super.dispose();
  }

  void _newGame() {
    setState(() {
      _game.newGame();
      _aiThinking = false;
      _showGameEndOverlay = false;
    });
    _runTurnFlow();
  }

  Future<void> _runTurnFlow() async {
    if (!mounted || _game.phase == GamePhase.gameEnd) return;

    if (_game.phase == GamePhase.awaitingPlay) {
      if (_game.turn == PlayerId.ai) {
        await _runAiPlayTurn();
      }
      return;
    }

    if (_game.phase != GamePhase.playing) return;

    if (_game.turn == PlayerId.ai) {
      await _runAiDrawAndPlay();
      return;
    }

    if (_isHumanTurn) {
      await _runHumanDraw();
    }
  }

  Future<void> _runHumanDraw() async {
    setState(() => _aiThinking = false);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || _game.phase != GamePhase.playing) return;

    setState(() {
      final drew = _game.drawCard();
      if (!drew && _game.phase == GamePhase.gameEnd) {
        _showGameEndOverlay = true;
      }
    });

    if (_game.phase == GamePhase.gameEnd) {
      await _sounds.win();
      return;
    }

    await _sounds.playCard();
  }

  Future<void> _runAiDrawAndPlay() async {
    setState(() => _aiThinking = true);
    await Future<void>.delayed(CasinoTheme.aiTurnDelay);
    if (!mounted) return;

    setState(() {
      final drew = _game.drawCard();
      if (!drew && _game.phase == GamePhase.gameEnd) {
        _showGameEndOverlay = true;
      }
    });

    if (_game.phase == GamePhase.gameEnd) {
      setState(() => _aiThinking = false);
      await _sounds.win();
      return;
    }

    await _runAiPlayTurn();
  }

  Future<void> _runAiPlayTurn() async {
    setState(() => _aiThinking = true);
    await Future<void>.delayed(CasinoTheme.aiTurnDelay);
    if (!mounted || _game.phase != GamePhase.awaitingPlay) return;

    final card = _ai.choosePlayCard(_game);
    if (card == null) {
      setState(() => _aiThinking = false);
      return;
    }

    setState(() => _game.selectHandCard(card));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    if (_game.selectionHasMatch) {
      final target = _ai.chooseMatchTarget(_game);
      if (target != null) {
        setState(() => _game.collectByClickingMatch(target));
        await _sounds.capture();
      }
    } else {
      setState(() => _game.placeSelectedOnFloor());
      await _sounds.playCard();
    }

    if (!mounted) return;
    setState(() => _aiThinking = false);

    if (_game.phase == GamePhase.gameEnd) {
      setState(() => _showGameEndOverlay = true);
      await _sounds.win();
      return;
    }

    await _runTurnFlow();
  }

  void _onHandCardTap(PlayingCard card) {
    if (!_canInteract) return;
    setState(() => _game.selectHandCard(card));
    _sounds.select();
  }

  void _onMatchTargetTap(PlayingCard target) {
    if (!_canInteract) return;
    if (!_game.selectionHasMatch) return;

    final ok = _game.collectByClickingMatch(target);
    if (!ok) return;

    setState(() {});
    _sounds.capture();

    if (_game.phase == GamePhase.gameEnd) {
      setState(() => _showGameEndOverlay = true);
      _sounds.win();
      return;
    }

    _runTurnFlow();
  }

  void _onFloorTap() {
    if (!_canInteract) return;
    if (_game.selectedCard == null || _game.selectionHasMatch) return;

    final ok = _game.placeSelectedOnFloor();
    if (!ok) return;

    setState(() {});
    _sounds.playCard();

    if (_game.phase == GamePhase.gameEnd) {
      setState(() => _showGameEndOverlay = true);
      _sounds.win();
      return;
    }

    _runTurnFlow();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Match'),
        actions: [
          TextButton.icon(
            onPressed: _newGame,
            icon: const Icon(Icons.refresh),
            label: const Text('New game'),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  _ScoreBar(game: _game),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: CasinoTheme.uiAnimationDuration,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _aiThinking
                          ? scheme.secondaryContainer
                          : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CasinoTable(
                      game: _game,
                      humanHand: _game.humanHand,
                      humanLabel: 'You',
                      humanCollected: _game.humanPile,
                      aiCollected: _game.aiPile,
                      selectedCard: _isHumanTurn ? _game.selectedCard : null,
                      canInteract: _canInteract,
                      deckCount: _game.deck.length,
                      onHandCardTap: _onHandCardTap,
                      onMatchTargetTap: _onMatchTargetTap,
                      onFloorTap: _onFloorTap,
                    ),
                  ),
                ],
              ),
            ),
            if (_showGameEndOverlay)
              _GameEndOverlay(
                game: _game,
                onPlayAgain: _newGame,
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.game});

  final CasinoGame game;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Deck: ${game.deck.length}',
          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        Text(
          'Match by number only',
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _GameEndOverlay extends StatelessWidget {
  const _GameEndOverlay({
    required this.game,
    required this.onPlayAgain,
  });

  final CasinoGame game;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final p1 = 'You';
    final p2 = 'AI';
    final winner = game.winner;

    final headline = game.isTie
        ? "It's a tie!"
        : (winner == PlayerId.human ? 'You win!' : 'AI wins!');

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  headline,
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text('$p1 collected: ${game.humanPile.length} cards'),
                Text('$p2 collected: ${game.aiPile.length} cards'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onPlayAgain,
                  child: const Text('Play again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
