/// Network constants for the Synshare mDNS service.
abstract final class NetworkConfig {
  /// mDNS service type advertised and discovered over LAN.
  static const String serviceType = '_synshare._tcp';

  /// TCP port reserved for direct device-to-device transfers.
  ///
  /// The transfer server binds this port when file sending lands.
  static const int transferPort = 58410;
}
