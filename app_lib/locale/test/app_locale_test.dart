import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocale', () {
    test('supportedLocales is not empty', () {
      expect(AppLocale.supportedLocales.isNotEmpty, true);
    });

    test('supportedLocales contains English', () {
      expect(
        AppLocale.supportedLocales.any((locale) => locale.languageCode == 'en'),
        isTrue,
      );
    });

    test('localizationsDelegates is not empty', () {
      expect(AppLocale.localizationsDelegates.isNotEmpty, true);
    });

    test('localizationsDelegates contains at least 4 delegates', () {
      // AppLocalizations, Material, Cupertino, Widgets
      expect(AppLocale.localizationsDelegates.length, greaterThanOrEqualTo(4));
    });
  });

  group('AppLocalizations integration', () {
    testWidgets('loads English localizations', (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      // Wait for localizations to load
      await tester.pumpAndSettle();

      final l10n = capturedContext.l10n;
      expect(l10n.appName, isNotEmpty);
      expect(l10n.ok, 'OK');
      expect(l10n.cancel, 'Cancel');
    });

    testWidgets('l10n extension provides access to localizations', (
      WidgetTester tester,
    ) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test that l10n extension works
      expect(capturedContext.l10n, isNotNull);
      expect(capturedContext.l10n.loading, 'Loading');
      expect(capturedContext.l10n.success, 'Success');
      expect(capturedContext.l10n.error, 'Error');
    });

    testWidgets('common UI strings are available', (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = capturedContext.l10n;

      // Navigation strings
      expect(l10n.navHome, 'Home');
      expect(l10n.navShowcase, 'Showcase');
      expect(l10n.navSetting, 'Setting');

      // Common actions
      expect(l10n.undo, 'Undo');
      expect(l10n.retry, 'Retry');

      // Theme strings
      expect(l10n.lightTheme, 'Light');
      expect(l10n.darkTheme, 'Dark');
      expect(l10n.systemTheme, 'System');
    });

    testWidgets('controller settings strings are available', (
      WidgetTester tester,
    ) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = capturedContext.l10n;

      // Controller settings
      expect(l10n.controllerSettings, 'Controller');
      expect(l10n.controllerSettingsTitle, 'Controller Settings');
      expect(l10n.controllerEnabled, 'Enable Controller Input');
      expect(l10n.connectedControllers, 'Connected Controllers');
      expect(l10n.noControllersConnected, 'No controllers connected');
      expect(l10n.buttonMapping, 'Button Mapping');
      expect(l10n.confirmButton, 'Confirm Button');
      expect(l10n.backButton, 'Back Button');
      expect(l10n.menuButton, 'Menu Button');
      expect(l10n.analogDeadzone, 'Analog Stick Deadzone');
    });

    testWidgets('settings strings are available', (WidgetTester tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocale.localizationsDelegates,
          supportedLocales: AppLocale.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = capturedContext.l10n;

      // Settings strings
      expect(l10n.settingsTitle, 'Setting');
      expect(l10n.smenuTheme, 'Theme');
      expect(l10n.appearance, 'Appearance');
      expect(l10n.accentColor, 'Accent Color');
      expect(l10n.language, 'Language');
    });
  });
}
