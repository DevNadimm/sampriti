import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

class DashboardSummaryModel {
  // Overall Organization Stats
  final int totalMembers;
  final double totalInvestment;
  final double bankBalance;
  final double cashBalance;
  final double totalFunds;
  final double institutionInvestment;
  final double loanOutstanding;
  final double totalSubsidy;
  final double institutionIncome;
  final double totalDonation;
  final double totalExpense;
  final double distributableProfit;
  final double totalPayout;
  final double pendingPayout;
  final List<TransactionModel> recentTransactions;

  // Shareholder Specific Stats (if logged in as Shareholder)
  final String? memberNo;
  final String? memberName;
  final int myShares;
  final bool isFounder;
  final bool isLabor;
  final double myTotalInvestment;
  final double myProfitDue;
  final double myProfitPaid;
  final double myProfitRemaining;

  const DashboardSummaryModel({
    this.totalMembers = 0,
    this.totalInvestment = 0,
    this.bankBalance = 0,
    this.cashBalance = 0,
    this.totalFunds = 0,
    this.institutionInvestment = 0,
    this.loanOutstanding = 0,
    this.totalSubsidy = 0,
    this.institutionIncome = 0,
    this.totalDonation = 0,
    this.totalExpense = 0,
    this.distributableProfit = 0,
    this.totalPayout = 0,
    this.pendingPayout = 0,
    this.recentTransactions = const [],
    this.memberNo,
    this.memberName,
    this.myShares = 1,
    this.isFounder = false,
    this.isLabor = false,
    this.myTotalInvestment = 0,
    this.myProfitDue = 0,
    this.myProfitPaid = 0,
    this.myProfitRemaining = 0,
  });
}
