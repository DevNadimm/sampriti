part of 'sector_bloc.dart';

sealed class SectorState {}

class SectorInitial extends SectorState {}

class SectorLoading extends SectorState {}

class SectorLoaded extends SectorState {
  final List<SectorModel> allSectors;
  final List<SectorModel> filteredSectors;
  final SectorType type;

  SectorLoaded({
    required this.allSectors,
    List<SectorModel>? filteredSectors,
    required this.type,
  }) : filteredSectors = filteredSectors ?? allSectors;
}

class SectorActionSuccess extends SectorState {
  final String message;
  SectorActionSuccess(this.message);
}

class SectorFailure extends SectorState {
  final String message;
  SectorFailure(this.message);
}
