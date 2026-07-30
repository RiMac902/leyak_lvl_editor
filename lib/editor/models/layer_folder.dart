/// "Папка" в Layers panel — суто організаційне угруповання сутностей у
/// z-порядку, БЕЗ жорсткого зв'язку трансформації (на відміну від
/// [LevelGroup]/Ctrl+G). Членство тут не зберігається — воно завжди
/// читається "наживо" з [LevelEntity.layerFolderId], той самий підхід, що
/// й у [LevelGroup] з [LevelEntity.groupId].
class LayerFolder {
  LayerFolder({required this.id, required this.name, this.isExpanded = true});

  final String id;
  String name;
  bool isExpanded;
}
