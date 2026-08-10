import 'package:flutter/material.dart';

import '../../components/device_card.dart';
import '../../constraints/colors.dart';
import '../../services/discovery/discovery_service.dart';

/// Main screen: nearby devices list.
///
/// Pure presentation. Reads state from [DeviceDiscoveryService]; all
/// networking lives in the service.
class DevicesScreen extends StatelessWidget {
  final DeviceDiscoveryService discovery;

  const DevicesScreen({super.key, required this.discovery});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: ListenableBuilder(
            listenable: discovery,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(onReload: discovery.refresh),
                  const SizedBox(height: 12),
                  Expanded(child: _body(discovery)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(DeviceDiscoveryService discovery) {
    final devices = discovery.devices;
    switch (discovery.status) {
      case DiscoveryStatus.idle:
        return _EmptyState(
          icon: Icons.wifi_off,
          title: 'No devices found.',
          message: 'Make sure both devices are\nconnected to the same network.',
        );
      case DiscoveryStatus.searching:
        return const _EmptyState(
          icon: Icons.radar,
          title: 'Searching nearby...',
          message: 'Keep both devices on the\nsame local network.',
        );
      case DiscoveryStatus.found:
        if (devices.isEmpty) {
          return const _EmptyState(
            icon: Icons.wifi_off,
            title: 'No devices found.',
            message:
                'Make sure both devices are\nconnected to the same network.',
          );
        }
        return ListView.separated(
          itemCount: devices.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) => DeviceCard(device: devices[index]),
        );
      case DiscoveryStatus.error:
        return _EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to connect.',
          message: discovery.errorMessage ?? 'Try again.',
        );
    }
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onReload;

  const _Header({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          icon: Icon(Icons.refresh, size: 20, color: AppColors.textGray),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AppColors.textGray),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: AppColors.text, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
