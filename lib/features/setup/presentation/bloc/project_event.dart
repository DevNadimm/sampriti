part of 'project_bloc.dart';

sealed class ProjectEvent {}

class ProjectFetchRequested extends ProjectEvent {}

class ProjectSearchRequested extends ProjectEvent {
  final String query;
  ProjectSearchRequested(this.query);
}

class ProjectSaveRequested extends ProjectEvent {
  final ProjectModel project;
  ProjectSaveRequested(this.project);
}

class ProjectDeleteRequested extends ProjectEvent {
  final String id;
  ProjectDeleteRequested(this.id);
}
