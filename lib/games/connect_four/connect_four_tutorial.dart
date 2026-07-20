/// Guided steps for campaign level 1 (tutorial).
enum ConnectFourTutorialStep {
  /// Goal of the game.
  welcome,

  /// Force the first drop into a highlighted column.
  dropDisc,

  /// Discs fall to the lowest empty slot.
  gravity,

  /// Win by connecting four; free play from here.
  connectFour,

  /// Tutorial coaching finished; play until the level ends.
  freePlay,
}

abstract final class ConnectFourTutorial {
  static const int level = 1;

  /// Column the coach asks the player to tap first (0-based, center).
  static const int firstColumn = 3;

  static bool isTutorialLevel(int? level) => level == ConnectFourTutorial.level;

  static String titleFor(ConnectFourTutorialStep step) => switch (step) {
        ConnectFourTutorialStep.welcome => 'How to play',
        ConnectFourTutorialStep.dropDisc => 'Drop a disc',
        ConnectFourTutorialStep.gravity => 'Gravity!',
        ConnectFourTutorialStep.connectFour => 'Connect four',
        ConnectFourTutorialStep.freePlay => 'Your turn',
      };

  static String bodyFor(ConnectFourTutorialStep step) => switch (step) {
        ConnectFourTutorialStep.welcome =>
          'You are Red. Drop discs into the board and get four in a row — '
              'across, up-and-down, or diagonal — before Yellow does.',
        ConnectFourTutorialStep.dropDisc =>
          'Tap the glowing column to drop your first disc. '
              'It falls to the bottom of that slot.',
        ConnectFourTutorialStep.gravity =>
          'Nice! Discs always stack from the bottom up. '
              'Yellow will drop next — then it is your turn again.',
        ConnectFourTutorialStep.connectFour =>
          'Line up four of your discs to win. '
              'Block Yellow if they get close. Practice AI is going easy on you!',
        ConnectFourTutorialStep.freePlay =>
          'Keep dropping until you connect four. You have got this!',
      };

  static String ctaFor(ConnectFourTutorialStep step) => switch (step) {
        ConnectFourTutorialStep.welcome => 'Got it',
        ConnectFourTutorialStep.dropDisc => 'Waiting for your tap…',
        ConnectFourTutorialStep.gravity => 'Continue',
        ConnectFourTutorialStep.connectFour => 'Let\'s play',
        ConnectFourTutorialStep.freePlay => '',
      };

  /// Steps that wait for a button press before continuing.
  static bool needsContinue(ConnectFourTutorialStep step) => switch (step) {
        ConnectFourTutorialStep.welcome ||
        ConnectFourTutorialStep.gravity ||
        ConnectFourTutorialStep.connectFour =>
          true,
        ConnectFourTutorialStep.dropDisc ||
        ConnectFourTutorialStep.freePlay =>
          false,
      };
}
