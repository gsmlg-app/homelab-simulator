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

/// Interaction type
enum InteractionType {
  terminal,
  device,
  none,
}
