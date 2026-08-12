import 'package:flutter_test/flutter_test.dart';
import 'package:leyak_lvl_editor/editor/entities/layer_folder_repository.dart';
import 'package:leyak_lvl_editor/editor/models/layer_folder.dart';

LayerFolder _folder(String id) => LayerFolder(id: id, name: id);

void main() {
  test('add stores the folder and fires onChanged', () {
    final repo = LayerFolderRepository();
    var changed = false;
    repo.onChanged = () => changed = true;

    final folder = _folder('f1');
    repo.add(folder);

    expect(repo.all, [folder]);
    expect(changed, isTrue);
  });

  test('find returns the matching folder or null', () {
    final repo = LayerFolderRepository();
    final folder = _folder('f1');
    repo.add(folder);

    expect(repo.find('f1'), folder);
    expect(repo.find('missing'), isNull);
  });

  test('remove drops the folder by id', () {
    final repo = LayerFolderRepository();
    repo.add(_folder('f1'));

    repo.remove('f1');

    expect(repo.all, isEmpty);
  });

  test('replaceAll clears the old list and installs the new one', () {
    final repo = LayerFolderRepository();
    repo.add(_folder('old'));

    final newFolders = [_folder('a'), _folder('b')];
    repo.replaceAll(newFolders);

    expect(repo.all, newFolders);
  });
}
