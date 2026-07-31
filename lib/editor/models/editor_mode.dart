enum EditorMode { draw, select, placeSpawn, cameraPath }

extension EditorModeLabel on EditorMode {
  String get label => switch (this) {
        EditorMode.draw => 'DRAW / FORMS',
        EditorMode.select => 'SELECT & MOVE',
        EditorMode.placeSpawn => 'PLAYER SPAWN',
        EditorMode.cameraPath => 'CAMERA PATH',
      };
}
