import 'package:flutter/material.dart';

import 'cartoon_ui/cartoon_assets.dart';
import 'cartoon_ui/cartoon_buttons.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.onPressed,
    this.compact = false,
    this.label = 'Play',
  });

  final VoidCallback onPressed;
  final bool compact;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return CartoonPillButton(
        label: label,
        onTap: onPressed,
        height: 36,
        fontSize: 15,
        asset: CartoonAssets.btnPillGold,
      );
    }

    return CartoonPillButton(
      label: label,
      onTap: onPressed,
      icon: Icons.play_arrow_rounded,
      height: 52,
      fontSize: 18,
      asset: CartoonAssets.btnPillGold,
    );
  }
}
