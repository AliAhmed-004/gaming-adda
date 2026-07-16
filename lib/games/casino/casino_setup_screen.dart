import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_assets.dart';
import '../../widgets/cartoon_ui/cartoon_buttons.dart';
import '../../widgets/cartoon_ui/cartoon_panel.dart';
import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'casino_config.dart';
import 'casino_play_screen.dart';

class CasinoSetupScreen extends StatefulWidget {
  const CasinoSetupScreen({super.key});

  @override
  State<CasinoSetupScreen> createState() => _CasinoSetupScreenState();
}

class _CasinoSetupScreenState extends State<CasinoSetupScreen> {
  var _soundEnabled = true;

  void _startGame() {
    final config = CasinoConfig(soundEnabled: _soundEnabled);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CasinoPlayScreen(config: config)),
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
            'How to play Card Match',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Each turn you draw a card into your hand. Select a card — it lifts '
            'with a glow. Match by number on the floor, the opponent\'s collection, '
            'or your own collection; tap a glowing card to collect. A match lets you '
            'draw and play again. Your turn ends only when you drop a card on the floor. '
            'Most collected cards when the deck runs out wins.',
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: CartoonPanel(
                title: 'CARD MATCH',
                maxWidth: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CartoonCircleButton(
                            icon: _soundEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            label: 'Sound',
                            enabled: _soundEnabled,
                            onTap: () =>
                                setState(() => _soundEnabled = !_soundEnabled),
                          ),
                        ),
                        Expanded(
                          child: CartoonCircleButton(
                            icon: Icons.help_outline_rounded,
                            label: 'Help',
                            onTap: _showHelp,
                          ),
                        ),
                        Expanded(
                          child: CartoonCircleButton(
                            icon: Icons.home_rounded,
                            label: 'Home',
                            asset: CartoonAssets.btnCircleBlue,
                            onTap: _goHome,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CartoonTheme.spaceXl),
                    CartoonPillButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Start Game',
                      isPrimary: true,
                      asset: CartoonAssets.btnPillGold,
                      onTap: _startGame,
                    ),
                    const SizedBox(height: CartoonTheme.spaceMd),
                    CartoonPillButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Back',
                      asset: CartoonAssets.btnPillRed,
                      onTap: () => Navigator.of(context).pop(),
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
