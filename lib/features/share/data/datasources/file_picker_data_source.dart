import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/selected_file_entity.dart';

abstract class FilePickerPort {
  Future<List<SelectedFileEntity>> pickFiles();
}

@LazySingleton(as: FilePickerPort)
class FilePickerDataSource implements FilePickerPort {
  @override
  Future<List<SelectedFileEntity>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return <SelectedFileEntity>[];

    return result.files
        .where((f) => f.path != null)
        .map(
          (f) => SelectedFileEntity(
            id: f.identifier ?? '${f.name}_${f.size}_${f.path}',
            name: f.name,
            path: f.path!,
            size: f.size,
          ),
        )
        .toList();
  }
}

// Bonus scaffold: swap this with a MethodChannel implementation if needed.
class PlatformChannelFilePickerDataSource implements FilePickerPort {
  @override
  Future<List<SelectedFileEntity>> pickFiles() {
    return FilePickerDataSource().pickFiles();
  }
}
