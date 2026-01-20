import 'package:test/test.dart';
import 'package:app_lib_core/app_lib_core.dart';

void main() {
  group('DeviceType', () {
    test('has all expected values', () {
      expect(DeviceType.values, hasLength(7));
      expect(DeviceType.values, contains(DeviceType.server));
      expect(DeviceType.values, contains(DeviceType.computer));
      expect(DeviceType.values, contains(DeviceType.phone));
      expect(DeviceType.values, contains(DeviceType.router));
      expect(DeviceType.values, contains(DeviceType.switch_));
      expect(DeviceType.values, contains(DeviceType.nas));
      expect(DeviceType.values, contains(DeviceType.iot));
    });

    test('switch_ is valid identifier for switch', () {
      // Dart requires underscore because 'switch' is a keyword
      expect(DeviceType.switch_.name, 'switch_');
    });
  });

  group('GameMode', () {
    test('has all expected values', () {
      expect(GameMode.values, hasLength(2));
      expect(GameMode.values, contains(GameMode.sim));
      expect(GameMode.values, contains(GameMode.live));
    });
  });

  group('PlacementMode', () {
    test('has all expected values', () {
      expect(PlacementMode.values, hasLength(3));
      expect(PlacementMode.values, contains(PlacementMode.none));
      expect(PlacementMode.values, contains(PlacementMode.placing));
      expect(PlacementMode.values, contains(PlacementMode.removing));
    });

    test('none is the default state', () {
      expect(PlacementMode.none.index, 0);
    });
  });

  group('Direction', () {
    test('has all expected values', () {
      expect(Direction.values, hasLength(5));
      expect(Direction.values, contains(Direction.up));
      expect(Direction.values, contains(Direction.down));
      expect(Direction.values, contains(Direction.left));
      expect(Direction.values, contains(Direction.right));
      expect(Direction.values, contains(Direction.none));
    });

    test('has none for idle state', () {
      expect(Direction.none.name, 'none');
    });
  });

  group('Gender', () {
    test('has all expected values', () {
      expect(Gender.values, hasLength(2));
      expect(Gender.values, contains(Gender.male));
      expect(Gender.values, contains(Gender.female));
    });
  });

  group('SkinTone', () {
    test('has all expected values', () {
      expect(SkinTone.values, hasLength(4));
      expect(SkinTone.values, contains(SkinTone.light));
      expect(SkinTone.values, contains(SkinTone.medium));
      expect(SkinTone.values, contains(SkinTone.tan));
      expect(SkinTone.values, contains(SkinTone.dark));
    });

    test('values are in order from light to dark', () {
      expect(SkinTone.light.index, lessThan(SkinTone.medium.index));
      expect(SkinTone.medium.index, lessThan(SkinTone.tan.index));
      expect(SkinTone.tan.index, lessThan(SkinTone.dark.index));
    });
  });

  group('HairStyle', () {
    test('has all expected values', () {
      expect(HairStyle.values, hasLength(6));
      expect(HairStyle.values, contains(HairStyle.short));
      expect(HairStyle.values, contains(HairStyle.medium));
      expect(HairStyle.values, contains(HairStyle.long));
      expect(HairStyle.values, contains(HairStyle.buzz));
      expect(HairStyle.values, contains(HairStyle.ponytail));
      expect(HairStyle.values, contains(HairStyle.spiky));
    });
  });

  group('HairColor', () {
    test('has all expected values', () {
      expect(HairColor.values, hasLength(8));
      expect(HairColor.values, contains(HairColor.black));
      expect(HairColor.values, contains(HairColor.brown));
      expect(HairColor.values, contains(HairColor.blonde));
      expect(HairColor.values, contains(HairColor.red));
      expect(HairColor.values, contains(HairColor.gray));
      expect(HairColor.values, contains(HairColor.blue));
      expect(HairColor.values, contains(HairColor.green));
      expect(HairColor.values, contains(HairColor.purple));
    });

    test('has natural colors', () {
      expect(HairColor.black.name, 'black');
      expect(HairColor.brown.name, 'brown');
      expect(HairColor.blonde.name, 'blonde');
      expect(HairColor.red.name, 'red');
      expect(HairColor.gray.name, 'gray');
    });

    test('has fantasy colors', () {
      expect(HairColor.blue.name, 'blue');
      expect(HairColor.green.name, 'green');
      expect(HairColor.purple.name, 'purple');
    });
  });

  group('OutfitVariant', () {
    test('has all expected values', () {
      expect(OutfitVariant.values, hasLength(4));
      expect(OutfitVariant.values, contains(OutfitVariant.casual));
      expect(OutfitVariant.values, contains(OutfitVariant.formal));
      expect(OutfitVariant.values, contains(OutfitVariant.tech));
      expect(OutfitVariant.values, contains(OutfitVariant.sporty));
    });
  });

  group('InteractionType', () {
    test('has all expected values', () {
      expect(InteractionType.values, hasLength(4));
      expect(InteractionType.values, contains(InteractionType.terminal));
      expect(InteractionType.values, contains(InteractionType.device));
      expect(InteractionType.values, contains(InteractionType.door));
      expect(InteractionType.values, contains(InteractionType.none));
    });

    test('none represents no interaction', () {
      expect(InteractionType.none.name, 'none');
    });
  });

  group('RoomType', () {
    test('has all expected values', () {
      expect(RoomType.values, hasLength(8));
      expect(RoomType.values, contains(RoomType.serverRoom));
      expect(RoomType.values, contains(RoomType.aws));
      expect(RoomType.values, contains(RoomType.gcp));
      expect(RoomType.values, contains(RoomType.cloudflare));
      expect(RoomType.values, contains(RoomType.vultr));
      expect(RoomType.values, contains(RoomType.azure));
      expect(RoomType.values, contains(RoomType.digitalOcean));
      expect(RoomType.values, contains(RoomType.custom));
    });

    test('has physical room type', () {
      expect(RoomType.serverRoom.name, 'serverRoom');
    });

    test('has cloud provider room types', () {
      expect(RoomType.aws.name, 'aws');
      expect(RoomType.gcp.name, 'gcp');
      expect(RoomType.azure.name, 'azure');
    });

    test('has custom room type for user-defined rooms', () {
      expect(RoomType.custom.name, 'custom');
    });
  });

  group('CloudProvider', () {
    test('has all expected values', () {
      expect(CloudProvider.values, hasLength(7));
      expect(CloudProvider.values, contains(CloudProvider.none));
      expect(CloudProvider.values, contains(CloudProvider.aws));
      expect(CloudProvider.values, contains(CloudProvider.gcp));
      expect(CloudProvider.values, contains(CloudProvider.cloudflare));
      expect(CloudProvider.values, contains(CloudProvider.vultr));
      expect(CloudProvider.values, contains(CloudProvider.azure));
      expect(CloudProvider.values, contains(CloudProvider.digitalOcean));
    });

    test('none represents no cloud provider (local)', () {
      expect(CloudProvider.none.name, 'none');
      expect(CloudProvider.none.index, 0);
    });

    test('major cloud providers are present', () {
      expect(CloudProvider.aws.name, 'aws');
      expect(CloudProvider.gcp.name, 'gcp');
      expect(CloudProvider.azure.name, 'azure');
    });
  });

  group('ServiceCategory', () {
    test('has all expected values', () {
      expect(ServiceCategory.values, hasLength(7));
      expect(ServiceCategory.values, contains(ServiceCategory.compute));
      expect(ServiceCategory.values, contains(ServiceCategory.storage));
      expect(ServiceCategory.values, contains(ServiceCategory.database));
      expect(ServiceCategory.values, contains(ServiceCategory.networking));
      expect(ServiceCategory.values, contains(ServiceCategory.container));
      expect(ServiceCategory.values, contains(ServiceCategory.serverless));
      expect(ServiceCategory.values, contains(ServiceCategory.other));
    });

    test('compute includes virtual machines and instances', () {
      expect(ServiceCategory.compute.name, 'compute');
    });

    test('has other category for miscellaneous services', () {
      expect(ServiceCategory.other.name, 'other');
    });
  });

  group('Enum string conversion', () {
    test('DeviceType converts to string correctly', () {
      expect(DeviceType.server.toString(), 'DeviceType.server');
    });

    test('CloudProvider converts to string correctly', () {
      expect(CloudProvider.aws.toString(), 'CloudProvider.aws');
    });

    test('ServiceCategory converts to string correctly', () {
      expect(ServiceCategory.compute.toString(), 'ServiceCategory.compute');
    });
  });
}
