import 'package:flutter/material.dart';

import '../constraints/colors.dart';
import '../models/transfer_file.dart';
import '../utils/format.dart';

/// Compact row for one selected file: icon, name, size, remove action.
class FileTile extends StatelessWidget {
  final OutgoingFile file;
  final VoidCallback? onRemove;

  const FileTile({super.key, required this.file, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.container,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.ghost,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.insert_drive_file,
              size: 16,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(color: AppColors.text, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formatBytes(file.size),
                  style: TextStyle(color: AppColors.textGray, fontSize: 11),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close, size: 16, color: AppColors.textGray),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
