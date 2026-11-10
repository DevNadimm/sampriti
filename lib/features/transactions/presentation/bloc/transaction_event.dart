part of 'transaction_bloc.dart';

sealed class TransactionEvent {}

class TransactionFetchRequested extends TransactionEvent {
  final String? memberNo;
  final String? type;
  TransactionFetchRequested({this.memberNo, this.type});
}

class TransactionAddRequested extends TransactionEvent {
  final TransactionModel transaction;
  TransactionAddRequested(this.transaction);
}

class TransactionDeleteRequested extends TransactionEvent {
  final String id;
  TransactionDeleteRequested(this.id);
}

class BulkPayoutRequested extends TransactionEvent {
  final double totalFund;
  final String date;
  final String mode;
  final String acct;
  final String note;

  BulkPayoutRequested({
    required this.totalFund,
    required this.date,
    required this.mode,
    required this.acct,
    this.note = 'মুনাফা বণ্টন',
  });
}
