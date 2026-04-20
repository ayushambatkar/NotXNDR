import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/config/injection.dart';
import 'features/share/data/datasources/fcm_service.dart';
import 'features/share/data/datasources/firestore_data_source.dart';
import 'features/share/domain/usecases/pick_files.dart';
import 'features/share/presentation/bloc/transfer_bloc.dart';
import 'features/share/presentation/bloc/transfer_event.dart';
import 'features/share/presentation/pages/home_page.dart';
import 'features/share/presentation/pages/transfer_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(FcmService.backgroundHandler);

  var firebaseReady = true;
  String? setupError;
  try {
    await Firebase.initializeApp();
    if (!AppConfig.hasSupabaseConfig) {
      throw Exception(
        'Missing Supabase config. Pass --dart-define SUPABASE_URL, SUPABASE_ANON_KEY and optional SUPABASE_STORAGE_BUCKET.',
      );
    }
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    configureDependencies();
    getIt<FcmService>();
  } catch (e) {
    firebaseReady = false;
    setupError = e.toString();
  }

  runApp(MyApp(firebaseReady: firebaseReady, setupError: setupError));
}

class MyApp extends StatelessWidget {
  final bool firebaseReady;
  final String? setupError;

  const MyApp({
    super.key,
    required this.firebaseReady,
    required this.setupError,
  });

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('NeoSapien Share Setup')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Backend is not configured yet. Ensure Firebase (FCM/Firestore) and Supabase (Storage) are configured, then rebuild.\n\nDetails: $setupError',
            ),
          ),
        ),
      );
    }

    final bloc = getIt<TransferBloc>();
    final pickFiles = getIt<PickFiles>();
    final fcm = getIt<FcmService>();
    final firestore = getIt<FirestoreDataSource>();

    return BlocProvider(
      create: (_) => bloc,
      child: _AppShell(pickFiles: pickFiles, fcm: fcm, firestore: firestore),
    );
  }
}

class _AppShell extends StatefulWidget {
  final PickFiles pickFiles;
  final FcmService fcm;
  final FirestoreDataSource firestore;

  const _AppShell({
    required this.pickFiles,
    required this.fcm,
    required this.firestore,
  });

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  StreamSubscription<String>? _tapSub;
  StreamSubscription<String>? _fgSub;
  late final GoRouter _router;

  TransferBloc get _bloc => context.read<TransferBloc>();

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomePage(pickFiles: widget.pickFiles),
        ),
        GoRoute(
          path: '/transfer',
          builder: (context, state) => const TransferPage(),
        ),
      ],
    );
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final initialId = await widget.fcm.getInitialTransferId();
    if (initialId != null && initialId.isNotEmpty) {
      final transfer = await widget.firestore.getTransferById(initialId);
      if (transfer != null) {
        _bloc.add(ReceiveTransfer(transfer));
        if (mounted) _router.go('/transfer');
      }
    }

    _tapSub = widget.fcm.onTransferTapped.listen((id) async {
      final transfer = await widget.firestore.getTransferById(id);
      if (transfer != null) {
        _bloc.add(ReceiveTransfer(transfer));
        if (mounted) _router.go('/transfer');
      }
    });

    _fgSub = widget.fcm.onForegroundTransfer.listen((id) async {
      final transfer = await widget.firestore.getTransferById(id);
      if (transfer != null) {
        _bloc.add(ReceiveTransfer(transfer));
        if (mounted) _router.go('/transfer');
      }
    });
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    _fgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NeoSapien Share',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      routerConfig: _router,
    );
  }
}
