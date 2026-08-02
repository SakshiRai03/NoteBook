import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:notebook_app/core/database/hive_service.dart';
import 'package:notebook_app/core/network/dio_client.dart';
import 'package:notebook_app/core/sync/sync_queue.dart';
import 'package:notebook_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:notebook_app/features/notes/domain/entities/note.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HiveService hiveService;
  late NotesRepositoryImpl repository;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('notebook_test_');
    Hive.init(dir.path);
    hiveService = HiveService(storagePath: dir.path);
    await hiveService.init();
    await hiveService.clear();
    repository = NotesRepositoryImpl(
      hiveService,
      DioClient(),
      SyncQueue(hiveService),
    );
  });

  test('createNote writes to Hive and returns a note', () async {
    final note = Note(
      id: '1',
      title: 'Test',
      body: 'Body',
      updatedAt: DateTime.now(),
    );

    final created = await repository.createNote(note);

    expect(created.id, '1');
    expect(hiveService.notesBox.containsKey('1'), isTrue);
  });

  test('resolveConflict keeps the chosen note version', () async {
    final localNote = Note(
      id: '2',
      title: 'Local',
      body: 'Local body',
      updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    );
    await repository.createNote(localNote);

    final resolved = await repository.resolveConflict('2', keepLocal: true);

    expect(resolved.id, '2');
    expect(resolved.title, 'Local');
  });
}
