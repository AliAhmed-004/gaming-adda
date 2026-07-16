import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'stack_controller.dart';
import 'stack_logic.dart';
import 'stack_theme.dart';

class StackPlayScreen extends StatefulWidget {
  const StackPlayScreen({super.key});

  @override
  State<StackPlayScreen> createState() => _StackPlayScreenState();
}

class _StackPlayScreenState extends State<StackPlayScreen> {
  late final StackGameController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = StackGameController()..addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onTapAnywhere() {
    _focusNode.requestFocus();
    _controller.onAction();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final score = _controller.displayScore;

    return Scaffold(
      backgroundColor: StackTheme.background,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.space) {
            _controller.onAction();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Must always call build() — three_js only runs setup from here.
            _controller.stage.build(),
            if (!_controller.stageReady)
              const ColoredBox(
                color: StackTheme.background,
                child: Center(child: CircularProgressIndicator()),
              ),
            // Full-screen tap catcher above WebGL (HtmlElementView eats clicks on web).
            Positioned.fill(
              child: PointerInterceptor(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onTapAnywhere,
                  child: const ColoredBox(color: Color(0x00000000)),
                ),
              ),
            ),
            _ScoreOverlay(score: score, state: state),
            _InstructionsOverlay(
              visible: state == StackGameState.playing &&
                  !_controller.hideInstructions,
            ),
            _ReadyOverlay(visible: state == StackGameState.ready),
            _GameOverOverlay(visible: state == StackGameState.ended),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: PointerInterceptor(
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: StackTheme.foreground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreOverlay extends StatelessWidget {
  const _ScoreOverlay({required this.score, required this.state});

  final int score;
  final StackGameState state;

  @override
  Widget build(BuildContext context) {
    final hidden = state == StackGameState.ready;
    final enlarged = state == StackGameState.ended;

    return IgnorePointer(
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        offset: hidden ? const Offset(0, -1.5) : Offset.zero,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          scale: enlarged ? 1.5 : 1,
          child: Align(
            alignment: enlarged ? const Alignment(0, -0.55) : Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: enlarged ? 0 : 20),
              child: Text(
                '$score',
                style: StackTheme.comfortaa(
                  fontSize: MediaQuery.sizeOf(context).height * 0.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionsOverlay extends StatelessWidget {
  const _InstructionsOverlay({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: visible ? 1 : 0,
        child: Align(
          alignment: const Alignment(0, -0.68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Click (or press the spacebar) to place the block',
              textAlign: TextAlign.center,
              style: StackTheme.comfortaa(
                fontSize: MediaQuery.sizeOf(context).height * 0.025,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyOverlay extends StatelessWidget {
  const _ReadyOverlay({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: visible ? 1 : 0,
        child: Center(
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 500),
            offset: visible ? Offset.zero : const Offset(0, -0.15),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: StackTheme.foreground, width: 3),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Start',
                  style: StackTheme.comfortaa(fontSize: 30),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: visible ? 1 : 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StaggeredLine(
                visible: visible,
                delay: Duration.zero,
                child: Text(
                  'Game Over',
                  style: StackTheme.comfortaa(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _StaggeredLine(
                visible: visible,
                delay: const Duration(milliseconds: 300),
                child: Text(
                  "You did great, you're the best.",
                  textAlign: TextAlign.center,
                  style: StackTheme.comfortaa(fontSize: 18),
                ),
              ),
              const SizedBox(height: 8),
              _StaggeredLine(
                visible: visible,
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Click or spacebar to start again',
                  textAlign: TextAlign.center,
                  style: StackTheme.comfortaa(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggeredLine extends StatelessWidget {
  const _StaggeredLine({
    required this.visible,
    required this.delay,
    required this.child,
  });

  final bool visible;
  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
