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
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: _currentStep > 0 ? 'Previous step' : 'Cancel',
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
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton.icon(
              onPressed: _randomizeAll,
              icon: const Icon(Icons.shuffle, color: AppColors.cyan500),
              label: const Text(
                'Randomize',
                style: TextStyle(color: AppColors.cyan500),
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
                duration: AppSpacing.animationFast,
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
      padding: AppSpacing.paddingStepIndicator,
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
            width: AppSpacing.stepDotSize,
            height: AppSpacing.stepDotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.cyan500
                  : AppColors.componentBackground,
              border: isCurrent
                  ? Border.all(
                      color: AppColors.textPrimary,
                      width: AppSpacing.borderWidth,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSpacing.fontSizeSmall,
              color: isActive ? AppColors.textPrimary : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
      height: AppSpacing.stepLineHeight,
      width: AppSpacing.stepLineWidth,
      color: isActive ? AppColors.cyan500 : AppColors.componentBackground,
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
      padding: AppSpacing.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Name',
            style: TextStyle(
              fontSize: AppSpacing.fontSizeHeading,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            '2-16 characters',
            style: TextStyle(
              fontSize: AppSpacing.fontSizeDefault,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Name input
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            autofocus: true,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSpacing.fontSizeLarge,
            ),
            maxLength: CharacterNameConstants.maxLength,
            decoration: InputDecoration(
              hintText: 'Enter name...',
              hintStyle: const TextStyle(color: AppColors.textHint),
              errorText: _nameError,
              errorStyle: const TextStyle(color: AppColors.redAccent),
              counterStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.componentBackground,
              border: const OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusLarge,
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusLarge,
                borderSide: BorderSide(
                  color: AppColors.cyan500,
                  width: AppSpacing.borderWidth,
                ),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusLarge,
                borderSide: BorderSide(
                  color: AppColors.redAccent,
                  width: AppSpacing.borderWidth,
                ),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.shuffle, color: AppColors.cyan500),
                onPressed: _generateRandomName,
                tooltip: 'Generate random name',
              ),
            ),
            onChanged: (_) => _validateName(),
            onSubmitted: (_) => _nextStep(),
          ),

          const SizedBox(height: AppSpacing.l),

          // Name suggestions
          const Text(
            'Or try one of these:',
            style: TextStyle(
              fontSize: AppSpacing.fontSizeDefault,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.ms),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: List.generate(5, (index) {
              final name = CharacterNameGenerator.generate();
              return ActionChip(
                label: Text(name),
                backgroundColor: AppColors.componentBackground,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
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
      color: AppColors.containerBackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Character sprite (enlarged)
          Container(
            width: AppSpacing.characterPreviewWidth,
            height: AppSpacing.characterPreviewHeight,
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: AppSpacing.borderRadiusXl,
              border: Border.fromBorderSide(BorderSide(color: AppColors.cyan700)),
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusXl,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  widthFactor: 1 / spriteSheet.columns,
                  heightFactor: 1 / spriteSheet.rows,
                  child: Image.asset(
                    spriteSheet.path,
                    width:
                        AppSpacing.characterPreviewWidth * spriteSheet.columns,
                    height:
                        AppSpacing.characterPreviewHeight * spriteSheet.rows,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // Name preview
          Text(
            _nameController.text.isEmpty ? 'Unnamed' : _nameController.text,
            style: const TextStyle(
              fontSize: AppSpacing.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // Appearance summary
          Text(
            '${_skinTone.name.capitalize()} skin • ${_hairStyle.name.capitalize()} ${_hairColor.name} hair',
            style: const TextStyle(
              fontSize: AppSpacing.fontSizeSmall,
              color: AppColors.textHint,
            ),
          ),
          Text(
            '${_outfitVariant.name.capitalize()} outfit',
            style: const TextStyle(
              fontSize: AppSpacing.fontSizeSmall,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPanel() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customize Appearance',
            style: TextStyle(
              fontSize: AppSpacing.fontSizeHeading,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.l),

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
      padding: const EdgeInsets.only(bottom: AppSpacing.ml),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppSpacing.fontSizeDefault,
              fontWeight: FontWeight.w500,
              color: isFocused ? AppColors.cyan500 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: values.map((v) {
              final isSelected = v == selected;
              return ChoiceChip(
                label: colorMapper != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: AppSpacing.iconSizeSmall,
                            height: AppSpacing.iconSizeSmall,
                            decoration: BoxDecoration(
                              color: colorMapper(v),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderLight),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(labelMapper(v)),
                        ],
                      )
                    : Text(labelMapper(v)),
                selected: isSelected,
                onSelected: (_) => onSelect(v),
                backgroundColor: AppColors.componentBackground,
                selectedColor: AppColors.cyan700,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                side: isSelected
                    ? const BorderSide(
                        color: AppColors.cyan500,
                        width: AppSpacing.borderWidth,
                      )
                    : BorderSide.none,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _hairColorToColor(HairColor color) {
    return switch (color) {
      HairColor.black => AppColors.hairBlack,
      HairColor.brown => AppColors.hairBrown,
      HairColor.blonde => AppColors.hairBlonde,
      HairColor.red => AppColors.hairRed,
      HairColor.gray => AppColors.hairGray,
      HairColor.blue => AppColors.hairBlue,
      HairColor.green => AppColors.hairGreen,
      HairColor.purple => AppColors.hairPurple,
    };
  }

  Widget _buildSummaryStep() {
    final spriteSheet = _gender == Gender.male
        ? GameCharacters.mainMale
        : GameCharacters.mainFemale;

    return SingleChildScrollView(
      padding: AppSpacing.paddingL,
      child: Column(
        children: [
          const Text(
            'Character Summary',
            style: TextStyle(
              fontSize: AppSpacing.fontSizeHeading,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Character preview card
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingL,
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: AppSpacing.borderRadiusXl,
              border: Border.fromBorderSide(BorderSide(color: AppColors.cyan700)),
            ),
            child: Row(
              children: [
                // Sprite
                Container(
                  width: AppSpacing.characterSummaryWidth,
                  height: AppSpacing.characterSummaryHeight,
                  decoration: const BoxDecoration(
                    color: AppColors.componentBackground,
                    borderRadius: AppSpacing.borderRadiusLarge,
                  ),
                  child: ClipRRect(
                    borderRadius: AppSpacing.borderRadiusLarge,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topLeft,
                        widthFactor: 1 / spriteSheet.columns,
                        heightFactor: 1 / spriteSheet.rows,
                        child: Image.asset(
                          spriteSheet.path,
                          width:
                              AppSpacing.characterSummaryWidth *
                              spriteSheet.columns,
                          height:
                              AppSpacing.characterSummaryHeight *
                              spriteSheet.rows,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.l),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text,
                        style: const TextStyle(
                          fontSize: AppSpacing.fontSizeTitle,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
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

          const SizedBox(height: AppSpacing.l),

          Text(
            widget.isEditing
                ? 'Your changes will be saved.'
                : 'Your character will start with ${GameConstants.startingCredits} credits.',
            style: const TextStyle(
              fontSize: AppSpacing.fontSizeDefault,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.summaryLabelWidth,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppSpacing.fontSizeDefault,
                color: AppColors.textHint,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppSpacing.fontSizeDefault,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: AppSpacing.paddingL,
      decoration: const BoxDecoration(
        color: AppColors.containerBackground,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
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
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderLight),
                padding: AppSpacing.paddingButton,
              ),
            )
          else
            const SizedBox(width: AppSpacing.placeholderWidth),

          // Gamepad hint
          Text(
            _currentStep == 2
                ? '🎮 A: Create • B: Back'
                : '🎮 A: Next • B: Back',
            style: const TextStyle(
              fontSize: AppSpacing.fontSizeSmall,
              color: AppColors.textHint,
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
              backgroundColor: AppColors.cyan600,
              padding: AppSpacing.paddingButtonLarge,
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
