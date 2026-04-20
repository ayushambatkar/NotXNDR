import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/transfer_bloc.dart';
import '../bloc/transfer_state.dart';
import '../widgets/file_progress_tile.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  String _formatDateTime(DateTime value) {
    final d = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Progress')),
      body: BlocBuilder<TransferBloc, TransferState>(
        builder: (context, state) {
          final items = state.progressByFile.entries.toList();
          final completed = state.completedTransfers;
          return Column(
            children: [
              if (state is Sending)
                const ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Sending files...'),
                ),
              if (state is Receiving)
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text('Incoming from ${state.transfer.senderCode}'),
                  subtitle: Text('Transfer: ${state.transfer.id}'),
                ),
              if (state is Success)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(state.message),
                ),
              if (state is Failure)
                ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: Text(state.message),
                ),
              Expanded(
                child: ListView(
                  children: [
                    if (items.isEmpty)
                      const ListTile(
                        title: Text('No active file progress yet.'),
                      ),
                    for (final e in items)
                      FileProgressTile(fileId: e.key, progress: e.value),
                    const Divider(height: 24),
                    const ListTile(
                      leading: Icon(Icons.history),
                      title: Text('Completed Transfers'),
                    ),
                    if (completed.isEmpty)
                      const ListTile(
                        title: Text('No completed transfers yet.'),
                      ),
                    for (final item in completed)
                      ListTile(
                        leading: Icon(
                          item.isIncoming
                              ? Icons.download_done
                                : Icons.file_upload_rounded,
                          color: Colors.green,
                        ),
                        title: Text(
                          '${item.isIncoming ? 'From' : 'To'} ${item.peerCode} (${item.fileCount} file(s))',
                        ),
                        subtitle: Text(_formatDateTime(item.completedAt)),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
