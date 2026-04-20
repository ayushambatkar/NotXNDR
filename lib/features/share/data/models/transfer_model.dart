import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/transfer_entity.dart';
import 'transfer_file_model.dart';

class TransferModel extends TransferEntity {
  const TransferModel({
    required super.id,
    required super.senderCode,
    required super.receiverCode,
    required List<TransferFileModel> super.files,
    required super.status,
    required super.createdAt,
    required super.ttl,
  });

  factory TransferModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    final files = (map['fileMeta'] as List<dynamic>? ?? <dynamic>[])
        .map(
          (item) =>
              TransferFileModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    return TransferModel(
      id: doc.id,
      senderCode: map['senderCode'] as String? ?? '',
      receiverCode: map['receiverCode'] as String? ?? '',
      files: files,
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ttl: (map['ttl'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderCode': senderCode,
      'receiverCode': receiverCode,
      'fileUrls': files.map((e) => e.url).whereType<String>().toList(),
      'fileMeta': files.map((e) => (e as TransferFileModel).toMap()).toList(),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'ttl': Timestamp.fromDate(ttl),
    };
  }
}
