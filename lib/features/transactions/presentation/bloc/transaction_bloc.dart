import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/data/repos/transactions_repo.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc() : super(TransactionInitial()) {
    on<TransactionFetchRequested>(_onFetch);
    on<TransactionAddRequested>(_onAdd);
    on<TransactionDeleteRequested>(_onDelete);
    on<ProjectProfitDistributionRequested>(_onProjectProfitDistribution);
  }

  Future<void> _onFetch(
    TransactionFetchRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final list = await TransactionsRepo.getTransactions(
        memberNo: event.memberNo,
        dir: event.dir,
        sectorId: event.sectorId,
        kind: event.kind,
        projectId: event.projectId,
        from: event.from,
        to: event.to,
      );
      emit(TransactionLoaded(
        transactions: list,
        activeMemberFilter: event.memberNo,
        activeDirFilter: event.dir,
        activeSectorFilter: event.sectorId,
        activeKindFilter: event.kind,
        activeProjectFilter: event.projectId,
      ));
    } catch (e) {
      emit(TransactionFailure(e.toString()));
    }
  }

  Future<void> _onAdd(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      await TransactionsRepo.addTransaction(event.transaction);
      final list = await TransactionsRepo.getTransactions();
      emit(TransactionActionSuccess('ভাউচার সফলভাবে তৈরি হয়েছে'));
      emit(TransactionLoaded(transactions: list));
    } catch (e) {
      emit(TransactionFailure(e.toString()));
    }
  }

  Future<void> _onDelete(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      await TransactionsRepo.deleteTransaction(event.id);
      final list = await TransactionsRepo.getTransactions();
      emit(TransactionActionSuccess('লেনদেন মুছে ফেলা হয়েছে'));
      emit(TransactionLoaded(transactions: list));
    } catch (e) {
      emit(TransactionFailure(e.toString()));
    }
  }

  Future<void> _onProjectProfitDistribution(
    ProjectProfitDistributionRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final count = await TransactionsRepo.doProjectProfitDistribution(
        projectId: event.projectId,
        totalProfit: event.totalProfit,
        date: event.date,
        mode: event.mode,
        acct: event.acct,
        note: event.note,
      );
      final list = await TransactionsRepo.getTransactions();
      emit(TransactionActionSuccess('$count জন সদস্যের মুনাফা সফলভাবে বণ্টন করা হয়েছে'));
      emit(TransactionLoaded(transactions: list));
    } catch (e) {
      emit(TransactionFailure(e.toString()));
    }
  }
}
