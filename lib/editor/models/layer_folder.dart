/// "Папка" в Layers panel — суто організаційне угруповання сутностей у
/// z-порядку, БЕЗ жорсткого зв'язку трансформації (на відміну від
/// [LevelGroup]/Ctrl+G). Членство тут не зберігається — воно завжди
/// читається "наживо" з [LevelEntity.layerFolderId], той самий підхід, що
/// й у [LevelGroup] з [LevelEntity.groupId].
class LayerFolder {
  LayerFolder({
    required this.id,
    required this.name,
    this.isExpanded = true,
    this.isBackground = false,
  });

  final String id;
  String name;
  bool isExpanded;

  /// Якщо true — члени цієї папки складають фон рівня: рендеряться позаду
  /// геть усього іншого контенту (див. [LayerFolderService.setFolderBackground]),
  /// і мисляться як "той самий екран", що позначає [BackgroundFrameComponent].
  /// Реальний паралакс-скрол — майбутня робота (потребує ігрової камери,
  /// якої ще нема); тут лише авторська підтримка: позначити контент фоном
  /// і бачити орієнтир розміром з екран, компонуючи його.
  bool isBackground;
}
