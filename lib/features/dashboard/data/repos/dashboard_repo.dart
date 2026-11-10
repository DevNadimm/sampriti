import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

class DashboardRepo {
  static final _firestore = FirebaseFirestore.instance;

  static Future<DashboardSummaryModel> getDashboardSummary() async {
    List<MemberModel> members = [];
    List<TransactionModel> txList = [];
    Map<String, dynamic> config = {'f': 20, 'l': 20, 'm': 60, 'cash0': 0};

    // 1. Fetch Members & Transactions from Firestore
    try {
      final memberSnaps = await _firestore.collection('members').get();
      members = memberSnaps.docs.map((d) => MemberModel.fromFirestore(d)).toList();

      final txSnaps = await _firestore.collection('transactions').orderBy('date', descending: true).get();
      txList = txSnaps.docs.map((d) => TransactionModel.fromFirestore(d)).toList();

      final cfgDoc = await _firestore.collection('settings').doc('org_config').get();
      if (cfgDoc.exists) {
        config = cfgDoc.data() ?? config;
      }
    } catch (e) {
      throw ApiException(
        message: 'ইন্টারনেট সংযোগ নেই বা সার্ভার থেকে ড্যাশবোর্ড ডাটা লোড করা সম্ভব হয়নি। অনুগ্রহ করে ইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।',
      );
    }

    final currentRole = await AppPreferences.getUserRole();
    final currentMemberNo = await AppPreferences.getMemberNo();

    // Calculations
    double totalInvest = 0.0;
    double cashIn = 0.0;
    double cashOut = 0.0;
    double bankIn = 0.0;
    double bankOut = 0.0;
    double instInvest = 0.0;
    double loanGiven = 0.0;
    double loanReturned = 0.0;
    double subsidy = 0.0;
    double instIncome = 0.0;
    double donation = 0.0;
    double expense = 0.0;
    double payout = 0.0;

    for (final t in txList) {
      final a = t.amount;
      if (t.type == 'share_in' || t.type == 'plan_dep') {
        totalInvest += a;
        if (t.mode == 'inst') instInvest += a;
      }
      if (t.type == 'inst_invest') instInvest += a;
      if (t.type == 'inst_loan') loanGiven += a;
      if (t.type == 'loan_return') loanReturned += a;
      if (t.type == 'inst_subsidy') subsidy += a;
      if (t.type == 'inst_income') instIncome += a;
      if (t.type == 'donation') donation += a;
      if (t.type == 'expense') expense += a;
      if (t.type == 'payout') payout += a;

      // Cash flow
      if (t.type == 'bank_dep') {
        cashOut += a;
        bankIn += a;
      } else if (t.type == 'bank_wd') {
        bankOut += a;
        cashIn += a;
      } else {
        if (t.mode == 'cash') {
          if (t.isInflow) cashIn += a;
          if (t.isOutflow) cashOut += a;
        } else if (t.mode == 'bank') {
          if (t.isInflow) bankIn += a;
          if (t.isOutflow) bankOut += a;
        }
      }
    }

    final double cash0 = (config['cash0'] as num?)?.toDouble() ?? 0.0;
    final double cashBalance = cash0 + cashIn - cashOut;
    final double bankBalance = bankIn - bankOut;
    final double totalFunds = cashBalance + bankBalance;
    final double loanOutstanding = loanGiven - loanReturned;
    final double distributable = instIncome > expense ? (instIncome - expense) : instIncome;

    // Shareholder specific calculation
    MemberModel? me;
    double myInvest = 0.0;
    double myDue = 0.0;
    double myPaid = 0.0;

    if (currentRole == 'shareholder' && currentMemberNo.isNotEmpty) {
      try {
        me = members.firstWhere((m) => m.no.toUpperCase() == currentMemberNo.toUpperCase());
      } catch (_) {}

      if (me != null) {
        // My Investment
        for (final t in txList.where((x) => x.member.toUpperCase() == me!.no.toUpperCase())) {
          if (t.type == 'share_in' || t.type == 'plan_dep') {
            myInvest += t.amount;
          }
          if (t.type == 'payout') {
            myPaid += t.amount;
          }
        }

        // Profit distribution entitlement
        final F = members.where((m) => m.founder).length;
        final L = members.where((m) => m.labor).length;
        final N = members.length;
        final fPct = ((config['founderPct'] ?? config['f'] ?? 20) as num).toDouble() / 100;
        final lPct = ((config['laborPct'] ?? config['l'] ?? 20) as num).toDouble() / 100;
        final mPct = ((config['mainFundPct'] ?? config['m'] ?? 60) as num).toDouble() / 100;

        final fShare = (me.founder && F > 0) ? (distributable * fPct) / F : 0.0;
        final lShare = (me.labor && L > 0) ? (distributable * lPct) / L : 0.0;
        final mShare = (N > 0) ? (distributable * mPct) / N : 0.0;

        myDue = fShare + lShare + mShare;
      }
    }

    return DashboardSummaryModel(
      totalMembers: members.length,
      totalInvestment: totalInvest,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
      totalFunds: totalFunds,
      institutionInvestment: instInvest,
      loanOutstanding: loanOutstanding,
      totalSubsidy: subsidy,
      institutionIncome: instIncome,
      totalDonation: donation,
      totalExpense: expense,
      distributableProfit: distributable,
      totalPayout: payout,
      pendingPayout: (distributable - payout).clamp(0, double.infinity),
      recentTransactions: (currentRole == 'shareholder' && currentMemberNo.isNotEmpty)
          ? txList.where((x) => x.member.toUpperCase() == currentMemberNo.toUpperCase()).take(6).toList()
          : txList.take(6).toList(),
      memberNo: me?.no,
      memberName: me?.displayName,
      myShares: me?.shares ?? 1,
      isFounder: me?.founder ?? false,
      isLabor: me?.labor ?? false,
      myTotalInvestment: myInvest,
      myProfitDue: myDue,
      myProfitPaid: myPaid,
      myProfitRemaining: (myDue - myPaid).clamp(0, double.infinity),
    );
  }
}
