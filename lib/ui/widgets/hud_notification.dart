import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';

/// Єдина відповідальність — показ поточного тексту короткого
/// HUD-сповіщення (зміна режиму, перемикання snap тощо). Сам текст
/// формує [EditorWorld] — цей віджет лише його відображає.
class HudNotification extends StatelessWidget {
  const HudNotification({super.key, required this.game});

  final MainEditor game;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            game.editorWorld.notificationText,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
