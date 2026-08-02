import 'package:equatable/equatable.dart';

import '../../domain/entities/note.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotes extends NotesEvent {}

class CreateNoteRequested extends NotesEvent {
  const CreateNoteRequested(this.note);

  final Note note;

  @override
  List<Object?> get props => [note];
}

class UpdateNoteRequested extends NotesEvent {
  const UpdateNoteRequested(this.note);

  final Note note;

  @override
  List<Object?> get props => [note];
}

class DeleteNoteRequested extends NotesEvent {
  const DeleteNoteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class RefreshNotes extends NotesEvent {}

class ResolveConflictRequested extends NotesEvent {
  const ResolveConflictRequested(this.id, {required this.keepLocal});

  final String id;
  final bool keepLocal;

  @override
  List<Object?> get props => [id, keepLocal];
}
