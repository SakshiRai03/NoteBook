// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_app/core/database/hive_service.dart';
import 'package:notebook_app/core/di/service_locator.dart';
import 'package:notebook_app/features/notes/data/models/note_model.dart';
import 'package:notebook_app/features/notes/domain/entities/note.dart';
import 'package:notebook_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('notebook_widget_test_');
    await getIt.reset();
    await initDependencies(storagePath: dir.path);
    await getIt<HiveService>().clear();
  });

  testWidgets('renders the notes screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NotebookApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Offline First Notes'), findsOneWidget);
    expect(find.text('New Note'), findsOneWidget);
  });

  testWidgets('shows a conflict resolution dialog for conflicted notes', (
    WidgetTester tester,
  ) async {
    final hiveService = getIt<HiveService>();
    final conflicted = Note(
      id: 'conflict-1',
      title: 'Conflict',
      body: 'Needs resolution',
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.conflict,
    );
    await hiveService.notesBox.put(
      conflicted.id,
      NoteModel.fromEntity(conflicted),
    );

    await tester.pumpWidget(const NotebookApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Conflict'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Resolve conflict'), findsOneWidget);
    expect(find.text('Keep local'), findsOneWidget);
    expect(find.text('Use remote'), findsOneWidget);
  });
}
