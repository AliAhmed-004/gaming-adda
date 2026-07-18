import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/cartoon_ui/cartoon_theme.dart';
import 'sudoku_board.dart';
import 'sudoku_config.dart';
import 'sudoku_generator.dart';
import 'sudoku_levels.dart';
import 'sudoku_logic.dart';
import 'sudoku_sounds.dart';
import 'sudoku_tutorial.dart';

class SudokuPlayScreen extends StatefulWidget {
  const SudokuPlayScreen({super.key, required this.config});

  final SudokuConfig config;

  @override
  State<SudokuPlayScreen> createState() => _SudokuPlayScreenState();
}

class _SudokuPlayScreenState extends State<SudokuPlayScreen> {
  SudokuGame? _game;
  late final SudokuSounds _sounds;
  var _loading = true;
  var _tutorialStep = SudokuTutorialStep.welcome;
  var _elapsed = Duration.zero;
  Timer? _timer;
  var _winShown = false;

  SudokuConfig get _config => widget.config;

  bool get _isTutorial => SudokuTutorial.isTutorialLevel(_config.level);

  SudokuCell? get _tutorialCell {
    final g = _game;
    if (g == null || !_isTutorial) return null;
    if (_tutorialStep == SudokuTutorialStep.selectCell ||
        _tutorialStep == SudokuTutorialStep.enterDigit) {
      return g.firstEmptyCell();
    }
    return null;
  }

  int? get _tutorialDigit {
    final cell = _tutorialCell;
    final g = _game;
    if (cell == null || g == null) return null;
    if (_tutorialStep == SudokuTutorialStep.enterDigit) {
      return g.solutionAt(cell.row, cell.col);
    }
    return null;
  }

  bool get _canInteract {
    if (_loading || _game == null || _game!.isSolved) return false;
    if (_isTutorial &&
        (_tutorialStep == SudokuTutorialStep.welcome ||
            _tutorialStep == SudokuTutorialStep.notes)) {
      return false;
    }
    return true;
  }

  String get _statusText {
    if (_loading) return 'Building puzzle…';
    if (_game!.isSolved) return 'Solved!';
    if (_isTutorial) return 'Tutorial';
    if (_config.isCampaign && _config.level != null) {
      return SudokuLevels.progressLabel(_config.level!);
    }
    final d = _config.difficulty;
    if (d == null) return 'Free Play';
    final shape = switch (d) {
      SudokuDifficulty.easy => '4×4',
      SudokuDifficulty.medium => '6×6',
      SudokuDifficulty.hard => '9×9',
    };
    return switch (d) {
      SudokuDifficulty.easy => '$shape · Easy',
      SudokuDifficulty.medium => '$shape · Medium',
      SudokuDifficulty.hard => '$shape · Hard',
    };
  }

  String get _timerText {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void initState() {
    super.initState();
    _sounds = SudokuSounds(enabled: _config.soundEnabled);
    _sounds.preload();
    _loadPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sounds.dispose();
    super.dispose();
  }

  Future<void> _loadPuzzle() async {
    setState(() {
      _loading = true;
      _winShown = false;
      _elapsed = Duration.zero;
    });
    _timer?.cancel();

    // Yield so the loading indicator paints before generation.
    await Future<void>.delayed(Duration.zero);
    final puzzle = _config.isCampaign
        ? SudokuGenerator.forLevel(_config.level ?? 1)
        : SudokuGenerator.forDifficulty(
            _config.difficulty ?? SudokuDifficulty.medium,
          );

    if (!mounted) return;
    setState(() {
      _game = SudokuGame(
        puzzle: puzzle.puzzle,
        solution: puzzle.solution,
        shape: puzzle.shape,
      );
      _loading = false;
      if (_isTutorial) {
        _tutorialStep = SudokuTutorialStep.welcome;
      }
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _game == null || _game!.isSolved) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _advanceTutorial() {
    setState(() {
      _tutorialStep = switch (_tutorialStep) {
        SudokuTutorialStep.welcome => SudokuTutorialStep.selectCell,
        SudokuTutorialStep.selectCell => SudokuTutorialStep.enterDigit,
        SudokuTutorialStep.enterDigit => SudokuTutorialStep.notes,
        SudokuTutorialStep.notes => SudokuTutorialStep.freePlay,
        SudokuTutorialStep.freePlay => SudokuTutorialStep.freePlay,
      };
    });
  }

  void _onTutorialContinue() => _advanceTutorial();

  void _onCellTap(int row, int col) {
    if (!_canInteract) return;
    final g = _game!;
    if (_isTutorial && _tutorialStep == SudokuTutorialStep.selectCell) {
      final target = g.firstEmptyCell();
      if (target == null || target.row != row || target.col != col) return;
      setState(() {
        g.select(row, col);
        _tutorialStep = SudokuTutorialStep.enterDigit;
      });
      return;
    }
    setState(() => g.select(row, col));
  }

  Future<void> _onDigit(int digit) async {
    if (!_canInteract) return;
    final g = _game!;
    if (!g.hasSelection) return;

    if (_isTutorial && _tutorialStep == SudokuTutorialStep.enterDigit) {
      final cell = g.firstEmptyCell();
      if (cell == null) return;
      final expected = g.solutionAt(cell.row, cell.col);
      if (digit != expected) return;
      if (g.selectedRow != cell.row || g.selectedCol != cell.col) {
        g.select(cell.row, cell.col);
      }
    }

    final changed = g.inputDigit(digit);
    if (!changed) return;
    setState(() {});
    await _sounds.place();

    if (_isTutorial && _tutorialStep == SudokuTutorialStep.enterDigit) {
      setState(() => _tutorialStep = SudokuTutorialStep.notes);
    }

    await _checkSolved();
  }

  Future<void> _checkSolved() async {
    final g = _game;
    if (g == null || !g.isSolved || _winShown) return;
    _winShown = true;
    _timer?.cancel();
    await _sounds.win();

    final level = _config.level;
    if (_config.isCampaign && level != null) {
      await SudokuProgress.completeLevel(level);
    }
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _showWinDialog();
  }

  void _showWinDialog() {
    final level = _config.level;
    final campaign = _config.isCampaign && level != null;
    final hasNext = campaign && level < SudokuLevels.maxLevel;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Puzzle solved',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 280),
      pageBuilder: (ctx, animation, secondary) {
        return _SudokuWinDialog(
          campaign: campaign,
          level: level ?? 0,
          hasNext: hasNext,
          timerText: _timerText,
          onLevels: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pop();
          },
          onReplay: () {
            Navigator.of(ctx).pop();
            _loadPuzzle();
          },
          onNext: hasNext
              ? () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => SudokuPlayScreen(
                        config: SudokuConfig(
                          mode: SudokuPlayMode.campaign,
                          soundEnabled: _config.soundEnabled,
                          level: level + 1,
                        ),
                      ),
                    ),
                  );
                }
              : null,
          onHome: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      },
      transitionBuilder: (ctx, animation, secondary, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  void _toggleNotes() {
    if (!_canInteract) return;
    setState(() => _game!.notesMode = !_game!.notesMode);
  }

  void _undo() {
    if (!_canInteract) return;
    if (_game!.undo()) setState(() {});
  }

  Future<void> _hint() async {
    if (!_canInteract) return;
    final cell = _game!.hint();
    if (cell == null) return;
    setState(() {});
    await _sounds.place();
    await _checkSolved();
  }

  Future<void> _erase() async {
    if (!_canInteract) return;
    if (_game!.clearCell()) {
      setState(() {});
      await _sounds.place();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isTutorial
        ? 'TUTORIAL'
        : (_config.level != null ? 'LEVEL ${_config.level}' : 'SUDOKU');

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPuzzle,
            tooltip: 'New game',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.4,
            colors: [Color(0xFF134E4A), Color(0xFF0F1D33), Color(0xFF070D18)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, kToolbarHeight + 4, 12, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statusText,
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _timerText,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: SudokuBoard.glow,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading || _game == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: SudokuBoard.glow,
                          ),
                        )
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: SudokuBoard(
                              game: _game!,
                              interactive: _canInteract,
                              onCellTap: _onCellTap,
                              highlightCell: _tutorialCell,
                              highlightDigit: _tutorialDigit,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                if (_isTutorial && _game != null && !_game!.isSolved) ...[
                  _TutorialCoachCard(
                    step: _tutorialStep,
                    onContinue: SudokuTutorial.needsContinue(_tutorialStep)
                        ? _onTutorialContinue
                        : null,
                  ),
                  if (_tutorialStep == SudokuTutorialStep.enterDigit ||
                      _tutorialStep == SudokuTutorialStep.freePlay) ...[
                    const SizedBox(height: 8),
                    _NumberPad(
                      maxDigit: _game?.maxDigit ?? 9,
                      enabled: _canInteract,
                      highlightDigit: _tutorialDigit,
                      onDigit: _onDigit,
                    ),
                  ],
                  if (_tutorialStep == SudokuTutorialStep.freePlay) ...[
                    const SizedBox(height: 8),
                    _ToolRow(
                      notesMode: _game?.notesMode ?? false,
                      canUndo: _game?.canUndo ?? false,
                      enabled: _canInteract,
                      onNotes: _toggleNotes,
                      onUndo: _undo,
                      onHint: _hint,
                      onErase: _erase,
                    ),
                  ],
                ] else ...[
                  _ToolRow(
                    notesMode: _game?.notesMode ?? false,
                    canUndo: _game?.canUndo ?? false,
                    enabled: _canInteract,
                    onNotes: _toggleNotes,
                    onUndo: _undo,
                    onHint: _hint,
                    onErase: _erase,
                  ),
                  const SizedBox(height: 8),
                  _NumberPad(
                    maxDigit: _game?.maxDigit ?? 9,
                    enabled: _canInteract,
                    highlightDigit: _tutorialDigit,
                    onDigit: _onDigit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.notesMode,
    required this.canUndo,
    required this.enabled,
    required this.onNotes,
    required this.onUndo,
    required this.onHint,
    required this.onErase,
  });

  final bool notesMode;
  final bool canUndo;
  final bool enabled;
  final VoidCallback onNotes;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToolButton(
          icon: Icons.edit_note_rounded,
          label: 'Notes',
          selected: notesMode,
          enabled: enabled,
          onTap: onNotes,
        ),
        _ToolButton(
          icon: Icons.undo_rounded,
          label: 'Undo',
          enabled: enabled && canUndo,
          onTap: onUndo,
        ),
        _ToolButton(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Hint',
          enabled: enabled,
          onTap: onHint,
        ),
        _ToolButton(
          icon: Icons.backspace_outlined,
          label: 'Erase',
          enabled: enabled,
          onTap: onErase,
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: selected
              ? SudokuBoard.frame.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: enabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: enabled
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({
    required this.maxDigit,
    required this.enabled,
    required this.onDigit,
    this.highlightDigit,
  });

  final int maxDigit;
  final bool enabled;
  final ValueChanged<int> onDigit;
  final int? highlightDigit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var d = 1; d <= maxDigit; d++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AspectRatio(
                aspectRatio: 0.85,
                child: Material(
                  color: highlightDigit == d
                      ? SudokuBoard.glow.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  elevation: highlightDigit == d ? 6 : 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: enabled ? () => onDigit(d) : null,
                    child: Center(
                      child: Text(
                        '$d',
                        style: GoogleFonts.fredoka(
                          fontSize: maxDigit <= 4 ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TutorialCoachCard extends StatelessWidget {
  const _TutorialCoachCard({required this.step, this.onContinue});

  final SudokuTutorialStep step;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final stepIndex = SudokuTutorialStep.values.indexOf(step);
    final total = SudokuTutorialStep.values.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D9B8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CartoonTheme.titleOutline, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CartoonTheme.titleOutline.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'STEP ${stepIndex + 1}/$total',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: CartoonTheme.titleOutline,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                SudokuTutorial.titleFor(step),
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CartoonTheme.titleOutline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            SudokuTutorial.bodyFor(step),
            style: GoogleFonts.nunito(
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3F2E1E),
            ),
          ),
          if (onContinue != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: SudokuBoard.frame,
                ),
                child: Text(SudokuTutorial.ctaFor(step)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SudokuWinDialog extends StatelessWidget {
  const _SudokuWinDialog({
    required this.campaign,
    required this.level,
    required this.hasNext,
    required this.timerText,
    required this.onLevels,
    required this.onReplay,
    required this.onHome,
    this.onNext,
  });

  final bool campaign;
  final int level;
  final bool hasNext;
  final String timerText;
  final VoidCallback onLevels;
  final VoidCallback onReplay;
  final VoidCallback onHome;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF134E4A), Color(0xFF0F766E)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SudokuBoard.glow, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                campaign ? 'Level $level cleared!' : 'Puzzle solved!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Time $timerText',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              if (campaign) ...[
                _DialogButton(label: 'Levels', onTap: onLevels),
                const SizedBox(height: 8),
                _DialogButton(label: 'Replay', onTap: onReplay),
                if (onNext != null) ...[
                  const SizedBox(height: 8),
                  _DialogButton(label: 'Next', primary: true, onTap: onNext!),
                ],
              ] else ...[
                _DialogButton(
                  label: 'New puzzle',
                  primary: true,
                  onTap: onReplay,
                ),
                const SizedBox(height: 8),
                _DialogButton(label: 'Home', onTap: onHome),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor:
              primary ? SudokuBoard.glow : Colors.white.withValues(alpha: 0.15),
          foregroundColor: primary ? const Color(0xFF0F172A) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
