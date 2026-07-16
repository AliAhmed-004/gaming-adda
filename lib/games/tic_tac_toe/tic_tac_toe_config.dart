enum TicTacToePlayMode { vsComputer, localTwoPlayer }

enum TicTacToeAiDifficulty { easy, medium, hard }

class TicTacToeConfig {
  const TicTacToeConfig({
    this.mode = TicTacToePlayMode.vsComputer,
    this.difficulty = TicTacToeAiDifficulty.medium,
    this.soundEnabled = true,
  });

  final TicTacToePlayMode mode;
  final TicTacToeAiDifficulty difficulty;
  final bool soundEnabled;

  bool get isVsComputer => mode == TicTacToePlayMode.vsComputer;
  bool get isLocalTwoPlayer => mode == TicTacToePlayMode.localTwoPlayer;
}
