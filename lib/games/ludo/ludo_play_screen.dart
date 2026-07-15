import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ludo_ai.dart';
import 'ludo_board.dart';
import 'ludo_config.dart';
import 'ludo_logic.dart';
import 'ludo_sounds.dart';
import 'ludo_theme.dart';

class LudoPlayScreen extends StatefulWidget {
  const LudoPlayScreen({super.key, required this.config});

  final LudoConfig config;

  @override
  State<LudoPlayScreen> createState() => _LudoPlayScreenState();
}

class _LudoPlayScreenState extends State<LudoPlayScreen> {
  late final LudoGame _game;
  final _ai = LudoAi();
  late final LudoSounds _sounds;

  int? _selectedTokenId;
  var _busy = false;
  var _lastRollDisplay = 0;

  static const _aiNames = <LudoColor, String>{
    LudoColor.red: 'Meera',
    LudoColor.green: 'Kavya',
    LudoColor.yellow: 'Dev',
    LudoColor.blue: 'Arjun',
  };

  LudoConfig get _config => widget.config;

  bool get _canInteract {
    if (_busy || _game.winner != null) return false;
    return _config.isHumanTurn(_game.turn);
  }

  Set<int> get _movableIds {
    return _game.legalMovesForCurrentRoll().map((m) => m.tokenId).toSet();
  }

  Map<LudoColor, String> get _labels {
    return {for (final c in _game.activeColors) c: _displayName(c)};
  }

  String _displayName(LudoColor c) {
    if (_config.isVsComputer && c == _config.humanColor) return 'You';
    if (_config.isVsComputer) return _aiNames[c] ?? c.label;
    return c.label;
  }

  String get _statusText {
    if (_game.winner != null) {
      if (_config.isVsComputer) {
        return _game.winner == _config.humanColor
            ? 'You win!'
            : '${_displayName(_game.winner!)} wins';
      }
      return '${_game.winner!.label} wins!';
    }
    if (_busy && !_config.isHumanTurn(_game.turn)) {
      return '${_displayName(_game.turn)} thinking…';
    }
    if (_game.pendingRoll != null) {
      return '${_displayName(_game.turn)}: pick a token';
    }
    return '${_displayName(_game.turn)} — roll the die';
  }

  @override
  void initState() {
    super.initState();
    _game = LudoGame(playerCount: _config.playerCount);
    _sounds = LudoSounds(enabled: _config.soundEnabled);
    _sounds.preload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_config.isHumanTurn(_game.turn)) {
        _runAiUntilHuman();
      }
    });
  }

  @override
  void dispose() {
    _sounds.dispose();
    super.dispose();
  }

  void _newGame() {
    setState(() {
      _game.reset();
      _selectedTokenId = null;
      _busy = false;
      _lastRollDisplay = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_config.isHumanTurn(_game.turn)) {
        _runAiUntilHuman();
      }
    });
  }

  Future<void> _playMoveSounds(LudoMove move) async {
    if (move.isCapture) {
      await _sounds.capture();
    } else {
      await _sounds.move();
    }
    if (_game.winner != null) {
      await _sounds.win();
    }
  }

  Future<void> _onRoll() async {
    if (!_canInteract || _game.pendingRoll != null) return;
    final roll = _game.rollDie();
    setState(() {
      _lastRollDisplay = roll;
      _selectedTokenId = null;
    });
    await _sounds.select();
    if (!mounted) return;

    final moves = _game.legalMovesForCurrentRoll();
    if (_game.pendingRoll == null && moves.isEmpty) {
      setState(() {});
      await _maybeContinueAi();
      return;
    }
    if (moves.length == 1) {
      await _applyMove(moves.single);
    } else {
      setState(() {});
    }
  }

  Future<void> _onTokenTap(LudoColor color, int tokenId) async {
    if (!_canInteract || _game.pendingRoll == null) return;
    if (color != _game.turn) return;

    final moves = _game
        .legalMovesForCurrentRoll()
        .where((m) => m.tokenId == tokenId)
        .toList();
    if (moves.isEmpty) return;

    if (moves.length == 1) {
      await _applyMove(moves.single);
      return;
    }

    setState(() => _selectedTokenId = tokenId);
    await _sounds.select();
  }

  Future<void> _applyMove(LudoMove move) async {
    setState(() {
      _game.applyMove(move);
      _selectedTokenId = null;
    });
    await _playMoveSounds(move);
    if (!mounted) return;
    await _maybeContinueAi();
  }

  Future<void> _maybeContinueAi() async {
    if (_game.winner != null) return;
    if (_config.isLocalHotseat) return;
    if (_config.isHumanTurn(_game.turn)) return;
    await _runAiUntilHuman();
  }

  Future<void> _runAiUntilHuman() async {
    if (_config.isLocalHotseat) return;
    setState(() => _busy = true);

    while (mounted &&
        _game.winner == null &&
        !_config.isHumanTurn(_game.turn)) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      if (_game.pendingRoll == null) {
        final roll = _game.rollDie();
        setState(() => _lastRollDisplay = roll);
        await _sounds.select();
        if (!mounted) return;
      }

      final moves = _game.legalMovesForCurrentRoll();
      if (_game.pendingRoll == null || moves.isEmpty) {
        setState(() {});
        continue;
      }

      final choice = _ai.chooseMove(_game) ?? moves.first;
      setState(() {
        _game.applyMove(choice);
        _selectedTokenId = null;
      });
      await _playMoveSounds(choice);
      if (!mounted) return;
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final canRoll = _canInteract && _game.pendingRoll == null;
    final dieColor = _config.isVsComputer ? _config.humanColor : _game.turn;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [LudoTheme.bgTop, LudoTheme.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // Soft cosmic glows
            Positioned(
              top: -80,
              left: -40,
              child: _GlowBlob(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.22),
                size: 220,
              ),
            ),
            Positioned(
              bottom: -60,
              right: -30,
              child: _GlowBlob(
                color: const Color(0xFF22D3EE).withValues(alpha: 0.14),
                size: 200,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: LudoTheme.statusText,
                          tooltip: 'Back',
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  LudoTheme.iconAsset,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ludo',
                                style: GoogleFonts.fredoka(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: LudoTheme.statusText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _busy ? null : _newGame,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('New game'),
                          style: TextButton.styleFrom(
                            foregroundColor: LudoTheme.statusText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LudoTheme.statusText.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Board fills screen width (square, height-limited if needed).
                        final boardSize = constraints.maxWidth
                            .clamp(0.0, constraints.maxHeight)
                            .toDouble();
                        final avatarSize = (boardSize * 0.11).clamp(40.0, 64.0);

                        return SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: boardSize,
                                height: boardSize,
                                child: LudoBoard(
                                  game: _game,
                                  selectedTokenId: _selectedTokenId,
                                  movableTokenIds: _canInteract
                                      ? _movableIds
                                      : const {},
                                  interactive:
                                      _canInteract && _game.pendingRoll != null,
                                  playerLabels: _labels,
                                  onTokenTap: _onTokenTap,
                                  onBoardTap: () =>
                                      setState(() => _selectedTokenId = null),
                                ),
                              ),
                              for (final color in _game.activeColors)
                                Align(
                                  alignment: LudoTheme.avatarAlignment(color),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: _PlayerAvatar(
                                      color: color,
                                      label: _displayName(color),
                                      size: avatarSize,
                                      isTurn: _game.turn == color,
                                      isYou:
                                          _config.isVsComputer &&
                                          color == _config.humanColor,
                                    ),
                                  ),
                                ),
                              Align(
                                alignment: LudoTheme.avatarAlignment(dieColor),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left:
                                        dieColor == LudoColor.green ||
                                            dieColor == LudoColor.red
                                        ? avatarSize + 12
                                        : 6,
                                    right:
                                        dieColor == LudoColor.yellow ||
                                            dieColor == LudoColor.blue
                                        ? avatarSize + 12
                                        : 6,
                                    top:
                                        dieColor == LudoColor.green ||
                                            dieColor == LudoColor.yellow
                                        ? 6
                                        : 0,
                                    bottom:
                                        dieColor == LudoColor.red ||
                                            dieColor == LudoColor.blue
                                        ? 6
                                        : 0,
                                  ),
                                  child: _PipDieButton(
                                    value:
                                        _game.pendingRoll ?? _lastRollDisplay,
                                    enabled: canRoll,
                                    accent: LudoTheme.vivid(dieColor),
                                    onTap: _onRoll,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({
    required this.color,
    required this.label,
    required this.size,
    required this.isTurn,
    required this.isYou,
  });

  final LudoColor color;
  final String label;
  final double size;
  final bool isTurn;
  final bool isYou;

  IconData get _icon {
    if (isYou) return Icons.person_rounded;
    return switch (color) {
      LudoColor.red || LudoColor.yellow => Icons.face_rounded,
      LudoColor.green || LudoColor.blue => Icons.emoji_emotions_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = LudoTheme.vivid(color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isTurn ? Colors.white : accent,
              width: isTurn ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isTurn ? 0.55 : 0.28),
                blurRadius: isTurn ? 14 : 8,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(accent, Colors.white, 0.25)!,
                LudoTheme.deep(color),
              ],
            ),
          ),
          child: Icon(_icon, color: Colors.white, size: size * 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PipDieButton extends StatelessWidget {
  const _PipDieButton({
    required this.value,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final int value;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final face = value.clamp(0, 6);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.72,
          child: Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LudoTheme.dieWell,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled ? accent : const Color(0xFF3B6FB0),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: enabled ? 0.4 : 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: face == 0
                  ? Center(
                      child: Text(
                        '?',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    )
                  : CustomPaint(painter: _DiePipsPainter(face)),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiePipsPainter extends CustomPainter {
  _DiePipsPainter(this.value);

  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0F172A);
    final r = size.shortestSide * 0.1;
    Offset p(double x, double y) => Offset(size.width * x, size.height * y);

    void dot(double x, double y) => canvas.drawCircle(p(x, y), r, paint);

    switch (value) {
      case 1:
        dot(0.5, 0.5);
      case 2:
        dot(0.28, 0.28);
        dot(0.72, 0.72);
      case 3:
        dot(0.28, 0.28);
        dot(0.5, 0.5);
        dot(0.72, 0.72);
      case 4:
        dot(0.28, 0.28);
        dot(0.72, 0.28);
        dot(0.28, 0.72);
        dot(0.72, 0.72);
      case 5:
        dot(0.28, 0.28);
        dot(0.72, 0.28);
        dot(0.5, 0.5);
        dot(0.28, 0.72);
        dot(0.72, 0.72);
      case 6:
        dot(0.28, 0.25);
        dot(0.28, 0.5);
        dot(0.28, 0.75);
        dot(0.72, 0.25);
        dot(0.72, 0.5);
        dot(0.72, 0.75);
    }
  }

  @override
  bool shouldRepaint(covariant _DiePipsPainter oldDelegate) =>
      oldDelegate.value != value;
}
