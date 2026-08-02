import 'dart:convert';

import 'package:hive/hive.dart';

import '../database/hive_service.dart';

class SyncQueueEntry {
  SyncQueueEntry({
    required this.id,
    required this.action,
    required this.noteId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.nextAttemptAt,
  });

  final String id;
  final String action;
  final String noteId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? nextAttemptAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'noteId': noteId,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'nextAttemptAt': nextAttemptAt?.toIso8601String(),
  };

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) {
    return SyncQueueEntry(
      id: json['id'] as String,
      action: json['action'] as String,
      noteId: json['noteId'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      nextAttemptAt: json['nextAttemptAt'] == null
          ? null
          : DateTime.parse(json['nextAttemptAt'] as String),
    );
  }
}

class SyncQueue {
  SyncQueue(this._hiveService);

  final HiveService _hiveService;

  Box<dynamic> get _queueBox => _hiveService.queueBox;

  Future<void> enqueue(SyncQueueEntry entry) async {
    await _queueBox.put(entry.id, jsonEncode(entry.toJson()));
  }

  Future<void> upsert(SyncQueueEntry entry) async {
    await _queueBox.put(entry.id, jsonEncode(entry.toJson()));
  }

  Future<List<SyncQueueEntry>> readAll() async {
    return _queueBox.values
        .map(
          (value) => SyncQueueEntry.fromJson(
            jsonDecode(value as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> remove(String id) async {
    await _queueBox.delete(id);
  }

  Future<void> removeForNote(String noteId) async {
    for (final entry in await readAll()) {
      if (entry.noteId == noteId) {
        await remove(entry.id);
      }
    }
  }

  Future<void> clear() async {
    await _queueBox.clear();
  }
}
