import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navigation.dart';
import 'screens/store_home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter web can assert with negative viewInsets during browser resize /
  // soft-keyboard dismiss (engine bug). Swallow that so the app keeps running.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isBenignWebViewInsetsBug(details.exceptionAsString())) {
      return;
    }
    (previousOnError ?? FlutterError.presentError)(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (_isBenignWebViewInsetsBug(error.toString())) {
      return true;
    }
    return false;
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const GamingAddaApp());
}

bool _isBenignWebViewInsetsBug(String message) {
  return message.contains('ViewInsets cannot be negative') ||
      message.contains('_viewInsets.isNonNegative');
}

/// Clamps MediaQuery insets/padding so a transient negative engine value
/// never reaches layout (web resize / keyboard race).
Widget _clampMediaQuery(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  EdgeInsets clampInsets(EdgeInsets e) => EdgeInsets.only(
        left: e.left.clamp(0.0, double.infinity),
        top: e.top.clamp(0.0, double.infinity),
        right: e.right.clamp(0.0, double.infinity),
        bottom: e.bottom.clamp(0.0, double.infinity),
      );

  return MediaQuery(
    data: mq.copyWith(
      viewInsets: clampInsets(mq.viewInsets),
      padding: clampInsets(mq.padding),
      viewPadding: clampInsets(mq.viewPadding),
      systemGestureInsets: clampInsets(mq.systemGestureInsets),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}

class GamingAddaApp extends StatefulWidget {
  const GamingAddaApp({super.key, this.controller});

  final ThemeController? controller;

  @override
  State<GamingAddaApp> createState() => _GamingAddaAppState();
}

class _GamingAddaAppState extends State<GamingAddaApp> {
  late final ThemeController _controller =
      widget.controller ?? ThemeController();

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// On web, `?game=<id>` deep-links straight into a game's play screen
  /// (used for capturing store screenshots).
  Widget _resolveHome() {
    final params = Uri.base.queryParameters;
    final gameId = params['game'];
    if (gameId != null) {
      final screen = buildGamePlayScreen(gameId, demo: params['demo'] == '1');
      if (screen != null) return screen;
    }
    return const StoreHomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _controller,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'Gaming Adda',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _controller.mode,
            builder: kIsWeb ? _clampMediaQuery : null,
            home: _resolveHome(),
          );
        },
      ),
    );
  }
}

/// Kept for test imports that historically referenced [MyApp].
typedef MyApp = GamingAddaApp;
