class AppConfig {
  AppConfig._();

  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
  static const Duration transferTtl = Duration(hours: 24);
  static const int chunkSize = 256 * 1024;

  static const String allowedCodeCharset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static const String usersCollection = 'users';
  static const String transfersCollection = 'transfers';
  static const String notificationQueueCollection = 'notificationQueue';
  static const String storageRoot = 'transfers';

  // Supabase Storage (single source of truth for storage backend config).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://youtlnghnquhdxxuyqmv.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_vtu5F2aiOY0-UZbPJz-pCg_zwdKcoOw',
  );
  static const String supabaseStorageBucket = String.fromEnvironment(
    'SUPABASE_STORAGE_BUCKET',
    defaultValue: 'prod1',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const String localUserCodeKey = 'local_user_code';
  static const String processedTransfersKey = 'processed_transfer_ids';
}
