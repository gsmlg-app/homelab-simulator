import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

import 'grid_component.dart';
import 'terminal_component.dart';
import 'hover_cell_component.dart';

/// Main room component containing grid, terminal, and hover indicator
class RoomComponent extends PositionComponent
    with FlameBlocReader<WorldBloc, WorldState> {
  final int gridWidth;
  final int gridHeight;
  final double tileSize;

  late final GridComponent _grid;
  late final TerminalComponent _terminal;
  late final HoverCellComponent _hoverCell;

  RoomComponent({
    this.gridWidth = GameConstants.roomWidth,
    this.gridHeight = GameConstants.roomHeight,
    this.tileSize = GameConstants.tileSize,
  }) : super(size: Vector2(gridWidth * tileSize, gridHeight * tileSize));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Background
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFF1A1A2E),
      ),
    );

    // Grid
    _grid = GridComponent(
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      tileSize: tileSize,
    );
    add(_grid);

    // Terminal
    _terminal = TerminalComponent(tileSize: tileSize);
    add(_terminal);

    // Hover indicator
    _hoverCell = HoverCellComponent(tileSize: tileSize);
    add(_hoverCell);
  }

  /// Handle hover position update from game
  void onHoverPosition(Vector2 position) {
    final gridPos = pixelToGrid(position.x, position.y);
    if (isWithinBounds(gridPos)) {
      bloc.add(CellHovered(gridPos));
    }
  }

  /// Handle hover exit
  void onHoverExit() {
    bloc.add(const CellHoverEnded());
  }

  /// Update hover cell validity for placement mode
  void setPlacementValid(bool valid) {
    _hoverCell.setValidPlacement(valid);
  }
}
