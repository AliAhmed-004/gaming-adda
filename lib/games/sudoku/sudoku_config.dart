enum SudokuPlayMode { campaign, freePlay }

enum SudokuDifficulty { easy, medium, hard }

class SudokuConfig {
  const SudokuConfig({
    this.mode = SudokuPlayMode.campaign,
    this.soundEnabled = true,
    this.level,
    this.difficulty,
  });

  final SudokuPlayMode mode;
  final bool soundEnabled;

  /// Campaign level (1-based); null in free play.
  final int? level;

  /// Free-play difficulty; null in campaign.
  final SudokuDifficulty? difficulty;

  bool get isCampaign => mode == SudokuPlayMode.campaign;
  bool get isFreePlay => mode == SudokuPlayMode.freePlay;
}
