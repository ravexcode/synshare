import 'package:flutter/material.dart';

import '../constraints/colors.dart';
import '../models/device.dart';
import 'device_icon.dart';

/// Compact card showing a discovered device.
///
/// Pure presentation. Networking belongs in controllers/services, not here.
class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceCard({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.container,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DeviceIcon(platform: device.platform),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.platform.label,
                      style: TextStyle(color: AppColors.textGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                device.connected ? Icons.link : Icons.link_off,
                size: 18,
                color: device.connected
                    ? AppColors.primary
                    : AppColors.textGray,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
