import 'package:flutter/material.dart';

import '../constraints/colors.dart';
import '../models/device.dart';
import '../screens/devices/devices_screen.dart';

/// Example devices. UI-only, no discovery logic yet.
const List<Device> _exampleDevices = [
  Device(
    id: 'example-1',
    name: 'Moto de Rafael',
    platform: DevicePlatform.android,
    connected: true,
    connectionType: ConnectionType.lan,
  ),
  Device(
    id: 'example-2',
    name: 'Computadora de Jose',
    platform: DevicePlatform.windows,
    connected: true,
    connectionType: ConnectionType.lan,
  ),
  Device(
    id: 'example-3',
    name: 'Portatil de Ana',
    platform: DevicePlatform.linux,
    connected: false,
    connectionType: ConnectionType.lan,
  ),
];

class SynshareApp extends StatelessWidget {
  const SynshareApp({super.key});

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
      home: DevicesScreen(devices: _exampleDevices, onReload: () {}),
    );
  }
}
