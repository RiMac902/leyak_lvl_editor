enum EditorMode { draw, select }

extension EditorModeLabel on EditorMode {
  String get label => switch (this) {
        EditorMode.draw => 'DRAW / FORMS',
        EditorMode.select => 'SELECT & MOVE',
      };
}
