import 'package:equatable/equatable.dart';

import '../../domain/entities/transfer_entity.dart';

class CompletedTransferItem extends Equatable {
  final String id;
  final String peerCode;
  final int fileCount;
  final bool isIncoming;
  final DateTime completedAt;

  const CompletedTransferItem({
    required this.id,
    required this.peerCode,
    required this.fileCount,
    required this.isIncoming,
    required this.completedAt,
  });

  @override
  List<Object?> get props => <Object?>[
    id,
    peerCode,
    fileCount,
    isIncoming,
    completedAt,
  ];
}

abstract class TransferState extends Equatable {
  final String userCode;
  final Map<String, double> progressByFile;
  final List<CompletedTransferItem> completedTransfers;

  const TransferState({
    required this.userCode,
    this.progressByFile = const <String, double>{},
    this.completedTransfers = const <CompletedTransferItem>[],
  });

  @override
  List<Object?> get props => <Object?>[
    userCode,
    progressByFile,
    completedTransfers,
  ];
}

class Idle extends TransferState {
  const Idle({
    required super.userCode,
    super.progressByFile,
    super.completedTransfers,
  });
}

class Sending extends TransferState {
  const Sending({
    required super.userCode,
    required super.progressByFile,
    super.completedTransfers,
  });
}

class Receiving extends TransferState {
  final TransferEntity transfer;

  const Receiving({
    required super.userCode,
    required super.progressByFile,
    super.completedTransfers,
    required this.transfer,
  });

  @override
  List<Object?> get props => <Object?>[
    userCode,
    progressByFile,
    completedTransfers,
    transfer,
  ];
}

class Success extends TransferState {
  final String message;

  const Success({
    required super.userCode,
    required this.message,
    super.progressByFile,
    super.completedTransfers,
  });

  @override
  List<Object?> get props => <Object?>[
    userCode,
    progressByFile,
    completedTransfers,
    message,
  ];
}

class Failure extends TransferState {
  final String message;

  const Failure({
    required super.userCode,
    required this.message,
    super.progressByFile,
    super.completedTransfers,
  });

  @override
  List<Object?> get props => <Object?>[
    userCode,
    progressByFile,
    completedTransfers,
    message,
  ];
}
