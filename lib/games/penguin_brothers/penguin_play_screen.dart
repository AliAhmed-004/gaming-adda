import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'penguin_config.dart';
import 'penguin_game.dart';
import 'penguin_sounds.dart';
import 'penguin_theme.dart';

class PenguinPlayScreen extends StatefulWidget {
  const PenguinPlayScreen({super.key, required this.config});

  final PenguinConfig config;

  @override
  State<PenguinPlayScreen> createState() => _PenguinPlayScreenState();
}

class _PenguinPlayScreenState extends State<PenguinPlayScreen> {
  late final PenguinSounds _sounds;
  late final PenguinGame _game;

  @override
  void initState() {
    super.initState();
    _sounds = PenguinSounds(enabled: widget.config.soundEnabled);
    _sounds.preload();
    _game = PenguinGame(config: widget.config, sounds: _sounds);
  }

  @override
  void dispose() {
    _sounds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GameWidget<PenguinGame>(
              game: _game,
              overlayBuilderMap: {
                'hud': (context, game) => _HudOverlay(game: game),
                'stageClear': (context, game) => _BannerOverlay(
                  title: 'Stage Clear!',
                  subtitle: 'Score ${game.score}',
                  actionLabel: 'Next',
                  onAction: () {
                    game.advanceOrWin();
                  },
                ),
                'gameOver': (context, game) => _BannerOverlay(
                  title: 'Game Over',
                  subtitle: 'Score ${game.score}',
                  actionLabel: 'Retry',
                  onAction: game.restartGame,
                  secondaryLabel: 'Quit',
                  onSecondary: () => Navigator.of(context).pop(),
                ),
                'gameWon': (context, game) => _BannerOverlay(
                  title: 'You Win!',
                  subtitle: 'Final score ${game.score}',
                  actionLabel: 'Play Again',
                  onAction: game.restartGame,
                  secondaryLabel: 'Quit',
                  onSecondary: () => Navigator.of(context).pop(),
                ),
              },
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                onPressed: () {
                  _game.paused = !_game.paused;
                  setState(() {});
                },
                icon: Icon(
                  _game.paused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _game.levelReady,
              builder: (context, ready, _) {
                if (!ready) return const SizedBox.shrink();
                return Stack(
                  children: [
                    Positioned(
                      left: 12,
                      bottom: 24,
                      child: _Joystick(
                        onChanged: (v) => _game.inputMoveX = v,
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 28,
                      child: Row(
                        children: [
                          _ActionButton(
                            label: 'Jump',
                            color: PenguinTheme.green,
                            onDown: () => _game.inputJump = true,
                            onUp: () => _game.inputJump = false,
                          ),
                          const SizedBox(width: 12),
                          _ActionButton(
                            label: 'Bomb',
                            color: PenguinTheme.pink,
                            onDown: () => _game.inputBomb = true,
                            onUp: () => _game.inputBomb = false,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_game.paused)
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Text('Paused', style: PenguinTheme.title()),
              ),
          ],
        ),
      ),
    );
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({required this.game});

  final PenguinGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: ValueListenableBuilder<int>(
            valueListenable: game.hudTick,
            builder: (context, _, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PenguinTheme.hudBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Lv ${game.stageIndex + 1}   ❤ ${game.lives}   '
                  '★ ${game.score}'
                  '${game.progress.keyCollected ? '   KEY' : ''}',
                  style: PenguinTheme.hud(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BannerOverlay extends StatelessWidget {
  const _BannerOverlay({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8D9B8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PenguinTheme.wood, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: PenguinTheme.title()),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: PenguinTheme.wood,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: PenguinTheme.green,
              ),
              child: Text(actionLabel),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Joystick extends StatefulWidget {
  const _Joystick({required this.onChanged});

  final ValueChanged<double> onChanged;

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) {
        setState(() => _dx = 0);
        widget.onChanged(0);
      },
      onPanCancel: () {
        setState(() => _dx = 0);
        widget.onChanged(0);
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Center(
          child: Transform.translate(
            offset: Offset(_dx * 28, 0),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _update(Offset local) {
    final v = ((local.dx - 60) / 60).clamp(-1.0, 1.0);
    setState(() => _dx = v);
    widget.onChanged(v.abs() < 0.15 ? 0 : v);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onDown,
    required this.onUp,
  });

  final String label;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
