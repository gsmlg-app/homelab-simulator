# Homelab Simulator

A homelab simulation game built with Flutter and Flame in a Melos workspace.

## Development

The workspace requires Dart 3.13 or newer and Flutter 3.47 or newer. Apple builds
are validated with Flutter 3.47.7, Dart 3.13.5, and Xcode 27.0.

```sh
flutter pub get --enforce-lockfile
dart run melos run build:runner
flutter run
```

Run code generation after changing database models or creating a fresh checkout.
Minimum deployment targets are Android 12 (API 31), iOS 18.0, and macOS 15.0.
Web is not a supported target.

## Android

Build with JDK 21 and Android SDK platform 36. The app requires Android 12
(API 31) or newer and compiles and targets API 36. The project uses built-in
Kotlin with AGP 9.3.1, Gradle 9.7.0, and Kotlin 2.4.21; built-in Kotlin requires
Flutter 3.47 or newer.

```sh
flutter build apk --debug --no-pub
```

## Apple platforms

The app requires iOS 18.0 or macOS 15.0 or newer. Both Xcode projects use Flutter
Swift Package Manager integration, enabled locally in `pubspec.yaml`. CocoaPods
is not required. Flutter generates the plugin Swift packages under each platform's
`Flutter/ephemeral/` directory; do not commit those generated packages.

```sh
flutter build macos --debug --no-pub
flutter build ios --simulator --debug --no-pub
```

Use an installed current iOS simulator runtime for simulator builds. For Xcode
development, open `ios/Runner.xcworkspace` or `macos/Runner.xcworkspace` after
running dependency setup and code generation. Device builds additionally require
a valid signing identity and provisioning profile.
