part of 'bank_bloc.dart';

abstract class BankState {}

class BankInitial extends BankState {}

class BankLoading extends BankState {}

class BankLoaded extends BankState {
  final List<BankAccountModel> allAccounts;
  final List<BankAccountModel> filteredAccounts;
  final double totalBankBalance;
  final double cashBalance;
  final double cashOpening;
  final double cashIn;
  final double cashOut;

  BankLoaded({
    required this.allAccounts,
    List<BankAccountModel>? filteredAccounts,
    this.totalBankBalance = 0.0,
    this.cashBalance = 0.0,
    this.cashOpening = 0.0,
    this.cashIn = 0.0,
    this.cashOut = 0.0,
  }) : filteredAccounts = filteredAccounts ?? allAccounts;
}

class BankActionSuccess extends BankState {
  final String message;
  BankActionSuccess(this.message);
}

class BankFailure extends BankState {
  final String message;
  BankFailure(this.message);
}
