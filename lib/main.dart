import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navigation.dart';
import 'screens/store_home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const GamingAddaApp());
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
            home: _resolveHome(),
          );
        },
      ),
    );
  }
}

/// Kept for test imports that historically referenced [MyApp].
typedef MyApp = GamingAddaApp;
