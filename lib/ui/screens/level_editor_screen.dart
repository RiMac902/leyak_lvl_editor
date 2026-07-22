import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';

class LevelEditorScreen extends StatefulWidget {
  const LevelEditorScreen({super.key});

  @override
  State<LevelEditorScreen> createState() => _LevelEditorScreenState();
}

class _LevelEditorScreenState extends State<LevelEditorScreen> {
  final FocusNode _gameFocusNode = FocusNode();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => _gameFocusNode.requestFocus(),
        child: GameWidget(
          game: MainEditor(),
          focusNode: _gameFocusNode,
          autofocus: true,
          overlayBuilderMap: {
            'ModeNotification': (context, MainEditor game) => Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        game.editorWorld.currentModeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
          },
        ),
      ),
    );
  }
}
