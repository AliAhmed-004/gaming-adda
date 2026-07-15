import 'package:flutter/material.dart';

import 'cartoon_assets.dart';
import 'cartoon_pressable.dart';
import 'cartoon_theme.dart';

class CartoonCircleButton extends StatelessWidget {
  const CartoonCircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.asset = CartoonAssets.btnCircleGreen,
    this.enabled = true,
    this.size = CartoonTheme.minTouch,
    this.showLabel = true,
    this.semanticHint,
    this.labelOnLight = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String asset;
  final bool enabled;
  final double size;
  final bool showLabel;
  final String? semanticHint;

  /// When true, label uses dark wood color (cream panel). White when false.
  final bool labelOnLight;

  @override
  Widget build(BuildContext context) {
    final touch = size.clamp(CartoonTheme.minTouch, 72.0);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: touch,
          height: touch,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(asset, fit: BoxFit.contain, semanticLabel: ''),
              Icon(icon, color: Colors.white, size: touch * 0.42),
              if (!enabled)
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: const SizedBox.expand(),
                ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: CartoonTheme.spaceXs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: labelOnLight
                ? CartoonTheme.circleLabel()
                : CartoonTheme.circleLabel().copyWith(color: Colors.white),
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      label: label,
      hint: semanticHint,
      toggled: semanticHint != null ? enabled : null,
      enabled: onTap != null,
      child: Opacity(
        opacity: enabled ? 1 : 0.85,
        child: CartoonPressable(
          onTap: onTap,
          enabled: onTap != null,
          borderRadius: BorderRadius.circular(touch),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: CartoonTheme.minTouch,
              minHeight: CartoonTheme.minTouch,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CartoonTheme.spaceXs,
                vertical: CartoonTheme.spaceXs,
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

class CartoonPillButton extends StatelessWidget {
  const CartoonPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.asset = CartoonAssets.btnPillGreen,
    this.selected = false,
    this.isPrimary = false,
    this.height = CartoonTheme.minTouch,
    this.width,
    this.fontSize,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final String asset;
  final bool selected;
  final bool isPrimary;
  final double height;
  final double? width;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    // Category chips may be shorter; main CTAs should pass ≥ 48.
    final h = height;
    final textSize = fontSize ?? (isPrimary ? 22.0 : 20.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: AnimatedScale(
        scale: selected && !isPrimary ? 1.02 : 1,
        duration: Duration(milliseconds: reduceMotion ? 0 : 120),
        child: CartoonPressable(
          onTap: onTap,
          pressedScale: 0.97,
          borderRadius: BorderRadius.circular(h),
          child: SizedBox(
            height: h,
            width: width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(h),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.transparent,
                  width: selected ? 2.5 : 0,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      asset,
                      fit: BoxFit.fill,
                      semanticLabel: '',
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: h * 0.3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize:
                          width == null ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: textSize + 4),
                          const SizedBox(width: CartoonTheme.spaceMd),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CartoonTheme.pillLabel(fontSize: textSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact chip-sized pill for category filters.
class CartoonCategoryChip extends StatelessWidget {
  const CartoonCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CartoonPillButton(
      label: label,
      onTap: onTap,
      selected: selected,
      height: 40,
      width: 108,
      fontSize: 15,
      asset: selected
          ? CartoonAssets.btnPillGold
          : CartoonAssets.btnPillGreen,
    );
  }
}
