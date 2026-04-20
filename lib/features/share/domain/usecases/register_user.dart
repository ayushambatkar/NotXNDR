import 'package:injectable/injectable.dart';

import '../entities/user_entity.dart';
import '../repositories/transfer_repository.dart';

@injectable
class RegisterUser {
  final TransferRepository repository;
  RegisterUser(this.repository);

  Future<UserEntity> call(UserEntity user) => repository.registerUser(user);
}
