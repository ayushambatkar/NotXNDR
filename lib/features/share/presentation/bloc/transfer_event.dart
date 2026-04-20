import 'package:equatable/equatable.dart';

import '../../domain/entities/selected_file_entity.dart';
import '../../domain/entities/transfer_entity.dart';

abstract class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class InitializeTransfer extends TransferEvent {
  const InitializeTransfer();
}

class StartListeningTransfers extends TransferEvent {
  const StartListeningTransfers();
}

class SendFiles extends TransferEvent {
  final String receiverCode;
  final List<SelectedFileEntity> files;

  const SendFiles({required this.receiverCode, required this.files});

  @override
  List<Object?> get props => <Object?>[receiverCode, files];
}

class ReceiveTransfer extends TransferEvent {
  final TransferEntity transfer;

  const ReceiveTransfer(this.transfer);

  @override
  List<Object?> get props => <Object?>[transfer];
}

class UpdateProgress extends TransferEvent {
  final String transferId;
  final String fileId;
  final double progress;
  final bool isSending;

  const UpdateProgress({
    required this.transferId,
    required this.fileId,
    required this.progress,
    required this.isSending,
  });

  @override
  List<Object?> get props => <Object?>[transferId, fileId, progress, isSending];
}

class FailTransfer extends TransferEvent {
  final String message;

  const FailTransfer(this.message);

  @override
  List<Object?> get props => <Object?>[message];
}
