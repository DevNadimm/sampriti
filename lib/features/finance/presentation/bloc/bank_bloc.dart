import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/finance/data/repos/bank_repo.dart';

part 'bank_event.dart';
part 'bank_state.dart';

class BankBloc extends Bloc<BankEvent, BankState> {
  List<BankAccountModel> _allAccounts = [];
  double _totalBank = 0.0;
  double _cashBalance = 0.0;
  double _cashOpening = 0.0;
  double _cashIn = 0.0;
  double _cashOut = 0.0;

  BankBloc() : super(BankInitial()) {
    on<BankFetchRequested>(_onFetch);
    on<BankSearchRequested>(_onSearch);
    on<BankSaveRequested>(_onSave);
    on<BankDeleteRequested>(_onDelete);
    on<BankCashOpeningSaveRequested>(_onCashOpeningSave);
  }

  BankLoaded _loaded({List<BankAccountModel>? filtered}) => BankLoaded(
        allAccounts: _allAccounts,
        filteredAccounts: filtered,
        totalBankBalance: _totalBank,
        cashBalance: _cashBalance,
        cashOpening: _cashOpening,
        cashIn: _cashIn,
        cashOut: _cashOut,
      );

  Future<void> _onFetch(
    BankFetchRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(BankLoading());
    try {
      _allAccounts = await BankRepo.getBankAccounts();
      final fundSummary = await BankRepo.getFundSummary();
      _totalBank = fundSummary['totalBank'] ?? 0.0;
      _cashBalance = fundSummary['cashBalance'] ?? 0.0;
      _cashOpening = fundSummary['cashOpening'] ?? 0.0;
      _cashIn = fundSummary['cashIn'] ?? 0.0;
      _cashOut = fundSummary['cashOut'] ?? 0.0;

      emit(_loaded());
    } catch (e) {
      emit(BankFailure(e.toString()));
    }
  }

  void _onSearch(
    BankSearchRequested event,
    Emitter<BankState> emit,
  ) {
    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) {
      emit(_loaded(filtered: _allAccounts));
      return;
    }

    final filtered = _allAccounts.where((a) {
      return a.bankName.toLowerCase().contains(query) ||
          a.branch.toLowerCase().contains(query) ||
          a.accountNo.toLowerCase().contains(query) ||
          a.accountName.toLowerCase().contains(query);
    }).toList();

    emit(_loaded(filtered: filtered));
  }

  Future<void> _onSave(
    BankSaveRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(BankLoading());
    try {
      final isNew = event.account.id.isEmpty;
      await BankRepo.saveBankAccount(event.account);
      emit(BankActionSuccess(
        isNew ? 'নতুন ব্যাংক হিসাব সফলভাবে যুক্ত করা হয়েছে' : 'ব্যাংক হিসাব সফলভাবে আপডেট করা হয়েছে',
      ));
      add(BankFetchRequested());
    } catch (e) {
      emit(BankFailure(e.toString()));
      add(BankFetchRequested());
    }
  }

  Future<void> _onDelete(
    BankDeleteRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(BankLoading());
    try {
      await BankRepo.deleteBankAccount(event.id);
      emit(BankActionSuccess('ব্যাংক হিসাব সফলভাবে মুছে ফেলা হয়েছে'));
      add(BankFetchRequested());
    } catch (e) {
      emit(BankFailure(e.toString()));
      add(BankFetchRequested());
    }
  }

  Future<void> _onCashOpeningSave(
    BankCashOpeningSaveRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(BankLoading());
    try {
      await BankRepo.saveCashOpening(event.amount);
      emit(BankActionSuccess('নগদের প্রারম্ভিক স্থিতি সফলভাবে আপডেট করা হয়েছে'));
      add(BankFetchRequested());
    } catch (e) {
      emit(BankFailure(e.toString()));
      add(BankFetchRequested());
    }
  }
}
