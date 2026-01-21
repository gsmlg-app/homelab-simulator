/// Sound effect types available in the game.
enum SfxType {
  /// Door opening sound effect.
  doorOpen('door_open.ogg'),

  /// Door closing sound effect.
  doorClose('door_close.ogg'),

  /// UI button click sound.
  buttonClick('button_click.ogg'),

  /// UI button hover sound.
  buttonHover('button_hover.ogg'),

  /// Item pickup sound.
  itemPickup('item_pickup.ogg'),

  /// Item placement sound.
  itemPlace('item_place.ogg'),

  /// Error/invalid action sound.
  error('error.ogg'),

  /// Success/completion sound.
  success('success.ogg'),

  /// Menu open sound.
  menuOpen('menu_open.ogg'),

  /// Menu close sound.
  menuClose('menu_close.ogg'),

  /// Device power on sound.
  devicePowerOn('device_power_on.ogg'),

  /// Device power off sound.
  devicePowerOff('device_power_off.ogg');

  const SfxType(this.filename);

  /// The filename of the audio asset.
  final String filename;

  /// Full asset path for Flame audio.
  String get assetPath => 'sfx/$filename';
}
