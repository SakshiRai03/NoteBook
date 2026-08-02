import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/database/hive_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../models/note_model.dart';

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(
    this._hiveService,
    this._dioClient,
    this._queue, [
    this._syncTrigger,
  ]);

  final HiveService _hiveService;
  final DioClient _dioClient;
  final SyncQueue _queue;
  final Future<void> Function()? _syncTrigger;

  Box<dynamic> get _notesBox => _hiveService.notesBox;

  @override
  Future<List<Note>> getNotes() async {
    final cached = _notesBox.values
        .cast<NoteModel>()
        .map((model) => model.toEntity())
        .toList();
    if (cached.isNotEmpty) {
      return cached.where((note) => !note.isDeleted).toList();
    }
    return refreshFromRemote();
  }

  @override
  Future<Note> createNote(Note note) async {
    final model = NoteModel.fromEntity(
      note.copyWith(syncStatus: SyncStatus.pending),
    );
    await _notesBox.put(model.id, model);
    await _queue.enqueue(
      SyncQueueEntry(
        id: '${model.id}-${DateTime.now().microsecondsSinceEpoch}',
        action: 'create',
        noteId: model.id,
        payload: model.toEntity().toJson(),
        createdAt: DateTime.now(),
      ),
    );
    // Both Hive writes are awaited before triggering sync, so this operation
    // cannot be missed by a sync that starts immediately after the write.
    await _triggerSync();
    return model.toEntity();
  }

  @override
  Future<Note> updateNote(Note note) async {
    final model = NoteModel.fromEntity(
      note.copyWith(syncStatus: SyncStatus.pending),
    );
    await _notesBox.put(model.id, model);
    await _queue.enqueue(
      SyncQueueEntry(
        id: '${model.id}-${DateTime.now().microsecondsSinceEpoch}',
        action: 'update',
        noteId: model.id,
        payload: model.toEntity().toJson(),
        createdAt: DateTime.now(),
      ),
    );
    await _triggerSync();
    return model.toEntity();
  }

  @override
  Future<void> deleteNote(String id) async {
    final existing = _notesBox.get(id);
    if (existing is NoteModel) {
      await _notesBox.put(
        id,
        NoteModel.fromEntity(
          existing.toEntity().copyWith(
            isDeleted: true,
            syncStatus: SyncStatus.pending,
          ),
        ),
      );
      await _queue.enqueue(
        SyncQueueEntry(
          id: '$id-${DateTime.now().microsecondsSinceEpoch}',
          action: 'delete',
          noteId: id,
          payload: {'id': id},
          createdAt: DateTime.now(),
        ),
      );
      await _triggerSync();
    }
  }

  Future<void> _triggerSync() async {
    await _syncTrigger?.call();
  }

  @override
  Future<List<Note>> refreshFromRemote() async {
    try {
      final response = await _dioClient.dio.get('${AppConfig.baseUrl}/notes');
      final remoteNotes = (response.data as List)
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
      final localNotes = _notesBox.values
          .cast<NoteModel>()
          .map((model) => model.toEntity())
          .toList();
      final merged = <String, Note>{};
      final localMap = {for (final note in localNotes) note.id: note};

      for (final remoteNote in remoteNotes) {
        final localNote = localMap[remoteNote.id];
        if (localNote != null && localNote.syncStatus != SyncStatus.synced) {
          final localChanged =
              localNote.serverUpdatedAt != null &&
              remoteNote.updatedAt.isAfter(localNote.serverUpdatedAt!);
          final preserved = localChanged
              ? localNote.copyWith(
                  syncStatus: SyncStatus.conflict,
                  conflictTitle: remoteNote.title,
                  conflictBody: remoteNote.body,
                  conflictUpdatedAt: remoteNote.updatedAt,
                )
              : localNote;
          await _notesBox.put(preserved.id, NoteModel.fromEntity(preserved));
          merged[remoteNote.id] = preserved;
          continue;
        }

        final resolved =
            localNote == null || localNote.syncStatus == SyncStatus.synced
            ? remoteNote
            : localNote;
        merged[resolved.id] = resolved.copyWith(
          syncStatus: SyncStatus.synced,
          serverUpdatedAt: remoteNote.updatedAt,
          lastSyncedAt: DateTime.now(),
          clearConflict: true,
        );
      }

      for (final localNote in localNotes) {
        if (!merged.containsKey(localNote.id)) {
          merged[localNote.id] = localNote.copyWith(
            syncStatus: SyncStatus.synced,
          );
        }
      }

      for (final entry in merged.entries) {
        await _notesBox.put(entry.key, NoteModel.fromEntity(entry.value));
      }
      return merged.values.where((note) => !note.isDeleted).toList();
    } on DioException catch (_) {
      final cached = _notesBox.values
          .cast<NoteModel>()
          .map((model) => model.toEntity())
          .where((note) => !note.isDeleted)
          .toList();
      return cached;
    }
  }

  @override
  Future<Note> resolveConflict(
    String id, {
    required bool keepLocal,
    Note? remoteNote,
  }) async {
    final existing = _notesBox.get(id);
    if (existing is! NoteModel) {
      throw StateError('Cannot resolve a missing note');
    }

    final localNote = existing.toEntity();
    if (keepLocal) {
      final persisted = localNote.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        clearConflict: true,
      );
      await _notesBox.put(id, NoteModel.fromEntity(persisted));
      await _queue.enqueue(
        SyncQueueEntry(
          id: '$id-${DateTime.now().microsecondsSinceEpoch}',
          action: 'update',
          noteId: id,
          payload: persisted.toJson(),
          createdAt: DateTime.now(),
        ),
      );
      return persisted;
    }

    final remote = remoteNote ?? await _fetchRemoteNote(id);
    final persisted = remote.copyWith(
      syncStatus: SyncStatus.synced,
      serverUpdatedAt: remote.updatedAt,
      lastSyncedAt: DateTime.now(),
      clearConflict: true,
    );
    await _notesBox.put(id, NoteModel.fromEntity(persisted));

    return persisted;
  }

  Future<Note> _fetchRemoteNote(String id) async {
    final response = await _dioClient.dio.get('${AppConfig.baseUrl}/notes/$id');
    return Note.fromJson(response.data as Map<String, dynamic>);
  }
}
