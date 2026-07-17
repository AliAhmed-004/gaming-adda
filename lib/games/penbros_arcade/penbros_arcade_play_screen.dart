import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'penbros_arcade_server.dart';

/// Runs the original Penguin Brothers arcade ROM through the EmulatorJS FBNeo
/// core inside a WebView, served from a local HTTP server. Landscape-only,
/// immersive fullscreen; touch controls are rendered by EmulatorJS itself.
class PenbrosArcadePlayScreen extends StatefulWidget {
  const PenbrosArcadePlayScreen({super.key});

  @override
  State<PenbrosArcadePlayScreen> createState() =>
      _PenbrosArcadePlayScreenState();
}

class _PenbrosArcadePlayScreenState extends State<PenbrosArcadePlayScreen> {
  PenbrosArcadeServer? _server;
  WebViewController? _controller;
  var _loading = true;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _start();
  }

  Future<void> _start() async {
    try {
      final server = await PenbrosArcadeServer.start();
      if (!mounted) {
        await server.stop();
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidWebViewController.enableDebugging(true);
      }
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setOnConsoleMessage((message) {
          debugPrint('[penbros webview] ${message.level.name}: '
              '${message.message}');
        })
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (error) {
              debugPrint('[penbros webview] resource error: '
                  '${error.errorCode} ${error.description} '
                  '(mainFrame: ${error.isForMainFrame})');
              // Sub-resource failures (e.g. a missing localization file) are
              // handled by EmulatorJS; only treat main-frame errors as fatal.
              if (error.isForMainFrame == true && mounted) {
                setState(() {
                  _loading = false;
                  _hasError = true;
                });
              }
            },
          ),
        );
      await controller.loadRequest(server.indexUri);
      setState(() {
        _server = server;
        _controller = controller;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _server?.stop();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller != null && !_hasError)
            WebViewWidget(controller: _controller!),
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videogame_asset_off_rounded,
                      size: 48, color: Colors.white54),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not start the arcade emulator',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _hasError = false;
                      });
                      _server?.stop();
                      _server = null;
                      _controller = null;
                      _start();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (_loading && !_hasError)
            const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            ),
          // Close button overlaid in the top-left corner.
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: Material(
                color: Colors.black45,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
