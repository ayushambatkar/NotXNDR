import 'transfer_file_entity.dart';

class TransferEntity {
  final String id;
  final String senderCode;
  final String receiverCode;
  final List<TransferFileEntity> files;
  final String status;
  final DateTime createdAt;
  final DateTime ttl;

  const TransferEntity({
    required this.id,
    required this.senderCode,
    required this.receiverCode,
    required this.files,
    required this.status,
    required this.createdAt,
    required this.ttl,
  });
}
