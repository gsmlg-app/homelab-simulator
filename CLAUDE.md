# Claude Code Guidelines for Homelab Simulator

## Project Overview
A Homelab Simulator game built with Flutter and Flame engine, using a Melos 7.0+ monorepo architecture with BLoC state management.

## Project Structure

```
homelab_simulator/
├── lib/                    # Flutter app entry points and UI screens
│   ├── main.dart
│   ├── app.dart
│   └── screens/            # UI screens (StartMenuScreen, etc.)
├── app_lib/                # Shared application libraries
│   ├── core/               # Core utilities, constants, enums (Gender, etc.)
│   ├── database/           # Database and storage services
│   ├── engine/             # Game engine models (CharacterModel, etc.)
│   ├── locale/             # Localization support
│   ├── logging/            # Structured logging
│   └── secure_storage/     # Secrets/keychain storage
├── app_bloc/
│   └── game/               # Application-level BLoC state
├── game_bloc/
│   └── world/              # Game world BLoC state
├── game_objects/           # Flame game components
│   ├── world/              # World components (GamepadHandler, etc.)
│   ├── room/               # Room components
│   ├── character/          # Character components
│   └── devices/            # Device components
├── game_widgets/           # Game UI overlays
│   ├── hud/                # HUD widgets
│   ├── shop/               # Shop widgets
│   └── panels/             # Panel widgets
├── game_asset/
│   └── characters/         # Character sprite assets (GameCharacters registry)
├── game_audio/
│   └── sfx/                # Sound effects
├── app_widget/
│   └── common/             # Common reusable widgets
└── test/                   # Root app tests
```

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (macOS, iOS, Android - NOT web)
flutter run

# Run tests
flutter test

# Melos commands (run from root)
melos run analyze      # Run dart analyze across all packages
melos run format       # Format all Dart files
melos run test         # Run tests in all packages with test/ folders
melos run build:runner # Run build_runner for code generation
melos bootstrap        # Bootstrap workspace after adding packages
```

**Important**: Web is not a supported target. Do not use `flutter run -d chrome` or `flutter build web`.

## Architecture Patterns

- **State Management**: Flutter BLoC (`flutter_bloc`) for UI, Flame BLoC (`flame_bloc`) for game components
- **Game Engine**: Flame with `FlameGame`, `PositionComponent`, and component-based architecture
- **Input Handling**:
  - Keyboard: Use `Focus` widget with `onKeyEvent` (not `KeyboardListener` to avoid duplicate events)
  - Gamepad: Use `gamepads` package with `GamepadEvent.type` (KeyType.button/analog)
- **Storage**: `app_lib/engine` for models, `app_lib/database` for persistence
- **Logging**: Use `app_lib/logging` for structured logs (not `print`)

## Coding Style

- Follow `flutter_lints` rules
- 2-space indentation with trailing commas
- File names: `snake_case.dart`
- Classes: `UpperCamelCase`
- Methods/fields: `lowerCamelCase`
- Test files: `*_test.dart`

## Key Packages

| Package | Purpose |
|---------|---------|
| `app_lib_core` | Core utilities, constants, enums |
| `app_lib_engine` | Game models (CharacterModel) |
| `app_database` | Storage services |
| `game_objects_world` | World components (GamepadHandler) |
| `game_asset_characters` | Sprite asset registry (GameCharacters) |

## Commit Guidelines

- Use Conventional Commits: `feat:`, `fix:`, `chore:`
- Short, present-tense summary
- No "Generated with Claude Code" or "Co-Authored-By: Claude" trailers
