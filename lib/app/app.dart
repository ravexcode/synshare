import 'package:flutter/material.dart';

import '../constraints/colors.dart';
import '../screens/devices/devices_screen.dart';
import '../services/discovery/discovery_service.dart';

class SynshareApp extends StatefulWidget {
  const SynshareApp({super.key, this.discoveryService});

  /// Injectable for tests; defaults to a real mDNS service.
  final DeviceDiscoveryService? discoveryService;

  @override
  State<SynshareApp> createState() => _SynshareAppState();
}

class _SynshareAppState extends State<SynshareApp> {
  late final DeviceDiscoveryService _discovery;

  @override
  void initState() {
    super.initState();
    _discovery = widget.discoveryService ?? DeviceDiscoveryService();
    _discovery.start();
  }

  @override
  void dispose() {
    _discovery.stop();
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
      home: DevicesScreen(discovery: _discovery),
    );
  }
}
