import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/sync_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc(this._syncService) : super(SyncInitial()) {
    on<SyncStarted>(_onStarted);
    on<SyncRequested>(_onRequested);
  }

  final SyncService _syncService;

  Future<void> _onStarted(SyncStarted event, Emitter<SyncState> emit) async {
    emit(SyncInProgress());
    try {
      await _syncService.syncNow();
      emit(SyncSuccess());
    } catch (error) {
      emit(SyncFailure(error.toString()));
    }
  }

  Future<void> _onRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (state is! SyncInProgress) {
      add(SyncStarted());
    }
  }
}
