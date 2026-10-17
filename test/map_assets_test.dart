import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homelab_simulator/map_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'production asset loader resolves real catalog and raster atlas',
    () async {
      final catalog = await loadMapCatalog();
      expect(catalog.initialMapId, 'server-lab');
      expect(catalog.maps.keys, containsAll(['server-lab', 'operations']));
      final bytes = await rootBundle.load(catalog.atlasAsset);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1024);
      expect(frame.image.height, 768);
      frame.image.dispose();
      codec.dispose();
    },
  );
}
