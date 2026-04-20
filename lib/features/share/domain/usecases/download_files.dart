import 'package:injectable/injectable.dart';

import '../entities/transfer_entity.dart';
import '../repositories/transfer_repository.dart';

@injectable
class DownloadFiles {
  final TransferRepository repository;
  DownloadFiles(this.repository);

  Future<void> call({
    required TransferEntity transfer,
    required void Function(String fileId, double progress) onFileProgress,
  }) {
    return repository.downloadTransfer(
      transfer: transfer,
      onFileProgress: onFileProgress,
    );
  }
}
