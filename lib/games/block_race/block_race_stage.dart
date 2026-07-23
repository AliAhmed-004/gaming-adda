import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import 'block_race_logic.dart';
import 'block_race_theme.dart';
import 'block_race_tween.dart';

class BlockRaceStage {
  BlockRaceStage({
    required this.onReady,
    required this.onTick,
  });

  final VoidCallback onReady;
  final void Function(double dt) onTick;

  late three.ThreeJS threeJs;
  late three.PerspectiveCamera camera;
  late three.Group boardGroup;
  late three.Group pawnGroup;
  late three.Group barricadeGroup;

  three.Mesh? bluePawn;
  three.Mesh? redPawn;
  final Map<BlockRaceCell, three.Mesh> _barricadeMeshes = {};
  final Map<String, three.Mesh> _tileMeshes = {};

  bool ready = false;

  void init() {
    threeJs = three.ThreeJS(
      settings: three.Settings(
        antialias: true,
        alpha: false,
        clearColor: 0x1A2332,
      ),
      onSetupComplete: () {
        ready = true;
        onReady();
      },
      setup: _setup,
    );
    threeJs.windowResizeUpdate = _onResize;
  }

  Future<void> _setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.fog = three.Fog(0x1A2332, 12, 28);

    final aspect =
        threeJs.height == 0 ? 1.0 : threeJs.width / threeJs.height;
    camera = three.PerspectiveCamera(45, aspect, 0.1, 100);
    camera.position.setValues(0, 11, 10);
    camera.lookAt(three.Vector3(0, 0, 0));
    threeJs.camera = camera;

    ready = true;
    _onResize(threeJs.screenSize ?? Size(threeJs.width, threeJs.height));

    final keyLight = three.DirectionalLight(0xffffff, 0.85);
    keyLight.position.setValues(5, 12, 8);
    threeJs.scene.add(keyLight);

    final fillLight = three.DirectionalLight(0x88aaff, 0.35);
    fillLight.position.setValues(-6, 6, -4);
    threeJs.scene.add(fillLight);

    final ambient = three.AmbientLight(0xffffff, 0.35);
    threeJs.scene.add(ambient);

    boardGroup = three.Group();
    pawnGroup = three.Group();
    barricadeGroup = three.Group();
    threeJs.scene.add(boardGroup);
    threeJs.scene.add(pawnGroup);
    threeJs.scene.add(barricadeGroup);

    _buildBoardTiles();
    bluePawn = _createPawn(BlockRaceTheme.bluePlayerHex);
    redPawn = _createPawn(BlockRaceTheme.redPlayerHex);
    pawnGroup.add(bluePawn!);
    pawnGroup.add(redPawn!);

    syncPawnPositions(
      BlockRaceGame.bluePath.first,
      BlockRaceGame.redPath.first,
    );

    threeJs.addAnimationEvent((dt) {
      if (!ready) return;
      onTick(dt);
    });
  }

  void _onResize(Size size) {
    if (!ready) return;
    camera.aspect = size.width / (size.height == 0 ? 1 : size.height);
    camera.updateProjectionMatrix();
  }

  void _buildBoardTiles() {
    final half = BlockRaceGame.boardCols / 2.0 - 0.5;
    for (var row = 0; row < BlockRaceGame.boardRows; row++) {
      for (var col = 0; col < BlockRaceGame.boardCols; col++) {
        final cell = BlockRaceGame.cellAt(row, col);
        final x = (col - half) * BlockRaceTheme.cellSize;
        final z = (row - half) * BlockRaceTheme.cellSize;

        final isPath = cell.isPath;
        final color = switch (cell.kind) {
          BlockRaceCellKind.blueGoal => BlockRaceTheme.goalBlueHex,
          BlockRaceCellKind.redGoal => BlockRaceTheme.goalRedHex,
          BlockRaceCellKind.path => BlockRaceTheme.pathTileHex,
          BlockRaceCellKind.empty => BlockRaceTheme.boardBaseHex,
        };
        final height = isPath ? 0.18 : 0.08;
        final y = height / 2;

        final geometry = three.BoxGeometry(
          BlockRaceTheme.cellSize * 0.92,
          height,
          BlockRaceTheme.cellSize * 0.92,
        );
        geometry.applyMatrix4(
          three.Matrix4().makeTranslation(0, y, 0),
        );

        final material = three.MeshToonMaterial({
          three.MaterialProperty.color: color,
          three.MaterialProperty.flatShading: true,
        });
        final mesh = three.Mesh(geometry, material);
        mesh.position.setValues(x, 0, z);
        boardGroup.add(mesh);
        _tileMeshes['$row,$col'] = mesh;
      }
    }
  }

  three.Mesh _createPawn(int colorHex) {
    final geometry = three.CylinderGeometry(
      BlockRaceTheme.pawnRadius,
      BlockRaceTheme.pawnRadius * 0.85,
      BlockRaceTheme.pawnHeight,
      24,
    );
    geometry.applyMatrix4(
      three.Matrix4().makeTranslation(0, BlockRaceTheme.pawnHeight / 2, 0),
    );
    final material = three.MeshToonMaterial({
      three.MaterialProperty.color: colorHex,
      three.MaterialProperty.flatShading: false,
    });
    return three.Mesh(geometry, material);
  }

  three.Vector3 cellWorldPosition(BlockRaceCell cell) {
    final half = BlockRaceGame.boardCols / 2.0 - 0.5;
    final x = (cell.col - half) * BlockRaceTheme.cellSize;
    final z = (cell.row - half) * BlockRaceTheme.cellSize;
    return three.Vector3(x, 0.18, z);
  }

  void syncPawnPositions(BlockRaceCell blueCell, BlockRaceCell redCell) {
    final bluePos = cellWorldPosition(blueCell);
    bluePawn?.position.setValues(bluePos.x, bluePos.y, bluePos.z);
    final redPos = cellWorldPosition(redCell);
    redPawn?.position.setValues(redPos.x, redPos.y, redPos.z);
  }

  void animatePawnMove({
    required BlockRacePlayer player,
    required List<BlockRaceCell> steps,
    required BlockRaceTweenRunner tweens,
    required VoidCallback onComplete,
  }) {
    if (steps.length < 2) {
      onComplete();
      return;
    }

    final mesh = player == BlockRacePlayer.blue ? bluePawn : redPawn;
    if (mesh == null) {
      onComplete();
      return;
    }

    final segmentDuration =
        BlockRaceTheme.moveAnimationDuration / (steps.length - 1);
    var delay = 0.0;

    for (var i = 1; i < steps.length; i++) {
      final from = cellWorldPosition(steps[i - 1]);
      final to = cellWorldPosition(steps[i]);
      final startX = from.x;
      final startZ = from.z;
      final endX = to.x;
      final endZ = to.z;
      final segmentDelay = delay;
      final baseY = from.y;

      tweens.add(
        BlockRaceTween(
          from: 0,
          to: 1,
          duration: segmentDuration,
          delay: segmentDelay,
          ease: BlockRaceEase.easeInOut,
          onUpdate: (t) {
            mesh.position.x = startX + (endX - startX) * t;
            mesh.position.z = startZ + (endZ - startZ) * t;
            mesh.position.y =
                baseY + math.sin(math.pi * t) * BlockRaceTheme.hopHeight;
          },
          onComplete: i == steps.length - 1 ? onComplete : null,
        ),
      );
      delay += segmentDuration;
    }
  }

  three.Mesh addBarricade(BlockRaceCell cell, BlockRaceTweenRunner tweens) {
    final pos = cellWorldPosition(cell);
    final geometry = three.BoxGeometry(
      BlockRaceTheme.cellSize * 0.7,
      BlockRaceTheme.barricadeHeight,
      BlockRaceTheme.cellSize * 0.35,
    );
    geometry.applyMatrix4(
      three.Matrix4().makeTranslation(
        0,
        BlockRaceTheme.barricadeHeight / 2,
        0,
      ),
    );
    final material = three.MeshToonMaterial({
      three.MaterialProperty.color: BlockRaceTheme.barricadeHex,
      three.MaterialProperty.flatShading: true,
    });
    final mesh = three.Mesh(geometry, material);
    mesh.position.setValues(pos.x, pos.y, pos.z);
    mesh.scale.y = 0.01;
    barricadeGroup.add(mesh);
    _barricadeMeshes[cell] = mesh;

    tweens.add(
      BlockRaceTween(
        from: 0.01,
        to: 1,
        duration: BlockRaceTheme.barricadeAnimationDuration,
        ease: BlockRaceEase.easeOut,
        onUpdate: (value) => mesh.scale.y = value,
      ),
    );
    return mesh;
  }

  void pulseTile(BlockRaceCell cell, BlockRaceTweenRunner tweens) {
    final mesh = _tileMeshes['${cell.row},${cell.col}'];
    if (mesh == null) return;
    final startY = mesh.scale.y;
    tweens.add(
      BlockRaceTween(
        from: 0,
        to: 1,
        duration: 0.35,
        ease: BlockRaceEase.easeInOut,
        onUpdate: (t) {
          mesh.scale.y = startY + 0.15 * (1 - (2 * t - 1).abs());
        },
      ),
    );
  }

  void dispose() {
    ready = false;
    if (threeJs.mounted) {
      threeJs.dispose();
      three.loading.clear();
    }
  }

  Widget build() => threeJs.build();
}
