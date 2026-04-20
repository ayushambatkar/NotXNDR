import 'package:injectable/injectable.dart';

import '../entities/user_entity.dart';
import '../repositories/transfer_repository.dart';

@injectable
class GetOrCreateIdentity {
  final TransferRepository repository;
  GetOrCreateIdentity(this.repository);

  Future<UserEntity> call() => repository.getOrCreateIdentity();
}
