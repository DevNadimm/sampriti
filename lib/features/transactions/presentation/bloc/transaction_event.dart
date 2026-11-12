part of 'transaction_bloc.dart';

sealed class TransactionEvent {}

class TransactionFetchRequested extends TransactionEvent {
  final String? memberNo;
  final String? dir; // 'in' | 'out' | 'xfer'
  final String? sectorId;
  final String? kind; // 'profit_payout' | 'bank_dep' | 'bank_wd'
  final String? projectId;
  final String? from; // YYYY-MM-DD
  final String? to; // YYYY-MM-DD

  TransactionFetchRequested({
    this.memberNo,
    this.dir,
    this.sectorId,
    this.kind,
    this.projectId,
    this.from,
    this.to,
  });
}

class TransactionAddRequested extends TransactionEvent {
  final TransactionModel transaction;
  TransactionAddRequested(this.transaction);
}

class TransactionDeleteRequested extends TransactionEvent {
  final String id;
  TransactionDeleteRequested(this.id);
}

class ProjectProfitDistributionRequested extends TransactionEvent {
  final String projectId;
  final double totalProfit;
  final String date;
  final String mode;
  final String acct;
  final String note;

  ProjectProfitDistributionRequested({
    required this.projectId,
    required this.totalProfit,
    required this.date,
    required this.mode,
    required this.acct,
    this.note = 'মুনাফা বণ্টন',
  });
}
