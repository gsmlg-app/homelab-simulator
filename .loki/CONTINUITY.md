# Loki Mode Continuity Document

## Project Overview
Homelab Simulator - Flutter/Flame game with Melos monorepo architecture and BLoC state management.

## Current PRD Focus
Two main feature sets from PRD.md:
1. **Character Creation Enhancements** - Multi-step creation flow, appearance customization, validation
2. **Game World & Rooms** - 2D room navigation, door transitions, room/object persistence

## Current State
- **Phase:** IMPLEMENTATION
- **Last Updated:** 2026-01-20
- **Iteration:** 1

## Completed Work
- Initial codebase exploration completed
- CharacterModel exists with basic fields (id, name, gender, createdAt, lastPlayedAt, totalPlayTime, level, credits)
- StartMenuScreen has basic character creation dialog with gender selection
- GameCharacters registry defines MainMale and MainFemale sprite sheets
- CharacterStorage persists to SharedPreferences
- GameBloc/WorldBloc architecture in place
- GameModel/RoomModel/DeviceModel for game state

## In Progress
- PRD Milestone 1: Updating CharacterModel with new appearance fields (skin tone, hair style/color, outfit variant)

## Next Tasks
1. Update CharacterModel with new appearance fields
2. Create AppearanceConfig enum/model for available options
3. Update game_asset/characters with appearance variant definitions
4. Build multi-step character creation UI
5. Add name validation (2-16 chars, trim whitespace, block empty/profane)
6. Implement randomize feature
7. Add edit character flow

## Architecture Decisions
- CharacterModel uses copyWith pattern for immutability
- Sprites defined in game_asset_characters package
- Storage uses SharedPreferences (not Drift DB yet)
- BLoC pattern: GameBloc for app state, WorldBloc for Flame component state

## Mistakes & Learnings
(None yet - first iteration)

## File References
- CharacterModel: `app_lib/engine/lib/src/models/character_model.dart`
- StartMenuScreen: `lib/screens/start_menu_screen.dart`
- GameCharacters: `game_asset/characters/lib/src/game_characters.dart`
- CharacterStorage: `app_lib/database/lib/src/character_storage.dart`
- Core Enums (Gender): `app_lib/core/lib/src/enums.dart`

## Git Checkpoint
- Starting branch: main
- Starting commit: (to be captured on first change)
