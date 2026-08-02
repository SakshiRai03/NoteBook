import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/sync_service.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc(this._syncService) : super(ConnectivityInitial()) {
    on<ConnectivityChecked>(_onChecked);
    on<ConnectivityChanged>(_onChanged);
    _subscription = _syncService.connectivityStream.listen((result) {
      add(ConnectivityChanged(result != ConnectivityResult.none));
    });
  }

  final SyncService _syncService;
  late final StreamSubscription<dynamic> _subscription;

  Future<void> _onChecked(
    ConnectivityChecked event,
    Emitter<ConnectivityState> emit,
  ) async {
    final online = await _syncService.isOnline;
    emit(online ? ConnectivityOnline() : ConnectivityOffline());
  }

  Future<void> _onChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) async {
    emit(event.isOnline ? ConnectivityOnline() : ConnectivityOffline());
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
