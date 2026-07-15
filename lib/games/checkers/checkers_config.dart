enum CheckersPlayMode { vsComputer, localTwoPlayer }

class CheckersConfig {
  const CheckersConfig({
    this.mode = CheckersPlayMode.vsComputer,
    this.soundEnabled = true,
  });

  final CheckersPlayMode mode;
  final bool soundEnabled;

  bool get isVsComputer => mode == CheckersPlayMode.vsComputer;
  bool get isLocalTwoPlayer => mode == CheckersPlayMode.localTwoPlayer;
}
