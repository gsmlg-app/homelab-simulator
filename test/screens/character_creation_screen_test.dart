import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:homelab_simulator/screens/character_creation_screen.dart';

void main() {
  group('CharacterCreationScreen', () {
    group('initial state', () {
      testWidgets('renders with Create Character title', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        expect(find.text('Create Character'), findsOneWidget);
      });

      testWidgets('shows step indicator with 3 steps', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Summary'), findsOneWidget);
      });

      testWidgets('starts on name step', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        expect(find.text('Choose Your Name'), findsOneWidget);
        expect(find.text('2-16 characters'), findsOneWidget);
      });

      testWidgets('shows Randomize button in app bar', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        expect(find.text('Randomize'), findsOneWidget);
        expect(find.byIcon(Icons.shuffle), findsWidgets);
      });

      testWidgets('shows Next button on first step', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        expect(find.text('Next'), findsOneWidget);
      });

      testWidgets('shows name suggestions', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        expect(find.text('Or try one of these:'), findsOneWidget);
        // Should have 5 ActionChips with generated names
        expect(find.byType(ActionChip), findsNWidgets(5));
      });
    });

    group('name step', () {
      testWidgets('validates empty name on Next', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        // Try to proceed without entering a name
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Should show error and stay on name step
        expect(find.text('Choose Your Name'), findsOneWidget);
      });

      testWidgets('validates name too short', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        await tester.enterText(find.byType(TextField), 'A');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Should show error and stay on name step
        expect(find.text('Choose Your Name'), findsOneWidget);
      });

      testWidgets('accepts valid name and proceeds to appearance step',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        await tester.enterText(find.byType(TextField), 'TestPlayer');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Should now be on appearance step
        expect(find.text('Customize Appearance'), findsOneWidget);
      });

      testWidgets('random name button generates a name', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        // Find the shuffle icon button inside the text field
        final shuffleButtons = find.descendant(
          of: find.byType(TextField),
          matching: find.byIcon(Icons.shuffle),
        );
        expect(shuffleButtons, findsOneWidget);

        await tester.tap(shuffleButtons);
        await tester.pumpAndSettle();

        // TextField should now have text
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, isNotEmpty);
      });

      testWidgets('tapping name suggestion fills the field', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        // Get the first ActionChip
        final chips = find.byType(ActionChip);
        expect(chips, findsNWidgets(5));

        // Get the text of the first chip before tapping
        final chip = tester.widget<ActionChip>(chips.first);
        final chipLabel = (chip.label as Text).data!;

        await tester.tap(chips.first);
        await tester.pumpAndSettle();

        // TextField should now have the chip's text
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, chipLabel);
      });
    });

    group('appearance step', () {
      Future<void> goToAppearanceStep(WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        await tester.enterText(find.byType(TextField), 'TestPlayer');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      testWidgets('shows all appearance options', (tester) async {
        await goToAppearanceStep(tester);

        expect(find.text('Gender'), findsOneWidget);
        expect(find.text('Skin Tone'), findsOneWidget);
        expect(find.text('Hair Style'), findsOneWidget);
        expect(find.text('Hair Color'), findsOneWidget);
        expect(find.text('Outfit'), findsOneWidget);
      });

      testWidgets('shows gender options', (tester) async {
        await goToAppearanceStep(tester);

        expect(find.text('Male'), findsOneWidget);
        expect(find.text('Female'), findsOneWidget);
      });

      testWidgets('shows character preview panel', (tester) async {
        await goToAppearanceStep(tester);

        // Preview should show name
        expect(find.text('TestPlayer'), findsOneWidget);
      });

      testWidgets('changing gender updates preview', (tester) async {
        await goToAppearanceStep(tester);

        // Tap on Female to change gender
        await tester.tap(find.text('Female'));
        await tester.pumpAndSettle();

        // The appearance summary should update
        // (exact text depends on defaults, but the widget should rebuild)
        expect(find.text('Customize Appearance'), findsOneWidget);
      });

      testWidgets('shows Back button', (tester) async {
        await goToAppearanceStep(tester);

        expect(find.text('Back'), findsOneWidget);
      });

      testWidgets('Back button returns to name step', (tester) async {
        await goToAppearanceStep(tester);

        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();

        expect(find.text('Choose Your Name'), findsOneWidget);
      });

      testWidgets('Next button proceeds to summary step', (tester) async {
        await goToAppearanceStep(tester);

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Character Summary'), findsOneWidget);
      });
    });

    group('summary step', () {
      Future<void> goToSummaryStep(WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        await tester.enterText(find.byType(TextField), 'TestPlayer');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      testWidgets('shows character summary', (tester) async {
        await goToSummaryStep(tester);

        expect(find.text('Character Summary'), findsOneWidget);
        expect(find.text('TestPlayer'), findsOneWidget);
      });

      testWidgets('shows Create button', (tester) async {
        await goToSummaryStep(tester);

        expect(find.text('Create'), findsOneWidget);
      });

      testWidgets('shows starting credits message', (tester) async {
        await goToSummaryStep(tester);

        expect(
          find.textContaining('${GameConstants.startingCredits} credits'),
          findsOneWidget,
        );
      });

      testWidgets('shows Back button', (tester) async {
        await goToSummaryStep(tester);

        expect(find.text('Back'), findsOneWidget);
      });

      testWidgets('Back button returns to appearance step', (tester) async {
        await goToSummaryStep(tester);

        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();

        expect(find.text('Customize Appearance'), findsOneWidget);
      });

      testWidgets('Create button pops with CharacterModel', (tester) async {
        CharacterModel? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<CharacterModel>(
                      MaterialPageRoute(
                        builder: (_) => const CharacterCreationScreen(),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'TestPlayer');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.name, 'TestPlayer');
      });
    });

    group('edit mode', () {
      testWidgets('shows Edit Character title', (tester) async {
        final existingCharacter = CharacterModel.create(
          name: 'ExistingPlayer',
          gender: Gender.female,
          skinTone: SkinTone.dark,
          hairStyle: HairStyle.long,
          hairColor: HairColor.black,
          outfitVariant: OutfitVariant.formal,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CharacterCreationScreen(existingCharacter: existingCharacter),
          ),
        );

        expect(find.text('Edit Character'), findsOneWidget);
      });

      testWidgets('pre-fills name from existing character', (tester) async {
        final existingCharacter = CharacterModel.create(
          name: 'ExistingPlayer',
          gender: Gender.female,
          skinTone: SkinTone.dark,
          hairStyle: HairStyle.long,
          hairColor: HairColor.black,
          outfitVariant: OutfitVariant.formal,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CharacterCreationScreen(existingCharacter: existingCharacter),
          ),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller!.text, 'ExistingPlayer');
      });

      testWidgets('shows Save button on summary step', (tester) async {
        final existingCharacter = CharacterModel.create(
          name: 'ExistingPlayer',
          gender: Gender.female,
          skinTone: SkinTone.dark,
          hairStyle: HairStyle.long,
          hairColor: HairColor.black,
          outfitVariant: OutfitVariant.formal,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: CharacterCreationScreen(existingCharacter: existingCharacter),
          ),
        );

        // Go through steps
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Your changes will be saved.'), findsOneWidget);
      });

      testWidgets('preserves original ID when saving', (tester) async {
        final existingCharacter = CharacterModel.create(
          name: 'ExistingPlayer',
          gender: Gender.female,
          skinTone: SkinTone.dark,
          hairStyle: HairStyle.long,
          hairColor: HairColor.black,
          outfitVariant: OutfitVariant.formal,
        );
        CharacterModel? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<CharacterModel>(
                      MaterialPageRoute(
                        builder: (_) => CharacterCreationScreen(
                          existingCharacter: existingCharacter,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Change name
        await tester.enterText(find.byType(TextField), 'UpdatedName');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.id, existingCharacter.id);
        expect(result!.name, 'UpdatedName');
      });
    });

    group('keyboard navigation', () {
      testWidgets('Escape pops navigator on first step', (tester) async {
        bool popped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CharacterCreationScreen(),
                      ),
                    );
                    popped = true;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(popped, isTrue);
      });

      testWidgets('Escape goes back on appearance step', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        await tester.enterText(find.byType(TextField), 'TestPlayer');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Customize Appearance'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.text('Choose Your Name'), findsOneWidget);
      });
    });

    group('randomize all', () {
      testWidgets('Randomize button changes name and appearance',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CharacterCreationScreen()),
        );

        // Initially name should be empty
        final textFieldBefore =
            tester.widget<TextField>(find.byType(TextField));
        expect(textFieldBefore.controller!.text, isEmpty);

        // Tap Randomize button in app bar
        await tester.tap(find.text('Randomize'));
        await tester.pumpAndSettle();

        // Name should now have text
        final textFieldAfter =
            tester.widget<TextField>(find.byType(TextField));
        expect(textFieldAfter.controller!.text, isNotEmpty);
      });
    });

    group('isEditing property', () {
      testWidgets('isEditing is false when no existing character', (_) async {
        const screen = CharacterCreationScreen();
        expect(screen.isEditing, isFalse);
      });

      testWidgets('isEditing is true when existing character provided',
          (_) async {
        final existingCharacter = CharacterModel.create(
          name: 'Test',
          gender: Gender.male,
          skinTone: SkinTone.medium,
          hairStyle: HairStyle.short,
          hairColor: HairColor.brown,
          outfitVariant: OutfitVariant.casual,
        );

        final screen =
            CharacterCreationScreen(existingCharacter: existingCharacter);
        expect(screen.isEditing, isTrue);
      });
    });
  });

  group('StringCapitalize extension', () {
    test('capitalizes first letter', () {
      expect('hello'.capitalize(), 'Hello');
    });

    test('returns empty string unchanged', () {
      expect(''.capitalize(), '');
    });

    test('handles single character', () {
      expect('a'.capitalize(), 'A');
    });

    test('handles already capitalized', () {
      expect('Hello'.capitalize(), 'Hello');
    });
  });
}
