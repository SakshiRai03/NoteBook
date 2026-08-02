import 'package:equatable/equatable.dart';

import '../../domain/entities/note.dart';

abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  const NotesLoaded(this.notes);

  final List<Note> notes;

  @override
  List<Object?> get props => [notes];
}

class NotesError extends NotesState {
  const NotesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NotesOperationSuccess extends NotesState {
  const NotesOperationSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
