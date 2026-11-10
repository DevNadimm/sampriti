part of 'auth_bloc.dart';

sealed class AuthEvent {}

class CheckAuthSessionRequested extends AuthEvent {}

class AdminLoginRequested extends AuthEvent {
  final String password;
  AdminLoginRequested(this.password);
}

class ShareholderLoginRequested extends AuthEvent {
  final String shareNo;
  final String pin;
  ShareholderLoginRequested({required this.shareNo, required this.pin});
}

class LogoutRequested extends AuthEvent {}
