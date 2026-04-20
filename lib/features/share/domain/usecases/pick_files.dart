import 'package:injectable/injectable.dart';

import '../entities/selected_file_entity.dart';
import '../repositories/transfer_repository.dart';

@injectable
class PickFiles {
  final TransferRepository repository;
  PickFiles(this.repository);

  Future<List<SelectedFileEntity>> call() => repository.pickFiles();
}
