import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FcmService {
  final FirebaseMessaging _messaging;

  FcmService(this._messaging);

  static Future<void> backgroundHandler(RemoteMessage message) async {
    // Keep background handler lightweight; transfer details are fetched from Firestore.
  }

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTransferTapped => FirebaseMessaging.onMessageOpenedApp
      .map((m) => m.data['transferId'] as String?)
      .where((id) => id != null && id.isNotEmpty)
      .cast<String>();

  Stream<String> get onForegroundTransfer => FirebaseMessaging.onMessage
      .map((m) => m.data['transferId'] as String?)
      .where((id) => id != null && id.isNotEmpty)
      .cast<String>();

  Future<String?> getInitialTransferId() async {
    final initial = await _messaging.getInitialMessage();
    return initial?.data['transferId'] as String?;
  }
}
