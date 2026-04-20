import '../entities/selected_file_entity.dart';
import '../entities/transfer_entity.dart';
import '../entities/user_entity.dart';

abstract class TransferRepository {
  Future<UserEntity> getOrCreateIdentity();
  Future<UserEntity> registerUser(UserEntity user);

  Future<void> sendFiles({
    required String senderCode,
    required String receiverCode,
    required List<SelectedFileEntity> files,
    required void Function(String fileId, double progress) onFileProgress,
  });

  Stream<TransferEntity> listenTransfers(String receiverCode);

  Future<void> downloadTransfer({
    required TransferEntity transfer,
    required void Function(String fileId, double progress) onFileProgress,
  });

  Future<bool> recipientExists(String recipientCode);

  Future<bool> isTransferProcessed(String transferId);
  Future<void> markTransferProcessed(String transferId);

  Future<List<SelectedFileEntity>> pickFiles();
}
