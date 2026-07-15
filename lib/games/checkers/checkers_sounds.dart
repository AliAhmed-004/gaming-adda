import 'package:audioplayers/audioplayers.dart';

/// Short SFX for Checkers. No-ops when [enabled] is false.
class CheckersSounds {
  CheckersSounds({required this.enabled});

  final bool enabled;

  final _select = AudioPlayer();
  final _move = AudioPlayer();
  final _capture = AudioPlayer();
  final _win = AudioPlayer();

  Future<void> preload() async {
    if (!enabled) return;
    try {
      await Future.wait([
        _select.setSource(AssetSource('sounds/select.wav')),
        _move.setSource(AssetSource('sounds/move.wav')),
        _capture.setSource(AssetSource('sounds/capture.wav')),
        _win.setSource(AssetSource('sounds/win.wav')),
      ]);
    } catch (_) {
      // Ignore preload failures (tests / missing plugin).
    }
  }

  Future<void> select() => _play(_select, 'sounds/select.wav');
  Future<void> move() => _play(_move, 'sounds/move.wav');
  Future<void> capture() => _play(_capture, 'sounds/capture.wav');
  Future<void> win() => _play(_win, 'sounds/win.wav');

  Future<void> _play(AudioPlayer player, String asset) async {
    if (!enabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {
      // Ignore audio failures (missing plugin on some test hosts).
    }
  }

  Future<void> dispose() async {
    await Future.wait([
      _select.dispose(),
      _move.dispose(),
      _capture.dispose(),
      _win.dispose(),
    ]);
  }
}
