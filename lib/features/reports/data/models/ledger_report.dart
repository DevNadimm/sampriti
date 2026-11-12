import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

class LedgerRow {
  final TransactionModel trx;
  final double inAmount;
  final double outAmount;
  final double? balance; // null when the balance column is hidden
  final bool affectsBalance; // false for bank transfers and institution-direct vouchers

  const LedgerRow({
    required this.trx,
    required this.inAmount,
    required this.outAmount,
    required this.balance,
    required this.affectsBalance,
  });
}

/// Ledger rows with in/out columns and an optional running balance.
///
/// Organisation mode: balance = total funds (cash + all banks).
/// Member statement mode: balance = member's capital (investment − capital returned).
class LedgerReport {
  final bool memberMode;
  final bool showBalance;
  final double opening;
  final List<LedgerRow> rows; // oldest first
  final double totalIn;
  final double totalOut;
  final double closing;

  // Breakdown (both modes)
  final double totalPayout; // profit_payout within totalOut
  final double totalCapitalReturn; // member mode: ব্যয় → শেয়ারহোল্ডার, not payout
  final int transferCount;

  const LedgerReport({
    required this.memberMode,
    required this.showBalance,
    required this.opening,
    required this.rows,
    required this.totalIn,
    required this.totalOut,
    required this.closing,
    this.totalPayout = 0,
    this.totalCapitalReturn = 0,
    this.transferCount = 0,
  });
}
