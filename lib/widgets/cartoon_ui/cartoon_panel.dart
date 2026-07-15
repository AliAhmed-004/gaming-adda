import 'package:flutter/material.dart';

import 'cartoon_assets.dart';
import 'cartoon_theme.dart';

/// Wooden framed panel with a title banner, matching casual game menus.
class CartoonPanel extends StatelessWidget {
  const CartoonPanel({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = CartoonTheme.panelMaxWidth,
  });

  final String title;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 360 ? 24.0 : 28.0;

    return Semantics(
      container: true,
      label: title,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      CartoonAssets.panelWood,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'Wooden settings panel',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 48, 28, 28),
                    child: child,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 40,
              right: 40,
              child: SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        CartoonAssets.bannerWood,
                        fit: BoxFit.fill,
                        semanticLabel: '',
                      ),
                    ),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: CartoonTheme.bannerTitle(fontSize: titleSize),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
