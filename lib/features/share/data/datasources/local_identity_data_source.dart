import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/app_config.dart';

@lazySingleton
class LocalIdentityDataSource {
  Future<String?> getUserCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.localUserCodeKey);
  }

  Future<void> saveUserCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.localUserCodeKey, code);
  }

  Future<bool> isTransferProcessed(String transferId) async {
    final prefs = await SharedPreferences.getInstance();
    final list =
        prefs.getStringList(AppConfig.processedTransfersKey) ?? <String>[];
    return list.contains(transferId);
  }

  Future<void> markTransferProcessed(String transferId) async {
    final prefs = await SharedPreferences.getInstance();
    final list =
        prefs.getStringList(AppConfig.processedTransfersKey) ?? <String>[];
    if (!list.contains(transferId)) {
      list.add(transferId);
      await prefs.setStringList(AppConfig.processedTransfersKey, list);
    }
  }
}
