import '../../domain/entities/transfer_file_entity.dart';

class TransferFileModel extends TransferFileEntity {
  const TransferFileModel({
    required super.id,
    required super.name,
    required super.size,
    required super.hash,
    super.localPath,
    super.url,
    super.objectPath,
  });

  factory TransferFileModel.fromMap(Map<String, dynamic> map) {
    return TransferFileModel(
      id: map['id'] as String,
      name: map['name'] as String,
      size: (map['size'] as num).toInt(),
      hash: map['hash'] as String,
      url: map['url'] as String?,
      objectPath: map['objectPath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'hash': hash,
      'url': url,
      'objectPath': objectPath,
    };
  }
}
