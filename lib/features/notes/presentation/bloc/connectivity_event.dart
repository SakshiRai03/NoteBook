import 'package:equatable/equatable.dart';

abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object?> get props => [];
}

class ConnectivityChecked extends ConnectivityEvent {}

class ConnectivityChanged extends ConnectivityEvent {
  const ConnectivityChanged(this.isOnline);

  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}
