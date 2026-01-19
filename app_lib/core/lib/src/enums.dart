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

/// Interaction type
enum InteractionType {
  terminal,
  device,
  none,
}
