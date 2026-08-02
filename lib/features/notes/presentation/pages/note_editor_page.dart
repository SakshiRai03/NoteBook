import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/note.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Note' : 'Create Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final now = DateTime.now();
          final note = (widget.note != null)
              ? widget.note!.copyWith(
                  title: _titleController.text,
                  body: _bodyController.text,
                  updatedAt: now,
                  syncStatus: SyncStatus.pending,
                )
              : Note(
                  id: const Uuid().v4(),
                  title: _titleController.text,
                  body: _bodyController.text,
                  updatedAt: now,
                  syncStatus: SyncStatus.pending,
                );
          if (isEditing) {
            context.read<NotesBloc>().add(UpdateNoteRequested(note));
          } else {
            context.read<NotesBloc>().add(CreateNoteRequested(note));
          }
          Navigator.pop(context);
        },
        label: Text(isEditing ? 'Save Changes' : 'Create Note'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
