import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';

class UploadResult {
  final String url;

  const UploadResult({required this.url});
}

@lazySingleton
class StorageDataSource {
  final SupabaseClient _supabase;

  StorageDataSource(this._supabase);

  Future<UploadResult> uploadFile({
    required String transferId,
    required String fileId,
    required File file,
    required void Function(double progress) onProgress,
  }) async {
    final objectPath = '${AppConfig.storageRoot}/$transferId/$fileId';
    final bucket = _supabase.storage.from(AppConfig.supabaseStorageBucket);
    try {
      await bucket.upload(
        objectPath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      onProgress(1);

      final url = bucket.getPublicUrl(objectPath);
      return UploadResult(url: url);
    } on StorageException catch (e) {
      throw _mapStorageException(e);
    }
  }

  Future<void> downloadFile({
    required String url,
    required File target,
    required void Function(double progress) onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw NetworkException(
          'Download failed with status ${response.statusCode}.',
        );
      }

      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = target.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            onProgress(received / total);
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      if (total == 0) {
        onProgress(1);
      }
    } finally {
      client.close();
    }

    if (!await target.exists()) {
      throw const NetworkException('Downloaded file was not written to disk.');
    }
  }

  AppException _mapStorageException(StorageException e) {
    final message = e.message.toLowerCase();

    if (message.contains('permission') || message.contains('unauthorized')) {
      return const PermissionException(
        'Supabase Storage permission denied. Update Storage policies.',
      );
    }

    if (message.contains('not found') || message.contains('does not exist')) {
      return const ValidationException(
        'Supabase storage object/bucket not found. Check bucket config.',
      );
    }

    if (message.contains('canceled') || message.contains('cancelled')) {
      return const NetworkException('Upload interrupted. Please retry.');
    }

    return NetworkException('Storage error: ${e.message}');
  }
}
