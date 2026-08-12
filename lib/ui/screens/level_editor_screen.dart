import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leyak_lvl_editor/code/di/injection.dart';
import 'package:leyak_lvl_editor/editor/history/scene_snapshot.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/state/scene_cubit.dart';
import 'package:leyak_lvl_editor/editor/video/video_texture_manager.dart';
import 'package:leyak_lvl_editor/ui/screens/playtest_screen.dart';
import 'package:leyak_lvl_editor/ui/widgets/hud_notification.dart';
import 'package:leyak_lvl_editor/ui/widgets/inspector_panel.dart';
import 'package:leyak_lvl_editor/ui/widgets/layers_panel.dart';
import 'package:leyak_lvl_editor/ui/widgets/level_file_toolbar.dart';
import 'package:leyak_lvl_editor/ui/widgets/shape_toolbar.dart';
import 'package:leyak_lvl_editor/ui/widgets/shortcuts_help_panel.dart';
import 'package:leyak_lvl_editor/ui/widgets/video_texture_host.dart';

class LevelEditorScreen extends StatefulWidget {
  const LevelEditorScreen({super.key});

  @override
  State<LevelEditorScreen> createState() => _LevelEditorScreenState();
}

class _LevelEditorScreenState extends State<LevelEditorScreen> {
  final FocusNode _gameFocusNode = FocusNode();
  final MainEditor _game = MainEditor();

  @override
  void initState() {
    super.initState();
    // Автоматично фокусуємо гру одразу після побудови віджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _gameFocusNode.dispose();
    super.dispose();
  }

  /// Копіює поточні сутності через [EntitySnapshot] (той самий механізм,
  /// що й undo/redo) — playtest отримує НЕЗАЛЕЖНУ глибоку копію, тож нічого
  /// в ньому не може ненавмисно змінити дані, які ти редагуєш.
  void _play() {
    final cubit = _game.editorWorld.objectManager.sceneCubit;
    final snapshot = cubit.state.entities.map((e) => EntitySnapshot.of(e).toEntity()).toList();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaytestScreen(
          entities: snapshot,
          tileSize: _game.tileSize,
          groundY: _game.gridLength * _game.tileSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SceneCubit>.value(
      value: _game.editorWorld.objectManager.sceneCubit,
      child: Scaffold(
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => _gameFocusNode.requestFocus(),
              child: GameWidget(
                game: _game,
                focusNode: _gameFocusNode,
                autofocus: true,
                overlayBuilderMap: {
                  'HudNotification': (context, MainEditor game) =>
                      HudNotification(game: game),
                },
              ),
            ),
            const LayersPanel(),
            const InspectorPanel(),
            ShapeToolbar(game: _game),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(child: LevelFileToolbar(game: _game)),
            ),
            VideoTextureHost(manager: getIt<VideoTextureManager>()),
            const Positioned(bottom: 16, left: 16, child: ShortcutsHelpButton()),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'play',
                backgroundColor: Colors.green,
                tooltip: 'Playtest',
                onPressed: _play,
                child: const Icon(Icons.play_arrow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
