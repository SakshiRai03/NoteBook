# Offline First Notes

An offline-first Flutter notes app using Hive for durable local data, Bloc for presentation state, Dio for HTTP, and json-server as a mock remote API. The UI talks to a repository; the repository writes the note and an operation to Hive, while the separate sync engine pushes queued operations and pulls remote changes when connectivity is available.

```text
Flutter UI -> NotesBloc -> NotesRepository -> Hive (notes + sync queue)
                                      \-> SyncService -> Dio -> json-server/db.json
```

## Setup

```powershell
flutter pub get
npx json-server --watch db.json --host 0.0.0.0
```

Run targets:

```powershell
# Flutter Web, json-server on this computer
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000

# Android emulator
flutter run -d <android-device> --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Physical Android/iOS device; replace with the computer's LAN IPv4 address
flutter run -d <device> --dart-define=API_BASE_URL=http://192.168.1.20:3000
```

For a physical device, the phone and computer must share a network and the firewall must allow TCP port 3000. The Web default is `http://localhost:3000`; the Android emulator must use `10.0.2.2`.

## Sync behavior

Every local write is awaited into both Hive boxes before requesting sync. This prevents a newly-created operation from being missed by a sync that starts immediately. If a write occurs while a sync is already running, the service schedules another pass. Failed operations stay in the queue with backoff.

The app stores the last known remote `updatedAt` as `serverUpdatedAt`. If a locally pending note sees a newer remote timestamp, it is marked Conflict and the remote title/body are retained for the resolution dialog.

## Manually test pull sync

1. Start json-server and the app.
2. Create a note and wait for Synced.
3. Edit that note's `title`, `body`, and `updatedAt` in `db.json` with a newer ISO timestamp.
4. Press refresh or trigger reconnect.
5. The local note updates immediately without restarting the app.

## Manually test a conflict

1. Create and sync a note; note its server `updatedAt`.
2. Edit the note locally while offline, leaving it Pending Sync.
3. Edit the same note in `db.json` with a newer `updatedAt`.
4. Restore connectivity and trigger sync. The note becomes Conflict.
5. Tap it and choose Keep Mine, Keep Server, or Merge Manually.
6. Keep Mine and Merge Manually enqueue a new update and return to Synced after push; Keep Server stores the server version as Synced.

## Known limitations

- json-server is a development mock and has no authentication or real server-side conflict/version enforcement.
- Timestamp conflict detection depends on comparable server timestamps; device clock drift can produce false positives or negatives.
- Retry backoff is in-memory behavior backed by the Hive queue, but there is no background OS scheduler when the app is terminated.
