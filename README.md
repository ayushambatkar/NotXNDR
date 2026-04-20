# NotXNDR

#### neosapien assignment

Minimal mobile file sharing app (sender/receiver code based) using Flutter, BLoC, Firebase (FCM + Firestore), and Supabase Storage.

## Working

### How transfers are done

1. Sender picks files (max 50MB each).
2. Each file is hashed (SHA-256), then uploaded to Supabase Storage at `transfers/{transferId}/{fileId}`.
3. A Firestore transfer document is created with sender/receiver codes, file metadata, hash, status, TTL, and storage paths.
4. Receiver gets notified through Firestore realtime listener (and FCM trigger path when configured).
5. Receiver downloads files to phone Download directory, verifies SHA-256, then marks transfer completed.
6. Uploaded Supabase objects are deleted after transfer completion/failure to avoid storage pile-up.

### How things are wired

- `TransferBloc` handles send/receive/progress states.
- Use cases call `TransferRepositoryImpl`.
- `FirestoreDataSource` manages transfer metadata + realtime listen.
- `FcmService` handles notification token and message hooks.
- `StorageDataSource` handles Supabase upload/download/delete.

### How it is configured

- Single source of truth: `lib/core/config/app_config.dart`.
- Startup in `lib/main.dart` initializes Firebase + Supabase, then DI (`get_it` + `injectable`).
- Supabase values are read from dart defines:
	- `SUPABASE_URL`
	- `SUPABASE_ANON_KEY`
	- `SUPABASE_STORAGE_BUCKET`
- Firestore and Supabase policies must allow required read/write/delete operations.

## Limits

- One-time transfer max file size: 50MB per file

## Permissions (Required)

1. Enable notifications on both phones (required for transfer alerts/background trigger).
2. On receiver phone, allow storage access when prompted after app install/download.
3. On Android 11+, if asked, allow "All files access" so files can be saved to Downloads directory.

## Transfer Notes

- Receiver files are saved to Downloads directory.
- Transfers are intended to be one-time.
