/// Character sprite definitions packaged by game_asset_characters.
class GameCharacters {
  GameCharacters._();

  static const CharacterSpriteSheet MainMale = CharacterSpriteSheet(
    path: 'packages/game_asset_characters/assets/boy.png',
    frameWidth: 192,
    frameHeight: 256,
    columns: 8,
    rows: 4,
    idleRow: 0,
    walkRows: [1, 2, 3],
  );

  static const CharacterSpriteSheet MainFemale = CharacterSpriteSheet(
    path: 'packages/game_asset_characters/assets/girl.png',
    frameWidth: 192,
    frameHeight: 256,
    columns: 8,
    rows: 4,
    idleRow: 0,
    walkRows: [1, 2, 3],
  );
}

enum CharacterDirection {
  down,
  downLeft,
  left,
  upLeft,
  up,
  upRight,
  right,
  downRight,
}

class CharacterSpriteSheet {
  final String path;
  final double frameWidth;
  final double frameHeight;
  final int columns;
  final int rows;
  final int idleRow;
  final List<int> walkRows;

  const CharacterSpriteSheet({
    required this.path,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this.rows,
    required this.idleRow,
    required this.walkRows,
  });

  int columnForDirection(CharacterDirection direction) =>
      _directionColumns[direction] ?? 0;
}

const Map<CharacterDirection, int> _directionColumns = {
  CharacterDirection.down: 0,
  CharacterDirection.downLeft: 1,
  CharacterDirection.left: 2,
  CharacterDirection.upLeft: 3,
  CharacterDirection.up: 4,
  CharacterDirection.upRight: 5,
  CharacterDirection.right: 6,
  CharacterDirection.downRight: 7,
};
