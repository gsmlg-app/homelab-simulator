import 'dart:async';
import 'package:app_database/app_database.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';

import 'game_screen.dart';
import 'character_creation_screen.dart';

/// Start menu screen with character selection and creation
class StartMenuScreen extends StatefulWidget {
  const StartMenuScreen({super.key});

  @override
  State<StartMenuScreen> createState() => _StartMenuScreenState();
}

class _StartMenuScreenState extends State<StartMenuScreen> {
  final CharacterStorage _storage = CharacterStorage();
  List<CharacterModel> _characters = [];
  bool _isLoading = true;

  // Gamepad support
  StreamSubscription<GamepadEvent>? _gamepadSubscription;
  int _selectedIndex = -1; // -1 means "Create New" button is selected
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCharacters();
    _gamepadSubscription = Gamepads.events.listen(_handleGamepadEvent);
  }

  @override
  void dispose() {
    _gamepadSubscription?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleGamepadEvent(GamepadEvent event) {
    // Only handle button presses
    if (event.type == KeyType.button &&
        event.value > GameConstants.gamepadButtonPressThreshold) {
      _handleGamepadKey(event.key);
    }
  }

  void _handleGamepadKey(String key) {
    final lowerKey = key.toLowerCase();

    // Navigation
    if (lowerKey == 'dpad up' || lowerKey == 'up') {
      _navigateUp();
    } else if (lowerKey == 'dpad down' || lowerKey == 'down') {
      _navigateDown();
    }
    // Confirm (A button)
    else if (lowerKey == 'a' ||
        lowerKey == 'button south' ||
        lowerKey == 'cross') {
      _confirmSelection();
    }
    // Delete (X button)
    else if (lowerKey == 'x' ||
        lowerKey == 'button west' ||
        lowerKey == 'square') {
      _deleteSelected();
    }
  }

  void _navigateUp() {
    setState(() {
      if (_characters.isEmpty) {
        _selectedIndex = -1;
      } else if (_selectedIndex == -1) {
        _selectedIndex = _characters.length - 1;
      } else if (_selectedIndex > 0) {
        _selectedIndex--;
      }
    });
  }

  void _navigateDown() {
    setState(() {
      if (_characters.isEmpty) {
        _selectedIndex = -1;
      } else if (_selectedIndex < _characters.length - 1) {
        _selectedIndex++;
      } else {
        _selectedIndex = -1; // Go to Create button
      }
    });
  }

  void _confirmSelection() {
    if (_selectedIndex == -1) {
      _createNewCharacter();
    } else if (_selectedIndex >= 0 && _selectedIndex < _characters.length) {
      _selectCharacter(_characters[_selectedIndex]);
    }
  }

  void _deleteSelected() {
    if (_selectedIndex >= 0 && _selectedIndex < _characters.length) {
      _deleteCharacter(_characters[_selectedIndex]);
    }
  }

  Future<void> _loadCharacters() async {
    final characters = await _storage.loadAll();
    setState(() {
      _characters = characters;
      _isLoading = false;
    });
  }

  void _selectCharacter(CharacterModel character) {
    // Update last played time (fire-and-forget, errors handled in save())
    final updated = character.copyWith(lastPlayedAt: DateTime.now());
    unawaited(_storage.save(updated));

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  Future<void> _createNewCharacter() async {
    final result = await Navigator.of(context).push<CharacterModel>(
      MaterialPageRoute(builder: (_) => const CharacterCreationScreen()),
    );

    if (result == null || !mounted) return;

    await _storage.save(result);

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  Future<void> _deleteCharacter(CharacterModel character) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text(
          'Delete Character',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${character.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red800),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.delete(character.id);
      await _loadCharacters();
    }
  }

  Future<void> _editCharacter(CharacterModel character) async {
    final result = await Navigator.of(context).push<CharacterModel>(
      MaterialPageRoute(
        builder: (_) => CharacterCreationScreen(existingCharacter: character),
      ),
    );

    if (result == null || !mounted) return;

    await _storage.save(result);
    await _loadCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          return _handleKeyEvent(event);
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.darkBackground, AppColors.secondaryBackground],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Title
                const Text(
                  'HOMELAB',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan400,
                    letterSpacing: 8,
                  ),
                ),
                const Text(
                  'SIMULATOR',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: AppColors.cyan200,
                    letterSpacing: 12,
                  ),
                ),
                const SizedBox(height: 60),

                // Character list or loading
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(),
                ),

                // Create new character button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _createNewCharacter,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'CREATE NEW CHARACTER',
                        style: TextStyle(fontSize: 16, letterSpacing: 2),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _selectedIndex == -1
                            ? AppColors.cyan500
                            : AppColors.cyan700,
                        side: _selectedIndex == -1
                            ? const BorderSide(
                                color: AppColors.textPrimary,
                                width: 2,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Gamepad hint
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '🎮 D-Pad: Navigate • A: Select • X: Delete',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _navigateUp();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _navigateDown();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _confirmSelection();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      _deleteSelected();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildContent() {
    if (_characters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 64, color: AppColors.borderLight),
            SizedBox(height: 16),
            Text(
              'No saved characters',
              style: TextStyle(fontSize: 18, color: AppColors.textTertiary),
            ),
            SizedBox(height: 8),
            Text(
              'Create a new character to start playing',
              style: TextStyle(fontSize: 14, color: AppColors.borderLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        final character = _characters[index];
        return _CharacterCard(
          character: character,
          isSelected: _selectedIndex == index,
          onTap: () => _selectCharacter(character),
          onEdit: () => _editCharacter(character),
          onDelete: () => _deleteCharacter(character),
        );
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final CharacterModel character;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CharacterCard({
    required this.character,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatPlayTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? AppColors.selectionBackground
          : AppColors.componentBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.textPrimary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Character sprite avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.cyan900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft,
                      widthFactor: 1 / 8,
                      heightFactor: 1 / 3,
                      child: Image.asset(
                        character.spritePath,
                        width: 56 * 8,
                        height: 56 * 3,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatPlayTime(character.totalPlayTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(character.lastPlayedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green800,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Lv.${character.level}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // Edit button
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.cyanMuted,
                ),
                tooltip: 'Edit character',
              ),

              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.redMuted,
                ),
                tooltip: 'Delete character',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
