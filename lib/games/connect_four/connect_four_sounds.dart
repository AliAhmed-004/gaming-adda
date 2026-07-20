import 'package:audioplayers/audioplayers.dart';

/// Short SFX for Connect 4. No-ops when [enabled] is false.
class ConnectFourSounds {
  ConnectFourSounds({required this.enabled});

  final bool enabled;

  final _drop = AudioPlayer();
  final _win = AudioPlayer();

  Future<void> preload() async {
    if (!enabled) return;
    try {
      await Future.wait([
        _drop.setSource(AssetSource('sounds/move.wav')),
        _win.setSource(AssetSource('sounds/win.wav')),
      ]);
    } catch (_) {
      // Ignore preload failures (tests / missing plugin).
    }
  }

  Future<void> drop() => _play(_drop, 'sounds/move.wav');
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
    await Future.wait([_drop.dispose(), _win.dispose()]);
  }
}
