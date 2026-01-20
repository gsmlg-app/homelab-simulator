/// Device types available in the game
enum DeviceType {
  server,
  computer,
  phone,
  router,
  switch_,
  nas,
  iot,
}

/// Game modes
enum GameMode {
  sim,
  live,
}

/// Placement mode states
enum PlacementMode {
  none,
  placing,
  removing,
}

/// Direction for character movement
enum Direction {
  up,
  down,
  left,
  right,
  none,
}

/// Character gender
enum Gender {
  male,
  female,
}

/// Character skin tone options
enum SkinTone {
  light,
  medium,
  tan,
  dark,
}

/// Hair style options
enum HairStyle {
  short,
  medium,
  long,
  buzz,
  ponytail,
  spiky,
}

/// Hair color options
enum HairColor {
  black,
  brown,
  blonde,
  red,
  gray,
  blue,
  green,
  purple,
}

/// Outfit variant options
enum OutfitVariant {
  casual,
  formal,
  tech,
  sporty,
}

/// Interaction type
enum InteractionType {
  terminal,
  device,
  none,
}
