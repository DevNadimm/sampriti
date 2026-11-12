part of 'transaction_bloc.dart';

sealed class TransactionState {}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final String? activeMemberFilter;
  final String? activeDirFilter;
  final String? activeSectorFilter;
  final String? activeKindFilter;
  final String? activeProjectFilter;

  TransactionLoaded({
    required this.transactions,
    this.activeMemberFilter,
    this.activeDirFilter,
    this.activeSectorFilter,
    this.activeKindFilter,
    this.activeProjectFilter,
  });
}

class TransactionActionSuccess extends TransactionState {
  final String message;
  TransactionActionSuccess(this.message);
}

class TransactionFailure extends TransactionState {
  final String message;
  TransactionFailure(this.message);
}
