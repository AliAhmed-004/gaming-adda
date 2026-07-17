import 'dart:io';

import 'package:flutter/services.dart';

/// Serves the bundled EmulatorJS files and ROM over `http://127.0.0.1:<port>`
/// so the WebView can fetch them with correct MIME types (wasm, js, zip, ...),
/// which `loadFlutterAsset` cannot provide.
class PenbrosArcadeServer {
  PenbrosArcadeServer._(this._server);

  static const _assetRoot = 'assets/penbros_arcade';

  static const _mimeTypes = <String, String>{
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.wasm': 'application/wasm',
    '.data': 'application/octet-stream',
    '.zip': 'application/zip',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.woff2': 'font/woff2',
  };

  final HttpServer _server;

  int get port => _server.port;

  Uri get indexUri =>
      Uri(scheme: 'http', host: '127.0.0.1', port: port, path: '/index.html');

  static Future<PenbrosArcadeServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final instance = PenbrosArcadeServer._(server);
    server.listen(instance._handleRequest);
    return instance;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    var path = Uri.decodeComponent(request.uri.path);
    if (path == '/' || path.isEmpty) path = '/index.html';

    if (path.contains('..')) {
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }

    try {
      final data = await rootBundle.load('$_assetRoot$path');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final dot = path.lastIndexOf('.');
      final ext = dot == -1 ? '' : path.substring(dot).toLowerCase();
      response.statusCode = HttpStatus.ok;
      // Cross-origin isolation exposes SharedArrayBuffer, which lets
      // EmulatorJS run the threaded FBNeo core (much smoother emulation).
      response.headers.set('Cross-Origin-Opener-Policy', 'same-origin');
      response.headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
      response.headers.contentType =
          ContentType.parse(_mimeTypes[ext] ?? 'application/octet-stream');
      response.contentLength = bytes.length;
      response.add(bytes);
    } catch (_) {
      response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }

  Future<void> stop() => _server.close(force: true);
}
