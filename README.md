# 📝 NoteBook App

A Flutter-based notes application that works **completely offline** and automatically synchronizes with a mock REST API when connectivity is restored — including automatic **conflict detection and resolution** when the same note is edited both locally and on the server.

---

## ✨ Features

- ✅ Create, edit, delete, and view notes
- ✅ Fully functional offline — every operation is stored locally first
- ✅ Local persistence using **Hive**
- ✅ Automatic background sync when connectivity is restored
- ✅ Real-time sync status per note: **Synced**, **Pending Sync**, **Conflict**
- ✅ Conflict resolution UI — compare local vs server versions and choose **Keep Mine**, **Keep Server**, or **Merge Manually**
- ✅ Mock REST API powered by `json-server`

---

## 🏗️ Architecture

```
UI (Bloc / Riverpod)
      ↓
Repository Layer   ← single source of truth for the UI
      ↓         ↓
 Local DB (Hive)   Remote API (REST via json-server)
      ↑
 Sync Engine  ←──── Connectivity Listener
```

The UI never talks to the network directly — it only reads and writes to the local Hive database. A background **Sync Engine** pushes pending local changes to the server and pulls remote changes down, resolving conflicts where both sides have diverged since the last successful sync.

---

## 📂 Project Structure

```
lib/
 ├── core/
 │    ├── config/          # App configuration (API base URL, etc.)
 │    ├── di/               # Service locator / dependency injection
 │    └── services/         # Sync service, connectivity service, Hive service
 ├── features/
 │    └── notes/
 │         ├── data/            # Repository implementations, local & remote sources
 │         ├── domain/          # Entities, repository contracts
 │         └── presentation/    # Screens, widgets, state management
 └── main.dart
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- Node.js installed (for the mock API)

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Start the mock API server
```bash
npx json-server --watch db.json --host 0.0.0.0 --port 3000
```
Keep this terminal running throughout development/testing.

Verify it's working by visiting `http://localhost:3000/notes` in a browser — you should see a JSON array.

### 3. Run the app

The correct `API_BASE_URL` depends on where you're running the app:

| Run target | Command |
|---|---|
| **Web (Chrome)** | `flutter run -d chrome` *(uses default `http://localhost:3000`)* |
| **Android Emulator** | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` |
| **Physical Device** | `flutter run --dart-define=API_BASE_URL=http://<your-PC-LAN-IP>:3000` (find your IP via `ipconfig`; phone and PC must be on the same Wi-Fi) |

> ⚠️ Using the wrong URL for the wrong platform is the most common source of "sync not working" issues — always match the table above.

---

## 🔄 How Sync Works

1. Every create/edit/delete is saved to Hive **immediately**, regardless of connectivity, and marked `Pending Sync`.
2. When online, the Sync Engine:
   - **Pushes** all pending local notes to the server.
   - **Pulls** the latest notes from the server.
3. For each note, it compares:
   - Whether the **local** copy has unsynced changes (`Pending`)
   - Whether the **server** copy has changed since the last known sync (`serverUpdatedAt`)
4. Based on that comparison:
   - Only local changed → push wins, note becomes `Synced`
   - Only server changed → server data is pulled in, note becomes `Synced`
   - **Both changed → marked `Conflict`**, and the user is prompted to resolve it

---

## ⚔️ Testing Conflict Resolution

To manually trigger a conflict:

1. Create a note in the app and let it sync (`Synced`).
2. Open `db.json` and manually edit that note's `title`/`body`, and set `updatedAt` to a timestamp later than the app's last known sync time.
3. In the app, **while offline**, edit the same note (different text than what you put in `db.json`).
4. Reconnect / trigger sync.
5. The note should now show status **Conflict**. Tap it to open the resolution dialog:
   - **Keep Mine** — pushes your local version, overwriting the server
   - **Keep Server** — discards your local edit, adopts the server version
   - **Merge Manually** — opens an editable form pre-filled with both versions so you can combine them

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Local Storage | Hive |
| State Management | Bloc *(update if using Riverpod)* |
| HTTP Client | Dio |
| Connectivity Detection | connectivity_plus |
| Mock REST API | json-server |

---

## 📌 Known Limitations

- Conflict resolution relies on timestamp comparison (`updatedAt`) — significant clock drift between the client and server could theoretically cause incorrect conflict detection.
- The mock API does not persist across different environments — `db.json` is local to the machine running `json-server`.
- Simultaneous edits from more than two sources (e.g., two offline devices both editing the same note) are resolved pairwise, not as a three-way merge.

---

## 📄 License

This project was built as part of a technical assignment.
