import 'dart:math' as math;

import 'stack_theme.dart';

enum StackBlockState { active, stopped, missed }

enum StackGameState { loading, ready, playing, ended, resetting }

enum StackAxis { x, z }

class StackDimensions {
  StackDimensions({this.width = 0, this.height = 0, this.depth = 0});

  double width;
  double height;
  double depth;

  StackDimensions copy() =>
      StackDimensions(width: width, height: height, depth: depth);
}

class StackPosition {
  StackPosition({this.x = 0, this.y = 0, this.z = 0});

  double x;
  double y;
  double z;

  StackPosition copy() => StackPosition(x: x, y: y, z: z);
}

class StackPlaceResult {
  StackPlaceResult({
    required this.missed,
    required this.bonus,
    required this.plane,
    required this.direction,
    this.placedDimensions,
    this.placedPosition,
    this.choppedDimensions,
    this.choppedPosition,
  });

  final bool missed;
  final bool bonus;
  final StackAxis plane;
  final double direction;
  final StackDimensions? placedDimensions;
  final StackPosition? placedPosition;
  final StackDimensions? choppedDimensions;
  final StackPosition? choppedPosition;
}

class StackBlock {
  StackBlock({StackBlock? target})
      : index = (target?.index ?? 0) + 1,
        targetBlock = target {
    workingPlane = index.isOdd ? StackAxis.x : StackAxis.z;
    dimension = StackDimensions(
      width: target?.dimension.width ?? 10,
      height: target?.dimension.height ?? 2,
      depth: target?.dimension.depth ?? 10,
    );
    position = StackPosition(
      x: target?.position.x ?? 0,
      y: dimension.height * index,
      z: target?.position.z ?? 0,
    );
    colorOffset = target?.colorOffset ?? math.Random().nextInt(100);
    colorHex = target == null
        ? StackTheme.baseBlockColor
        : _stackColor(index + colorOffset);
    state = index > 1 ? StackBlockState.active : StackBlockState.stopped;
    speed = -0.1 - (index * 0.005);
    if (speed < -4) speed = -4;
    direction = speed;

    if (state == StackBlockState.active) {
      _setAxis(position, workingPlane, math.Random().nextBool() ? -moveAmount : moveAmount);
    }
  }

  static const double moveAmount = 12;

  final int index;
  final StackBlock? targetBlock;
  late final StackAxis workingPlane;
  late final StackDimensions dimension;
  late final StackPosition position;
  late final int colorOffset;
  late final int colorHex;
  late StackBlockState state;
  late double speed;
  late double direction;

  StackAxis get workingDimensionAxis => workingPlane;

  String get workingDimension =>
      workingPlane == StackAxis.x ? 'width' : 'depth';

  double _axisValue(StackPosition pos, StackAxis axis) =>
      axis == StackAxis.x ? pos.x : pos.z;

  void _setAxis(StackPosition pos, StackAxis axis, double value) {
    if (axis == StackAxis.x) {
      pos.x = value;
    } else {
      pos.z = value;
    }
  }

  double _dimensionValue(StackDimensions dims, StackAxis axis) =>
      axis == StackAxis.x ? dims.width : dims.depth;

  void _setDimensionValue(StackDimensions dims, StackAxis axis, double value) {
    if (axis == StackAxis.x) {
      dims.width = value;
    } else {
      dims.depth = value;
    }
  }

  void reverseDirection() {
    direction = direction > 0 ? speed : speed.abs();
  }

  StackPlaceResult place() {
    state = StackBlockState.stopped;
    final target = targetBlock!;

    var overlap = _dimensionValue(target.dimension, workingPlane) -
        (_axisValue(position, workingPlane) -
                _axisValue(target.position, workingPlane))
            .abs();

    var bonus = false;

    if (_dimensionValue(dimension, workingPlane) - overlap < 0.3) {
      overlap = _dimensionValue(dimension, workingPlane);
      bonus = true;
      position.x = target.position.x;
      position.z = target.position.z;
      dimension.width = target.dimension.width;
      dimension.depth = target.dimension.depth;
    }

    if (overlap <= 0) {
      state = StackBlockState.missed;
      return StackPlaceResult(
        missed: true,
        bonus: false,
        plane: workingPlane,
        direction: direction,
      );
    }

    final choppedDimensions = dimension.copy();
    _setDimensionValue(
      choppedDimensions,
      workingPlane,
      _dimensionValue(choppedDimensions, workingPlane) - overlap,
    );
    _setDimensionValue(dimension, workingPlane, overlap);

    final placedPosition = position.copy();
    final choppedPosition = position.copy();

    if (_axisValue(position, workingPlane) <
        _axisValue(target.position, workingPlane)) {
      _setAxis(position, workingPlane, _axisValue(target.position, workingPlane));
      placedPosition.x = position.x;
      placedPosition.z = position.z;
    } else {
      _setAxis(
        choppedPosition,
        workingPlane,
        _axisValue(choppedPosition, workingPlane) + overlap,
      );
    }

    return StackPlaceResult(
      missed: false,
      bonus: bonus,
      plane: workingPlane,
      direction: direction,
      placedDimensions: dimension.copy(),
      placedPosition: placedPosition,
      choppedDimensions: bonus ? null : choppedDimensions,
      choppedPosition: bonus ? null : choppedPosition,
    );
  }

  void tick() {
    if (state != StackBlockState.active) return;

    final value = _axisValue(position, workingPlane);
    if (value > moveAmount || value < -moveAmount) {
      reverseDirection();
    }
    _setAxis(position, workingPlane, value + direction);
  }

  static int _stackColor(int offset) {
    final r = (math.sin(0.3 * offset) * 55 + 200).round();
    final g = (math.sin(0.3 * offset + 2) * 55 + 200).round();
    final b = (math.sin(0.3 * offset + 4) * 55 + 200).round();
    return (r << 16) | (g << 8) | b;
  }

  static double cappedSpeed(int index) {
    var speed = -0.1 - (index * 0.005);
    if (speed < -4) speed = -4;
    return speed;
  }
}

class StackGame {
  StackGame() {
    addBlock();
  }

  final List<StackBlock> blocks = [];
  StackGameState state = StackGameState.loading;

  int get score => blocks.length - 1;

  bool get hideInstructions => blocks.length >= 5;

  StackBlock? get activeBlock =>
      blocks.isEmpty ? null : blocks.last;

  void setState(StackGameState newState) => state = newState;

  bool addBlock() {
    final last = blocks.isEmpty ? null : blocks.last;
    if (last != null && last.state == StackBlockState.missed) {
      return false;
    }

    blocks.add(StackBlock(target: last));
    return true;
  }

  StackPlaceResult? placeCurrentBlock() {
    final current = activeBlock;
    if (current == null || current.state != StackBlockState.active) {
      return null;
    }
    return current.place();
  }

  void trimToBase() {
    if (blocks.isNotEmpty) {
      blocks.removeRange(1, blocks.length);
    }
  }
}
