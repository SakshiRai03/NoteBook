import 'package:hive/hive.dart';

import '../../domain/entities/note.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    required this.syncStatus,
    required this.isDeleted,
    this.lastSyncedAt,
    this.serverUpdatedAt,
    this.conflictTitle,
    this.conflictBody,
    this.conflictUpdatedAt,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String body;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  String syncStatus;

  @HiveField(5)
  bool isDeleted;

  @HiveField(6)
  DateTime? lastSyncedAt;

  @HiveField(7)
  DateTime? serverUpdatedAt;

  @HiveField(8)
  String? conflictTitle;

  @HiveField(9)
  String? conflictBody;

  @HiveField(10)
  DateTime? conflictUpdatedAt;

  Note toEntity() {
    return Note(
      id: id,
      title: title,
      body: body,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.values.firstWhere(
        (value) => value.name == syncStatus,
        orElse: () => SyncStatus.pending,
      ),
      isDeleted: isDeleted,
      lastSyncedAt: lastSyncedAt,
      serverUpdatedAt: serverUpdatedAt,
      conflictTitle: conflictTitle,
      conflictBody: conflictBody,
      conflictUpdatedAt: conflictUpdatedAt,
    );
  }

  static NoteModel fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      syncStatus: note.syncStatus.name,
      isDeleted: note.isDeleted,
      lastSyncedAt: note.lastSyncedAt,
      serverUpdatedAt: note.serverUpdatedAt,
      conflictTitle: note.conflictTitle,
      conflictBody: note.conflictBody,
      conflictUpdatedAt: note.conflictUpdatedAt,
    );
  }
}
