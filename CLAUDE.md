# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter + Flame (2D game engine) desktop/web app: a level editor for a Geometry-Dash-style game, plus an in-app playtest runtime. Two `FlameGame`s share the same `LevelEntity` data model: `MainEditor` (editing) and `PlaytestGame` (playing).

## Commands

```bash
flutter pub get                          # install dependencies
flutter run -d macos                     # run (or -d chrome, -d windows, etc.)
flutter test                             # run all tests
flutter test test/game/level_loader_test.dart   # run a single test file
flutter test --plain-name "uses the marked spawn entity"  # run a single test by name
flutter analyze                          # static analysis (flutter_lints)
```

There is no CI config in this repo; `flutter analyze` and `flutter test` are the checks to run before considering work done.

## Architecture

### Editor vs. game runtime

- **Editor** (`lib/editor/`, `lib/ui/`): `MainEditor` (`lib/editor/main_editor.dart`) is the `FlameGame` shown in `LevelEditorScreen`. Its `World` is `EditorWorld`, which owns `ObjectManager`.
- **Game** (`lib/game/`): `PlaytestGame` is a separate, independent `FlameGame` shown in `PlaytestScreen`. Pressing Play deep-copies the current entities via `EntitySnapshot` (the same mechanism undo/redo uses) so the playtest session can never mutate the level being edited.
- **Bridge**: `lib/game/level_loader.dart` (`buildLevel`) converts a `List<LevelEntity>` into playtest components. `lib/game/trigger_kind.dart` (`classifyEntity`) is the single place that inspects `LevelEntity.customProperties` to decide an entity's role (player spawn / camera node / mode trigger / speed trigger / finish / plain solid block) — extend this enum+switch (not an if-chain) when adding a new entity role, since the exhaustive `switch` in `buildLevel` will fail to compile until a new case is handled.

### Composition roots (no DI framework inside the editor)

`ObjectManager` (`lib/editor/components/object_manager.dart`) is the composition root for scene editing: it lazily builds every tool/service/controller/repository, routes drag events to whichever `EditorTool` matches the current `EditorMode`, and wires up all callback subscriptions in `onLoad()`. Callback slots on repositories (`EntityRepository.onChanged`, `GroupRepository.onGroupAdded`, `SelectionTool.onChanged`, etc.) are single-slot/one-shot, so `ObjectManager.onLoad()` is the one place responsible for composing every subscriber a given event needs (typically both `SceneComponentRegistry`, which keeps Flame components in sync, and `SceneCubit`, which feeds Flutter UI).

`EditorWorld` (`lib/editor/components/editor_world.dart`) is the composition root for input: it owns `ObjectManager` plus overlay components (grid, background frame, level-end marker, camera path overlay) and dispatches keyboard shortcuts (mode switch, group/ungroup, undo/redo, duplicate, delete, merge, path finish/cancel, grid snap toggle) to dedicated `*Shortcut` resolver classes in `lib/editor/input/`.

`get_it` (`lib/code/di/injection.dart`) is used only for a few app-wide singletons unrelated to scene state: `ShaderCatalog`, `VideoAssetCatalog`/`VideoTextureManager`, `AudioAssetCatalog`/`AudioTextureManager`. Everything scene-related goes through `ObjectManager`, not `get_it`.

### Data flow: Flame world ↔ Flutter UI

- `EntityRepository`/`GroupRepository`/`LayerFolderRepository` hold the source-of-truth data (`LevelEntity`, `LevelGroup`, `LayerFolder`).
- `SceneComponentRegistry` mirrors that data into live `EntityComponent`/`GroupComponent` Flame nodes (spawn/despawn on add/remove/group/ungroup); it never renders anything itself.
- `SceneCubit` (flutter_bloc `Cubit<SceneState>`) is the read model + edit facade Flutter widgets (Layers panel, Inspector panel) consume. It doesn't subscribe to anything itself — `ObjectManager` calls `sceneCubit.refresh()` alongside other subscribers whenever underlying data changes.
- Coordinates: `GridCoordinateConverter` converts world (pixel) positions to grid positions, snapping to whole cells when `GridSnapController.snapEnabled` is on and passing through fractional positions otherwise. `tileSize`/`gridWidth`/`gridLength` live on `MainEditor` and are read lazily via closures (converter/tools are constructed before the game instance's values are finalized).

### Editor tools and modes

`EditorMode` (`draw`, `select`, `placeSpawn`, `cameraPath`) picks the active `EditorTool` in `ObjectManager._activeTool`. All tools implement the same three-method `EditorTool` interface (`dragStart`/`dragUpdate`/`dragEnd`) so `ObjectManager`/`EditorWorld` can route drag events without knowing which tool is active. `draw` mode itself further dispatches between `DrawTool` (single-drag shapes) and `PathTool` (multi-click polyline, has its own Enter/Escape lifecycle via `PathShortcut`) based on the shape selected in `ShapeToolbar`.

### Undo/redo and persistence

`HistoryController` snapshots repository state; callers must call `history.checkpoint()` **before** mutating state (not after) — this pattern repeats throughout `SceneCubit` and `ObjectManager`. `LevelFileService` (`lib/editor/persistence/`) saves/loads a `LevelDocument` as JSON via `file_picker`, using byte APIs (`saveFile`/`pickFiles` with `bytes`) rather than `dart:io.File` so the same code path works on desktop and web.

### Compound entities

A `LevelEntity` can either be a single shape (`shapeType`/`shapeStyle`/`visual` directly on the entity) or a compound entity made of `EntityPart`s (each with its own relative position/size/color/shapeType/shader/video) — created via `MergeService` (Cmd/Ctrl+M). Code that edits visual/shader/corner-radius/line-thickness properties generally has two parallel methods in `SceneCubit`: one for the plain entity, one taking a `partIndex` for compound entities (e.g. `setEntityColor`/`setPartColor`).

### Code comments

Existing non-obvious "why" comments in this codebase are written in Ukrainian. Follow the existing convention of that file/module rather than switching languages, unless the user asks otherwise.
