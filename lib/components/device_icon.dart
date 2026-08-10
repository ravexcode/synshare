import 'package:flutter/material.dart';

import '../../constraints/colors.dart';
import '../../models/device.dart';

/// Icon for a device platform, rendered inside a ghost surface.
class DeviceIcon extends StatelessWidget {
  final DevicePlatform platform;
  final double size;

  const DeviceIcon({super.key, required this.platform, this.size = 20});

  IconData get _icon => switch (platform) {
    DevicePlatform.android => Icons.android,
    DevicePlatform.ios => Icons.phone_iphone,
    DevicePlatform.linux => Icons.computer,
    DevicePlatform.macos => Icons.laptop_mac,
    DevicePlatform.windows => Icons.desktop_windows,
    DevicePlatform.web => Icons.language,
    DevicePlatform.unknown => Icons.devices,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 2,
      height: size * 2,
      decoration: BoxDecoration(
        color: AppColors.ghost,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(_icon, size: size, color: AppColors.text),
    );
  }
}
