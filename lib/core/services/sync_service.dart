import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../database/hive_service.dart';
import '../network/dio_client.dart';
import '../sync/sync_queue.dart';
import '../../features/notes/domain/entities/note.dart';
import '../../features/notes/data/models/note_model.dart';

class SyncService {
  SyncService(
    this._hiveService,
    this._dioClient,
    this._queue, [
    Future<bool> Function()? onlineChecker,
    Connectivity? connectivity,
  ]) : _connectivity = connectivity ?? Connectivity(),
       _onlineChecker = onlineChecker;

  final HiveService _hiveService;
  final DioClient _dioClient;
  final SyncQueue _queue;
  final Connectivity _connectivity;
  final Future<bool> Function()? _onlineChecker;
  bool _syncInProgress = false;
  bool _syncAgain = false;

  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged.map((results) {
        if (results.isEmpty) {
          return ConnectivityResult.none;
        }
        return results.first;
      });

  Future<bool> get isOnline async {
    if (_onlineChecker != null) {
      return _onlineChecker();
    }
    final result = await _connectivity.checkConnectivity();
    return result.any((item) => item != ConnectivityResult.none);
  }

  Future<void> syncNow() async {
    if (_syncInProgress) {
      _syncAgain = true;
      return;
    }
    _syncInProgress = true;
    try {
      await _syncNow();
    } finally {
      _syncInProgress = false;
      if (_syncAgain) {
        _syncAgain = false;
        unawaited(syncNow());
      }
    }
  }

  Future<void> _syncNow() async {
    if (!await isOnline) {
      return;
    }
    final now = DateTime.now();
    final entries = (await _queue.readAll())
        .where(
          (entry) =>
              entry.nextAttemptAt == null || !entry.nextAttemptAt!.isAfter(now),
        )
        .toList();
    for (final entry in entries) {
      try {
        final response = await _process(entry);
        await _markLocalOperationSynced(entry, response);
        await _queue.remove(entry.id);
      } on DioException catch (error) {
        developer.log(
          'Sync failed (${entry.action} ${entry.noteId}): ${error.message}; response=${error.response?.statusCode}',
        );
        if (error.response?.statusCode == 409) {
          await _markConflict(entry.noteId);
          await _queue.remove(entry.id);
          continue;
        }
        final nextEntry = SyncQueueEntry(
          id: entry.id,
          action: entry.action,
          noteId: entry.noteId,
          payload: entry.payload,
          createdAt: entry.createdAt,
          retryCount: entry.retryCount + 1,
          nextAttemptAt: DateTime.now().add(_retryDelay(entry.retryCount + 1)),
        );
        await _queue.upsert(nextEntry);
      } catch (error) {
        developer.log('Sync failed (${entry.action} ${entry.noteId}): $error');
        final nextEntry = SyncQueueEntry(
          id: entry.id,
          action: entry.action,
          noteId: entry.noteId,
          payload: entry.payload,
          createdAt: entry.createdAt,
          retryCount: entry.retryCount + 1,
          nextAttemptAt: DateTime.now().add(_retryDelay(entry.retryCount + 1)),
        );
        await _queue.upsert(nextEntry);
      }
    }
    await _pullRemoteNotes();
  }

  Future<Response<dynamic>?> _process(SyncQueueEntry entry) async {
    final noteId = entry.noteId;
    final payload = entry.payload;
    switch (entry.action) {
      case 'create':
        final url = '${AppConfig.baseUrl}/notes';
        return _dioClient.dio.post(url, data: payload);
      case 'update':
        final url = '${AppConfig.baseUrl}/notes/$noteId';
        return _dioClient.dio.put(url, data: payload);
      case 'delete':
        final url = '${AppConfig.baseUrl}/notes/$noteId';
        return _dioClient.dio.delete(url);
    }
    return null;
  }

  Future<void> _pullRemoteNotes() async {
    try {
      final url = '${AppConfig.baseUrl}/notes';
      final response = await _dioClient.dio.get(url);
      final remoteNotes = (response.data as List)
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
      final localBox = _hiveService.notesBox;
      final remoteIds = remoteNotes.map((note) => note.id).toSet();
      for (final note in remoteNotes) {
        final local = localBox.get(note.id);
        if (local is NoteModel) {
          final localNote = local.toEntity();
          if (localNote.syncStatus == SyncStatus.pending &&
              localNote.serverUpdatedAt != null &&
              note.updatedAt.isAfter(localNote.serverUpdatedAt!)) {
            await localBox.put(
              note.id,
              NoteModel.fromEntity(
                localNote.copyWith(
                  syncStatus: SyncStatus.conflict,
                  conflictTitle: note.title,
                  conflictBody: note.body,
                  conflictUpdatedAt: note.updatedAt,
                ),
              ),
            );
            await _queue.removeForNote(note.id);
            continue;
          }
          if (localNote.syncStatus != SyncStatus.synced) {
            continue;
          }
        }
        await localBox.put(
          note.id,
          NoteModel.fromEntity(
            note.copyWith(
              syncStatus: SyncStatus.synced,
              serverUpdatedAt: note.updatedAt,
              lastSyncedAt: DateTime.now(),
              clearConflict: true,
            ),
          ),
        );
      }
      for (final value in localBox.values.whereType<NoteModel>()) {
        final local = value.toEntity();
        if (!remoteIds.contains(local.id) &&
            local.syncStatus == SyncStatus.synced &&
            !local.isDeleted) {
          await localBox.put(
            local.id,
            NoteModel.fromEntity(local.copyWith(isDeleted: true)),
          );
        }
      }
    } on DioException catch (error) {
      developer.log(
        'Sync pull failed: ${error.message}; response=${error.response?.statusCode}',
      );
      // Keep the local state and let the next sync attempt refresh it.
    }
  }

  Future<void> _markLocalOperationSynced(
    SyncQueueEntry entry,
    Response<dynamic>? response,
  ) async {
    final value = _hiveService.notesBox.get(entry.noteId);
    if (value is! NoteModel) return;
    if (entry.action == 'delete') {
      await _hiveService.notesBox.put(
        entry.noteId,
        NoteModel.fromEntity(
          value.toEntity().copyWith(
            isDeleted: true,
            syncStatus: SyncStatus.synced,
            lastSyncedAt: DateTime.now(),
            clearConflict: true,
          ),
        ),
      );
      return;
    }
    final remote = response?.data is Map<String, dynamic>
        ? Note.fromJson(response!.data as Map<String, dynamic>)
        : null;
    await _hiveService.notesBox.put(
      entry.noteId,
      NoteModel.fromEntity(
        value.toEntity().copyWith(
          syncStatus: SyncStatus.synced,
          lastSyncedAt: DateTime.now(),
          serverUpdatedAt: remote?.updatedAt ?? value.toEntity().updatedAt,
          clearConflict: true,
        ),
      ),
    );
  }

  Future<void> _markConflict(String noteId) async {
    final value = _hiveService.notesBox.get(noteId);
    if (value is NoteModel) {
      await _hiveService.notesBox.put(
        noteId,
        NoteModel.fromEntity(
          value.toEntity().copyWith(syncStatus: SyncStatus.conflict),
        ),
      );
    }
  }

  Duration _retryDelay(int retryCount) {
    final seconds = 5 * (1 << (retryCount.clamp(0, 6)));
    return Duration(seconds: seconds > 300 ? 300 : seconds);
  }
}
