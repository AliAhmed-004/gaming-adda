import 'dart:math' as math;

enum BlockRaceEase { linear, easeIn, easeInOut, easeOut }

class BlockRaceTween {
  BlockRaceTween({
    required this.from,
    required this.to,
    required this.duration,
    this.ease = BlockRaceEase.linear,
    this.onUpdate,
    this.onComplete,
    this.delay = 0,
  });

  final double from;
  final double to;
  final double duration;
  final BlockRaceEase ease;
  final void Function(double value)? onUpdate;
  final void Function()? onComplete;
  final double delay;

  double _elapsed = 0;
  bool _completed = false;

  bool get isComplete => _completed;

  void update(double dt) {
    if (_completed) return;

    _elapsed += dt;
    if (_elapsed < delay) return;

    final active = _elapsed - delay;
    if (duration <= 0) {
      _finish(1);
      return;
    }

    final t = (active / duration).clamp(0.0, 1.0);
    final eased = _applyEase(t);
    final value = from + (to - from) * eased;
    onUpdate?.call(value);

    if (t >= 1) {
      _finish(1);
    }
  }

  void _finish(double t) {
    if (_completed) return;
    _completed = true;
    final eased = _applyEase(t);
    onUpdate?.call(from + (to - from) * eased);
    onComplete?.call();
  }

  double _applyEase(double t) {
    return switch (ease) {
      BlockRaceEase.linear => t,
      BlockRaceEase.easeIn => t * t,
      BlockRaceEase.easeOut => t * (2 - t),
      BlockRaceEase.easeInOut => 0.5 - math.cos(math.pi * t) / 2,
    };
  }
}

class BlockRaceTweenRunner {
  final List<BlockRaceTween> _tweens = [];

  void add(BlockRaceTween tween) => _tweens.add(tween);

  void update(double dt) {
    for (final tween in List<BlockRaceTween>.from(_tweens)) {
      tween.update(dt);
      if (tween.isComplete) {
        _tweens.remove(tween);
      }
    }
  }

  void clear() => _tweens.clear();

  bool get isEmpty => _tweens.isEmpty;
  bool get isAnimating => _tweens.isNotEmpty;
}
