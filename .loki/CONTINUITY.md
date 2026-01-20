# Loki Mode Continuity Document

## Project Overview
Homelab Simulator - Flutter/Flame game with Melos monorepo architecture and BLoC state management.

## Current PRD Focus
Two main feature sets from PRD.md:
1. **Character Creation Enhancements** - ✅ COMPLETED
2. **Game World & Rooms** - ✅ COMPLETED (all milestones implemented)

## Current State
- **Phase:** VALIDATION
- **Last Updated:** 2026-01-21
- **Iteration:** 19
- **Last Commit:** 85184a0

## Test Coverage Summary
- **app_lib/core:** 115 tests passing
  - CharacterName: 12 tests
  - GridPosition: 25 tests
  - Helpers (GameConstants, gridToPixel, pixelToGrid, isWithinBounds): 21 tests
  - IDs: 15 tests
  - Enums: 42 tests (NEW)
- **app_lib/engine:** 211 tests passing
  - CharacterModel: 12 tests
  - RoomModel: 28 tests
  - DoorModel: 16 tests
  - CloudServiceModel: 26 tests
  - GameModel: 22 tests
  - DeviceModel/DeviceTemplate: 23 tests
  - Reducer: 26 tests
  - DomainEvents: 58 tests
- **app_lib/database:** 27 tests passing
  - GameStorage: 11 tests
  - CharacterStorage: 15 tests
  - app_database_test: 1 test
- **app_lib/logging:** 82 tests passing
  - LogLevel: 8 tests
  - LogRecord: 14 tests
  - AppLogger: 26 tests (NEW)
  - ApiLoggingInterceptor: 34 tests (NEW)
- **game_bloc/world:** 47 tests passing
  - WorldBloc: 23 tests
  - WorldState: 16 tests
  - WorldEvent: 8 tests
- **app_bloc/game:** 57 tests passing
  - GameBloc: 32 tests
  - GameState: 8 tests
  - GameEvent: 17 tests
- **game_widgets/panels:** 23 tests passing
  - InfoPanel: 5 tests
  - RoomSummaryPanel: 18 tests
- **game_widgets/hud:** 13 tests passing
  - CreditsDisplay: 5 tests
  - InteractionHint: 8 tests
- **game_widgets/shop:** 12 tests passing
  - DeviceCard: 12 tests
- **game_asset/characters:** 23 tests passing
  - CharacterSpriteSheet: 12 tests
  - GameCharacters: 8 tests
  - CharacterDirection: 3 tests
- **Total:** 598 unit tests

## Completed Work

### Character Creation PRD (100% Complete)
- ✅ M1: Updated CharacterModel with appearance fields (skinTone, hairStyle, hairColor, outfitVariant)
- ✅ M2: Multi-step character creation screen (Name → Appearance → Summary)
- ✅ M3: Edit flow from character list with Edit button
- ✅ M4: Name validation (2-16 chars, blocked words) + randomize feature
- ✅ M5: Unit tests for CharacterModel and name validation

### Game World PRD (100% Complete)
- ✅ M1: Data models (RoomModel, DoorModel, CloudServiceModel, DeviceModel, GameModel)
- ✅ M2: Basic 2D room view + player spawn + door transitions (HomelabGame, RoomComponent)
- ✅ M3: Room creation + provider presets (RoomAdded event, AddRoomModal)
- ✅ M4: Object catalog + room placement UI (CloudServiceCatalog, PlacementGhostComponent)
- ✅ M5: Room summary panel with object counts (RoomSummaryPanel)
- ✅ Unit tests for all engine models, reducer, and domain events (211 tests passing)
- ✅ Unit tests for WorldBloc (47 tests)
- ✅ Unit tests for GameBloc (57 tests)

### Files Modified/Created
- `app_lib/core/lib/src/enums.dart` - RoomType, CloudProvider, ServiceCategory enums
- `app_lib/engine/lib/src/models/room_model.dart` - Room with devices/doors/services
- `app_lib/engine/lib/src/models/door_model.dart` - Door with wall positioning
- `app_lib/engine/lib/src/models/cloud_service_model.dart` - Cloud service + catalog
- `app_lib/engine/lib/src/models/device_model.dart` - Physical devices
- `app_lib/engine/lib/src/reducer.dart` - Game state reducer
- `app_lib/engine/test/room_model_test.dart` - 28 tests
- `app_lib/engine/test/door_model_test.dart` - 16 tests
- `app_lib/engine/test/cloud_service_model_test.dart` - 26 tests
- `app_lib/engine/test/game_model_test.dart` - 22 tests
- `app_lib/engine/test/device_model_test.dart` - 23 tests
- `app_lib/engine/test/reducer_test.dart` - 26 tests
- `app_lib/engine/test/domain_events_test.dart` - 58 tests
- `game_bloc/world/test/world_bloc_test.dart` - 47 tests
- `app_bloc/game/test/game_bloc_test.dart` - 57 tests
- `game_widgets/panels/test/info_panel_test.dart` - 5 tests
- `game_widgets/panels/test/room_summary_panel_test.dart` - 18 tests
- `game_widgets/hud/test/credits_display_test.dart` - 5 tests
- `game_widgets/hud/test/interaction_hint_test.dart` - 8 tests
- `game_widgets/shop/test/device_card_test.dart` - 12 tests
- `game_asset/characters/test/game_characters_test.dart` - 23 tests
- `app_lib/database/test/game_storage_test.dart` - 11 tests
- `app_lib/database/test/character_storage_test.dart` - 15 tests
- `app_lib/logging/test/log_level_test.dart` - 8 tests
- `app_lib/logging/test/log_record_test.dart` - 14 tests
- `app_lib/core/test/position_test.dart` - 25 tests
- `app_lib/core/test/helpers_test.dart` - 21 tests
- `app_lib/core/test/ids_test.dart` - 15 tests
- `app_lib/core/test/enums_test.dart` - 42 tests (NEW)
- `app_lib/logging/test/app_logger_test.dart` - 26 tests (NEW)
- `app_lib/logging/test/api_logging_interceptor_test.dart` - 34 tests (NEW)

## In Progress
- All core features complete, continuing improvements

## Next Tasks
1. Consider additional test coverage for edge cases
2. Look for performance optimizations
3. Consider additional features: VFX/feedback, audio, more asset coverage
4. Review and update documentation

## Architecture Decisions
- CharacterModel uses copyWith pattern for immutability
- Sprites defined in game_asset_characters package
- Storage uses SharedPreferences via GameStorage (not Drift DB yet)
- BLoC pattern: GameBloc for app state, WorldBloc for Flame component state
- Character creation as full-screen route (not dialog) for better UX
- Rooms form a tree structure with parentId relationships
- Doors positioned on walls with wallSide + wallPosition
- GameModel contains all rooms - no separate WorldModel needed
- Reducer is a pure function for testable state transformations

## Mistakes & Learnings
1. **Use flutter_test for packages with Flame dependencies** - Pure `test` package doesn't work with Flame due to dart:ui dependencies
2. **Run dart fix after writing tests** - Auto-fixes const usage and removes unused imports
3. **Check existing models before creating new ones** - GameModel already contained room management, no separate WorldModel was needed
4. **Use plain `test` package for pure Dart packages** - Packages without Flutter dependencies (like app_lib/core) should use `test:` not `flutter_test:` to avoid dart:ui issues
5. **Singleton logger tests need unique markers** - When testing singleton loggers that use global streams, filter by unique message markers to isolate test data

## File References
- WorldBloc: `game_bloc/world/lib/src/world_bloc.dart`
- WorldState: `game_bloc/world/lib/src/world_state.dart`
- WorldEvent: `game_bloc/world/lib/src/world_event.dart`
- CharacterModel: `app_lib/engine/lib/src/models/character_model.dart`
- RoomModel: `app_lib/engine/lib/src/models/room_model.dart`
- DoorModel: `app_lib/engine/lib/src/models/door_model.dart`
- CloudServiceModel: `app_lib/engine/lib/src/models/cloud_service_model.dart`
- DeviceModel: `app_lib/engine/lib/src/models/device_model.dart`
- GameModel: `app_lib/engine/lib/src/models/game_model.dart`
- Reducer: `app_lib/engine/lib/src/reducer.dart`
- DomainEvents: `app_lib/engine/lib/src/events/domain_events.dart`
- GameBloc: `app_bloc/game/lib/src/game_bloc.dart`
- GameStorage: `app_lib/database/lib/src/game_storage.dart`
- CharacterCreationScreen: `lib/screens/character_creation_screen.dart`
- StartMenuScreen: `lib/screens/start_menu_screen.dart`
- GameCharacters: `game_asset/characters/lib/src/game_characters.dart`
- CharacterStorage: `app_lib/database/lib/src/character_storage.dart`
- Core Enums: `app_lib/core/lib/src/enums.dart`

## Git Checkpoints
- 85184a0: test: add unit tests for logging and enums (91 tests)
- 2d0d066: test: add unit tests for core utilities (61 tests)
- 97a02b8: test: add unit tests for logging package (22 tests)
- 695ff78: fix: resolve analyzer warnings in HUD widget tests
- d152e3e: test: add unit tests for GameStorage and CharacterStorage (26 tests)
- fc04a03: test: add tests for CharacterSpriteSheet and GameCharacters (23 tests)
- 192c418: test: add widget tests for DeviceCard (12 tests)
- 5466444: test: add widget tests for CreditsDisplay and InteractionHint (13 tests)
- 4b74bd8: test: add widget tests for InfoPanel and RoomSummaryPanel (23 tests)
- 4498a86: fix: remove unused variable in reducer test
- 3aa2859: test: add unit tests for GameBloc (57 tests)
- 151ffc1: test: add unit tests for WorldBloc (47 tests)
- 65b7188: test: add unit tests for domain events Equatable props
- 7b2e93c: test: add unit tests for game state reducer
- a98ab77: style: fix const warnings in add_room_modal
- 36cb849: test: add unit tests for DeviceModel and DeviceTemplate
- fd45aac: test: add unit tests for GameModel
- bb1a548: test: add unit tests for game world models
- df60ed7: test: add unit tests for character name validation and model
- 83af0c6: feat: add multi-step character creation screen with edit flow
- 3ac6509: feat: add character appearance fields and name validation
