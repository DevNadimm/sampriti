import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

class DashboardSummaryModel {
  // Overall Organization Stats
  final int totalMembers;
  final double totalInvestment; // আয় → শেয়ারহোল্ডার
  final double bankBalance;
  final double cashBalance;
  final double totalFunds;
  final double projectIncome; // আয় → প্রকল্প
  final double projectExpense; // ব্যয় → প্রকল্প
  final double donationExpense; // ব্যয় → ডোনেশন
  final double capitalReturn; // ব্যয় → শেয়ারহোল্ডার (ম্যানুয়াল, মুনাফা নয়)
  final double totalExpense; // সব ব্যয়, মুনাফা বণ্টন বাদে
  final double distributableProfit;
  final double totalPayout;
  final double pendingPayout;
  final Map<String, double> incomeBySector; // খাতের নাম → মোট
  final Map<String, double> expenseBySector;
  final List<TransactionModel> recentTransactions;

  // Shareholder Specific Stats (if logged in as Shareholder)
  final String? memberNo;
  final String? memberName;
  final int myShares;
  final bool isFounder;
  final bool isLabor;
  final double myTotalInvestment;
  final double myProfitPaid;

  const DashboardSummaryModel({
    this.totalMembers = 0,
    this.totalInvestment = 0,
    this.bankBalance = 0,
    this.cashBalance = 0,
    this.totalFunds = 0,
    this.projectIncome = 0,
    this.projectExpense = 0,
    this.donationExpense = 0,
    this.capitalReturn = 0,
    this.totalExpense = 0,
    this.distributableProfit = 0,
    this.totalPayout = 0,
    this.pendingPayout = 0,
    this.incomeBySector = const {},
    this.expenseBySector = const {},
    this.recentTransactions = const [],
    this.memberNo,
    this.memberName,
    this.myShares = 1,
    this.isFounder = false,
    this.isLabor = false,
    this.myTotalInvestment = 0,
    this.myProfitPaid = 0,
  });
}
