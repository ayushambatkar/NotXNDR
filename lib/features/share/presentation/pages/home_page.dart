import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/selected_file_entity.dart';
import '../../domain/usecases/pick_files.dart';
import '../bloc/transfer_bloc.dart';
import '../bloc/transfer_event.dart';
import '../bloc/transfer_state.dart';

class HomePage extends StatefulWidget {
  final PickFiles pickFiles;

  const HomePage({super.key, required this.pickFiles});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _recipientController = TextEditingController();
  List<SelectedFileEntity> _selectedFiles = <SelectedFileEntity>[];

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code copied to clipboard')));
  }

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final files = await widget.pickFiles();
    if (!mounted) return;

    setState(() {
      _selectedFiles = files;
    });
  }

  void _send() {
    final recipient = _recipientController.text.trim().toUpperCase();
    context.read<TransferBloc>().add(
      SendFiles(receiverCode: recipient, files: _selectedFiles),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeoSapien Share'),
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes),
            onPressed: () {
              context.push('/transfer');
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              context.read<TransferBloc>().add(const InitializeTransfer());
            },
          ),
        ],
      ),
      body: BlocConsumer<TransferBloc, TransferState>(
        listenWhen: (previous, current) {
          if (current is Receiving) {
            final previousId = previous is Receiving
                ? previous.transfer.id
                : null;
            return previousId != current.transfer.id;
          }
          if (current is Success) {
            return previous is! Success || previous.message != current.message;
          }
          if (current is Failure) {
            return previous is! Failure || previous.message != current.message;
          }
          return false;
        },
        listener: (context, state) {
          if (state is Receiving) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Incoming transfer from ${state.transfer.senderCode}',
                ),
              ),
            );
          } else if (state is Success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is Failure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.perm_identity),
                  title: const Text('Your Code'),
                  subtitle: Text(
                    state.userCode.trim().isEmpty
                        ? 'Generating...'
                        : state.userCode,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy code',
                    onPressed: state.userCode.trim().isEmpty
                        ? null
                        : () => _copyCode(state.userCode),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _recipientController,
                maxLength: 8,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Recipient Code',
                  hintText: 'Enter 6-8 char code',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file),
                label: const Text('Pick Files'),
              ),
              const SizedBox(height: 8),
              Text('Selected: ${_selectedFiles.length} file(s)'),
              for (final f in _selectedFiles)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(f.name),
                  subtitle: Text(
                    '${(f.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    _selectedFiles.isEmpty || state.userCode.trim().isEmpty
                    ? null
                    : _send,
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
              if (state is Failure)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
