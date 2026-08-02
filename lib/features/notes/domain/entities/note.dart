import 'package:equatable/equatable.dart';

enum SyncStatus { synced, pending, conflict }

class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.isDeleted = false,
    this.lastSyncedAt,
    this.serverUpdatedAt,
    this.conflictTitle,
    this.conflictBody,
    this.conflictUpdatedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;
  final DateTime? lastSyncedAt;
  final DateTime? serverUpdatedAt;
  final String? conflictTitle;
  final String? conflictBody;
  final DateTime? conflictUpdatedAt;

  Note copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
    DateTime? lastSyncedAt,
    DateTime? serverUpdatedAt,
    String? conflictTitle,
    String? conflictBody,
    DateTime? conflictUpdatedAt,
    bool clearConflict = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      conflictTitle: clearConflict ? null : conflictTitle ?? this.conflictTitle,
      conflictBody: clearConflict ? null : conflictBody ?? this.conflictBody,
      conflictUpdatedAt: clearConflict
          ? null
          : conflictUpdatedAt ?? this.conflictUpdatedAt,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncStatus: SyncStatus.values.firstWhere(
        (value) => value.name == (json['syncStatus'] as String? ?? 'pending'),
        orElse: () => SyncStatus.pending,
      ),
      isDeleted: json['isDeleted'] as bool? ?? false,
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.parse(json['lastSyncedAt'] as String),
      serverUpdatedAt: json['serverUpdatedAt'] == null
          ? null
          : DateTime.parse(json['serverUpdatedAt'] as String),
      conflictTitle: json['conflictTitle'] as String?,
      conflictBody: json['conflictBody'] as String?,
      conflictUpdatedAt: json['conflictUpdatedAt'] == null
          ? null
          : DateTime.parse(json['conflictUpdatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.name,
      'isDeleted': isDeleted,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'serverUpdatedAt': serverUpdatedAt?.toIso8601String(),
      'conflictTitle': conflictTitle,
      'conflictBody': conflictBody,
      'conflictUpdatedAt': conflictUpdatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    updatedAt,
    syncStatus,
    isDeleted,
    lastSyncedAt,
    serverUpdatedAt,
    conflictTitle,
    conflictBody,
    conflictUpdatedAt,
  ];
}
