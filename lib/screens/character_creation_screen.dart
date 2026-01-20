import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:game_asset_characters/game_asset_characters.dart';

/// Multi-step character creation screen
class CharacterCreationScreen extends StatefulWidget {
  final CharacterModel? existingCharacter;

  const CharacterCreationScreen({super.key, this.existingCharacter});

  bool get isEditing => existingCharacter != null;

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  // Current step: 0 = name, 1 = appearance, 2 = summary
  int _currentStep = 0;

  // Form data
  final TextEditingController _nameController = TextEditingController();
  String? _nameError;
  Gender _gender = Gender.male;
  SkinTone _skinTone = SkinTone.medium;
  HairStyle _hairStyle = HairStyle.short;
  HairColor _hairColor = HairColor.brown;
  OutfitVariant _outfitVariant = OutfitVariant.casual;

  // Focus management
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _screenFocusNode = FocusNode();

  // Gamepad state for option navigation
  int _focusedOptionIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingCharacter != null) {
      final c = widget.existingCharacter!;
      _nameController.text = c.name;
      _gender = c.gender;
      _skinTone = c.skinTone;
      _hairStyle = c.hairStyle;
      _hairColor = c.hairColor;
      _outfitVariant = c.outfitVariant;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _validateName() {
    final result = validateCharacterName(_nameController.text);
    setState(() {
      _nameError = result.isValid ? null : result.errorMessage;
    });
  }

  void _generateRandomName() {
    setState(() {
      _nameController.text = CharacterNameGenerator.generate();
      _nameError = null;
    });
  }

  void _randomizeAppearance() {
    final random = Random();
    setState(() {
      _gender = Gender.values[random.nextInt(Gender.values.length)];
      _skinTone = SkinTone.values[random.nextInt(SkinTone.values.length)];
      _hairStyle = HairStyle.values[random.nextInt(HairStyle.values.length)];
      _hairColor = HairColor.values[random.nextInt(HairColor.values.length)];
      _outfitVariant =
          OutfitVariant.values[random.nextInt(OutfitVariant.values.length)];
    });
  }

  void _randomizeAll() {
    _generateRandomName();
    _randomizeAppearance();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      _validateName();
      if (_nameError != null) return;
    }
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _focusedOptionIndex = 0;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _focusedOptionIndex = 0;
      });
    }
  }

  void _finish() {
    _validateName();
    if (_nameError != null) {
      setState(() => _currentStep = 0);
      return;
    }

    final result = CharacterModel.create(
      name: _nameController.text.trim(),
      gender: _gender,
      skinTone: _skinTone,
      hairStyle: _hairStyle,
      hairColor: _hairColor,
      outfitVariant: _outfitVariant,
    );

    // If editing, preserve original id and timestamps
    final finalResult = widget.existingCharacter != null
        ? result.copyWith(
            id: widget.existingCharacter!.id,
            createdAt: widget.existingCharacter!.createdAt,
            lastPlayedAt: DateTime.now(),
            totalPlayTime: widget.existingCharacter!.totalPlayTime,
            level: widget.existingCharacter!.level,
            credits: widget.existingCharacter!.credits,
          )
        : result;

    Navigator.of(context).pop(finalResult);
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_currentStep > 0) {
        _previousStep();
      } else {
        Navigator.of(context).pop();
      }
      return KeyEventResult.handled;
    }

    // Only handle navigation keys when not in text field
    if (_currentStep != 0 || !_nameFocusNode.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _navigateOption(1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _navigateOption(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (_currentStep == 2) {
          _finish();
        } else {
          _nextStep();
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _navigateOption(int delta) {
    final maxIndex = _getMaxOptionIndex();
    setState(() {
      _focusedOptionIndex = (_focusedOptionIndex + delta).clamp(0, maxIndex);
    });
  }

  int _getMaxOptionIndex() {
    if (_currentStep == 1) {
      // Gender(2) + SkinTone(4) + HairStyle(6) + HairColor(8) + Outfit(4) = 5 rows
      return 4; // 5 rows, 0-indexed
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.isEditing ? 'Edit Character' : 'Create Character',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton.icon(
              onPressed: _randomizeAll,
              icon: const Icon(Icons.shuffle, color: Colors.cyan),
              label: const Text(
                'Randomize',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Step indicator
            _buildStepIndicator(),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildStepContent(),
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(0, 'Name'),
          _buildStepLine(0),
          _buildStepDot(1, 'Appearance'),
          _buildStepLine(1),
          _buildStepDot(2, 'Summary'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.cyan : const Color(0xFF252540),
              border: isCurrent
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.white : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
      height: 2,
      width: 40,
      color: isActive ? Colors.cyan : const Color(0xFF252540),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildAppearanceStep();
      case 2:
        return _buildSummaryStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Name',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '2-16 characters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Name input
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            maxLength: CharacterNameConstants.maxLength,
            decoration: InputDecoration(
              hintText: 'Enter name...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              errorText: _nameError,
              errorStyle: const TextStyle(color: Colors.redAccent),
              counterStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: const Color(0xFF252540),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.cyan, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.shuffle, color: Colors.cyan),
                onPressed: _generateRandomName,
                tooltip: 'Generate random name',
              ),
            ),
            onChanged: (_) => _validateName(),
            onSubmitted: (_) => _nextStep(),
          ),

          const SizedBox(height: 24),

          // Name suggestions
          const Text(
            'Or try one of these:',
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(5, (index) {
              final name = CharacterNameGenerator.generate();
              return ActionChip(
                label: Text(name),
                backgroundColor: const Color(0xFF252540),
                labelStyle: const TextStyle(color: Colors.white70),
                side: BorderSide.none,
                onPressed: () {
                  setState(() {
                    _nameController.text = name;
                    _nameError = null;
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceStep() {
    return Row(
      children: [
        // Preview panel
        Expanded(flex: 2, child: _buildPreviewPanel()),

        // Options panel
        Expanded(flex: 3, child: _buildOptionsPanel()),
      ],
    );
  }

  Widget _buildPreviewPanel() {
    final spriteSheet = _gender == Gender.male
        ? GameCharacters.mainMale
        : GameCharacters.mainFemale;

    return Container(
      color: const Color(0xFF151528),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character sprite (enlarged)
          Container(
            width: 192,
            height: 256,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  widthFactor: 1 / spriteSheet.columns,
                  heightFactor: 1 / spriteSheet.rows,
                  child: Image.asset(
                    spriteSheet.path,
                    width: 192.0 * spriteSheet.columns,
                    height: 256.0 * spriteSheet.rows,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name preview
          Text(
            _nameController.text.isEmpty ? 'Unnamed' : _nameController.text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Appearance summary
          Text(
            '${_skinTone.name.capitalize()} skin • ${_hairStyle.name.capitalize()} ${_hairColor.name} hair',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          Text(
            '${_outfitVariant.name.capitalize()} outfit',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customize Appearance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Gender
          _buildOptionSection(
            'Gender',
            0,
            Gender.values,
            _gender,
            (v) => setState(() => _gender = v),
            (g) => g == Gender.male ? 'Male' : 'Female',
          ),

          // Skin Tone
          _buildOptionSection(
            'Skin Tone',
            1,
            SkinTone.values,
            _skinTone,
            (v) => setState(() => _skinTone = v),
            (s) => s.name.capitalize(),
          ),

          // Hair Style
          _buildOptionSection(
            'Hair Style',
            2,
            HairStyle.values,
            _hairStyle,
            (v) => setState(() => _hairStyle = v),
            (h) => h.name.capitalize(),
          ),

          // Hair Color
          _buildOptionSection(
            'Hair Color',
            3,
            HairColor.values,
            _hairColor,
            (v) => setState(() => _hairColor = v),
            (h) => h.name.capitalize(),
            colorMapper: _hairColorToColor,
          ),

          // Outfit
          _buildOptionSection(
            'Outfit',
            4,
            OutfitVariant.values,
            _outfitVariant,
            (v) => setState(() => _outfitVariant = v),
            (o) => o.name.capitalize(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSection<T>(
    String label,
    int rowIndex,
    List<T> values,
    T selected,
    void Function(T) onSelect,
    String Function(T) labelMapper, {
    Color Function(T)? colorMapper,
  }) {
    final isFocused = _currentStep == 1 && _focusedOptionIndex == rowIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isFocused ? Colors.cyan : Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((v) {
              final isSelected = v == selected;
              return ChoiceChip(
                label: colorMapper != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colorMapper(v),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(labelMapper(v)),
                        ],
                      )
                    : Text(labelMapper(v)),
                selected: isSelected,
                onSelected: (_) => onSelect(v),
                backgroundColor: const Color(0xFF252540),
                selectedColor: Colors.cyan.shade700,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                side: isSelected
                    ? const BorderSide(color: Colors.cyan, width: 2)
                    : BorderSide.none,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _hairColorToColor(HairColor color) {
    switch (color) {
      case HairColor.black:
        return const Color(0xFF1A1A1A);
      case HairColor.brown:
        return const Color(0xFF8B4513);
      case HairColor.blonde:
        return const Color(0xFFFFD700);
      case HairColor.red:
        return const Color(0xFFB22222);
      case HairColor.gray:
        return const Color(0xFF808080);
      case HairColor.blue:
        return const Color(0xFF4169E1);
      case HairColor.green:
        return const Color(0xFF228B22);
      case HairColor.purple:
        return const Color(0xFF9932CC);
    }
  }

  Widget _buildSummaryStep() {
    final spriteSheet = _gender == Gender.male
        ? GameCharacters.mainMale
        : GameCharacters.mainFemale;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Character Summary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Character preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                // Sprite
                Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252540),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topLeft,
                        widthFactor: 1 / spriteSheet.columns,
                        heightFactor: 1 / spriteSheet.rows,
                        child: Image.asset(
                          spriteSheet.path,
                          width: 120.0 * spriteSheet.columns,
                          height: 160.0 * spriteSheet.rows,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        'Gender',
                        _gender == Gender.male ? 'Male' : 'Female',
                      ),
                      _buildSummaryRow(
                        'Skin Tone',
                        _skinTone.name.capitalize(),
                      ),
                      _buildSummaryRow(
                        'Hair Style',
                        _hairStyle.name.capitalize(),
                      ),
                      _buildSummaryRow(
                        'Hair Color',
                        _hairColor.name.capitalize(),
                      ),
                      _buildSummaryRow(
                        'Outfit',
                        _outfitVariant.name.capitalize(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            widget.isEditing
                ? 'Your changes will be saved.'
                : 'Your character will start with ${GameConstants.startingCredits} credits.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151528),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            )
          else
            const SizedBox(width: 100),

          // Gamepad hint
          Text(
            _currentStep == 2
                ? '🎮 A: Create • B: Back'
                : '🎮 A: Next • B: Back',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),

          // Next/Create button
          FilledButton.icon(
            onPressed: _currentStep == 2 ? _finish : _nextStep,
            icon: Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward),
            label: Text(
              _currentStep == 2
                  ? (widget.isEditing ? 'Save' : 'Create')
                  : 'Next',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.cyan.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// String extension for capitalize
extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
