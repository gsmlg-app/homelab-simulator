import 'package:shared_preferences/shared_preferences.dart';

/// Mixin providing lazy SharedPreferences initialization.
///
/// Classes using this mixin get a [preferences] getter that returns
/// a cached SharedPreferences instance, initializing it on first access.
mixin SharedPreferencesMixin {
  SharedPreferences? _prefs;

  /// Returns a cached SharedPreferences instance.
  ///
  /// The instance is lazily initialized on first access and reused
  /// for subsequent calls.
  Future<SharedPreferences> get preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}
