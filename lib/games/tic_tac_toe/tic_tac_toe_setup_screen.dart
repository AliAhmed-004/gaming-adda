import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_assets.dart';
import '../../widgets/cartoon_ui/cartoon_buttons.dart';
import '../../widgets/cartoon_ui/cartoon_panel.dart';
import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'tic_tac_toe_config.dart';
import 'tic_tac_toe_play_screen.dart';

class TicTacToeSetupScreen extends StatefulWidget {
  const TicTacToeSetupScreen({super.key});

  @override
  State<TicTacToeSetupScreen> createState() => _TicTacToeSetupScreenState();
}

class _TicTacToeSetupScreenState extends State<TicTacToeSetupScreen> {
  var _mode = TicTacToePlayMode.vsComputer;
  var _difficulty = TicTacToeAiDifficulty.medium;
  var _soundEnabled = true;

  void _startGame() {
    final config = TicTacToeConfig(
      mode: _mode,
      difficulty: _difficulty,
      soundEnabled: _soundEnabled,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TicTacToePlayScreen(config: config),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            'How to play',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Take turns placing X and O on the 3×3 grid. '
            'Get three in a row — horizontally, vertically, or diagonally — to win. '
            'X always goes first. If the board fills with no winner, it is a draw.',
            style: GoogleFonts.nunito(height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(backgroundColor: scheme.primary),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  String get _modeHint {
    if (_mode == TicTacToePlayMode.localTwoPlayer) {
      return 'Pass-and-play on this device. X moves first.';
    }
    return switch (_difficulty) {
      TicTacToeAiDifficulty.easy => 'You are X. AI picks random moves.',
      TicTacToeAiDifficulty.medium => 'You are X. AI blocks and goes for wins.',
      TicTacToeAiDifficulty.hard => 'You are X. AI plays perfectly — good luck!',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ui/bg_jungle.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final circleSize = narrow ? 48.0 : 56.0;
              final pillHeight = narrow ? 48.0 : 52.0;
              final maxPanel = constraints.maxWidth.clamp(280.0, 400.0);

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? 12 : 20,
                    vertical: CartoonTheme.spaceLg,
                  ),
                  child: CartoonPanel(
                    title: 'SETTINGS',
                    maxWidth: maxPanel,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'QUICK',
                            textAlign: TextAlign.center,
                            style: CartoonTheme.sectionLabel(),
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceSm),
                        Row(
                          children: [
                            Expanded(
                              child: CartoonCircleButton(
                                icon: _soundEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                label: 'Sound',
                                size: circleSize,
                                enabled: _soundEnabled,
                                semanticHint: _soundEnabled
                                    ? 'Sound on. Tap to mute.'
                                    : 'Sound off. Tap to unmute.',
                                asset: _soundEnabled
                                    ? CartoonAssets.btnCircleGreen
                                    : CartoonAssets.btnCircleOff,
                                onTap: () => setState(
                                  () => _soundEnabled = !_soundEnabled,
                                ),
                              ),
                            ),
                            Expanded(
                              child: CartoonCircleButton(
                                icon: Icons.help_outline_rounded,
                                label: 'Help',
                                size: circleSize,
                                semanticHint: 'Show how to play',
                                onTap: _showHelp,
                              ),
                            ),
                            Expanded(
                              child: CartoonCircleButton(
                                icon: Icons.home_rounded,
                                label: 'Home',
                                size: circleSize,
                                asset: CartoonAssets.btnCircleBlue,
                                semanticHint: 'Return to game store',
                                onTap: _goHome,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: CartoonTheme.spaceXl),
                        Semantics(
                          header: true,
                          child: Text(
                            'MODE',
                            textAlign: TextAlign.center,
                            style: CartoonTheme.sectionLabel(),
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceSm),
                        CartoonPillButton(
                          icon: Icons.smart_toy_outlined,
                          label: 'Vs Computer',
                          height: pillHeight,
                          selected: _mode == TicTacToePlayMode.vsComputer,
                          onTap: () => setState(
                            () => _mode = TicTacToePlayMode.vsComputer,
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceMd),
                        CartoonPillButton(
                          icon: Icons.people_outline,
                          label: '2 Players',
                          height: pillHeight,
                          selected:
                              _mode == TicTacToePlayMode.localTwoPlayer,
                          onTap: () => setState(
                            () => _mode = TicTacToePlayMode.localTwoPlayer,
                          ),
                        ),
                        if (_mode == TicTacToePlayMode.vsComputer) ...[
                          const SizedBox(height: CartoonTheme.spaceXl),
                          Semantics(
                            header: true,
                            child: Text(
                              'DIFFICULTY',
                              textAlign: TextAlign.center,
                              style: CartoonTheme.sectionLabel(),
                            ),
                          ),
                          const SizedBox(height: CartoonTheme.spaceSm),
                          CartoonPillButton(
                            icon: Icons.sentiment_satisfied_alt_outlined,
                            label: 'Easy',
                            height: pillHeight,
                            selected:
                                _difficulty == TicTacToeAiDifficulty.easy,
                            onTap: () => setState(
                              () => _difficulty = TicTacToeAiDifficulty.easy,
                            ),
                          ),
                          const SizedBox(height: CartoonTheme.spaceMd),
                          CartoonPillButton(
                            icon: Icons.sentiment_neutral_outlined,
                            label: 'Medium',
                            height: pillHeight,
                            selected:
                                _difficulty == TicTacToeAiDifficulty.medium,
                            onTap: () => setState(
                              () =>
                                  _difficulty = TicTacToeAiDifficulty.medium,
                            ),
                          ),
                          const SizedBox(height: CartoonTheme.spaceMd),
                          CartoonPillButton(
                            icon: Icons.sentiment_very_dissatisfied_outlined,
                            label: 'Hard',
                            height: pillHeight,
                            selected:
                                _difficulty == TicTacToeAiDifficulty.hard,
                            onTap: () => setState(
                              () => _difficulty = TicTacToeAiDifficulty.hard,
                            ),
                          ),
                        ],
                        const SizedBox(height: CartoonTheme.spaceSm),
                        Text(
                          _modeHint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: CartoonTheme.woodMuted,
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceXl),
                        CartoonPillButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Start Game',
                          height: pillHeight + 4,
                          isPrimary: true,
                          asset: CartoonAssets.btnPillGold,
                          onTap: _startGame,
                        ),
                        const SizedBox(height: CartoonTheme.spaceMd),
                        CartoonPillButton(
                          icon: Icons.arrow_back_rounded,
                          label: 'Back',
                          height: pillHeight,
                          asset: CartoonAssets.btnPillRed,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
