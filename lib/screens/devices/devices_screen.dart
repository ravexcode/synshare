import 'package:flutter/material.dart';

import '../../components/device_card.dart';
import '../../constraints/colors.dart';
import '../../models/device.dart';
import '../../services/discovery/discovery_service.dart';
import '../../services/transfer/transfer_service.dart';
import '../../utils/format.dart';
import '../transfer/send_screen.dart';

/// Main screen: nearby devices list.
///
/// Pure presentation. Reads state from [DeviceDiscoveryService]; all
/// networking lives in the services.
class DevicesScreen extends StatefulWidget {
  final DeviceDiscoveryService discovery;
  final TransferService transfer;

  const DevicesScreen({
    super.key,
    required this.discovery,
    required this.transfer,
  });

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _incomingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    widget.transfer.incoming.addListener(_onIncomingChanged);
  }

  @override
  void dispose() {
    widget.transfer.incoming.removeListener(_onIncomingChanged);
    super.dispose();
  }

  void _onIncomingChanged() {
    if (_incomingDialogOpen) return;
    final incoming = widget.transfer.incoming.value;
    if (incoming == null) return;
    _incomingDialogOpen = true;
    _promptIncoming(incoming);
  }

  Future<void> _promptIncoming(IncomingTransfer incoming) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.container,
        title: Text(
          'Incoming file',
          style: TextStyle(color: AppColors.text, fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              incoming.fileName,
              style: TextStyle(color: AppColors.text, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              formatBytes(incoming.size),
              style: TextStyle(color: AppColors.textGray, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              'Accept this file?',
              style: TextStyle(color: AppColors.textGray, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Reject', style: TextStyle(color: AppColors.textGray)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _incomingDialogOpen = false;
    if (accepted != true) {
      widget.transfer.rejectIncoming(incoming);
      return;
    }
    _saveIncoming(incoming);
  }

  Future<void> _saveIncoming(IncomingTransfer incoming) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.container,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                  backgroundColor: AppColors.ghost,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Receiving...',
                style: TextStyle(color: AppColors.text, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
    try {
      final path = await widget.transfer.saveIncoming(incoming);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved to $path',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.container,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Receive failed: $e',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.container,
        ),
      );
      widget.transfer.rejectIncoming(incoming);
    }
  }

  Future<void> _openDevice(Device device) async {
    if (device.address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot connect: no address for ${device.name}',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.container,
        ),
      );
      return;
    }
    try {
      await widget.transfer.connect(device);
      widget.discovery.markConnected(device.id, true);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SendScreen(device: device, transfer: widget.transfer),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to connect: $e',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.container,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: ListenableBuilder(
            listenable: Listenable.merge([widget.discovery, widget.transfer]),
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(onReload: widget.discovery.refresh),
                  const SizedBox(height: 12),
                  Expanded(child: _body()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final discovery = widget.discovery;
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
          itemBuilder: (_, index) {
            final device = devices[index];
            return DeviceCard(device: device, onTap: () => _openDevice(device));
          },
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
