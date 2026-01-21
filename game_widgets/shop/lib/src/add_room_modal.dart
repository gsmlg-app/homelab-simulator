import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:app_lib_engine/app_lib_engine.dart';

/// Provider preset configuration
class ProviderPreset {
  final String name;
  final RoomType type;
  final IconData icon;
  final Color color;
  final List<String> regions;

  const ProviderPreset({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.regions = const [],
  });
}

/// Available provider presets
const _providerPresets = [
  ProviderPreset(
    name: 'AWS',
    type: RoomType.aws,
    icon: Icons.cloud,
    color: AppColors.providerAws,
    regions: ['us-east-1', 'us-west-2', 'eu-west-1', 'ap-northeast-1'],
  ),
  ProviderPreset(
    name: 'GCP',
    type: RoomType.gcp,
    icon: Icons.cloud_circle,
    color: AppColors.providerGcp,
    regions: ['us-central1', 'us-east1', 'europe-west1', 'asia-east1'],
  ),
  ProviderPreset(
    name: 'Cloudflare',
    type: RoomType.cloudflare,
    icon: Icons.security,
    color: AppColors.providerCloudflare,
    regions: [],
  ),
  ProviderPreset(
    name: 'Vultr',
    type: RoomType.vultr,
    icon: Icons.dns,
    color: AppColors.providerVultr,
    regions: ['ewr', 'lax', 'ams', 'sgp'],
  ),
  ProviderPreset(
    name: 'Azure',
    type: RoomType.azure,
    icon: Icons.cloud_queue,
    color: AppColors.providerAzure,
    regions: ['eastus', 'westus2', 'westeurope', 'southeastasia'],
  ),
  ProviderPreset(
    name: 'DigitalOcean',
    type: RoomType.digitalOcean,
    icon: Icons.water_drop,
    color: AppColors.providerDigitalOcean,
    regions: ['nyc1', 'sfo3', 'ams3', 'sgp1'],
  ),
  ProviderPreset(
    name: 'Custom Room',
    type: RoomType.custom,
    icon: Icons.add_box,
    color: AppColors.roomCustom,
    regions: [],
  ),
];

/// Modal dialog for adding new rooms
class AddRoomModal extends StatefulWidget {
  final VoidCallback onClose;

  const AddRoomModal({super.key, required this.onClose});

  @override
  State<AddRoomModal> createState() => _AddRoomModalState();
}

class _AddRoomModalState extends State<AddRoomModal> {
  int _currentStep = 0;
  ProviderPreset? _selectedProvider;
  String? _selectedRegion;
  String _customName = '';
  WallSide _doorSide = WallSide.bottom;
  int _doorPosition = 5;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _roomName {
    if (_customName.isNotEmpty) return _customName;
    if (_selectedProvider == null) return '';
    if (_selectedRegion != null) {
      return '${_selectedProvider!.name} - $_selectedRegion';
    }
    return _selectedProvider!.name;
  }

  /// Whether the current door is on a horizontal wall (top or bottom).
  bool get _isHorizontalWall =>
      _doorSide == WallSide.top || _doorSide == WallSide.bottom;

  /// Maximum valid door position for the current wall side.
  int get _maxDoorPosition => _isHorizontalWall
      ? GameConstants.roomWidth - 2
      : GameConstants.roomHeight - 2;

  /// Get the accent color for the current provider selection.
  Color get _accentColor => _selectedProvider?.color ?? AppColors.roomCustom;

  bool get _canCreate {
    if (_selectedProvider == null) return false;
    if (_selectedProvider!.regions.isNotEmpty && _selectedRegion == null) {
      return false;
    }
    return true;
  }

  void _createRoom() {
    if (!_canCreate) return;

    context.read<GameBloc>().add(
      GameAddRoom(
        name: _roomName,
        type: _selectedProvider!.type,
        regionCode: _selectedRegion,
        doorSide: _doorSide,
        doorPosition: _doorPosition,
      ),
    );

    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: AppColors.overlayBackground,
        child: Center(
          child: GestureDetector(onTap: () {}, child: _buildContent(context)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      width: 500,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.modalAccentDark, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.modalAccentDark.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _currentStep == 0
                  ? _buildProviderSelection()
                  : _buildDoorPlacement(),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.overlayBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_home,
                color: AppColors.modalAccentLight,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                _currentStep == 0 ? 'ADD ROOM' : 'DOOR PLACEMENT',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Provider',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ..._providerPresets.map((preset) => _buildProviderCard(preset)),
        if (_selectedProvider?.regions.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          Text(
            'Select Region',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedProvider!.regions
                .map((region) => _buildRegionChip(region))
                .toList(),
          ),
        ],
        if (_selectedProvider?.type == RoomType.custom) ...[
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Room Name',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.grey600),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.modalAccentLight),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() => _customName = value),
          ),
        ],
      ],
    );
  }

  Widget _buildProviderCard(ProviderPreset preset) {
    final isSelected = _selectedProvider == preset;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedProvider = preset;
            _selectedRegion = null;
            _customName = '';
            _nameController.clear();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? preset.color.withValues(alpha: 0.2)
                : AppColors.overlayBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? preset.color : AppColors.grey700,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(preset.icon, color: preset.color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (preset.regions.isNotEmpty)
                      Text(
                        '${preset.regions.length} regions available',
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: preset.color, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionChip(String region) {
    final isSelected = _selectedRegion == region;
    return FilterChip(
      label: Text(region),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedRegion = selected ? region : null);
      },
      selectedColor: _accentColor.withValues(alpha: 0.3),
      checkmarkColor: _accentColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
      backgroundColor: AppColors.overlayBackground,
      side: BorderSide(color: isSelected ? _accentColor : AppColors.grey700),
    );
  }

  Widget _buildDoorPlacement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.overlayBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _selectedProvider?.icon ?? Icons.room,
                color: _accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _roomName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Door Wall',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: WallSide.values
              .map((side) => _buildWallSideButton(side))
              .toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Door Position',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('1', style: TextStyle(color: AppColors.textSecondary)),
            Expanded(
              child: Slider(
                value: _doorPosition.toDouble(),
                min: 1,
                max: _maxDoorPosition.toDouble(),
                divisions: _maxDoorPosition - 1,
                onChanged: (value) {
                  setState(() => _doorPosition = value.round());
                },
                activeColor: _accentColor,
              ),
            ),
            Text(
              '$_maxDoorPosition',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        Center(
          child: Text(
            'Position: $_doorPosition',
            style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        _buildRoomPreview(),
      ],
    );
  }

  Widget _buildWallSideButton(WallSide side) {
    final isSelected = _doorSide == side;
    final label = side.name[0].toUpperCase() + side.name.substring(1);
    final icon = switch (side) {
      WallSide.top => Icons.arrow_upward,
      WallSide.bottom => Icons.arrow_downward,
      WallSide.left => Icons.arrow_back,
      WallSide.right => Icons.arrow_forward,
    };

    return InkWell(
      onTap: () {
        setState(() {
          _doorSide = side;
          // Reset position to middle when changing wall
          final maxPos = (side == WallSide.top || side == WallSide.bottom)
              ? GameConstants.roomWidth - 2
              : GameConstants.roomHeight - 2;
          _doorPosition = maxPos ~/ 2;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _accentColor.withValues(alpha: 0.3)
              : AppColors.overlayBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _accentColor : AppColors.grey700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomPreview() {
    const cellSize = 20.0;
    const width = GameConstants.roomWidth;
    const height = GameConstants.roomHeight;

    return Center(
      child: Container(
        width: width * cellSize,
        height: height * cellSize,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          border: Border.all(color: AppColors.grey700, width: 2),
        ),
        child: Stack(
          children: [
            // Grid lines
            ...List.generate(width - 1, (i) {
              return Positioned(
                left: (i + 1) * cellSize,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: AppColors.grey800),
              );
            }),
            ...List.generate(height - 1, (i) {
              return Positioned(
                left: 0,
                right: 0,
                top: (i + 1) * cellSize,
                child: Container(height: 1, color: AppColors.grey800),
              );
            }),
            // Door indicator
            Positioned(
              left: _getDoorLeft(cellSize),
              top: _getDoorTop(cellSize),
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: _accentColor,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.door_front_door,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getDoorLeft(double cellSize) {
    return switch (_doorSide) {
      WallSide.left => 0,
      WallSide.right => (GameConstants.roomWidth - 1) * cellSize,
      WallSide.top || WallSide.bottom => _doorPosition * cellSize,
    };
  }

  double _getDoorTop(double cellSize) {
    return switch (_doorSide) {
      WallSide.top => 0,
      WallSide.bottom => (GameConstants.roomHeight - 1) * cellSize,
      WallSide.left || WallSide.right => _doorPosition * cellSize,
    };
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.overlayBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: _currentStep == 0
                ? (_canCreate ? () => setState(() => _currentStep++) : null)
                : (_canCreate ? _createRoom : null),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(_currentStep == 0 ? 'Next' : 'Create Room'),
          ),
        ],
      ),
    );
  }
}
