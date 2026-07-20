import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_assets.dart';
import '../../widgets/cartoon_ui/cartoon_buttons.dart';
import '../../widgets/cartoon_ui/cartoon_panel.dart';
import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'connect_four_config.dart';
import 'connect_four_levels_screen.dart';
import 'connect_four_play_screen.dart';

class ConnectFourSetupScreen extends StatefulWidget {
  const ConnectFourSetupScreen({super.key});

  @override
  State<ConnectFourSetupScreen> createState() => _ConnectFourSetupScreenState();
}

class _ConnectFourSetupScreenState extends State<ConnectFourSetupScreen> {
  var _mode = ConnectFourPlayMode.vsComputer;
  var _soundEnabled = true;

  void _startGame() {
    if (_mode == ConnectFourPlayMode.vsComputer) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ConnectFourLevelsScreen(soundEnabled: _soundEnabled),
        ),
      );
      return;
    }
    final config = ConnectFourConfig(mode: _mode, soundEnabled: _soundEnabled);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConnectFourPlayScreen(config: config),
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
            'Red moves first. Tap a column to drop your disc — it falls to '
            'the lowest empty slot. Connect four of your discs in a row '
            '(horizontally, vertically, or diagonally) before your opponent '
            'does to win.',
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

  String get _modeHint => _mode == ConnectFourPlayMode.vsComputer
      ? 'Battle through 365 levels — the AI gets stronger as you climb.'
      : 'Pass-and-play on this device. Red moves first.';

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
                          selected: _mode == ConnectFourPlayMode.vsComputer,
                          onTap: () => setState(
                            () => _mode = ConnectFourPlayMode.vsComputer,
                          ),
                        ),
                        const SizedBox(height: CartoonTheme.spaceMd),
                        CartoonPillButton(
                          icon: Icons.people_outline,
                          label: '2 Players',
                          height: pillHeight,
                          selected:
                              _mode == ConnectFourPlayMode.localTwoPlayer,
                          onTap: () => setState(
                            () => _mode = ConnectFourPlayMode.localTwoPlayer,
                          ),
                        ),
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
