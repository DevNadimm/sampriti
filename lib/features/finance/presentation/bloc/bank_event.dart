part of 'bank_bloc.dart';

abstract class BankEvent {}

class BankFetchRequested extends BankEvent {}

class BankSearchRequested extends BankEvent {
  final String query;
  BankSearchRequested(this.query);
}

class BankSaveRequested extends BankEvent {
  final BankAccountModel account;
  BankSaveRequested(this.account);
}

class BankDeleteRequested extends BankEvent {
  final String id;
  BankDeleteRequested(this.id);
}

class BankCashOpeningSaveRequested extends BankEvent {
  final double amount;
  BankCashOpeningSaveRequested(this.amount);
}
