import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            home: const StoreHomeScreen(),
          );
        },
      ),
    );
  }
}

/// Kept for test imports that historically referenced [MyApp].
typedef MyApp = GamingAddaApp;
