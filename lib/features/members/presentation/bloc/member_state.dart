part of 'member_bloc.dart';

sealed class MemberState {}

class MemberInitial extends MemberState {}

class MemberLoading extends MemberState {}

class MemberLoaded extends MemberState {
  final List<MemberModel> allMembers;
  final List<MemberModel> filteredMembers;
  final String searchQuery;

  MemberLoaded({
    required this.allMembers,
    List<MemberModel>? filteredMembers,
    this.searchQuery = '',
  }) : filteredMembers = filteredMembers ?? allMembers;
}

class MemberActionSuccess extends MemberState {
  final String message;
  MemberActionSuccess(this.message);
}

class MemberFailure extends MemberState {
  final String message;
  MemberFailure(this.message);
}
