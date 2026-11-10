import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sampriti/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:sampriti/features/dashboard/data/repos/dashboard_repo.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardFetchRequested>(_onFetch);
  }

  Future<void> _onFetch(
    DashboardFetchRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final summary = await DashboardRepo.getDashboardSummary();
      emit(DashboardLoaded(summary));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }
}
