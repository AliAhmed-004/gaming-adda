/// Guided steps for campaign level 1 (tutorial).
enum SudokuTutorialStep {
  /// Goal of the game.
  welcome,

  /// Force selecting a highlighted empty cell.
  selectCell,

  /// Enter the correct digit from the pad.
  enterDigit,

  /// Brief intro to pencil notes.
  notes,

  /// Tutorial coaching finished; solve the rest.
  freePlay,
}

abstract final class SudokuTutorial {
  static const int level = 1;

  static bool isTutorialLevel(int? level) => level == SudokuTutorial.level;

  static String titleFor(SudokuTutorialStep step) => switch (step) {
        SudokuTutorialStep.welcome => 'How to play',
        SudokuTutorialStep.selectCell => 'Pick a cell',
        SudokuTutorialStep.enterDigit => 'Enter a number',
        SudokuTutorialStep.notes => 'Pencil notes',
        SudokuTutorialStep.freePlay => 'Your puzzle',
      };

  static String bodyFor(SudokuTutorialStep step) => switch (step) {
        SudokuTutorialStep.welcome =>
          'Start on a small 4×4 board — fill every empty cell so each row, '
              'column, and 2×2 box has the digits 1–4 once. Later levels grow '
              'to 6×6 and full 9×9. Given numbers stay locked.',
        SudokuTutorialStep.selectCell =>
          'Tap the glowing empty cell to select it.',
        SudokuTutorialStep.enterDigit =>
          'Tap the highlighted digit on the pad to fill that cell.',
        SudokuTutorialStep.notes =>
          'Need to remember options? Toggle Notes, then tap digits to mark '
              'pencil candidates. Tap Notes again to place real numbers.',
        SudokuTutorialStep.freePlay =>
          'Nice! Keep filling cells until the puzzle is complete. '
              'Conflicts glow red — fix them as you go.',
      };

  static String ctaFor(SudokuTutorialStep step) => switch (step) {
        SudokuTutorialStep.welcome => 'Got it',
        SudokuTutorialStep.selectCell => 'Waiting for your tap…',
        SudokuTutorialStep.enterDigit => 'Waiting for the digit…',
        SudokuTutorialStep.notes => 'Got it',
        SudokuTutorialStep.freePlay => '',
      };

  /// Steps that wait for a button press before continuing.
  static bool needsContinue(SudokuTutorialStep step) => switch (step) {
        SudokuTutorialStep.welcome || SudokuTutorialStep.notes => true,
        _ => false,
      };
}
