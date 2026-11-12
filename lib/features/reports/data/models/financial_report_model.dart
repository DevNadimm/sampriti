import 'package:sampriti/features/reports/data/models/report_period.dart';

/// Cash in hand or one bank account over the period.
class FundRow {
  final String name;
  final bool isCash;
  final double opening;
  final double inflow;
  final double outflow;

  const FundRow({
    required this.name,
    required this.isCash,
    required this.opening,
    required this.inflow,
    required this.outflow,
  });

  double get closing => opening + inflow - outflow;
}

class SectorRow {
  final String name;
  final String dir; // 'in' | 'out'
  final int count;
  final double amount;
  final double percent; // share of all income (or all expense) in the period

  const SectorRow({
    required this.name,
    required this.dir,
    required this.count,
    required this.amount,
    required this.percent,
  });
}

class ProjectRow {
  final String id;
  final String name;
  final String status;
  final double budget;
  final int memberCount;
  final double income; // আয় → প্রকল্প
  final double expense; // ব্যয় → প্রকল্প
  final double payout; // profit_payout tagged to this project
  final double memberInvestment; // আয় → শেয়ারহোল্ডার tagged to this project

  const ProjectRow({
    required this.id,
    required this.name,
    required this.status,
    required this.budget,
    required this.memberCount,
    required this.income,
    required this.expense,
    required this.payout,
    required this.memberInvestment,
  });

  double get net => income - expense;
  double get budgetUsedPercent => budget > 0 ? (expense / budget) * 100 : 0;
  bool get isActive => status == 'active';
}

class MemberRow {
  final String no;
  final String name;
  final int shares;
  final bool founder;
  final bool labor;
  final double investment;
  final double profitReceived;
  final double capitalReturn;

  const MemberRow({
    required this.no,
    required this.name,
    required this.shares,
    required this.founder,
    required this.labor,
    required this.investment,
    required this.profitReceived,
    required this.capitalReturn,
  });

  double get netCapital => investment - capitalReturn;

  String get policyLabel {
    final parts = <String>[];
    if (founder) parts.add('প্রতিষ্ঠাতা');
    if (labor) parts.add('শ্রমদাতা');
    return parts.isEmpty ? 'সাধারণ' : parts.join(', ');
  }
}

class MonthRow {
  final String month; // YYYY-MM
  final double income;
  final double expense;
  final double payout;

  const MonthRow({
    required this.month,
    required this.income,
    required this.expense,
    required this.payout,
  });

  double get net => income - expense - payout;
  String get label => bnMonthLabel(month);
}

/// Everything the financial report screen and PDF show for one period.
class FinancialReportModel {
  final ReportPeriod period;
  final double totalIncome;
  final double totalExpense; // excludes profit payouts
  final double totalPayout;
  final double totalTransfer;
  final int incomeCount;
  final int expenseCount;
  final int payoutCount;
  final int transferCount;
  final List<FundRow> funds;
  final List<SectorRow> incomeSectors;
  final List<SectorRow> expenseSectors;
  final List<ProjectRow> projects;
  final List<MemberRow> members;
  final List<MonthRow> months;

  const FinancialReportModel({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalPayout,
    required this.totalTransfer,
    required this.incomeCount,
    required this.expenseCount,
    required this.payoutCount,
    required this.transferCount,
    required this.funds,
    required this.incomeSectors,
    required this.expenseSectors,
    required this.projects,
    required this.members,
    required this.months,
  });

  double get netResult => totalIncome - totalExpense - totalPayout;
  double get openingFunds => funds.fold(0.0, (s, f) => s + f.opening);
  double get closingFunds => funds.fold(0.0, (s, f) => s + f.closing);
  int get voucherCount => incomeCount + expenseCount + payoutCount + transferCount;
}
