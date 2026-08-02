import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_app/features/notes/domain/entities/note.dart';
import 'package:notebook_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:notebook_app/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:notebook_app/features/notes/presentation/bloc/notes_event.dart';
import 'package:notebook_app/features/notes/presentation/bloc/notes_state.dart';

class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository({List<Note>? initialNotes}) : _notes = initialNotes ?? [];

  final List<Note> _notes;

  @override
  Future<List<Note>> getNotes() async => List<Note>.from(_notes);

  @override
  Future<Note> createNote(Note note) async {
    _notes.add(note);
    return note;
  }

  @override
  Future<Note> updateNote(Note note) async {
    final index = _notes.indexWhere((existing) => existing.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    return note;
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((note) => note.id == id);
  }

  @override
  Future<List<Note>> refreshFromRemote() async => List<Note>.from(_notes);

  @override
  Future<Note> resolveConflict(
    String id, {
    required bool keepLocal,
    Note? remoteNote,
  }) async {
    final existing = _notes.firstWhere(
      (note) => note.id == id,
      orElse: () => _notes.first,
    );
    return keepLocal ? existing : (remoteNote ?? existing);
  }
}

void main() {
  late FakeNotesRepository repository;
  late NotesBloc bloc;

  setUp(() {
    repository = FakeNotesRepository(
      initialNotes: [
        Note(id: '1', title: 'One', body: 'Body', updatedAt: DateTime.now()),
      ],
    );
    bloc = NotesBloc(repository);
  });

  tearDown(() => bloc.close());

  test('loads notes from the repository', () async {
    bloc.add(LoadNotes());
    await expectLater(
      bloc.stream,
      emitsInOrder([isA<NotesLoading>(), isA<NotesLoaded>()]),
    );
  });
}
