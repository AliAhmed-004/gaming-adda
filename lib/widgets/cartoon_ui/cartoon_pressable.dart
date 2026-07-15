import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Scales down briefly on press for a toy-button feel.
class CartoonPressable extends StatefulWidget {
  const CartoonPressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.pressedScale = 0.92,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double pressedScale;
  final BorderRadius? borderRadius;

  @override
  State<CartoonPressable> createState() => _CartoonPressableState();
}

class _CartoonPressableState extends State<CartoonPressable> {
  var _pressed = false;

  bool get _canTap => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_canTap || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1,
      duration: Duration(milliseconds: reduceMotion ? 0 : 90),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canTap
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onTap!();
                }
              : null,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
          child: widget.child,
        ),
      ),
    );
  }
}
