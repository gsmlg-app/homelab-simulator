# Configurable Maps Validation

Status: complete. User approved the design with `LGTM`; scoped automated checks, read-only reviews and macOS Dart MCP acceptance passed.

## Scope and ownership

Baseline: `main@89b799c846e274ec5a2da143a1cc037a5f07bee1`, with existing uncommitted sprite work preserved. Existing `AGENTS.md` is untouched. No commit or push is authorized.

| Task | Owner | Status | Sol repairs | Astra repairs |
| --- | --- | --- | --- | --- |
| `map-engine` | `sprite_runtime_diagnosis` | Complete, writer stopped | 2 | 0 |
| `map-art-renderer` | `map_art_renderer` | Complete, writer stopped | 2 | 0 |
| `map-integration-world` | `sprite_runtime_diagnosis`, bounded recovery by `map_fixture_recovery` | Complete, writer stopped | 2 | 1 |
| `map-integration-ui` | `map_art_renderer`, bounded recovery by `map_fixture_recovery` | Complete, writer stopped | 2 | 1 |

Integration tasks are independent new assignments with disjoint writes. World owns Flame/camera/input, character/device projection and WorldBloc. UI owns app loading, GameScreen, root asset declarations, HUD and root scene tests. Their fixed `HomelabGame` interface is `zoomIn`, `zoomOut`, `resetCamera`, `cancelRoute`, `interact`, and `navigateToRoom(String)`. Navigation follows a reachable outgoing portal and uses its named target spawn.

## Completed automated checks

| Scope | Command | Evidence |
| --- | --- | --- |
| Engine | `flutter test --no-pub` in `app_lib/engine` | 436 passed; `/tmp/map-engine-green-round2.log`; exit 0 |
| GameBloc | `flutter test --no-pub` in `app_bloc/game` | 150 passed; `/tmp/map-bloc-green-round2.log`; exit 0 |
| Engine/GameBloc sources and tests | Scoped `dart analyze` | No issues; `/tmp/map-engine-analysis-round2.log`; exit 0 |
| Room | `flutter test --no-pub` in `game_objects/room` | Worker tool transcript: 150 passed, including 7 new tests |
| Art | `python3 assets/maps/tool/build_maps.py --check` | Worker tool transcript: 22 frames, two maps; atlas and both previews reproduce decoded pixels |
| Room sources and new tests | Scoped `dart analyze`, `dart format`, `git diff --check` | Worker tool transcript: clean |
| World | `flutter test --no-pub` in `game_objects/world` | 90 passed; `/tmp/map-world-round2.log`; exit 0 |
| WorldBloc | `flutter test --no-pub` in `game_bloc/world` | 124 passed; `/tmp/map-worldbloc-round2.log`; exit 0 |
| Character | `flutter test --no-pub --reporter expanded` in `game_objects/character` | 32 passed; `/tmp/map-recovery-character.log`; exit 0 |
| Devices | Same command in `game_objects/devices` | 104 passed; `/tmp/map-recovery-devices.log`; exit 0 |
| HUD and bundled assets | Scoped Flutter tests | 88 passed; `/tmp/homelab-map-ui-hud-assets-final.log`; exit 0 |
| Root scene/menu/logout/sprites/assets | Six-file command below | 63 passed; `/tmp/map-recovery-root-round1.log`; exit 0 |
| Final integration sources and tests | Scoped `dart analyze` on 13 files | No issues; `/tmp/map-integration-final-analysis.log`; exit 0 |
| Final formatting and preservation | Scoped `dart format --output=none --set-exit-if-changed`, `git diff --check` | 13 files unchanged; checks passed; existing `AGENTS.md` and original boy/girl artwork unchanged |

Root validation command:

```sh
flutter test --no-pub --reporter expanded \
  test/screens/map_scene_flow_test.dart \
  test/screens/game_screen_test.dart \
  test/screens/logout_flow_test.dart \
  test/screens/start_menu_screen_test.dart \
  test/screens/character_sprite_flow_test.dart \
  test/map_assets_test.dart
```

Behavioral red tests preceded implementation. Engine coverage includes immutable catalog data, invalid definitions, bounds, occupancy, shortest cardinal paths, portal access, current portal restoration and rejection of nonadjacent mapped movement. Renderer coverage includes real atlas sampling, ground anchors, placement-only grid, owned-subtree removal and delayed atlas completion after removal.

Parent inspected engine/Bloc changes, renderer source and tests, asset documentation, and assembled previews. Preview inspection alone is not native runtime acceptance.

## Review and bounded recovery

ROUTE `map-integration-world` and `map-integration-ui` to Sol for independent implementation. Both reached their two-round repair limit with required acceptance failures; gate `SOL_REPEATED_FAILURE` admitted bounded Astra recovery. Preserve the counts above. Recovery changed four test files only: reset sprite fixtures through `snapTo`, stub mock closure state, observe actual pending sprite loads, and initialize/wait for Bloc in one real async zone. All original behavior and removal assertions remain. No Astra validation failed.

Sol read-only cross-reviews `map-review-world` and `map-review-ui` reported no actionable P0/P1/P2 findings. Parent inspected source, recovery diffs and passing logs before acceptance.

## Native acceptance

Dart MCP hot restart refreshed the isolate and loaded the real bundled catalog/atlas. Tests used actual constraints at 1280×800, 800×600, 390×640 and 480×400. Live macOS runtime checks used the existing 986×647 viewport and actual pointer events:

- Both supplied character sheets reached the scene; artwork proportions and grounded feet remained intact.
- Zoom changed from 1.4140625 to 1.767578125. A transformed click reached cell `(10,7)`; a rack-footprint click left both accepted and rendered positions unchanged. Fit reset worked.
- Connected-room navigation reached Operations, 16×10, at named spawn `(1,7)`. Touch interaction returned to Server Lab, 20×12, at `(18,8)`. Round trip retained one environment and one provider, with scene child counts 16→13→16.
- Details opened/closed and canceled queued movement. A terminal-adjacent pointer interaction opened the existing shop.
- Placement rejected a static occupied cell without spending credits. After zoom, preview and committed Basic Server agreed at `(14,7)`; one dynamic device rendered. The temporary device and credits were restored to the pre-test snapshot and saved. Multi-cell occupancy is covered by engine tests.
- Walking behind `compute-a` produced actor priority 9600, prop priority 12800 and prop opacity 0.48, keeping the actor visible.
- Two clean native logout runs removed all old game children and ended the subscription; one began with ten queued route steps. Flutter error capture remained empty, and instrumentation was restored afterward.

An earlier heavily instrumented inspector session left Navigator history locked while awaiting disposal. A clean hot restart and two pointer-only logout repetitions verified complete disposal without a production workaround. Tool error polling alone was not used as acceptance evidence.

Native screenshots: `/tmp/homelab-map-server-lab.png` and `/tmp/homelab-map-operations.png`. The app was left in a working Server Lab scene. Android/iOS physical-device validation was not run for this map change.

No dependency refresh, Web build, legacy-data migration, character-creation redesign, backend implementation or telemetry fabrication is included.
