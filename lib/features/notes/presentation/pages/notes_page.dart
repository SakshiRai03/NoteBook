import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/repositories/notes_repository.dart';
import '../bloc/connectivity_bloc.dart';
import '../bloc/connectivity_event.dart';
import '../bloc/connectivity_state.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';
import '../../domain/entities/note.dart';
import 'note_editor_page.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => NotesBloc(getIt<NotesRepository>())..add(LoadNotes()),
        ),
        BlocProvider(
          create: (_) => SyncBloc(getIt<SyncService>())..add(SyncRequested()),
        ),
        BlocProvider(
          create: (_) =>
              ConnectivityBloc(getIt<SyncService>())
                ..add(ConnectivityChecked()),
        ),
      ],
      child: const NotesView(),
    );
  }
}

class NotesView extends StatelessWidget {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConnectivityBloc, ConnectivityState>(
          listener: (context, state) {
            if (state is ConnectivityOnline) {
              context.read<SyncBloc>().add(SyncRequested());
              context.read<NotesBloc>().add(RefreshNotes());
            }
          },
        ),
        BlocListener<NotesBloc, NotesState>(
          listener: (context, state) {
            if (state is NotesOperationSuccess) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
        BlocListener<SyncBloc, SyncState>(
          listener: (context, state) {
            if (state is SyncSuccess) {
              context.read<NotesBloc>().add(RefreshNotes());
            }
            if (state is SyncFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Sync failed: ${state.message}')),
                );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConfig.appTitle),
          actions: [
            BlocBuilder<ConnectivityBloc, ConnectivityState>(
              builder: (context, state) {
                final isOnline = state is ConnectivityOnline;
                return Chip(
                  label: Text(isOnline ? 'Online' : 'Offline'),
                  backgroundColor: isOnline
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<SyncBloc>().add(SyncRequested());
                context.read<NotesBloc>().add(RefreshNotes());
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<SyncBloc>().add(SyncRequested());
            context.read<NotesBloc>().add(RefreshNotes());
          },
          child: BlocBuilder<NotesBloc, NotesState>(
            builder: (context, state) {
              if (state is NotesLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is NotesError) {
                return Center(child: Text(state.message));
              }
              if (state is NotesLoaded) {
                if (state.notes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notes yet. Create your first offline note.',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.notes.length,
                  itemBuilder: (context, index) {
                    final note = state.notes[index];
                    return _NoteCard(note: note);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final notesBloc = context.read<NotesBloc>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: notesBloc,
                  child: const NoteEditorPage(),
                ),
              ),
            );
          },
          label: const Text('New Note'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text(
          note.title.isEmpty ? 'Untitled' : note.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          note.body.isEmpty ? 'No content' : note.body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SyncStatusChip(status: note.syncStatus),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        onTap: () {
          if (note.syncStatus == SyncStatus.conflict) {
            _showConflictDialog(context);
            return;
          }
          final notesBloc = context.read<NotesBloc>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: notesBloc,
                child: NoteEditorPage(note: note),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!context.mounted) return;
      context.read<NotesBloc>().add(DeleteNoteRequested(note.id));
    }
  }

  Future<void> _showConflictDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resolve conflict'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your local version',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Title: ${note.title}'),
              Text('Body: ${note.body}'),
              const SizedBox(height: 16),
              const Text(
                'Server version',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Title: ${note.conflictTitle ?? '(unavailable)'}'),
              Text('Body: ${note.conflictBody ?? '(unavailable)'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'local'),
            child: const Text('Keep Mine'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'merge'),
            child: const Text('Merge Manually'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'remote'),
            child: const Text('Keep Server'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (!context.mounted) return;
    if (result == 'merge') {
      final notesBloc = context.read<NotesBloc>();
      final merged = note.copyWith(
        title: '${note.title}\n\n[Server title]\n${note.conflictTitle ?? ''}',
        body:
            '${note.body}\n\n--- Server version ---\n${note.conflictBody ?? ''}',
        syncStatus: SyncStatus.pending,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: notesBloc,
            child: NoteEditorPage(note: merged),
          ),
        ),
      );
      return;
    }
    context.read<NotesBloc>().add(
      ResolveConflictRequested(note.id, keepLocal: result == 'local'),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  const _SyncStatusChip({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case SyncStatus.synced:
        color = Colors.green;
        label = 'Synced';
        break;
      case SyncStatus.pending:
        color = Colors.orange;
        label = 'Pending Sync';
        break;
      case SyncStatus.conflict:
        color = Colors.red;
        label = 'Conflict';
        break;
    }
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.16),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
