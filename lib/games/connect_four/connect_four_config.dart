enum ConnectFourPlayMode { vsComputer, localTwoPlayer }

class ConnectFourConfig {
  const ConnectFourConfig({
    this.mode = ConnectFourPlayMode.vsComputer,
    this.soundEnabled = true,
    this.level,
  });

  final ConnectFourPlayMode mode;
  final bool soundEnabled;

  /// Campaign level (1-based) when playing vs computer; null in 2-player.
  final int? level;

  bool get isVsComputer => mode == ConnectFourPlayMode.vsComputer;
  bool get isLocalTwoPlayer => mode == ConnectFourPlayMode.localTwoPlayer;
}
