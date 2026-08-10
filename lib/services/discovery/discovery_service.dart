import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

import '../../constraints/network.dart';
import '../../models/device.dart';

/// Lifecycle state of device discovery.
enum DiscoveryStatus {
  /// No discovery active.
  idle,

  /// Actively looking for devices.
  searching,

  /// At least one device found.
  found,

  /// Discovery failed (permissions, platform support, network).
  error,
}

/// Discovers Synshare devices over the local network using mDNS.
///
/// Advertises this device as a `_synshare._tcp` service and browses for
/// peers. Exposes results as [devices] and [status]. UI listens via
/// `ListenableBuilder`; no networking lives in widgets.
class DeviceDiscoveryService extends ChangeNotifier {
  /// Instance id advertised in TXT records so this device ignores itself.
  final String _instanceId;

  /// Friendly name advertised for this device.
  final String _deviceName;

  final List<Device> _devices = [];

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;

  DiscoveryStatus _status = DiscoveryStatus.idle;

  /// Human-readable label for the last failure.
  String? errorMessage;

  DeviceDiscoveryService({String? instanceId, String? deviceName})
    : _instanceId = instanceId ?? _generateInstanceId(),
      _deviceName = deviceName ?? _defaultDeviceName();

  List<Device> get devices => List.unmodifiable(_devices);

  DiscoveryStatus get status => _status;

  /// Starts advertising and browsing. Safe to call once; repeated calls
  /// are no-ops while already running.
  Future<void> start() async {
    if (_broadcast != null || _discovery != null) return;
    if (kIsWeb) {
      _setError('Discovery is not supported on web yet.');
      return;
    }
    _setStatus(DiscoveryStatus.searching);
    try {
      await _startBroadcast();
      await _startDiscovery();
    } catch (e) {
      _setError('Discovery failed: $e');
    }
  }

  /// Restarts browsing and drops the current device list.
  Future<void> refresh() async {
    await _stopDiscovery();
    _devices.clear();
    _setStatus(DiscoveryStatus.searching);
    if (kIsWeb) return;
    try {
      await _startDiscovery();
    } catch (e) {
      _setError('Discovery failed: $e');
    }
  }

  /// Stops advertising and browsing, clears state.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _stopDiscovery();
    await _stopBroadcast();
    _devices.clear();
    _setStatus(DiscoveryStatus.idle);
  }

  Future<void> _startBroadcast() async {
    final service = BonsoirService(
      name: _deviceName,
      type: NetworkConfig.serviceType,
      port: NetworkConfig.transferPort,
      attributes: {
        'instance': _instanceId,
        'platform': defaultTargetPlatform.name,
      },
    );
    final broadcast = BonsoirBroadcast(service: service);
    await broadcast.initialize();
    await broadcast.start();
    _broadcast = broadcast;
  }

  Future<void> _startDiscovery() async {
    final discovery = BonsoirDiscovery(type: NetworkConfig.serviceType);
    await discovery.initialize();
    _subscription = discovery.eventStream?.listen(_onDiscoveryEvent);
    await discovery.start();
    _discovery = discovery;
  }

  Future<void> _stopDiscovery() async {
    await _subscription?.cancel();
    _subscription = null;
    await _discovery?.stop();
    _discovery = null;
  }

  Future<void> _stopBroadcast() async {
    await _broadcast?.stop();
    _broadcast = null;
  }

  void _onDiscoveryEvent(BonsoirDiscoveryEvent event) {
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent():
        final resolver = _discovery?.serviceResolver;
        if (resolver != null) {
          event.service.resolve(resolver);
        }
      case BonsoirDiscoveryServiceResolvedEvent():
        _upsert(event.service);
      case BonsoirDiscoveryServiceUpdatedEvent():
        _upsert(event.service);
      case BonsoirDiscoveryServiceLostEvent():
        _remove(event.service);
      default:
        break;
    }
  }

  void _upsert(BonsoirService? service) {
    final device = _toDevice(service);
    if (device == null) return;
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index >= 0) {
      _devices[index] = device;
    } else {
      _devices.add(device);
    }
    _setStatus(DiscoveryStatus.found);
  }

  void _remove(BonsoirService? service) {
    if (service == null) return;
    final id = service.attributes['instance'] ?? _fallbackId(service);
    _devices.removeWhere((d) => d.id == id);
    _setStatus(
      _devices.isEmpty ? DiscoveryStatus.searching : DiscoveryStatus.found,
    );
  }

  Device? _toDevice(BonsoirService? service) {
    if (service == null) return null;
    final instance = service.attributes['instance'];
    if (instance == _instanceId) return null; // Our own advertisement.
    final address = _pickAddress(service.hostAddresses);
    return Device(
      id: instance ?? _fallbackId(service),
      name: service.name,
      platform: _platformFromName(service.attributes['platform']),
      address: address,
      port: service.port,
      connected: false,
      connectionType: ConnectionType.lan,
    );
  }

  static String _fallbackId(BonsoirService service) =>
      '${service.name}:${service.port}';

  static String? _pickAddress(List<String> addresses) {
    if (addresses.isEmpty) return null;
    // Prefer IPv4; link-local IPv6 (fe80::) is often unusable for TCP.
    for (final address in addresses) {
      if (address.contains('.')) return address;
    }
    return addresses.first;
  }

  static DevicePlatform _platformFromName(String? name) =>
      DevicePlatform.values.asNameMap()[name] ?? DevicePlatform.unknown;

  static String _generateInstanceId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(16);

  static String _defaultDeviceName() {
    if (kIsWeb) return 'Synshare Web';
    final hostname = Platform.localHostname.trim();
    if (hostname.isEmpty || hostname == 'localhost') {
      final platform = defaultTargetPlatform.name;
      return 'Synshare ${platform[0].toUpperCase()}${platform.substring(1)}';
    }
    return hostname.length > 60 ? hostname.substring(0, 60) : hostname;
  }

  void _setStatus(DiscoveryStatus value) {
    _status = value;
    notifyListeners();
  }

  void _setError(String message) {
    errorMessage = message;
    _setStatus(DiscoveryStatus.error);
  }

  /// Test-only hook to inject devices without a live network.
  @visibleForTesting
  void debugSetDevices(List<Device> devices) {
    _devices
      ..clear()
      ..addAll(devices);
    _setStatus(DiscoveryStatus.found);
  }
}
