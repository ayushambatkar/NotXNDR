// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:neosapien/core/config/injectable_module.dart' as _i16;
import 'package:neosapien/features/share/data/datasources/fcm_service.dart'
    as _i534;
import 'package:neosapien/features/share/data/datasources/file_picker_data_source.dart'
    as _i323;
import 'package:neosapien/features/share/data/datasources/firestore_data_source.dart'
    as _i342;
import 'package:neosapien/features/share/data/datasources/local_identity_data_source.dart'
    as _i815;
import 'package:neosapien/features/share/data/datasources/storage_data_source.dart'
    as _i1003;
import 'package:neosapien/features/share/data/repositories/transfer_repository_impl.dart'
    as _i204;
import 'package:neosapien/features/share/domain/repositories/transfer_repository.dart'
    as _i730;
import 'package:neosapien/features/share/domain/usecases/download_files.dart'
    as _i155;
import 'package:neosapien/features/share/domain/usecases/get_or_create_identity.dart'
    as _i707;
import 'package:neosapien/features/share/domain/usecases/listen_transfers.dart'
    as _i194;
import 'package:neosapien/features/share/domain/usecases/pick_files.dart'
    as _i901;
import 'package:neosapien/features/share/domain/usecases/register_user.dart'
    as _i829;
import 'package:neosapien/features/share/domain/usecases/send_files.dart'
    as _i419;
import 'package:neosapien/features/share/presentation/bloc/transfer_bloc.dart'
    as _i474;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final injectableModule = _$InjectableModule();
    gh.lazySingleton<_i974.FirebaseFirestore>(() => injectableModule.firestore);
    gh.lazySingleton<_i454.SupabaseClient>(
      () => injectableModule.supabaseClient,
    );
    gh.lazySingleton<_i892.FirebaseMessaging>(() => injectableModule.messaging);
    gh.lazySingleton<_i815.LocalIdentityDataSource>(
      () => _i815.LocalIdentityDataSource(),
    );
    gh.lazySingleton<_i534.FcmService>(
      () => _i534.FcmService(gh<_i892.FirebaseMessaging>()),
    );
    gh.lazySingleton<_i323.FilePickerPort>(() => _i323.FilePickerDataSource());
    gh.lazySingleton<_i1003.StorageDataSource>(
      () => _i1003.StorageDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i342.FirestoreDataSource>(
      () => _i342.FirestoreDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.singleton<_i730.TransferRepository>(
      () => _i204.TransferRepositoryImpl(
        localIdentity: gh<_i815.LocalIdentityDataSource>(),
        firestore: gh<_i342.FirestoreDataSource>(),
        storage: gh<_i1003.StorageDataSource>(),
        fcm: gh<_i534.FcmService>(),
        filePicker: gh<_i323.FilePickerPort>(),
      ),
    );
    gh.factory<_i155.DownloadFiles>(
      () => _i155.DownloadFiles(gh<_i730.TransferRepository>()),
    );
    gh.factory<_i707.GetOrCreateIdentity>(
      () => _i707.GetOrCreateIdentity(gh<_i730.TransferRepository>()),
    );
    gh.factory<_i194.ListenTransfers>(
      () => _i194.ListenTransfers(gh<_i730.TransferRepository>()),
    );
    gh.factory<_i901.PickFiles>(
      () => _i901.PickFiles(gh<_i730.TransferRepository>()),
    );
    gh.factory<_i829.RegisterUser>(
      () => _i829.RegisterUser(gh<_i730.TransferRepository>()),
    );
    gh.factory<_i419.SendFilesUseCase>(
      () => _i419.SendFilesUseCase(gh<_i730.TransferRepository>()),
    );
    gh.factory<_i474.TransferBloc>(
      () => _i474.TransferBloc(
        getOrCreateIdentity: gh<_i707.GetOrCreateIdentity>(),
        sendFilesUseCase: gh<_i419.SendFilesUseCase>(),
        listenTransfersUseCase: gh<_i194.ListenTransfers>(),
        downloadFilesUseCase: gh<_i155.DownloadFiles>(),
      ),
    );
    return this;
  }
}

class _$InjectableModule extends _i16.InjectableModule {}
