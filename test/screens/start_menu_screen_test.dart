import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:homelab_simulator/screens/start_menu_screen.dart';

void main() {
  group('StartMenuScreen', () {
    setUp(() {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('initial state', () {
      testWidgets('renders title', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('HOMELAB'), findsOneWidget);
        expect(find.text('SIMULATOR'), findsOneWidget);
      });

      testWidgets('shows Create New Character button', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('CREATE NEW CHARACTER'), findsOneWidget);
      });

      testWidgets('shows gamepad hint', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('D-Pad: Navigate'),
          findsOneWidget,
        );
      });

      testWidgets('shows empty state when no characters', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('No saved characters'), findsOneWidget);
        expect(
          find.text('Create a new character to start playing'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.person_add), findsOneWidget);
      });

      testWidgets('shows loading indicator initially', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );

        // Before pumpAndSettle, should show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        // After loading completes, indicator should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('with saved characters', () {
      Future<void> setupWithCharacters(List<CharacterModel> characters) async {
        final json = jsonEncode(characters.map((c) => c.toJson()).toList());
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });
      }

      testWidgets('displays character cards', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );
        await setupWithCharacters([character]);

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('TestPlayer'), findsOneWidget);
        expect(find.text('Lv.1'), findsOneWidget);
      });

      testWidgets('shows edit button on character card', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );
        await setupWithCharacters([character]);

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        expect(find.byTooltip('Edit character'), findsOneWidget);
      });

      testWidgets('shows delete button on character card', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );
        await setupWithCharacters([character]);

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        expect(find.byTooltip('Delete character'), findsOneWidget);
      });

      testWidgets('displays multiple characters', (tester) async {
        final character1 = CharacterModel.create(
          name: 'Player1',
          gender: Gender.male,
          skinTone: SkinTone.light,
          hairStyle: HairStyle.short,
          hairColor: HairColor.black,
          outfitVariant: OutfitVariant.casual,
        );
        final character2 = CharacterModel.create(
          name: 'Player2',
          gender: Gender.female,
          skinTone: SkinTone.dark,
          hairStyle: HairStyle.long,
          hairColor: HairColor.blonde,
          outfitVariant: OutfitVariant.formal,
        );
        await setupWithCharacters([character1, character2]);

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Player1'), findsOneWidget);
        expect(find.text('Player2'), findsOneWidget);
      });

      testWidgets('tapping delete button shows confirmation dialog',
          (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );
        await setupWithCharacters([character]);

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Delete Character'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete "TestPlayer"?'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('cancel button dismisses delete dialog', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );
        await setupWithCharacters([character]);

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.text('Delete Character'), findsNothing);
        // Character should still exist
        expect(find.text('TestPlayer'), findsOneWidget);
      });

      testWidgets('confirming delete removes character', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );
        await setupWithCharacters([character]);

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Character should be removed
        expect(find.text('TestPlayer'), findsNothing);
        // Should show empty state
        expect(find.text('No saved characters'), findsOneWidget);
      });
    });

    group('keyboard navigation', () {
      testWidgets('arrow down navigates to first character', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        // Press arrow down to select first character
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        // The card should be selected (visual indicator)
        // Card with selected state has a white border
        final card = tester.widget<Card>(find.byType(Card));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side.color, Colors.white);
      });

      testWidgets('arrow up from first character stays at first character',
          (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        // First go to character
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        // Then try to go up (stays at first character, index clamped to 0)
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        // Card should still be selected (navigation clamped, doesn't wrap)
        final card = tester.widget<Card>(find.byType(Card));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side.color, Colors.white);
      });

      testWidgets('delete key triggers delete on selected character',
          (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        // Select the character
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        // Press delete
        await tester.sendKeyEvent(LogicalKeyboardKey.delete);
        await tester.pumpAndSettle();

        // Delete dialog should appear
        expect(find.text('Delete Character'), findsOneWidget);
      });
    });

    group('_CharacterCard formatting', () {
      testWidgets('formats play time in seconds', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        ).copyWith(totalPlayTime: 30);
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('30s'), findsOneWidget);
      });

      testWidgets('formats play time in minutes', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        ).copyWith(totalPlayTime: 300); // 5 minutes
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('5m'), findsOneWidget);
      });

      testWidgets('formats play time in hours', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        ).copyWith(totalPlayTime: 7500); // 2h 5m
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('2h 5m'), findsOneWidget);
      });

      testWidgets('formats date as Today', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        ).copyWith(lastPlayedAt: DateTime.now());
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Today'), findsOneWidget);
      });

      testWidgets('formats date as Yesterday', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        ).copyWith(
          lastPlayedAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Yesterday'), findsOneWidget);
      });

      testWidgets('formats date as X days ago', (tester) async {
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        ).copyWith(
          lastPlayedAt: DateTime.now().subtract(const Duration(days: 3)),
        );
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('3 days ago'), findsOneWidget);
      });

      testWidgets('formats old date as MM/DD/YYYY', (tester) async {
        final oldDate = DateTime(2024, 6, 15);
        final character = CharacterModel.create(
          name: 'TestPlayer',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        ).copyWith(lastPlayedAt: oldDate);
        final json = jsonEncode([character.toJson()]);
        SharedPreferences.setMockInitialValues({
          'homelab_characters': json,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('6/15/2024'), findsOneWidget);
      });
    });

    group('gradient background', () {
      testWidgets('has gradient container decoration', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StartMenuScreen()),
        );
        await tester.pumpAndSettle();

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(Scaffold),
                matching: find.byType(Container),
              )
              .first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull);
        expect(decoration.gradient, isA<LinearGradient>());
      });
    });
  });
}
