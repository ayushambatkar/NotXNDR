import 'package:injectable/injectable.dart';

import '../entities/selected_file_entity.dart';
import '../repositories/transfer_repository.dart';

@injectable
class SendFilesUseCase {
  final TransferRepository repository;
  SendFilesUseCase(this.repository);

  Future<void> call({
    required String senderCode,
    required String receiverCode,
    required List<SelectedFileEntity> files,
    required void Function(String fileId, double progress) onFileProgress,
  }) {
    return repository.sendFiles(
      senderCode: senderCode,
      receiverCode: receiverCode,
      files: files,
      onFileProgress: onFileProgress,
    );
  }
}
