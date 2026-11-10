import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/features/auth/data/models/user_session_model.dart';
import 'package:sampriti/features/auth/data/repos/auth_repo.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthSessionRequested>(_onCheckSession);
    on<AdminLoginRequested>(_onAdminLogin);
    on<ShareholderLoginRequested>(_onShareholderLogin);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onCheckSession(
    CheckAuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final session = await AuthRepo.checkSession();
      if (session != null) {
        emit(AuthAuthenticated(session));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAdminLogin(
    AdminLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final session = await AuthRepo.adminLogin(event.password);
      emit(AuthAuthenticated(session));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onShareholderLogin(
    ShareholderLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final session = await AuthRepo.shareholderLogin(
        shareNo: event.shareNo,
        pin: event.pin,
      );
      emit(AuthAuthenticated(session));
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await AuthRepo.logout();
    emit(AuthUnauthenticated());
  }
}
