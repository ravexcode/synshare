/// Network constants for the Synshare mDNS service.
abstract final class NetworkConfig {
  /// mDNS service type advertised and discovered over LAN.
  static const String serviceType = '_synshare._tcp';

  /// TCP port reserved for direct device-to-device transfers.
  ///
  /// The transfer server binds this port when file sending lands.
  static const int transferPort = 58410;

  /// Plain-text protocol id used in pairing and transfer headers.
  static const String protocol = 'SYNSHARE/1';

  /// Default timeout for pairing and per-transfer TCP operations.
  static const Duration connectTimeout = Duration(seconds: 5);
}
