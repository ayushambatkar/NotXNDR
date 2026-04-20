import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/code_generator.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/download_files.dart';
import '../../domain/usecases/get_or_create_identity.dart';
import '../../domain/usecases/listen_transfers.dart';
import '../../domain/usecases/send_files.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';

@injectable
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final GetOrCreateIdentity getOrCreateIdentity;
  final SendFilesUseCase sendFilesUseCase;
  final ListenTransfers listenTransfersUseCase;
  final DownloadFiles downloadFilesUseCase;

  UserEntity? _user;
  StreamSubscription<TransferEntity>? _incomingSubscription;

  List<CompletedTransferItem> _appendCompleted(
    List<CompletedTransferItem> current,
    CompletedTransferItem item,
  ) {
    final next = <CompletedTransferItem>[
      item,
      ...current.where((e) => e.id != item.id),
    ];
    if (next.length > 100) return next.take(100).toList();
    return next;
  }

  TransferBloc({
    required this.getOrCreateIdentity,
    required this.sendFilesUseCase,
    required this.listenTransfersUseCase,
    required this.downloadFilesUseCase,
  }) : super(const Idle(userCode: '')) {
    on<InitializeTransfer>(_onInitialize);
    on<StartListeningTransfers>(_onStartListening);
    on<SendFiles>(_onSendFiles);
    on<ReceiveTransfer>(_onReceiveTransfer);
    on<UpdateProgress>(_onUpdateProgress);
    on<FailTransfer>(_onFailTransfer);

    // Trigger identity initialization as soon as the bloc is created.
    add(const InitializeTransfer());
  }

  Future<void> _onInitialize(
    InitializeTransfer event,
    Emitter<TransferState> emit,
  ) async {
    try {
      _user = await getOrCreateIdentity();
      emit(
        Idle(
          userCode: _user!.code,
          completedTransfers: state.completedTransfers,
        ),
      );
      add(const StartListeningTransfers());
    } catch (e) {
      final fallbackCode = state.userCode.trim().isNotEmpty
          ? state.userCode
          : CodeGenerator.generate();
      _user ??= UserEntity(code: fallbackCode, fcmToken: 'pending-token');
      emit(
        Failure(
          userCode: fallbackCode,
          message: 'Identity initialized in offline mode: $e',
          completedTransfers: state.completedTransfers,
        ),
      );
    }
  }

  Future<void> _onStartListening(
    StartListeningTransfers event,
    Emitter<TransferState> emit,
  ) async {
    final user = _user;
    if (user == null) return;

    await _incomingSubscription?.cancel();
    _incomingSubscription = listenTransfersUseCase(user.code).listen(
      (transfer) => add(ReceiveTransfer(transfer)),
      onError: (error) => add(FailTransfer(error.toString())),
    );
  }

  Future<void> _onSendFiles(
    SendFiles event,
    Emitter<TransferState> emit,
  ) async {
    final user = _user;
    if (user == null) {
      emit(
        Failure(
          userCode: state.userCode,
          message: 'User identity is not ready yet. Please try again.',
          completedTransfers: state.completedTransfers,
        ),
      );
      return;
    }

    try {
      emit(
        Sending(
          userCode: user.code,
          progressByFile: const <String, double>{},
          completedTransfers: state.completedTransfers,
        ),
      );
      await sendFilesUseCase(
        senderCode: user.code,
        receiverCode: event.receiverCode,
        files: event.files,
        onFileProgress: (fileId, progress) {
          add(
            UpdateProgress(
              transferId: 'sending',
              fileId: fileId,
              progress: progress,
              isSending: true,
            ),
          );
        },
      );
      final completed = _appendCompleted(
        state.completedTransfers,
        CompletedTransferItem(
          id: 'out_${DateTime.now().microsecondsSinceEpoch}',
          peerCode: event.receiverCode,
          fileCount: event.files.length,
          isIncoming: false,
          completedAt: DateTime.now(),
        ),
      );
      emit(
        Success(
          userCode: user.code,
          message: 'Transfer sent.',
          completedTransfers: completed,
        ),
      );
      emit(Idle(userCode: user.code, completedTransfers: completed));
    } catch (e) {
      emit(
        Failure(
          userCode: user.code,
          message: e.toString(),
          completedTransfers: state.completedTransfers,
        ),
      );
    }
  }

  Future<void> _onReceiveTransfer(
    ReceiveTransfer event,
    Emitter<TransferState> emit,
  ) async {
    final user = _user;
    if (user == null) return;

    final progress = <String, double>{
      for (final f in event.transfer.files) f.id: 0,
    };

    emit(
      Receiving(
        userCode: user.code,
        transfer: event.transfer,
        progressByFile: progress,
        completedTransfers: state.completedTransfers,
      ),
    );

    try {
      await downloadFilesUseCase(
        transfer: event.transfer,
        onFileProgress: (fileId, p) {
          add(
            UpdateProgress(
              transferId: event.transfer.id,
              fileId: fileId,
              progress: p,
              isSending: false,
            ),
          );
        },
      );
      final completed = _appendCompleted(
        state.completedTransfers,
        CompletedTransferItem(
          id: event.transfer.id,
          peerCode: event.transfer.senderCode,
          fileCount: event.transfer.files.length,
          isIncoming: true,
          completedAt: DateTime.now(),
        ),
      );
      emit(
        Success(
          userCode: user.code,
          message: 'Received ${event.transfer.files.length} file(s).',
          progressByFile: state.progressByFile,
          completedTransfers: completed,
        ),
      );
      emit(Idle(userCode: user.code, completedTransfers: completed));
    } catch (e) {
      emit(
        Failure(
          userCode: user.code,
          message: e.toString(),
          progressByFile: state.progressByFile,
          completedTransfers: state.completedTransfers,
        ),
      );
    }
  }

  void _onUpdateProgress(UpdateProgress event, Emitter<TransferState> emit) {
    final updated = Map<String, double>.from(state.progressByFile)
      ..[event.fileId] = event.progress;

    if (event.isSending) {
      emit(
        Sending(
          userCode: state.userCode,
          progressByFile: updated,
          completedTransfers: state.completedTransfers,
        ),
      );
      return;
    }

    final transfer = state is Receiving ? (state as Receiving).transfer : null;
    if (transfer != null) {
      emit(
        Receiving(
          userCode: state.userCode,
          transfer: transfer,
          progressByFile: updated,
          completedTransfers: state.completedTransfers,
        ),
      );
    }
  }

  void _onFailTransfer(FailTransfer event, Emitter<TransferState> emit) {
    emit(
      Failure(
        userCode: state.userCode,
        message: event.message,
        progressByFile: state.progressByFile,
        completedTransfers: state.completedTransfers,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _incomingSubscription?.cancel();
    return super.close();
  }
}
