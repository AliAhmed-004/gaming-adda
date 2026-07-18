enum CasinoPlayMode { vsComputer }

class CasinoConfig {
  const CasinoConfig({
    this.mode = CasinoPlayMode.vsComputer,
    this.soundEnabled = true,
  });

  final CasinoPlayMode mode;
  final bool soundEnabled;

  bool get isVsComputer => mode == CasinoPlayMode.vsComputer;
}
