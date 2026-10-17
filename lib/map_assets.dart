import 'dart:convert';

import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:flutter/services.dart';

/// Loads and validates the bundled developer-authored map catalog.
Future<MapCatalog> loadMapCatalog({AssetBundle? bundle}) async {
  final json = await (bundle ?? rootBundle).loadString(
    'assets/maps/catalog.json',
  );
  return MapCatalog.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
