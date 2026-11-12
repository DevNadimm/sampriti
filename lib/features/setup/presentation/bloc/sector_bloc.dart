import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/setup/data/repos/setup_repo.dart';

part 'sector_event.dart';
part 'sector_state.dart';

class SectorBloc extends Bloc<SectorEvent, SectorState> {
  List<SectorModel> _allSectors = [];
  SectorType _currentType = SectorType.income;

  SectorBloc() : super(SectorInitial()) {
    on<SectorFetchRequested>(_onFetch);
    on<SectorSearchRequested>(_onSearch);
    on<SectorSaveRequested>(_onSave);
    on<SectorDeleteRequested>(_onDelete);
  }

  Future<void> _onFetch(
    SectorFetchRequested event,
    Emitter<SectorState> emit,
  ) async {
    _currentType = event.type;
    emit(SectorLoading());
    try {
      _allSectors = await SetupRepo.getSectors(event.type);
      emit(SectorLoaded(allSectors: _allSectors, type: _currentType));
    } catch (e) {
      emit(SectorFailure(e.toString()));
    }
  }

  void _onSearch(
    SectorSearchRequested event,
    Emitter<SectorState> emit,
  ) {
    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) {
      emit(SectorLoaded(allSectors: _allSectors, filteredSectors: _allSectors, type: _currentType));
      return;
    }

    final filtered = _allSectors.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.description.toLowerCase().contains(query) ||
          s.key.toLowerCase().contains(query);
    }).toList();

    emit(SectorLoaded(
      allSectors: _allSectors,
      filteredSectors: filtered,
      type: _currentType,
    ));
  }

  Future<void> _onSave(
    SectorSaveRequested event,
    Emitter<SectorState> emit,
  ) async {
    emit(SectorLoading());
    try {
      final isNew = event.sector.id.isEmpty;
      await SetupRepo.saveSector(event.sector);
      final label = event.sector.type == SectorType.income ? 'আয়ের খাত' : 'ব্যয়ের খাত';
      emit(SectorActionSuccess(isNew ? 'নতুন $label সফলভাবে তৈরি হয়েছে' : '$label সফলভাবে আপডেট হয়েছে'));
      add(SectorFetchRequested(event.sector.type));
    } catch (e) {
      emit(SectorFailure(e.toString()));
    }
  }

  Future<void> _onDelete(
    SectorDeleteRequested event,
    Emitter<SectorState> emit,
  ) async {
    emit(SectorLoading());
    try {
      await SetupRepo.deleteSector(event.id, event.type);
      final label = event.type == SectorType.income ? 'আয়ের খাত' : 'ব্যয়ের খাত';
      emit(SectorActionSuccess('$label সফলভাবে মুছে ফেলা হয়েছে'));
      add(SectorFetchRequested(event.type));
    } catch (e) {
      emit(SectorFailure(e.toString()));
    }
  }
}
