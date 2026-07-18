import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import 'stack_logic.dart';
import 'stack_tween.dart';

class StackStage {
  StackStage({
    required this.onReady,
    required this.onTick,
  });

  final VoidCallback onReady;
  final void Function(double dt) onTick;

  late three.ThreeJS threeJs;
  late three.OrthographicCamera camera;
  late three.Group newBlocks;
  late three.Group placedBlocks;
  late three.Group choppedBlocks;

  double lookAtY = 0;
  bool ready = false;

  final Map<int, three.Material> _materials = {};

  void init() {
    threeJs = three.ThreeJS(
      settings: three.Settings(
        antialias: true,
        alpha: false,
        clearColor: 0xD0CBC7,
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

    final aspect =
        threeJs.height == 0 ? 1.0 : threeJs.width / threeJs.height;
    const d = 20.0;
    camera = three.OrthographicCamera(
      -d * aspect,
      d * aspect,
      d,
      -d,
      -100,
      1000,
    );
    camera.position.setValues(2, 2, 2);
    camera.lookAt(three.Vector3(0, 0, 0));
    threeJs.camera = camera;

    // Mark ready before resize so _onResize can update the frustum.
    ready = true;
    _onResize(threeJs.screenSize ?? Size(threeJs.width, threeJs.height));

    final light = three.DirectionalLight(0xffffff, 0.5);
    light.position.setValues(0, 499, 0);
    threeJs.scene.add(light);

    final softLight = three.AmbientLight(0xffffff, 0.4);
    threeJs.scene.add(softLight);

    newBlocks = three.Group();
    placedBlocks = three.Group();
    choppedBlocks = three.Group();
    threeJs.scene.add(newBlocks);
    threeJs.scene.add(placedBlocks);
    threeJs.scene.add(choppedBlocks);

    threeJs.addAnimationEvent((dt) {
      if (!ready) return;
      camera.lookAt(three.Vector3(0, lookAtY, 0));
      onTick(dt);
    });
  }

  void _onResize(Size size) {
    if (!ready) return;
    const viewSize = 30.0;
    camera.left = size.width / -viewSize;
    camera.right = size.width / viewSize;
    camera.top = size.height / viewSize;
    camera.bottom = size.height / -viewSize;
    camera.updateProjectionMatrix();
  }

  void setCameraY(double y, double speed, StackTweenRunner tweens) {
    final targetLookAt = y;
    final targetPositionY = y + 4;
    final startLookAt = lookAtY;
    final startPositionY = camera.position.y;

    tweens.add(
      StackTween(
        from: startLookAt,
        to: targetLookAt,
        duration: speed,
        ease: StackEase.easeInOut,
        onUpdate: (value) => lookAtY = value,
      ),
    );
    tweens.add(
      StackTween(
        from: startPositionY,
        to: targetPositionY,
        duration: speed,
        ease: StackEase.easeInOut,
        onUpdate: (value) => camera.position.y = value,
      ),
    );
  }

  three.Mesh createMesh({
    required StackDimensions dimensions,
    required StackPosition position,
    required int colorHex,
  }) {
    final material = _materialFor(colorHex);
    final geometry = three.BoxGeometry(
      dimensions.width,
      dimensions.height,
      dimensions.depth,
    );
    geometry.applyMatrix4(
      three.Matrix4().makeTranslation(
        dimensions.width / 2,
        dimensions.height / 2,
        dimensions.depth / 2,
      ),
    );
    final mesh = three.Mesh(geometry, material);
    mesh.position.setValues(position.x, position.y, position.z);
    return mesh;
  }

  three.Material _materialFor(int colorHex) {
    return _materials.putIfAbsent(colorHex, () {
      return three.MeshToonMaterial({
        three.MaterialProperty.color: colorHex,
        three.MaterialProperty.flatShading: true,
      });
    });
  }

  void dispose() {
    ready = false;
    // ThreeJS.dispose() touches late scene/camera — only safe after setup.
    if (threeJs.mounted) {
      threeJs.dispose();
      three.loading.clear();
    }
  }

  Widget build() => threeJs.build();
}
