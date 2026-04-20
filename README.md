# NotXNDR

#### neosapien assignment

Minimal mobile file sharing app (sender/receiver code based) using Flutter, BLoC, Firebase (FCM + Firestore), and Supabase Storage.

## Limits

- One-time transfer max file size: 50MB per file

## Permissions (Required)

1. Enable notifications on both phones (required for transfer alerts/background trigger).
2. On receiver phone, allow storage access when prompted after app install/download.
3. On Android 11+, if asked, allow "All files access" so files can be saved to Downloads directory.

## Transfer Notes

- Receiver files are saved to Downloads directory.
- Transfers are intended to be one-time.
- Supabase uploaded objects should be deleted after transfer completion (do not keep them indefinitely).
