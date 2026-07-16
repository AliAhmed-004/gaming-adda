import 'package:audioplayers/audioplayers.dart';

class CasinoSounds {
  CasinoSounds({required this.enabled});

  final bool enabled;

  final _select = AudioPlayer();
  final _play = AudioPlayer();
  final _capture = AudioPlayer();
  final _win = AudioPlayer();

  Future<void> preload() async {
    if (!enabled) return;
    try {
      await Future.wait([
        _select.setSource(AssetSource('sounds/select.wav')),
        _play.setSource(AssetSource('sounds/move.wav')),
        _capture.setSource(AssetSource('sounds/capture.wav')),
        _win.setSource(AssetSource('sounds/win.wav')),
      ]);
    } catch (_) {}
  }

  Future<void> select() => _playAsset(_select, 'sounds/select.wav');
  Future<void> playCard() => _playAsset(_play, 'sounds/move.wav');
  Future<void> capture() => _playAsset(_capture, 'sounds/capture.wav');
  Future<void> win() => _playAsset(_win, 'sounds/win.wav');

  Future<void> _playAsset(AudioPlayer player, String asset) async {
    if (!enabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await Future.wait([
      _select.dispose(),
      _play.dispose(),
      _capture.dispose(),
      _win.dispose(),
    ]);
  }
}
