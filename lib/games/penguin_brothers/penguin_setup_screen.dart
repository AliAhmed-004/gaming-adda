import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_buttons.dart';
import '../../widgets/cartoon_ui/cartoon_panel.dart';
import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'penguin_assets.dart';
import 'penguin_config.dart';
import 'penguin_play_screen.dart';

class PenguinSetupScreen extends StatefulWidget {
  const PenguinSetupScreen({super.key});

  @override
  State<PenguinSetupScreen> createState() => _PenguinSetupScreenState();
}

class _PenguinSetupScreenState extends State<PenguinSetupScreen> {
  var _mode = PenguinPlayMode.solo;
  var _soundEnabled = true;

  void _startGame() {
    final config = PenguinConfig(mode: _mode, soundEnabled: _soundEnabled);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PenguinPlayScreen(config: config),
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
            'Move with the stick, jump, and throw bombs. Clear every enemy, '
            'pick up the disc key, then carry it to the exit door. '
            'Bombs hurt you too — keep your distance! '
            'Break barrels for power-ups. Beat all five stages, including King Kuda.',
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
    if (_mode == PenguinPlayMode.aiPartner) {
      return 'You control green Donfi; pink Turu helps as AI.';
    }
    return 'You play as Donfi alone across five stages.';
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

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? 12 : 20,
                    vertical: CartoonTheme.spaceLg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          PenguinAssets.icon,
                          height: narrow ? 96 : 120,
                          width: narrow ? 96 : 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: CartoonTheme.spaceLg),
                      CartoonPanel(
                        title: 'Penguin Brothers',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('MODE', style: CartoonTheme.sectionLabel()),
                            const SizedBox(height: CartoonTheme.spaceSm),
                            Wrap(
                              spacing: CartoonTheme.spaceSm,
                              runSpacing: CartoonTheme.spaceSm,
                              children: [
                                _modeChip(
                                  label: 'Solo',
                                  selected: _mode == PenguinPlayMode.solo,
                                  onTap: () => setState(
                                    () => _mode = PenguinPlayMode.solo,
                                  ),
                                ),
                                _modeChip(
                                  label: 'AI Partner',
                                  selected: _mode == PenguinPlayMode.aiPartner,
                                  onTap: () => setState(
                                    () => _mode = PenguinPlayMode.aiPartner,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: CartoonTheme.spaceSm),
                            Text(
                              _modeHint,
                              style: GoogleFonts.nunito(
                                color: CartoonTheme.woodMuted,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: CartoonTheme.spaceLg),
                            Text('SOUND', style: CartoonTheme.sectionLabel()),
                            const SizedBox(height: CartoonTheme.spaceSm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CartoonCircleButton(
                                icon: _soundEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                asset: _soundEnabled
                                    ? 'assets/ui/btn_circle_green.png'
                                    : 'assets/ui/btn_circle_off.png',
                                label: _soundEnabled ? 'On' : 'Off',
                                size: circleSize,
                                enabled: _soundEnabled,
                                onTap: () => setState(
                                  () => _soundEnabled = !_soundEnabled,
                                ),
                              ),
                            ),
                            const SizedBox(height: CartoonTheme.spaceXl),
                            CartoonPillButton(
                              icon: Icons.play_arrow_rounded,
                              asset: 'assets/ui/btn_pill_gold.png',
                              label: 'Start',
                              height: pillHeight,
                              isPrimary: true,
                              onTap: _startGame,
                            ),
                            const SizedBox(height: CartoonTheme.spaceSm),
                            Row(
                              children: [
                                Expanded(
                                  child: CartoonPillButton(
                                    icon: Icons.help_outline_rounded,
                                    asset: 'assets/ui/btn_pill_green.png',
                                    label: 'Help',
                                    height: pillHeight * 0.9,
                                    onTap: _showHelp,
                                  ),
                                ),
                                const SizedBox(width: CartoonTheme.spaceSm),
                                Expanded(
                                  child: CartoonPillButton(
                                    icon: Icons.home_rounded,
                                    asset: 'assets/ui/btn_pill_red.png',
                                    label: 'Home',
                                    height: pillHeight * 0.9,
                                    onTap: _goHome,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? CartoonTheme.titleYellow : CartoonTheme.cream,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: CartoonTheme.wood,
            ),
          ),
        ),
      ),
    );
  }
}
