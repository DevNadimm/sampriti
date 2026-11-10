part of 'dashboard_bloc.dart';

sealed class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardSummaryModel summary;
  DashboardLoaded(this.summary);
}

class DashboardFailure extends DashboardState {
  final String message;
  DashboardFailure(this.message);
}
