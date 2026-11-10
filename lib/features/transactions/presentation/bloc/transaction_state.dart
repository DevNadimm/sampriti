part of 'transaction_bloc.dart';

sealed class TransactionState {}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final String? activeMemberFilter;
  final String? activeTypeFilter;

  TransactionLoaded({
    required this.transactions,
    this.activeMemberFilter,
    this.activeTypeFilter,
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
