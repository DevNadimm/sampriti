import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';

part 'member_event.dart';
part 'member_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  List<MemberModel> _allMembers = [];

  MemberBloc() : super(MemberInitial()) {
    on<MemberFetchRequested>(_onFetch);
    on<MemberSearchRequested>(_onSearch);
    on<MemberSaveRequested>(_onSave);
    on<MemberDeleteRequested>(_onDelete);
    on<MemberSetPinRequested>(_onSetPin);
  }

  Future<void> _onFetch(
    MemberFetchRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    try {
      _allMembers = await MembersRepo.getMembers();
      emit(MemberLoaded(allMembers: _allMembers));
    } catch (e) {
      emit(MemberFailure(e.toString()));
    }
  }

  void _onSearch(
    MemberSearchRequested event,
    Emitter<MemberState> emit,
  ) {
    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) {
      emit(MemberLoaded(allMembers: _allMembers, filteredMembers: _allMembers));
      return;
    }

    final filtered = _allMembers.where((m) {
      return m.no.toLowerCase().contains(query) ||
          m.nameBn.toLowerCase().contains(query) ||
          m.nameEn.toLowerCase().contains(query) ||
          m.mobile.contains(query) ||
          m.nid.contains(query);
    }).toList();

    emit(MemberLoaded(
      allMembers: _allMembers,
      filteredMembers: filtered,
      searchQuery: event.query,
    ));
  }

  Future<void> _onSave(
    MemberSaveRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    try {
      await MembersRepo.saveMember(event.member);
      _allMembers = await MembersRepo.getMembers();
      emit(MemberActionSuccess('সদস্য তথ্য সফলভাবে সংরক্ষিত হয়েছে'));
      emit(MemberLoaded(allMembers: _allMembers));
    } catch (e) {
      emit(MemberFailure(e.toString()));
    }
  }

  Future<void> _onDelete(
    MemberDeleteRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    try {
      await MembersRepo.deleteMember(event.no);
      _allMembers = await MembersRepo.getMembers();
      emit(MemberActionSuccess('সদস্য অপসারণ করা হয়েছে'));
      emit(MemberLoaded(allMembers: _allMembers));
    } catch (e) {
      emit(MemberFailure(e.toString()));
    }
  }

  Future<void> _onSetPin(
    MemberSetPinRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    try {
      await MembersRepo.setMemberPin(event.no, event.newPin);
      _allMembers = await MembersRepo.getMembers();
      emit(MemberActionSuccess('পিন সফলভাবে পরিবর্তন হয়েছে'));
      emit(MemberLoaded(allMembers: _allMembers));
    } catch (e) {
      emit(MemberFailure(e.toString()));
    }
  }
}
