import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_assets.dart';
import '../../widgets/cartoon_ui/cartoon_buttons.dart';
import '../../widgets/cartoon_ui/cartoon_panel.dart';
import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'connect_four_ai.dart';
import 'connect_four_board.dart';
import 'connect_four_config.dart';
import 'connect_four_levels.dart';
import 'connect_four_logic.dart';
import 'connect_four_sounds.dart';
import 'connect_four_tutorial.dart';

class ConnectFourPlayScreen extends StatefulWidget {
  const ConnectFourPlayScreen({super.key, required this.config});

  final ConnectFourConfig config;

  @override
  State<ConnectFourPlayScreen> createState() => _ConnectFourPlayScreenState();
}

class _ConnectFourPlayScreenState extends State<ConnectFourPlayScreen> {
  final _game = ConnectFourGame();
  late final ConnectFourAi _ai;
  late final ConnectFourSounds _sounds;

  int? _hoverColumn;
  var _aiThinking = false;
  var _tutorialStep = ConnectFourTutorialStep.welcome;

  ConnectFourConfig get _config => widget.config;

  bool get _isTutorial =>
      ConnectFourTutorial.isTutorialLevel(_config.level);

  bool get _canInteract {
    if (_aiThinking || _game.isOver) return false;
    if (_isTutorial &&
        (_tutorialStep == ConnectFourTutorialStep.welcome ||
            _tutorialStep == ConnectFourTutorialStep.gravity ||
            _tutorialStep == ConnectFourTutorialStep.connectFour)) {
      return false;
    }
    if (_config.isLocalTwoPlayer) return true;
    return _game.turn == Disc.red;
  }

  int? get _tutorialHighlight =>
      _isTutorial && _tutorialStep == ConnectFourTutorialStep.dropDisc
          ? ConnectFourTutorial.firstColumn
          : null;

  Set<int>? get _tutorialAllowedColumns =>
      _isTutorial && _tutorialStep == ConnectFourTutorialStep.dropDisc
          ? {ConnectFourTutorial.firstColumn}
          : null;

  String get _statusText {
    if (_config.isLocalTwoPlayer) {
      if (_game.winner == Disc.red) return 'Red wins!';
      if (_game.winner == Disc.yellow) return 'Yellow wins!';
      if (_game.isDraw) return 'Draw';
      return _game.turn == Disc.red ? "Red's turn" : "Yellow's turn";
    }
    if (_game.winner == Disc.red) return 'You win!';
    if (_game.winner == Disc.yellow) return 'AI wins';
    if (_game.isDraw) return 'Draw';
    if (_aiThinking) return 'AI thinking…';
    return 'Your turn';
  }

  String get _redLabel => _config.isVsComputer ? 'You' : 'Red';
  String get _yellowLabel {
    if (!_config.isVsComputer) return 'Yellow';
    if (_isTutorial) return 'Practice';
    final level = _config.level;
    return level == null ? 'AI' : ConnectFourLevels.tierName(level);
  }

  @override
  void initState() {
    super.initState();
    // Tutorial AI always blunders so the player can learn without pressure.
    _ai = _isTutorial
        ? ConnectFourAi(depth: 1, randomMoveChance: 1)
        : ConnectFourAi.forLevel(_config.level ?? 1);
    _sounds = ConnectFourSounds(enabled: _config.soundEnabled);
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
      _hoverColumn = null;
      _aiThinking = false;
      if (_isTutorial) {
        _tutorialStep = ConnectFourTutorialStep.welcome;
      }
    });
  }

  void _advanceTutorial() {
    setState(() {
      _tutorialStep = switch (_tutorialStep) {
        ConnectFourTutorialStep.welcome => ConnectFourTutorialStep.dropDisc,
        ConnectFourTutorialStep.dropDisc => ConnectFourTutorialStep.gravity,
        ConnectFourTutorialStep.gravity => ConnectFourTutorialStep.connectFour,
        ConnectFourTutorialStep.connectFour => ConnectFourTutorialStep.freePlay,
        ConnectFourTutorialStep.freePlay => ConnectFourTutorialStep.freePlay,
      };
    });
  }

  Future<void> _onTutorialContinue() async {
    final from = _tutorialStep;
    _advanceTutorial();
    if (!mounted) return;

    // After the gravity tip, let Practice take its first turn.
    if (from == ConnectFourTutorialStep.gravity) {
      if (_config.isVsComputer && !_game.isOver && _game.turn == Disc.yellow) {
        await _runAiTurn();
      }
      await _handleGameEnd();
    }
  }

  Future<void> _playMoveSounds() async {
    await _sounds.drop();
    if (_game.winner != null) {
      await _sounds.win();
    }
  }

  Future<void> _onColumnTap(int col) async {
    if (!_canInteract || !_game.canDrop(col)) return;
    if (_tutorialAllowedColumns != null &&
        !_tutorialAllowedColumns!.contains(col)) {
      return;
    }

    setState(() {
      _game.drop(col);
      if (_isTutorial && _tutorialStep == ConnectFourTutorialStep.dropDisc) {
        _tutorialStep = ConnectFourTutorialStep.gravity;
      }
    });
    await _playMoveSounds();
    if (!mounted) return;

    // During the gravity tip, pause before the practice AI replies.
    if (_isTutorial && _tutorialStep == ConnectFourTutorialStep.gravity) {
      return;
    }

    if (_config.isVsComputer && !_game.isOver && _game.turn == Disc.yellow) {
      await _runAiTurn();
    }
    await _handleGameEnd();
  }

  Future<void> _runAiTurn() async {
    setState(() => _aiThinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final col = _ai.chooseColumn(_game);
    if (col != null) {
      setState(() {
        _game.drop(col);
        _aiThinking = false;
      });
      await _playMoveSounds();
    } else {
      setState(() => _aiThinking = false);
    }
  }

  Future<void> _handleGameEnd() async {
    final level = _config.level;
    if (!_game.isOver || !_config.isVsComputer || level == null) return;

    final won = _game.winner == Disc.red;
    if (won) {
      await ConnectFourProgress.completeLevel(level);
    }
    if (!mounted) return;

    // Let the win line / final position sink in before the dialog.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || !_game.isOver) return;
    _showLevelDialog(won: won, level: level);
  }

  void _showLevelDialog({required bool won, required int level}) {
    final hasNext = won && level < ConnectFourLevels.maxLevel;
    final isDraw = _game.isDraw;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Level result',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      // ui-ux-pro-max: 150–300ms UI transitions; ease-out enter.
      transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 280),
      pageBuilder: (ctx, animation, secondary) {
        return _CartoonLevelResultDialog(
          won: won,
          isDraw: isDraw,
          level: level,
          hasNext: hasNext,
          onLevels: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pop();
          },
          onReplay: () {
            Navigator.of(ctx).pop();
            _newGame();
          },
          onNext: hasNext
              ? () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => ConnectFourPlayScreen(
                        config: ConnectFourConfig(
                          mode: _config.mode,
                          soundEnabled: _config.soundEnabled,
                          level: level + 1,
                        ),
                      ),
                    ),
                  );
                }
              : null,
        );
      },
      transitionBuilder: (ctx, animation, secondary, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  bool get _redActive =>
      !_game.isOver && _game.turn == Disc.red && !_aiThinking;
  bool get _yellowActive =>
      !_game.isOver && (_game.turn == Disc.yellow || _aiThinking);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isTutorial
              ? 'TUTORIAL'
              : (_config.level != null ? 'LEVEL ${_config.level}' : 'CONNECT 4'),
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _newGame,
            tooltip: 'New game',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.4,
            colors: [Color(0xFF1E3A5F), Color(0xFF0F1D33), Color(0xFF070D18)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 8, 16, 12),
            child: Column(
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _PlayerCard(
                        label: _redLabel,
                        color: ConnectFourBoard.redDisc,
                        active: _redActive,
                        alignEnd: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _statusText,
                          key: ValueKey(_statusText),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PlayerCard(
                        label: _yellowLabel,
                        color: ConnectFourBoard.yellowDisc,
                        active: _yellowActive,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform(
                                alignment: Alignment.bottomCenter,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0012)
                                  ..rotateX(-0.06),
                                child: ConnectFourBoard(
                                  game: _game,
                                  interactive: _canInteract,
                                  onColumnTap: _onColumnTap,
                                  hoverColumn: _hoverColumn,
                                  onHoverColumn: (col) =>
                                      setState(() => _hoverColumn = col),
                                  highlightColumn: _tutorialHighlight,
                                  allowedColumns: _tutorialAllowedColumns,
                                ),
                              ),
                              const _BoardStand(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isTutorial && !_game.isOver)
                  _TutorialCoachCard(
                    step: _tutorialStep,
                    onContinue: ConnectFourTutorial.needsContinue(_tutorialStep)
                        ? _onTutorialContinue
                        : null,
                  )
                else
                  Text(
                    _game.isOver
                        ? 'Tap the refresh button for a rematch.'
                        : 'Tap a column to drop your disc. Connect four to win.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom coach card that walks through tutorial steps.
class _TutorialCoachCard extends StatelessWidget {
  const _TutorialCoachCard({required this.step, this.onContinue});

  final ConnectFourTutorialStep step;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final stepIndex = ConnectFourTutorialStep.values.indexOf(step);
    final total = ConnectFourTutorialStep.values.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D9B8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CartoonTheme.titleOutline, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CartoonTheme.titleYellow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CartoonTheme.titleOutline, width: 2),
                ),
                child: Text(
                  'TIP ${stepIndex + 1}/$total',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: CartoonTheme.wood,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ConnectFourTutorial.titleFor(step),
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CartoonTheme.wood,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ConnectFourTutorial.bodyFor(step),
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: CartoonTheme.woodMuted,
            ),
          ),
          if (onContinue != null) ...[
            const SizedBox(height: 12),
            CartoonPillButton(
              icon: Icons.arrow_forward_rounded,
              label: ConnectFourTutorial.ctaFor(step),
              height: 46,
              isPrimary: true,
              fontSize: 18,
              asset: CartoonAssets.btnPillGold,
              onTap: onContinue,
            ),
          ] else if (step == ConnectFourTutorialStep.dropDisc) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 18,
                  color: CartoonTheme.woodMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  ConnectFourTutorial.ctaFor(step),
                  style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: CartoonTheme.woodMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Glassy player chip with a 3D disc token; lights up on the active turn.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.label,
    required this.color,
    required this.active,
    required this.alignEnd,
  });

  final String label;
  final Color color;
  final bool active;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final token = SizedBox(
      width: 26,
      height: 26,
      child: Disc3D(color: color),
    );
    final name = Flexible(
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.fredoka(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: active ? 1 : 0.6),
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.14 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: active
            ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)]
            : null,
      ),
      child: Row(
        mainAxisAlignment:
            alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: alignEnd
            ? [name, const SizedBox(width: 8), token]
            : [token, const SizedBox(width: 8), name],
      ),
    );
  }
}

/// The plastic feet under the board, like the physical toy.
class _BoardStand extends StatelessWidget {
  const _BoardStand();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          width: w,
          height: w * 0.075,
          child: CustomPaint(painter: _StandPainter()),
        );
      },
    );
  }
}

class _StandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final legW = size.width * 0.16;
    final rect = Offset.zero & size;

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ConnectFourBoard.frame,
          ConnectFourBoard.frameDark,
          Color(0xFF15295E),
        ],
      ).createShader(rect);

    for (final leftEdge in [size.width * 0.04, size.width * 0.80]) {
      final path = Path()
        ..moveTo(leftEdge + legW * 0.22, 0)
        ..lineTo(leftEdge + legW * 0.78, 0)
        ..lineTo(leftEdge + legW, size.height * 0.9)
        ..quadraticBezierTo(leftEdge + legW * 0.5, size.height * 1.15,
            leftEdge, size.height * 0.9)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.12),
      );
    }

    // Soft ground shadow.
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.02,
        size.height * 0.75,
        size.width * 0.96,
        size.height * 0.5,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(_StandPainter oldDelegate) => false;
}

/// Level-result modal styled per ui-ux-pro-max:
/// Claymorphism + Fredoka/Nunito, clear CTA hierarchy, reduced-motion safe.
class _CartoonLevelResultDialog extends StatelessWidget {
  const _CartoonLevelResultDialog({
    required this.won,
    required this.isDraw,
    required this.level,
    required this.hasNext,
    required this.onLevels,
    required this.onReplay,
    this.onNext,
  });

  final bool won;
  final bool isDraw;
  final int level;
  final bool hasNext;
  final VoidCallback onLevels;
  final VoidCallback onReplay;
  final VoidCallback? onNext;

  // Claymorphism accents (skill style guide) on the existing wood panel.
  static const _clayMint = Color(0xFF86EFAC);
  static const _clayPeach = Color(0xFFFDBCB4);
  static const _claySky = Color(0xFFADD8E6);

  String get _bannerTitle {
    if (won) {
      if (level == ConnectFourTutorial.level) return 'NICE!';
      return hasNext ? 'LEVEL UP!' : 'CHAMPION!';
    }
    if (isDraw) return 'DRAW!';
    return 'OH NO!';
  }

  String get _headline {
    if (won) {
      if (level == ConnectFourTutorial.level) return 'Tutorial complete!';
      return hasNext ? 'Level $level cleared!' : 'Campaign complete!';
    }
    if (isDraw) return 'Nobody connected four';
    return 'AI snagged this round';
  }

  String get _body {
    if (won) {
      if (level == ConnectFourTutorial.level) {
        return 'You know the rules. Level 2 unlocks now — the AI starts easy and gets sharper as you climb.';
      }
      return hasNext
          ? 'Level ${level + 1} unlocked. The AI got a little sharper.'
          : 'You beat all ${ConnectFourLevels.maxLevel} levels. What a legend!';
    }
    return 'Give it another shot — you know its tricks now.';
  }

  IconData get _statusIcon {
    if (won) return hasNext ? Icons.arrow_upward_rounded : Icons.emoji_events_rounded;
    if (isDraw) return Icons.handshake_rounded;
    return Icons.refresh_rounded;
  }

  Color get _badgeFill {
    if (won) return _clayMint;
    if (isDraw) return _claySky;
    return _clayPeach;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: _headline,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: CartoonPanel(
              title: _bannerTitle,
              maxWidth: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ClayStatusBadge(
                    icon: _statusIcon,
                    fill: _badgeFill,
                    animate: won && !reduceMotion,
                  ),
                  const SizedBox(height: CartoonTheme.spaceMd),
                  // Type hierarchy: 24 / 14 (skill modular scale)
                  Text(
                    _headline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: CartoonTheme.wood,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: CartoonTheme.spaceSm),
                  Text(
                    _body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: CartoonTheme.woodMuted,
                    ),
                  ),
                  if (hasNext) ...[
                    const SizedBox(height: CartoonTheme.spaceMd),
                    _NextLevelChip(
                      level: level + 1,
                      tier: ConnectFourLevels.tierName(level + 1),
                    ),
                  ],
                  const SizedBox(height: CartoonTheme.spaceXl),
                  // Primary CTA first — one clear job.
                  if (onNext != null) ...[
                    CartoonPillButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Next Level',
                      height: 54,
                      isPrimary: true,
                      asset: CartoonAssets.btnPillGold,
                      onTap: onNext,
                    ),
                    const SizedBox(height: CartoonTheme.spaceMd),
                  ],
                  // Secondary actions share a row (scan faster, less scroll).
                  Row(
                    children: [
                      Expanded(
                        child: CartoonPillButton(
                          icon: Icons.refresh_rounded,
                          label: won ? 'Replay' : 'Retry',
                          height: 48,
                          fontSize: 16,
                          asset: CartoonAssets.btnPillGreen,
                          onTap: onReplay,
                        ),
                      ),
                      const SizedBox(width: CartoonTheme.spaceMd),
                      Expanded(
                        child: CartoonPillButton(
                          icon: Icons.grid_view_rounded,
                          label: 'Levels',
                          height: 48,
                          fontSize: 16,
                          asset: CartoonAssets.btnPillRed,
                          onTap: onLevels,
                        ),
                      ),
                    ],
                  ),
                  if (won && hasNext) ...[
                    const SizedBox(height: CartoonTheme.spaceSm),
                    Text(
                      'Tip: connect four faster than the AI thinks.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CartoonTheme.woodMuted.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft 3D clay badge — thick border, inner+outer shadow (claymorphism).
class _ClayStatusBadge extends StatefulWidget {
  const _ClayStatusBadge({
    required this.icon,
    required this.fill,
    required this.animate,
  });

  final IconData icon;
  final Color fill;
  final bool animate;

  @override
  State<_ClayStatusBadge> createState() => _ClayStatusBadgeState();
}

class _ClayStatusBadgeState extends State<_ClayStatusBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      // One-shot pop only — skill: no continuous decorative animation.
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      )..forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.fill,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(3, 5),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.65),
              blurRadius: 6,
              offset: const Offset(-2, -2),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          size: 34,
          color: CartoonTheme.wood,
        ),
      ),
    );

    final controller = _controller;
    if (controller == null) return badge;

    return ScaleTransition(
      scale: TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.12)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.12, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 40,
        ),
      ]).animate(controller),
      child: badge,
    );
  }
}

class _NextLevelChip extends StatelessWidget {
  const _NextLevelChip({required this.level, required this.tier});

  final int level;
  final String tier;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Next level $level, $tier tier',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE566).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CartoonTheme.titleOutline, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(2, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: Disc3D(color: ConnectFourBoard.redDisc),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Level $level  ·  $tier',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: CartoonTheme.wood,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 22,
              height: 22,
              child: Disc3D(color: ConnectFourBoard.yellowDisc),
            ),
          ],
        ),
      ),
    );
  }
}

