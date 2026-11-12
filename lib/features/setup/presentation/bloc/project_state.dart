part of 'project_bloc.dart';

sealed class ProjectState {}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  final List<ProjectModel> allProjects;
  final List<ProjectModel> filteredProjects;

  ProjectLoaded({
    required this.allProjects,
    List<ProjectModel>? filteredProjects,
  }) : filteredProjects = filteredProjects ?? allProjects;
}

class ProjectActionSuccess extends ProjectState {
  final String message;
  ProjectActionSuccess(this.message);
}

class ProjectFailure extends ProjectState {
  final String message;
  ProjectFailure(this.message);
}
