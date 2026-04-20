import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/app_config.dart';
import '../models/transfer_model.dart';
import '../models/user_model.dart';

@lazySingleton
class FirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSource(this._firestore);

  Future<void> upsertUser(UserModel user) async {
    await _firestore.collection(AppConfig.usersCollection).doc(user.code).set({
      ...user.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserModel?> getUserByCode(String code) async {
    final doc = await _firestore
        .collection(AppConfig.usersCollection)
        .doc(code)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<String> createTransfer(TransferModel transfer) async {
    final ref = await _firestore
        .collection(AppConfig.transfersCollection)
        .add(transfer.toMap());
    return ref.id;
  }

  Stream<TransferModel> listenTransfers(String receiverCode) {
    return _firestore
        .collection(AppConfig.transfersCollection)
        .where('receiverCode', isEqualTo: receiverCode)
        .where('status', whereIn: <String>['pending', 'sent'])
        .snapshots()
        .expand((snapshot) => snapshot.docs)
        .map(TransferModel.fromDoc)
        .where((transfer) => transfer.ttl.isAfter(DateTime.now().toUtc()));
  }

  Future<TransferModel?> getTransferById(String transferId) async {
    final doc = await _firestore
        .collection(AppConfig.transfersCollection)
        .doc(transferId)
        .get();
    if (!doc.exists) return null;
    return TransferModel.fromDoc(doc);
  }

  Future<void> updateTransferStatus(String transferId, String status) async {
    await _firestore
        .collection(AppConfig.transfersCollection)
        .doc(transferId)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> queueFcmTrigger({
    required String receiverCode,
    required String transferId,
    required String senderCode,
  }) async {
    await _firestore.collection(AppConfig.notificationQueueCollection).add({
      'receiverCode': receiverCode,
      'transferId': transferId,
      'senderCode': senderCode,
      'type': 'incoming_transfer',
      'createdAt': FieldValue.serverTimestamp(),
      // TODO: Process this collection with Firebase Cloud Functions to send FCM.
    });
  }
}
