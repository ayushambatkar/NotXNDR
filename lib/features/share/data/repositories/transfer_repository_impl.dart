import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/utils/hash_utils.dart';
import '../../domain/entities/selected_file_entity.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/fcm_service.dart';
import '../datasources/file_picker_data_source.dart';
import '../datasources/firestore_data_source.dart';
import '../datasources/local_identity_data_source.dart';
import '../datasources/storage_data_source.dart';
import '../models/transfer_file_model.dart';
import '../models/transfer_model.dart';
import '../models/user_model.dart';

@Singleton(as: TransferRepository)
class TransferRepositoryImpl implements TransferRepository {
  final LocalIdentityDataSource localIdentity;
  final FirestoreDataSource firestore;
  final StorageDataSource storage;
  final FcmService fcm;
  final FilePickerPort filePicker;

  final Uuid _uuid = const Uuid();

  TransferRepositoryImpl({
    required this.localIdentity,
    required this.firestore,
    required this.storage,
    required this.fcm,
    required this.filePicker,
  });

  bool _isValidUserCode(String? value) {
    if (value == null) return false;
    final pattern = RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6,8}$');
    return pattern.hasMatch(value);
  }

  @override
  Future<UserEntity> getOrCreateIdentity() async {
    try {
      await fcm.initialize();
    } catch (_) {
      // Allow local identity generation even if messaging init fails.
    }

    String code;
    try {
      final storedCode = await localIdentity.getUserCode();
      code = _isValidUserCode(storedCode)
          ? storedCode!
          : CodeGenerator.generate();
      await localIdentity.saveUserCode(code);
    } catch (_) {
      // If local persistence is unavailable, still expose an in-memory code.
      code = CodeGenerator.generate();
    }

    String? token;
    try {
      token = await fcm.getToken();
    } catch (_) {
      token = null;
    }

    final safeToken = (token == null || token.isEmpty)
        ? 'pending-token'
        : token;

    final user = UserModel(code: code, fcmToken: safeToken);

    try {
      await firestore.upsertUser(user);
    } catch (_) {
      // Firestore may be unavailable during initial setup; keep local identity usable.
    }

    return user;
  }

  @override
  Future<UserEntity> registerUser(UserEntity user) async {
    final model = UserModel(code: user.code, fcmToken: user.fcmToken);
    await firestore.upsertUser(model);
    return model;
  }

  @override
  Future<bool> recipientExists(String recipientCode) async {
    final recipient = await firestore.getUserByCode(recipientCode);
    return recipient != null;
  }

  @override
  Future<List<SelectedFileEntity>> pickFiles() => filePicker.pickFiles();

  @override
  Future<void> sendFiles({
    required String senderCode,
    required String receiverCode,
    required List<SelectedFileEntity> files,
    required void Function(String fileId, double progress) onFileProgress,
  }) async {
    if (files.isEmpty) {
      throw const ValidationException('No files selected.');
    }

    if (senderCode == receiverCode) {
      throw const ValidationException(
        'Sender and receiver code cannot be the same.',
      );
    }

    final recipientOk = await recipientExists(receiverCode);
    if (!recipientOk) {
      throw const ValidationException('Recipient code is invalid.');
    }

    for (final file in files) {
      if (file.size > AppConfig.maxFileSizeBytes) {
        throw ValidationException('File ${file.name} exceeds 50MB limit.');
      }
    }

    final transferId = _uuid.v4();
    final uploadedFiles = <TransferFileModel>[];

    try {
      for (final file in files) {
        final local = File(file.path);
        final hash = await HashUtils.sha256File(local);

        final upload = await storage.uploadFile(
          transferId: transferId,
          fileId: file.id,
          file: local,
          onProgress: (progress) => onFileProgress(file.id, progress),
        );

        uploadedFiles.add(
          TransferFileModel(
            id: file.id,
            name: file.name,
            size: file.size,
            hash: hash,
            url: upload.url,
            objectPath: upload.objectPath,
          ),
        );
      }

      final now = DateTime.now().toUtc();
      final transfer = TransferModel(
        id: transferId,
        senderCode: senderCode,
        receiverCode: receiverCode,
        files: uploadedFiles,
        status: 'pending',
        createdAt: now,
        ttl: now.add(AppConfig.transferTtl),
      );

      final createdTransferId = await firestore.createTransfer(transfer);
      await firestore.queueFcmTrigger(
        receiverCode: receiverCode,
        transferId: createdTransferId,
        senderCode: senderCode,
      );
    } catch (e) {
      await _cleanupObjects(
        uploadedFiles.map((f) => f.objectPath).whereType<String>().toList(),
      );
      rethrow;
    }
  }

  @override
  Stream<TransferEntity> listenTransfers(String receiverCode) {
    return firestore.listenTransfers(receiverCode).asyncExpand((
      transfer,
    ) async* {
      final isProcessed = await localIdentity.isTransferProcessed(transfer.id);
      if (!isProcessed) {
        yield transfer;
      }
    });
  }

  @override
  Future<void> downloadTransfer({
    required TransferEntity transfer,
    required void Function(String fileId, double progress) onFileProgress,
  }) async {
    final permission = await _ensureStoragePermission();
    if (!permission) {
      throw const PermissionException('Storage permission denied.');
    }

    final root = await _resolveDownloadDirectory();
    await root.create(recursive: true);
    final objectPaths = transfer.files
        .map(_resolveObjectPath)
        .whereType<String>()
        .toList();

    try {
      await firestore.updateTransferStatus(transfer.id, 'receiving');

      for (final file in transfer.files) {
        if (file.url == null || file.url!.isEmpty) {
          throw ValidationException('File URL missing for ${file.name}.');
        }

        final targetPath = p.join(root.path, '${transfer.id}_${file.name}');
        final target = File(targetPath);

        await storage.downloadFile(
          url: file.url!,
          target: target,
          onProgress: (progress) => onFileProgress(file.id, progress),
        );

        final actualHash = await HashUtils.sha256File(target);
        if (actualHash != file.hash) {
          await firestore.updateTransferStatus(transfer.id, 'corrupted');
          throw HashMismatchException(
            'Hash mismatch detected for ${file.name}.',
          );
        }
      }

      await firestore.updateTransferStatus(transfer.id, 'completed');
      await localIdentity.markTransferProcessed(transfer.id);
    } catch (_) {
      await firestore.updateTransferStatus(transfer.id, 'failed');
      rethrow;
    } finally {
      await _cleanupObjects(objectPaths);
    }
  }

  String? _resolveObjectPath(dynamic file) {
    if (file is TransferFileModel &&
        file.objectPath != null &&
        file.objectPath!.isNotEmpty) {
      return file.objectPath;
    }

    final dynamicObjectPath = (file as dynamic).objectPath as String?;
    if (dynamicObjectPath != null && dynamicObjectPath.isNotEmpty) {
      return dynamicObjectPath;
    }

    final url = (file as dynamic).url as String?;
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final publicIndex = segments.indexOf('public');
    if (publicIndex == -1 || publicIndex + 2 > segments.length) return null;

    // Path format: /storage/v1/object/public/{bucket}/{objectPath...}
    final objectSegments = segments.sublist(publicIndex + 2);
    return objectSegments.join('/');
  }

  Future<void> _cleanupObjects(List<String> objectPaths) async {
    if (objectPaths.isEmpty) return;
    try {
      await storage.deleteObjects(objectPaths.toSet().toList());
    } catch (_) {
      // Cleanup is best-effort to avoid masking transfer result paths.
    }
  }

  @override
  Future<bool> isTransferProcessed(String transferId) {
    return localIdentity.isTransferProcessed(transferId);
  }

  @override
  Future<void> markTransferProcessed(String transferId) {
    return localIdentity.markTransferProcessed(transferId);
  }

  Future<bool> _ensureStoragePermission() async {
    if (Platform.isAndroid) {
      final sdk = _androidSdkInt();

      // Writing to /storage/emulated/0/Download requires broad external access on Android 11+.
      if (sdk >= 30) {
        final status = await Permission.manageExternalStorage.request();
        final granted = status.isGranted || status.isLimited;
        if (!granted && status.isPermanentlyDenied) {
          await openAppSettings();
        }
        return granted;
      }

      final status = await Permission.storage.request();
      final granted = status.isGranted || status.isLimited;

      if (!granted && status.isPermanentlyDenied) {
        await openAppSettings();
      }

      return granted;
    }
    return true;
  }

  int _androidSdkInt() {
    final match = RegExp(
      r'SDK (\d+)',
    ).firstMatch(Platform.operatingSystemVersion);
    return int.tryParse(match?.group(1) ?? '') ?? 34;
  }

  Future<Directory> _resolveDownloadDirectory() async {
    if (Platform.isAndroid) {
      const candidates = <String>[
        '/storage/emulated/0/Download',
        '/sdcard/Download',
      ];
      for (final path in candidates) {
        final dir = Directory(path);
        if (await dir.exists()) {
          return dir;
        }
      }
      return Directory(candidates.first);
    }

    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'neosapien_downloads'));
  }
}
