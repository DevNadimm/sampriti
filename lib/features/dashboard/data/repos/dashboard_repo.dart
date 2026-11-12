import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/finance/data/repos/bank_repo.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

class DashboardRepo {
  static final _firestore = FirebaseFirestore.instance;

  static Future<DashboardSummaryModel> getDashboardSummary() async {
    List<MemberModel> members = [];
    List<TransactionModel> txList = [];
    List<BankAccountModel> bankAccounts = [];
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

      bankAccounts = await BankRepo.getBankAccounts();
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
    double projectIncome = 0.0;
    double projectExpense = 0.0;
    double donationExpense = 0.0;
    double capitalReturn = 0.0;
    // Profit pool: non-shareholder income minus non-shareholder expense, payouts excluded.
    // Shareholder capital (in or out) is never profit.
    double profitIn = 0.0;
    double profitOut = 0.0;
    double totalExpense = 0.0;
    double payout = 0.0;
    final incomeBySector = <String, double>{};
    final expenseBySector = <String, double>{};

    for (final t in txList) {
      final a = t.amount;

      if (t.dir == 'in') {
        incomeBySector[t.sectorName] = (incomeBySector[t.sectorName] ?? 0) + a;
        if (t.sectorKey == SectorModel.keyShareholder) {
          totalInvest += a;
        } else {
          profitIn += a;
        }
        if (t.sectorKey == SectorModel.keyProkolpo) projectIncome += a;
      } else if (t.dir == 'out') {
        if (t.isProfitPayout) {
          payout += a;
        } else {
          if (t.sectorKey != SectorModel.keyShareholder) profitOut += a;
          totalExpense += a;
          expenseBySector[t.sectorName] = (expenseBySector[t.sectorName] ?? 0) + a;
          if (t.sectorKey == SectorModel.keyProkolpo) projectExpense += a;
          if (t.sectorKey == SectorModel.keyDonation) donationExpense += a;
          if (t.sectorKey == SectorModel.keyShareholder) capitalReturn += a;
        }
      }

      // Cash flow
      if (t.kind == 'bank_dep') {
        cashOut += a;
      } else if (t.kind == 'bank_wd') {
        cashIn += a;
      } else if (t.mode == 'cash') {
        if (t.isInflow) cashIn += a;
        if (t.isOutflow) cashOut += a;
      }
    }

    final double cash0 = (config['cash0'] as num?)?.toDouble() ?? 0.0;
    final double cashBalance = cash0 + cashIn - cashOut;
    // Same source as the bank accounts page and the financial report: initial balance + flows.
    final double bankBalance = bankAccounts.fold(0.0, (s, b) => s + b.currentBalance);
    final double totalFunds = cashBalance + bankBalance;
    final double distributable = (profitIn - profitOut).clamp(0, double.infinity).toDouble();

    // Shareholder specific calculation
    MemberModel? me;
    double myInvest = 0.0;
    double myPaid = 0.0;

    if (currentRole == 'shareholder' && currentMemberNo.isNotEmpty) {
      try {
        me = members.firstWhere((m) => m.no.toUpperCase() == currentMemberNo.toUpperCase());
      } catch (_) {}

      if (me != null) {
        for (final t in txList.where((x) => x.member.toUpperCase() == me!.no.toUpperCase())) {
          if (t.dir == 'in' && t.sectorKey == SectorModel.keyShareholder) {
            myInvest += t.amount;
          }
          if (t.isProfitPayout) {
            myPaid += t.amount;
          }
        }
      }
    }

    return DashboardSummaryModel(
      totalMembers: members.length,
      totalInvestment: totalInvest,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
      totalFunds: totalFunds,
      projectIncome: projectIncome,
      projectExpense: projectExpense,
      donationExpense: donationExpense,
      capitalReturn: capitalReturn,
      totalExpense: totalExpense,
      distributableProfit: distributable,
      totalPayout: payout,
      pendingPayout: (distributable - payout).clamp(0, double.infinity).toDouble(),
      incomeBySector: incomeBySector,
      expenseBySector: expenseBySector,
      recentTransactions: (currentRole == 'shareholder' && currentMemberNo.isNotEmpty)
          ? txList.where((x) => x.member.toUpperCase() == currentMemberNo.toUpperCase()).take(6).toList()
          : txList.take(6).toList(),
      memberNo: me?.no,
      memberName: me?.displayName,
      myShares: me?.shares ?? 1,
      isFounder: me?.founder ?? false,
      isLabor: me?.labor ?? false,
      myTotalInvestment: myInvest,
      myProfitPaid: myPaid,
    );
  }
}
