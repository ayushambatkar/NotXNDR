import 'package:injectable/injectable.dart';

import '../entities/transfer_entity.dart';
import '../repositories/transfer_repository.dart';

@injectable
class ListenTransfers {
  final TransferRepository repository;
  ListenTransfers(this.repository);

  Stream<TransferEntity> call(String receiverCode) {
    return repository.listenTransfers(receiverCode);
  }
}
