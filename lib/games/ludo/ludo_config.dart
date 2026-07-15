import 'ludo_logic.dart';

enum LudoPlayMode { vsComputer, localHotseat }

class LudoConfig {
  const LudoConfig({
    this.playerCount = 4,
    this.mode = LudoPlayMode.vsComputer,
    this.humanColor = LudoColor.red,
    this.soundEnabled = true,
  });

  final int playerCount;
  final LudoPlayMode mode;
  final LudoColor humanColor;
  final bool soundEnabled;

  bool get isVsComputer => mode == LudoPlayMode.vsComputer;
  bool get isLocalHotseat => mode == LudoPlayMode.localHotseat;

  List<LudoColor> get activeColors => activeColorsForPlayerCount(playerCount);

  bool isHumanTurn(LudoColor turn) {
    if (isLocalHotseat) return true;
    return turn == humanColor;
  }
}
