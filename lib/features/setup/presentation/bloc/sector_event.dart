part of 'sector_bloc.dart';

sealed class SectorEvent {}

class SectorFetchRequested extends SectorEvent {
  final SectorType type;
  SectorFetchRequested(this.type);
}

class SectorSearchRequested extends SectorEvent {
  final String query;
  SectorSearchRequested(this.query);
}

class SectorSaveRequested extends SectorEvent {
  final SectorModel sector;
  SectorSaveRequested(this.sector);
}

class SectorDeleteRequested extends SectorEvent {
  final String id;
  final SectorType type;
  SectorDeleteRequested({required this.id, required this.type});
}
