import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/notes_repository.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc(this._repository) : super(NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<CreateNoteRequested>(_onCreateNote);
    on<UpdateNoteRequested>(_onUpdateNote);
    on<DeleteNoteRequested>(_onDeleteNote);
    on<RefreshNotes>(_onRefreshNotes);
    on<ResolveConflictRequested>(_onResolveConflict);
  }

  final NotesRepository _repository;

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());
    try {
      final notes = await _repository.getNotes();
      emit(NotesLoaded(notes));
    } catch (error) {
      emit(NotesError(error.toString()));
    }
  }

  Future<void> _onCreateNote(
    CreateNoteRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _repository.createNote(event.note);
      emit(const NotesOperationSuccess('Note created'));
      add(LoadNotes());
    } catch (error) {
      emit(NotesError(error.toString()));
    }
  }

  Future<void> _onUpdateNote(
    UpdateNoteRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _repository.updateNote(event.note);
      emit(const NotesOperationSuccess('Note updated'));
      add(LoadNotes());
    } catch (error) {
      emit(NotesError(error.toString()));
    }
  }

  Future<void> _onDeleteNote(
    DeleteNoteRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _repository.deleteNote(event.id);
      emit(const NotesOperationSuccess('Note deleted'));
      add(LoadNotes());
    } catch (error) {
      emit(NotesError(error.toString()));
    }
  }

  Future<void> _onRefreshNotes(
    RefreshNotes event,
    Emitter<NotesState> emit,
  ) async {
    try {
      final notes = await _repository.refreshFromRemote();
      emit(NotesLoaded(notes));
    } catch (error) {
      emit(NotesError(error.toString()));
    }
  }

  Future<void> _onResolveConflict(
    ResolveConflictRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _repository.resolveConflict(event.id, keepLocal: event.keepLocal);
      add(LoadNotes());
    } catch (error) {
      emit(NotesError(error.toString()));
    }
  }
}
