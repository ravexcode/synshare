import 'package:flutter/material.dart';

import '../constraints/colors.dart';
import '../screens/devices/devices_screen.dart';
import '../services/discovery/discovery_service.dart';
import '../services/transfer/transfer_service.dart';

class SynshareApp extends StatefulWidget {
  const SynshareApp({super.key, this.discoveryService, this.transferService});

  /// Injectable for tests; defaults to a real mDNS service.
  final DeviceDiscoveryService? discoveryService;

  /// Injectable for tests; defaults to a real transfer service.
  final TransferService? transferService;

  @override
  State<SynshareApp> createState() => _SynshareAppState();
}

class _SynshareAppState extends State<SynshareApp> {
  late final DeviceDiscoveryService _discovery;
  late final TransferService _transfer;

  @override
  void initState() {
    super.initState();
    _discovery = widget.discoveryService ?? DeviceDiscoveryService();
    _transfer =
        widget.transferService ??
        TransferService(deviceName: _discovery.deviceName);
    _discovery.start();
    _transfer.start();
  }

  @override
  void dispose() {
    _discovery.stop();
    _transfer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synshare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.container,
        ),
      ),
      home: DevicesScreen(discovery: _discovery, transfer: _transfer),
    );
  }
}
