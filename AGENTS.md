# Repository Guidelines

## Project Structure & Module Organization
- `lib/` holds the Flutter app entry points (`main.dart`, `app.dart`) and UI screens under `lib/screens/`.
- Domain packages live in subfolders like `app_lib/`, `app_bloc/`, `game_bloc/`, `game_objects/`, and `game_widgets/`, each with its own Dart package.
- Assets are split by type: `assets/` (Flutter assets), `game_asset/characters/` (character sprites), and `game_audio/` (SFX).
- Tests are in `test/` for the root app; package-level tests live in each package’s own `test/` folder.

## Architecture Overview
- The root Flutter app wires feature blocs (`app_bloc/`, `game_bloc/`) with game/domain models (`game_objects/`) and UI widgets (`game_widgets/`).
- Shared utilities live in `app_lib/` packages; notable modules include `app_lib/logging` for structured logging and `app_lib/secure_storage` for secrets storage.
- Locale support lives in `app_lib/locale` and is scoped to this repo.

## Build, Test, and Development Commands
- `flutter pub get` installs root dependencies.
- `flutter run` launches the app on the active device.
- `flutter test` runs root tests in `test/`.
- `melos run analyze` runs `dart analyze` across all workspace packages.
- `melos run format` formats Dart files across all packages.
- `melos run test` runs `flutter test` in every package with tests.
- `melos run build:runner` runs code generation where `build_runner` is used.
 - Web is not a supported target; do not use `flutter run -d chrome` or `flutter build web`.

## Coding Style & Naming Conventions
- Dart style follows `flutter_lints`; keep formatting consistent with `dart format`.
- Indentation is 2 spaces; use trailing commas to preserve formatter behavior.
- File names use `snake_case.dart`; classes use `UpperCamelCase`; methods and fields use `lowerCamelCase`.

## Testing Guidelines
- Use `flutter_test` for widget and unit tests.
- Test files follow the `*_test.dart` naming pattern.
- Prefer focused unit tests per package; add widget tests in the root app when UI flows are involved.

## Commit & Pull Request Guidelines
- Commit messages use a Conventional Commits style (`feat:`, `chore:`, `fix:`) with a short, present-tense summary.
- PRs should include a clear description, linked issue (if applicable), and screenshots or GIFs for UI changes.
- Keep PRs focused on one feature or fix to make review easier.

## Security & Configuration Tips
- `app_lib/secure_storage` relies on platform keychain/keystore support; ensure keychain entitlements are present on iOS/macOS and consider disabling Android auto-backup to avoid key invalidation.
- Use `app_lib/logging` for structured logs in app code instead of `print` so production logging stays consistent.

## Configuration & Workspace Tips
- This is a Melos workspace; run `melos bootstrap` if you add or update packages.
- Update `pubspec.yaml` workspace entries when adding new local packages.
