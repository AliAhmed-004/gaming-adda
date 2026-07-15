enum PenguinPlayMode { solo, aiPartner }

class PenguinConfig {
  const PenguinConfig({
    this.mode = PenguinPlayMode.solo,
    this.soundEnabled = true,
    this.startingLives = 3,
  });

  final PenguinPlayMode mode;
  final bool soundEnabled;
  final int startingLives;

  bool get hasAiPartner => mode == PenguinPlayMode.aiPartner;
}
