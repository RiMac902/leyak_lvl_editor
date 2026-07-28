import 'package:get_it/get_it.dart';
import 'package:leyak_lvl_editor/editor/rendering/shader_catalog.dart';
import 'package:leyak_lvl_editor/editor/video/video_texture_manager.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final shaderCatalog = ShaderCatalog();
  await shaderCatalog.load();
  getIt.registerSingleton<ShaderCatalog>(shaderCatalog);

  getIt.registerSingleton<VideoTextureManager>(VideoTextureManager());
}
