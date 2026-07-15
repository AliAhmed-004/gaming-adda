import 'package:audioplayers/audioplayers.dart';

/// Short SFX for Penguin Brothers. No-ops when [enabled] is false.
class PenguinSounds {
  PenguinSounds({required this.enabled});

  final bool enabled;

  final _select = AudioPlayer();
  final _throw = AudioPlayer();
  final _explode = AudioPlayer();
  final _pickup = AudioPlayer();
  final _hurt = AudioPlayer();
  final _win = AudioPlayer();

  Future<void> preload() async {
    if (!enabled) return;
    try {
      await Future.wait([
        _select.setSource(AssetSource('sounds/select.wav')),
        _throw.setSource(AssetSource('sounds/bomb_throw.wav')),
        _explode.setSource(AssetSource('sounds/explode.wav')),
        _pickup.setSource(AssetSource('sounds/pickup.wav')),
        _hurt.setSource(AssetSource('sounds/hurt.wav')),
        _win.setSource(AssetSource('sounds/win.wav')),
      ]);
    } catch (_) {}
  }

  Future<void> select() => _play(_select, 'sounds/select.wav');
  Future<void> bombThrow() => _play(_throw, 'sounds/bomb_throw.wav');
  Future<void> explode() => _play(_explode, 'sounds/explode.wav');
  Future<void> pickup() => _play(_pickup, 'sounds/pickup.wav');
  Future<void> hurt() => _play(_hurt, 'sounds/hurt.wav');
  Future<void> win() => _play(_win, 'sounds/win.wav');

  Future<void> _play(AudioPlayer player, String asset) async {
    if (!enabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await Future.wait([
      _select.dispose(),
      _throw.dispose(),
      _explode.dispose(),
      _pickup.dispose(),
      _hurt.dispose(),
      _win.dispose(),
    ]);
  }
}
