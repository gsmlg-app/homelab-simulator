# Loki Mode Continuity Document

## Project Overview
Homelab Simulator - Flutter/Flame game with Melos monorepo architecture and BLoC state management.

## Current PRD Focus
Two main feature sets from PRD.md:
1. **Character Creation Enhancements** - ✅ COMPLETED
2. **Game World & Rooms** - IN PROGRESS

## Current State
- **Phase:** IMPLEMENTATION
- **Last Updated:** 2026-01-20
- **Iteration:** 4
- **Last Commit:** df60ed7

## Completed Work

### Character Creation PRD (100% Complete)
- ✅ M1: Updated CharacterModel with appearance fields (skinTone, hairStyle, hairColor, outfitVariant)
- ✅ M2: Multi-step character creation screen (Name → Appearance → Summary)
- ✅ M3: Edit flow from character list with Edit button
- ✅ M4: Name validation (2-16 chars, blocked words) + randomize feature
- ✅ M5: Unit tests for CharacterModel and name validation

### Files Modified/Created
- `app_lib/core/lib/src/enums.dart` - Added SkinTone, HairStyle, HairColor, OutfitVariant enums
- `app_lib/core/lib/src/character_name.dart` - Name validation and generator
- `app_lib/engine/lib/src/models/character_model.dart` - New appearance fields
- `lib/screens/character_creation_screen.dart` - New multi-step creation UI
- `lib/screens/start_menu_screen.dart` - Edit button, cleaned up old dialog
- `app_lib/core/test/character_name_test.dart` - Validation tests
- `app_lib/engine/test/character_model_test.dart` - Model serialization tests

## In Progress
- Game World M1: Data model + persistence for rooms/objects

## Next Tasks
1. Review existing RoomModel, update for PRD requirements (doors, child rooms)
2. Create WorldModel for room tree structure
3. Add DoorModel for room transitions
4. Add CloudServiceModel for provider objects (AWS, GCP, etc.)
5. Update persistence layer for world/room data
6. Build room view UI

## Architecture Decisions
- CharacterModel uses copyWith pattern for immutability
- Sprites defined in game_asset_characters package
- Storage uses SharedPreferences (not Drift DB yet)
- BLoC pattern: GameBloc for app state, WorldBloc for Flame component state
- Character creation as full-screen route (not dialog) for better UX

## Mistakes & Learnings
1. **Use flutter_test for packages with Flame dependencies** - Pure `test` package doesn't work with Flame due to dart:ui dependencies

## File References
- CharacterModel: `app_lib/engine/lib/src/models/character_model.dart`
- CharacterCreationScreen: `lib/screens/character_creation_screen.dart`
- StartMenuScreen: `lib/screens/start_menu_screen.dart`
- GameCharacters: `game_asset/characters/lib/src/game_characters.dart`
- CharacterStorage: `app_lib/database/lib/src/character_storage.dart`
- Core Enums: `app_lib/core/lib/src/enums.dart`
- Name Validation: `app_lib/core/lib/src/character_name.dart`

## Git Checkpoints
- df60ed7: test: add unit tests for character name validation and model
- 83af0c6: feat: add multi-step character creation screen with edit flow
- 3ac6509: feat: add character appearance fields and name validation
