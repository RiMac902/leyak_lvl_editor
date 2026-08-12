import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:leyak_lvl_editor/editor/entities/entity_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/group_repository.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_repository.dart';
import 'package:leyak_lvl_editor/editor/persistence/level_document.dart';

/// Єдина відповідальність — збереження/завантаження сцени у/з `.json`-файл
/// через системний файловий діалог ([FilePicker]). Працює через
/// байти ([FilePicker.saveFile]/[FilePicker.pickFiles] з `bytes`), а не
/// `dart:io.File`, — той самий код працює і на десктопі/мобільних (де
/// плагін сам пише байти на обраний шлях), і на web (де байти стають
/// браузерним завантаженням, а не файлом на "диску").
class LevelFileService {
  LevelFileService(this._entities, this._groups, this._layerFolders);

  final EntityRepository _entities;
  final GroupRepository _groups;
  final LayerFolderRepository _layerFolders;

  /// Показує системний діалог "Зберегти як" і пише поточну сцену туди.
  /// Повертає `true`, якщо користувач підтвердив збереження, `false` —
  /// якщо скасував діалог.
  Future<bool> save({
    required double tileSize,
    required int gridWidth,
    required int gridLength,
  }) async {
    final document = LevelDocument(
      tileSize: tileSize,
      gridWidth: gridWidth,
      gridLength: gridLength,
      entities: _entities.all,
      groups: _groups.all,
      folders: _layerFolders.all,
    );
    final bytes = Uint8List.fromList(utf8.encode(document.encode()));

    final path = await FilePicker.saveFile(
      dialogTitle: 'Save level',
      fileName: 'level.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    return path != null;
  }

  /// Показує системний діалог "Відкрити" і повністю замінює поточну сцену
  /// (сутності/групи/папки) вмістом обраного файлу. Повертає розпарсений
  /// [LevelDocument] (композиційний корінь застосовує з нього
  /// tileSize/gridWidth/gridLength), або `null`, якщо користувач скасував
  /// діалог.
  Future<LevelDocument?> open() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Open level',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return null;

    final document = LevelDocument.decode(utf8.decode(bytes));

    _entities.replaceAll(document.entities);
    _groups.replaceAll(document.groups);
    _layerFolders.replaceAll(document.folders);

    return document;
  }
}
