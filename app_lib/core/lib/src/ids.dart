import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generate a unique entity ID
String generateEntityId() => _uuid.v4();

/// Generate a unique device ID
String generateDeviceId() => 'device_${_uuid.v4()}';

/// Generate a unique room ID
String generateRoomId() => 'room_${_uuid.v4()}';

/// Generate a unique door ID
String generateDoorId() => 'door_${_uuid.v4()}';

/// Generate a unique character ID
String generateCharacterId() => 'char_${_uuid.v4()}';
