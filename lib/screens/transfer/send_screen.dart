import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../components/device_icon.dart';
import '../../components/file_tile.dart';
import '../../constraints/colors.dart';
import '../../models/device.dart';
import '../../models/transfer_file.dart';
import '../../services/transfer/transfer_service.dart';

/// Screen for sending files to a paired device.
class SendScreen extends StatefulWidget {
  final Device device;
  final TransferService transfer;

  const SendScreen({super.key, required this.device, required this.transfer});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final List<OutgoingFile> _files = [];
  FileSort _sort = FileSort.latest;
  bool _sending = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    final picked = <OutgoingFile>[];
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      DateTime modified;
      try {
        modified = await File(path).lastModified();
      } catch (_) {
        modified = DateTime.now();
      }
      picked.add(
        OutgoingFile(
          name: file.name,
          size: file.size,
          path: path,
          modified: modified,
        ),
      );
    }
    setState(() {
      _files.addAll(picked);
      _files.sort((a, b) => compareFiles(_sort, a, b));
    });
  }

  void _removeFile(OutgoingFile file) {
    setState(() => _files.remove(file));
  }

  void _changeSort(FileSort? sort) {
    if (sort == null || sort == _sort) return;
    setState(() {
      _sort = sort;
      _files.sort((a, b) => compareFiles(_sort, a, b));
    });
  }

  Future<void> _send() async {
    if (_files.isEmpty || _sending) return;
    setState(() => _sending = true);
    final progress = ValueNotifier<double>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _TransferProgressDialog(progress: progress, fileCount: _files.length),
    );
    try {
      await widget.transfer.sendFiles(
        device: widget.device,
        files: List.of(_files),
        onProgress: (sent, total) =>
            progress.value = total == 0 ? 1 : sent / total,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sent ${_files.length} file(s) to ${widget.device.name}',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.container,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Send failed: $e',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.container,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    icon: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.device.name,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: DeviceIcon(platform: widget.device.platform, size: 36),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _sending ? null : _pickFiles,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.ghost),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  icon: Icon(Icons.add, size: 18, color: AppColors.primary),
                  label: const Text('Select files'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Files',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<FileSort>(
                    onSelected: _changeSort,
                    tooltip: 'Sort files',
                    itemBuilder: (_) => [
                      for (final sort in FileSort.values)
                        PopupMenuItem<FileSort>(
                          value: sort,
                          child: Text(
                            sort.label,
                            style: TextStyle(
                              color: sort == _sort
                                  ? AppColors.primary
                                  : AppColors.text,
                            ),
                          ),
                        ),
                    ],
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_vert,
                          size: 16,
                          color: AppColors.textGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _sort.label,
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _files.isEmpty
                    ? Center(
                        child: Text(
                          'No files selected.\nTap "Select files" to add documents.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _files.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => FileTile(
                          file: _files[index],
                          onRemove: _sending
                              ? null
                              : () => _removeFile(_files[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _sending
          ? null
          : Container(
              color: AppColors.container,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _files.isEmpty ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.ghost,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _files.isEmpty
                          ? 'Select files to send'
                          : 'Send ${_files.length} file(s)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TransferProgressDialog extends StatelessWidget {
  final ValueNotifier<double> progress;
  final int fileCount;

  const _TransferProgressDialog({
    required this.progress,
    required this.fileCount,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.container,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sending $fileCount file(s)...',
              style: TextStyle(color: AppColors.text, fontSize: 14),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (_, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: AppColors.ghost,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (_, value, _) => Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
