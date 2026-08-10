/// How a device was discovered / is connected.
enum ConnectionType { lan, bluetooth }

/// Known device platforms.
enum DevicePlatform {
  android,
  ios,
  linux,
  macos,
  windows,
  web,
  unknown;

  /// Human-readable label shown in the UI.
  String get label => switch (this) {
    android => 'Android',
    ios => 'iOS',
    linux => 'Linux',
    macos => 'macOS',
    windows => 'Windows',
    web => 'Web',
    unknown => 'Device',
  };
}

/// A device discovered on the local network.
class Device {
  final String id;
  final String name;
  final DevicePlatform platform;
  final String? address;
  final int? port;
  final bool connected;
  final ConnectionType connectionType;

  const Device({
    required this.id,
    required this.name,
    required this.platform,
    this.address,
    this.port,
    required this.connected,
    required this.connectionType,
  });
}
