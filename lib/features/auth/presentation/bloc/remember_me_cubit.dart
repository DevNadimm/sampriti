import 'package:flutter_bloc/flutter_bloc.dart';

class RememberMeCubit extends Cubit<bool> {
  RememberMeCubit() : super(false);

  void toggleRememberMe() => emit(!state);
  void resetRememberMe() => emit(false);
}
