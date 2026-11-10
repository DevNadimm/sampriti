part of 'member_bloc.dart';

sealed class MemberEvent {}

class MemberFetchRequested extends MemberEvent {}

class MemberSearchRequested extends MemberEvent {
  final String query;
  MemberSearchRequested(this.query);
}

class MemberSaveRequested extends MemberEvent {
  final MemberModel member;
  MemberSaveRequested(this.member);
}

class MemberDeleteRequested extends MemberEvent {
  final String no;
  MemberDeleteRequested(this.no);
}

class MemberSetPinRequested extends MemberEvent {
  final String no;
  final String newPin;
  MemberSetPinRequested({required this.no, required this.newPin});
}
