# Configurable Map System

Status: approved in conversation (`LGTM`, 2026-10-17). The first release uses developer-authored JSON; an application map editor and Tiled import are future adapters.

## Outcome

Replace the placeholder room with a coherent orthogonal, layered 2D environment. Keep the supplied male/female characters. Ship a polished server room and a connected operations room with different dimensions. A developer adds maps and object definitions through assets, without adding a new renderer class for each room.

## Boundaries

- Keep Flutter, Flame, Bloc and existing workspace packages.
- Preserve character creation and existing sprite preparation/lifecycle work.
- No cloud backend, fabricated monitoring telemetry, new editor, dependency refresh, Web target, legacy-data migration, commit or push.
- Existing incompatible world snapshots need not be migrated; character storage remains separate and untouched. Current map-enabled snapshots retain IDs and resolve definitions from the catalog.
- Original environment artwork is created in this repository, with editable source and reproducible PNG output. No external artwork is downloaded.

## Visual Direction

Use illustrated top-down equipment with visible wall height, matching the supplied character proportions. Floors, inset wall panels, corners, thresholds, racks, consoles, cooling and restrained shadows share a palette and light direction. Normal exploration hides the placement grid. Show grid/hover feedback during placement. Floors render below actors; actors and props sort by their bottom-center ground anchor. Tall visual overhang is independent of occupied cells. Foreground elements must leave the player and interaction target readable.

## Data Contract

One UTF-8 JSON catalog at `assets/maps/catalog.json` contains `schemaVersion: 1`, `atlasAsset`, `initialMapId`, `tiles`, `prefabs`, and `maps`. Atlas coordinates are source pixels; the initial logical cell size is 32 units. Lists use explicit stable IDs, with references resolved into immutable models.

```json
{
  "schemaVersion": 1,
  "atlasAsset": "assets/maps/homelab_atlas.png",
  "initialMapId": "server-lab",
  "tiles": [
    {"id":"floor.metal","frame":[0,0,64,64],"blocksMovement":false,"blocksPlacement":false}
  ],
  "prefabs": [
    {"id":"rack","frame":[0,128,128,192],"width":2,"height":1,"drawWidth":64,"drawHeight":96,"blocksMovement":true,"blocksPlacement":true}
  ],
  "maps": [
    {
      "id":"server-lab","name":"Server Lab","width":20,"height":12,
      "spawns":{"entry":[10,9]},"terminalPosition":[2,2],
      "layers":[{"id":"floor","foreground":false,"cells":[]}],
      "objects":[{"id":"rack-a","prefabId":"rack","position":[5,3]}],
      "portals":[{"id":"to-operations","targetMapId":"operations","wallSide":"right","wallPosition":8,"targetSpawnId":"entry"}]
    }
  ]
}
```

The example abbreviates cell rows and the destination map; shipped data must contain complete rectangular layers and valid destinations. A layer cell is a tile ID or null. Object definitions may include an optional `bindingSlot` and `interaction` (`shop` for the existing terminal). Binding slots are stable semantic references, not credentials or invented health data. Moving an object never changes its ID or slot.

### Public Engine Interface

- `MapAtlasFrame`: integer `x`, `y`, `width`, `height`.
- `MapTileDefinition`: `id`, `frame`, `blocksMovement`, `blocksPlacement`.
- `MapPrefabDefinition`: `id`, `frame`, cell `width`/`height`, logical `drawWidth`/`drawHeight`, `blocksMovement`, `blocksPlacement`.
- `MapTileLayer`: `id`, `foreground`, immutable `cells` (`List<List<String?>>`).
- `MapObjectDefinition`: `id`, `prefabId`, `position`, optional `bindingSlot`/`interaction`.
- `MapPortalDefinition`: `id`, `targetMapId`, `wallSide` (`WallSide`), `wallPosition`, `targetSpawnId`.
- `MapDefinition`: `id`, `name`, `width`, `height`, `spawns`, `terminalPosition`, `layers`, `objects`, `portals`, resolved `tiles`/`prefabs`; `spawn` returns `spawns['entry']`; logical `tileSize` is 32.
- `MapCatalog.fromJson(Map<String,dynamic>)`: validates and resolves the catalog; exposes `atlasAsset`, `initialMapId`, maps/tiles/prefabs keyed by ID; `createGame()` instantiates bundled maps as rooms and portals as doors; `resolveGame(GameModel)` reattaches current definitions or creates a fresh map world when a snapshot has no supported definitions.
- `RoomModel.definition`: optional transient `MapDefinition`; `definitionId`: persisted reference. `containsCell`, `canWalk`, `canPlaceDevice`, and `findPath(start,target)` share room bounds, static terrain/props and dynamic occupancy. Paths exclude the start and include the destination; unreachable targets return an empty list.
- `DoorModel.targetSpawnId`: optional named spawn reference; configured portals resolve to valid destination spawns.
- `GameBloc` optionally accepts `Future<MapCatalog> Function()? mapCatalogLoader`; initialization resolves definitions before emitting `GameReady`. A nullable read-only `mapCatalog` getter exposes the loaded catalog to scene composition. Existing isolated callers without a loader retain their current behavior.

Unknown versions, duplicate IDs, missing references, invalid frame sizes, inconsistent rows, out-of-bounds footprints, blocked spawns and unreachable portal interaction cells produce actionable `FormatException`s. No remote URLs or arbitrary code are evaluated by the catalog.

## Runtime and Input

`GameBloc` and pure engine rules own accepted movement, placement and room transitions. Flame only renders/interpolates accepted positions. Definition-backed movement events accept one cardinal cell per step; click movement follows a four-neighbor path through the shared walkability rules and cannot interpolate through furniture or walls. Cancel a route on keyboard movement, room change, panel opening or logout.

Mount map components under one Flame `World`. The camera fits and centers the room including visual overhang, with bounded zoom and a reset-to-fit action. Screen input passes through the camera inverse exactly once. Hover, picking and placement preview use the same conversion and validation as committed placement. Flutter panels consume their own events; background HUD space allows scene interaction.

Map changes replace terrain, terminal, doors and static props, synchronize same-ID dynamic object changes, and clear stale hover/selection/routes. Providers belong to stable scene containers; removing objects must remove their full owned subtree. Preserve delayed-image-load removal guards.

## Ownership and Validation

- `app_lib/engine`, `app_bloc/game`: models, parsing, validation, collision, route rules and catalog-aware initialization.
- `assets/maps`, `game_objects/room`: original environment art, two definitions and layered rendering.
- `game_objects/world`, device/character components, `lib/app.dart`, `lib/screens/game_screen.dart`: loading, camera, accepted-state animation, scene lifecycle and screen controls.
- `game_widgets/hud`: interactive, responsive map status and details.

Require focused engine/Bloc/room/world and root-flow tests; real view sizes 1280×800, 800×600, 390×640 and 480×400; correct picking after camera transforms; blocked movement and multi-cell placement; repeated map changes/logout; single-frame character appearance unchanged. Verify visually and through real pointer events with Dart MCP after hot restart. Distinguish automated evidence, live macOS evidence and untested physical devices.
