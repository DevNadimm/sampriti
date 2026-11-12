import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sampriti/features/setup/data/models/project_model.dart';
import 'package:sampriti/features/setup/data/repos/setup_repo.dart';

part 'project_event.dart';
part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  List<ProjectModel> _allProjects = [];

  ProjectBloc() : super(ProjectInitial()) {
    on<ProjectFetchRequested>(_onFetch);
    on<ProjectSearchRequested>(_onSearch);
    on<ProjectSaveRequested>(_onSave);
    on<ProjectDeleteRequested>(_onDelete);
  }

  Future<void> _onFetch(
    ProjectFetchRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    try {
      _allProjects = await SetupRepo.getProjects();
      emit(ProjectLoaded(allProjects: _allProjects));
    } catch (e) {
      emit(ProjectFailure(e.toString()));
    }
  }

  void _onSearch(
    ProjectSearchRequested event,
    Emitter<ProjectState> emit,
  ) {
    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) {
      emit(ProjectLoaded(allProjects: _allProjects, filteredProjects: _allProjects));
      return;
    }

    final filtered = _allProjects.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.memberNos.any((no) => no.toLowerCase().contains(query));
    }).toList();

    emit(ProjectLoaded(
      allProjects: _allProjects,
      filteredProjects: filtered,
    ));
  }

  Future<void> _onSave(
    ProjectSaveRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    try {
      final isNew = event.project.id.isEmpty;
      await SetupRepo.saveProject(event.project);
      emit(ProjectActionSuccess(isNew ? 'নতুন প্রকল্প সফলভাবে তৈরি হয়েছে' : 'প্রকল্প সফলভাবে আপডেট হয়েছে'));
      add(ProjectFetchRequested());
    } catch (e) {
      emit(ProjectFailure(e.toString()));
    }
  }

  Future<void> _onDelete(
    ProjectDeleteRequested event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    try {
      await SetupRepo.deleteProject(event.id);
      emit(ProjectActionSuccess('প্রকল্প সফলভাবে মুছে ফেলা হয়েছে'));
      add(ProjectFetchRequested());
    } catch (e) {
      emit(ProjectFailure(e.toString()));
    }
  }
}
