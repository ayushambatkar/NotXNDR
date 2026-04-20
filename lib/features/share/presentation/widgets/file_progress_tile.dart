import 'package:flutter/material.dart';

class FileProgressTile extends StatelessWidget {
  final String fileId;
  final double progress;

  const FileProgressTile({
    super.key,
    required this.fileId,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileId, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Text('$pct%'),
          ],
        ),
      ),
    );
  }
}
