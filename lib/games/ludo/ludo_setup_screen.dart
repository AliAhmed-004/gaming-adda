import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_assets.dart';
import '../../widgets/cartoon_ui/cartoon_buttons.dart';
import '../../widgets/cartoon_ui/cartoon_panel.dart';
import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'ludo_config.dart';
import 'ludo_logic.dart';
import 'ludo_play_screen.dart';
import 'ludo_theme.dart';

class LudoSetupScreen extends StatefulWidget {
  const LudoSetupScreen({super.key});

  @override
  State<LudoSetupScreen> createState() => _LudoSetupScreenState();
}

class _LudoSetupScreenState extends State<LudoSetupScreen> {
  var _playerCount = 4;
  var _mode = LudoPlayMode.vsComputer;
  var _humanColor = LudoColor.red;
  var _soundEnabled = true;

  List<LudoColor> get _active => activeColorsForPlayerCount(_playerCount);

  void _setPlayerCount(int n) {
    setState(() {
      _playerCount = n;
      if (!_active.contains(_humanColor)) {
        _humanColor = _active.first;
      }
    });
  }

  void _startGame() {
    final config = LudoConfig(
      playerCount: _playerCount,
      mode: _mode,
      humanColor: _humanColor,
      soundEnabled: _soundEnabled,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LudoPlayScreen(config: config)),
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
            'Roll a 6 to leave your yard. Move around the board clockwise. '
            'Land on an opponent (not on a safe star) to send them home. '
            'Exact rolls finish a token. First to get all four home wins. '
            'Rolling a 6, capturing, or finishing earns another turn.',
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
    if (_mode == LudoPlayMode.vsComputer) {
      return 'You play as ${_humanColor.label}; other seats are AI.';
    }
    return 'Pass-and-play on this device. Red rolls first.';
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
              final maxPanel = constraints.maxWidth.clamp(280.0, 420.0);

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
                          LudoTheme.iconAsset,
                          width: narrow ? 88 : 104,
                          height: narrow ? 88 : 104,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: CartoonTheme.spaceMd),
                      Text(
                        'LUDO',
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: CartoonTheme.spaceLg),
                      CartoonPanel(
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
                                'PLAYERS',
                                textAlign: TextAlign.center,
                                style: CartoonTheme.sectionLabel(),
                              ),
                            ),
                            const SizedBox(height: CartoonTheme.spaceSm),
                            Row(
                              children: [
                                for (final n in const [2, 3, 4]) ...[
                                  if (n != 2) const SizedBox(width: 8),
                                  Expanded(
                                    child: CartoonPillButton(
                                      label: '$n',
                                      height: pillHeight,
                                      selected: _playerCount == n,
                                      onTap: () => _setPlayerCount(n),
                                    ),
                                  ),
                                ],
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
                              selected: _mode == LudoPlayMode.vsComputer,
                              onTap: () => setState(
                                () => _mode = LudoPlayMode.vsComputer,
                              ),
                            ),
                            const SizedBox(height: CartoonTheme.spaceMd),
                            CartoonPillButton(
                              icon: Icons.people_outline,
                              label: 'Local Hotseat',
                              height: pillHeight,
                              selected: _mode == LudoPlayMode.localHotseat,
                              onTap: () => setState(
                                () => _mode = LudoPlayMode.localHotseat,
                              ),
                            ),
                            if (_mode == LudoPlayMode.vsComputer) ...[
                              const SizedBox(height: CartoonTheme.spaceXl),
                              Semantics(
                                header: true,
                                child: Text(
                                  'YOUR COLOR',
                                  textAlign: TextAlign.center,
                                  style: CartoonTheme.sectionLabel(),
                                ),
                              ),
                              const SizedBox(height: CartoonTheme.spaceSm),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final c in _active)
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _humanColor = c),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: LudoTheme.vivid(c),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _humanColor == c
                                                ? Colors.white
                                                : Colors.black26,
                                            width: _humanColor == c ? 3 : 1,
                                          ),
                                          boxShadow: _humanColor == c
                                              ? [
                                                  BoxShadow(
                                                    color: LudoTheme.vivid(
                                                      c,
                                                    ).withValues(alpha: 0.5),
                                                    blurRadius: 8,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                ],
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
}
