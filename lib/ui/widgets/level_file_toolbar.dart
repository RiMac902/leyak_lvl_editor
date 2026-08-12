import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/main_editor.dart';
import 'package:leyak_lvl_editor/editor/persistence/level_document.dart';

/// Кнопки "Save"/"Open" для збереження/завантаження рівня у `.json`-файл
/// (див. [LevelFileService], викликається через [ObjectManager.saveLevel]/
/// [ObjectManager.openLevel]). Сам не містить логіки файлового діалогу —
/// лише показує результат користувачу через [SnackBar].
class LevelFileToolbar extends StatelessWidget {
  const LevelFileToolbar({super.key, required this.game});

  final MainEditor game;

  Future<void> _save(BuildContext context) async {
    final saved = await game.editorWorld.objectManager.saveLevel();
    if (!context.mounted || !saved) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Level saved')));
  }

  Future<void> _open(BuildContext context) async {
    try {
      final opened = await game.editorWorld.objectManager.openLevel();
      if (!context.mounted || !opened) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Level loaded')));
    } on LevelDocumentFormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open level: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            tooltip: 'Save level',
            onPressed: () => _save(context),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_outlined, color: Colors.white),
            tooltip: 'Open level',
            onPressed: () => _open(context),
          ),
        ],
      ),
    );
  }
}
