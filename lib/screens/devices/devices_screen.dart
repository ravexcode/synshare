import 'package:flutter/material.dart';

import '../../components/device_card.dart';
import '../../constraints/colors.dart';
import '../../models/device.dart';

/// Main screen: nearby devices list.
class DevicesScreen extends StatelessWidget {
  final List<Device> devices;
  final VoidCallback? onReload;

  const DevicesScreen({super.key, required this.devices, this.onReload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Devices',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onReload,
                    tooltip: 'Search again',
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: devices.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: devices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final device = devices[index];
                          return DeviceCard(device: device, onTap: () {});
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 28, color: AppColors.textGray),
          const SizedBox(height: 12),
          Text(
            'No devices found.',
            style: TextStyle(color: AppColors.text, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Make sure both devices are\nconnected to the same network.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
