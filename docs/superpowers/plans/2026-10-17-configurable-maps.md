# Configurable Maps Implementation Plan

> **For agentic workers:** Execute tasks with parent-managed Sol workers, scoped tests, specification review followed by code review. Preserve all existing uncommitted sprite work. Do not commit or push.

**Goal:** Deliver configurable layered maps with original environment art, authoritative movement/collision and working responsive native scene interaction.

**Architecture:** A validated immutable JSON catalog defines tiles, prefabs and maps. Existing engine/Bloc state owns accepted mutations; Flame World and camera render the current definition. Original atlas artwork and two connected maps demonstrate extension without a new per-map renderer.

**Tech Stack:** Dart 3.13, Flutter 3.47, Flame 1.38, Bloc, existing image preparation tools, Flutter tests and Dart MCP.

---

## Task 1: Definitions and authoritative rules (`map-engine`)

**Ownership:** `app_lib/engine/**`, `app_bloc/game/**`; no art, root app or renderer edits.

- [x] Add focused tests for per-room bounds, blocked terrain/props, multi-cell footprints, route detours/unreachable targets, invalid named spawns/portals and definition round trips.
- [x] Run the tests before implementation and record the expected missing-feature failures. Example behavioral assertion:

```dart
expect(room.containsCell(GridPosition(room.width, 1)), isFalse);
expect(room.findPath(start, blockedTarget), isEmpty);
for (final cell in room.findPath(start, reachableTarget)) {
  expect(room.canWalk(cell), isTrue);
}
```

- [x] Implement the exact public interface in the approved design using focused map model/parser files; export through `app_lib_engine.dart`.
- [x] Route reducer movement, placement and transitions through room-owned bounds/occupancy. Add optional catalog loading to GameBloc; keep standalone no-loader callers working.
- [x] Run `flutter test --no-pub` from `app_lib/engine` and `app_bloc/game`, then scoped analysis/format checks. Stop on unrelated failures and report them.

## Task 2: Original artwork, maps and layered renderer (`map-art-renderer`)

**Ownership:** `assets/maps/**`, `game_objects/room/**`; no root pubspec or engine edits. Run independently against the frozen interface above.

- [x] Create editable original environment art and deterministic atlas preparation, with source/provenance documentation. Include metal floors/trim, complete wall edges/corners, doors, racks, console, cooling and workbench props; review their assembled scale alongside existing characters.
- [x] Create complete `catalog.json` data: 20×12 server lab and differently sized operations room, valid entry spawns and reciprocal portals. Keep paths open and separate walkable occupancy from tall sprite overhang.
- [x] Add meaningful tests for layer dimensions, prefab ground anchors/ordering, ordinary grid visibility and room replacement. Record expected pre-implementation failures.
- [x] Implement a `MapEnvironmentComponent` accepting `MapCatalog` and `MapDefinition`, drawing atlas layers and sortable static prefab components; retain isolated `RoomComponent` compatibility until integration switches production use.
- [x] Run `flutter test --no-pub` from `game_objects/room` after engine interface files are ready. Inspect atlas and composed-room images; do not claim visual acceptance from geometry assertions alone.

## Task 3: App, world, camera and scene controls (`map-integration`)

**Ownership:** `lib/app.dart`, new `lib/map_assets.dart`, `lib/screens/game_screen.dart`, root `pubspec.yaml`, `game_objects/world/**`, required device/character component synchronization, `game_bloc/world/**`, `game_widgets/hud/**`, root scene/map tests. Start after Tasks 1–2 interface/validation handoffs.

- [x] Load `assets/maps/catalog.json` via Flutter AssetBundle; inject the loader into GameBloc. Declare catalog and atlas assets in root pubspec.
- [x] Add real scene tests for rejected movement, room switching and transformed pointer picking. Use real constraints, not MediaQuery-only overrides:

```dart
tester.view.devicePixelRatio = 1;
tester.view.physicalSize = size;
addTearDown(tester.view.resetPhysicalSize);
addTearDown(tester.view.resetDevicePixelRatio);
```

- [x] Mount environment, actors and dynamic objects under a camera-controlled Flame World with stable Bloc provider ownership. Fit/center with visual margins; add bounded zoom/reset controls. Convert screen positions to world coordinates before cell picking.
- [x] Remove speculative direct player movement from keyboard/gamepad/tap handlers. Queue click routes and advance accepted adjacent steps. Cancel transient routes on room/panel/session changes; ensure all same-ID dynamic model changes are reflected.
- [x] Replace the blocked full-HUD IgnorePointer with selective event handling; keep details, map controls and logout reachable at every target size. Maintain existing shop behavior.
- [x] Run affected world/Bloc/HUD and root map/game/logout/sprite flow tests, plus scoped analysis, formatting and `git diff --check`.

## Task 4: Review and live acceptance

- [x] Parent checks specification coverage, then code quality; use read-only Sol review after implementation. Preserve per-task repair counters (maximum two Sol repair rounds before evidenced escalation).
- [x] Hot restart via Dart MCP, rediscover the isolate, inspect screenshots and widget tree, and dispatch real pointer events to validate movement, camera picking, details and map transitions. Capture evidence without printing VM authentication tokens.
- [x] Verify the second map changes dimensions/layout through configuration and retains valid spawns and access paths. Verify repeated room entry/logout does not leave orphan components or late-loaded character visuals.
- [x] Update this checklist and a scoped validation report with actual commands/outcomes. Report any remaining visual or platform limitation honestly. No commit/push, unrelated cleanup, character-creation changes, backend implementation or old-data migration.
