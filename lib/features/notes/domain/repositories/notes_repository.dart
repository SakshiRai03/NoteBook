import '../entities/note.dart';

abstract class NotesRepository {
  Future<List<Note>> getNotes();
  Future<Note> createNote(Note note);
  Future<Note> updateNote(Note note);
  Future<void> deleteNote(String id);
  Future<List<Note>> refreshFromRemote();
  Future<Note> resolveConflict(
    String id, {
    required bool keepLocal,
    Note? remoteNote,
  });
}
