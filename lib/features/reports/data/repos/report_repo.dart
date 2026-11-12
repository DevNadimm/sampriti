import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/finance/data/repos/bank_repo.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/reports/data/models/financial_report_model.dart';
import 'package:sampriti/features/reports/data/models/ledger_report.dart';
import 'package:sampriti/features/reports/data/models/report_period.dart';
import 'package:sampriti/features/setup/data/models/project_model.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/setup/data/repos/setup_repo.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/data/repos/transactions_repo.dart';

/// Pure calculations. No Firestore here, so it can be unit tested.
class ReportCalculator {
  const ReportCalculator._();

  /// Same matching rule as BankRepo.getBankAccounts.
  static bool _isBankOf(TransactionModel t, BankAccountModel b, int bankCount) {
    return t.mode == 'bank' &&
        (t.acct == b.id || t.acct == b.accountNo || (t.acct.isEmpty && bankCount == 1));
  }

  /// Signed effect on one bank account (+in, -out). Matches BankRepo.
  static double bankDelta(TransactionModel t) {
    if (t.kind == 'bank_dep') return t.amount;
    if (t.kind == 'bank_wd') return -t.amount;
    if (t.isInflow) return t.amount;
    if (t.isOutflow) return -t.amount;
    return 0;
  }

  /// Signed effect on cash in hand. Matches BankRepo.getFundSummary.
  static double cashDelta(TransactionModel t) {
    if (t.kind == 'bank_dep') return -t.amount;
    if (t.kind == 'bank_wd') return t.amount;
    if (t.mode == 'cash') {
      if (t.isInflow) return t.amount;
      if (t.isOutflow) return -t.amount;
    }
    return 0;
  }

  /// Member capital effect: investment (+), capital returned (-). Profit payouts do not touch capital.
  static double capitalDelta(TransactionModel t) {
    if (t.dir == 'in' && t.sectorKey == SectorModel.keyShareholder) return t.amount;
    if (t.dir == 'out' && t.sectorKey == SectorModel.keyShareholder && !t.isProfitPayout) {
      return -t.amount;
    }
    return 0;
  }

  static FinancialReportModel compute({
    required List<TransactionModel> txs,
    required ReportPeriod period,
    required List<ProjectModel> projects,
    required List<MemberModel> members,
    required List<BankAccountModel> banks,
    required double cash0,
  }) {
    final bankCount = banks.length;

    // ---- Funds: opening (before window) and in-window flows ----
    double cashOpen = cash0;
    double cashIn = 0;
    double cashOut = 0;
    final bankOpen = List<double>.generate(bankCount, (i) => banks[i].initialBalance);
    final bankIn = List<double>.filled(bankCount, 0);
    final bankOut = List<double>.filled(bankCount, 0);

    for (final t in txs) {
      if (period.isAfter(t.date)) continue;
      final before = period.isBefore(t.date);

      final cd = cashDelta(t);
      if (before) {
        cashOpen += cd;
      } else {
        if (cd > 0) cashIn += cd;
        if (cd < 0) cashOut -= cd;
      }

      for (var i = 0; i < bankCount; i++) {
        if (!_isBankOf(t, banks[i], bankCount)) continue;
        final bd = bankDelta(t);
        if (before) {
          bankOpen[i] += bd;
        } else {
          if (bd > 0) bankIn[i] += bd;
          if (bd < 0) bankOut[i] -= bd;
        }
      }
    }

    final funds = <FundRow>[
      FundRow(name: 'নগদ (হাতে)', isCash: true, opening: cashOpen, inflow: cashIn, outflow: cashOut),
      for (var i = 0; i < bankCount; i++)
        FundRow(
          name: banks[i].displayName,
          isCash: false,
          opening: bankOpen[i],
          inflow: bankIn[i],
          outflow: bankOut[i],
        ),
    ];

    // ---- Period flows ----
    final win = txs.where((t) => period.contains(t.date)).toList();
    double income = 0;
    double expense = 0;
    double payout = 0;
    double transfer = 0;
    int incC = 0;
    int expC = 0;
    int payC = 0;
    int trC = 0;
    for (final t in win) {
      if (t.isBankTransfer) {
        transfer += t.amount;
        trC++;
      } else if (t.dir == 'in') {
        income += t.amount;
        incC++;
      } else if (t.dir == 'out') {
        if (t.isProfitPayout) {
          payout += t.amount;
          payC++;
        } else {
          expense += t.amount;
          expC++;
        }
      }
    }

    // ---- Sector breakdown ----
    List<SectorRow> sectorRows(String dir, double total) {
      final map = <String, _Acc>{};
      for (final t in win) {
        if (t.dir != dir || t.isProfitPayout) continue;
        final key = t.sectorId.isNotEmpty ? t.sectorId : t.sectorName;
        final acc = map.putIfAbsent(
          key,
          () => _Acc(t.sectorName.isNotEmpty ? t.sectorName : 'অন্যান্য'),
        );
        acc.count++;
        acc.amount += t.amount;
      }
      final rows = map.values
          .map((a) => SectorRow(
                name: a.name,
                dir: dir,
                count: a.count,
                amount: a.amount,
                percent: total > 0 ? a.amount / total * 100 : 0,
              ))
          .toList();
      rows.sort((a, b) => b.amount.compareTo(a.amount));
      return rows;
    }

    // ---- Project breakdown (projects deleted from setup are not shown) ----
    final projectRows = <ProjectRow>[];
    for (final p in projects) {
      double inc = 0;
      double exp = 0;
      double pay = 0;
      double inv = 0;
      for (final t in win) {
        if (t.project != p.id) continue;
        if (t.isProfitPayout) {
          pay += t.amount;
        } else if (t.dir == 'in' && t.sectorKey == SectorModel.keyProkolpo) {
          inc += t.amount;
        } else if (t.dir == 'out' && t.sectorKey == SectorModel.keyProkolpo) {
          exp += t.amount;
        } else if (t.dir == 'in' && t.sectorKey == SectorModel.keyShareholder) {
          inv += t.amount;
        }
      }
      projectRows.add(ProjectRow(
        id: p.id,
        name: p.name,
        status: p.status,
        budget: p.budget,
        memberCount: p.memberNos.length,
        income: inc,
        expense: exp,
        payout: pay,
        memberInvestment: inv,
      ));
    }

    // ---- Member breakdown ----
    final memberRows = <MemberRow>[];
    for (final m in members) {
      final no = m.no.toUpperCase();
      double inv = 0;
      double prof = 0;
      double cap = 0;
      for (final t in win) {
        if (t.member.toUpperCase() != no) continue;
        if (t.isProfitPayout) {
          prof += t.amount;
        } else if (t.dir == 'in' && t.sectorKey == SectorModel.keyShareholder) {
          inv += t.amount;
        } else if (t.dir == 'out' && t.sectorKey == SectorModel.keyShareholder) {
          cap += t.amount;
        }
      }
      memberRows.add(MemberRow(
        no: m.no,
        name: m.displayName,
        shares: m.shares,
        founder: m.founder,
        labor: m.labor,
        investment: inv,
        profitReceived: prof,
        capitalReturn: cap,
      ));
    }
    memberRows.sort((a, b) => b.investment.compareTo(a.investment));

    return FinancialReportModel(
      period: period,
      totalIncome: income,
      totalExpense: expense,
      totalPayout: payout,
      totalTransfer: transfer,
      incomeCount: incC,
      expenseCount: expC,
      payoutCount: payC,
      transferCount: trC,
      funds: funds,
      incomeSectors: sectorRows('in', income),
      expenseSectors: sectorRows('out', expense),
      projects: projectRows,
      members: memberRows,
      months: _monthRows(period, win),
    );
  }

  static List<MonthRow> _monthRows(ReportPeriod period, List<TransactionModel> win) {
    if (win.isEmpty) return [];
    final dates = win.map((t) => t.date).toList()..sort();
    final startDate = period.from.isNotEmpty ? period.from : dates.first;
    final endDate = period.to.isNotEmpty ? period.to : dates.last;

    final agg = <String, List<double>>{}; // [income, expense, payout]
    for (final t in win) {
      if (t.isBankTransfer) continue;
      final key = t.date.substring(0, 7);
      final a = agg.putIfAbsent(key, () => [0, 0, 0]);
      if (t.dir == 'in') {
        a[0] += t.amount;
      } else if (t.dir == 'out') {
        if (t.isProfitPayout) {
          a[2] += t.amount;
        } else {
          a[1] += t.amount;
        }
      }
    }

    final rows = <MonthRow>[];
    var y = int.parse(startDate.substring(0, 4));
    var m = int.parse(startDate.substring(5, 7));
    final ey = int.parse(endDate.substring(0, 4));
    final em = int.parse(endDate.substring(5, 7));
    while (y < ey || (y == ey && m <= em)) {
      final key = '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}';
      final a = agg[key] ?? [0, 0, 0];
      rows.add(MonthRow(month: key, income: a[0], expense: a[1], payout: a[2]));
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    return rows;
  }

  /// Ledger with in/out columns and running balance.
  ///
  /// Organisation mode (memberNo == null): balance = total funds. Bank transfers and
  /// institution-direct (mode 'inst') vouchers are shown but do not move the balance.
  /// Member mode: balance = member capital. Profit payouts do not reduce capital.
  static LedgerReport ledger({
    required List<TransactionModel> all,
    required List<TransactionModel> rows,
    required ReportPeriod period,
    required double openingFunds,
    required bool showBalance,
    String? memberNo,
  }) {
    final sorted = [...rows]..sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.vno.compareTo(b.vno);
      });

    if (memberNo != null) {
      return _memberLedger(all, sorted, period, memberNo, showBalance);
    }
    return _orgLedger(sorted, openingFunds, showBalance);
  }

  static LedgerReport _orgLedger(
    List<TransactionModel> sorted,
    double openingFunds,
    bool showBalance,
  ) {
    double bal = openingFunds;
    double totIn = 0;
    double totOut = 0;
    double totPay = 0;
    int tr = 0;
    final out = <LedgerRow>[];
    for (final t in sorted) {
      final inA = t.dir == 'in' ? t.amount : 0.0;
      final outA = t.dir == 'out' ? t.amount : 0.0;
      final affects = t.dir != 'xfer' && t.mode != 'inst';
      if (affects) bal += inA - outA;
      if (t.dir == 'xfer') tr++;
      if (t.isProfitPayout) totPay += outA;
      totIn += inA;
      totOut += outA;
      out.add(LedgerRow(
        trx: t,
        inAmount: inA,
        outAmount: outA,
        balance: showBalance ? bal : null,
        affectsBalance: affects,
      ));
    }
    return LedgerReport(
      memberMode: false,
      showBalance: showBalance,
      opening: openingFunds,
      rows: out,
      totalIn: totIn,
      totalOut: totOut,
      closing: bal,
      totalPayout: totPay,
      transferCount: tr,
    );
  }

  static LedgerReport _memberLedger(
    List<TransactionModel> all,
    List<TransactionModel> sorted,
    ReportPeriod period,
    String memberNo,
    bool showBalance,
  ) {
    final no = memberNo.toUpperCase();

    double opening = 0;
    for (final t in all) {
      if (t.member.toUpperCase() != no || !period.isBefore(t.date)) continue;
      opening += capitalDelta(t);
    }

    double bal = opening;
    double totIn = 0;
    double totOut = 0;
    double totPay = 0;
    double totCap = 0;
    final out = <LedgerRow>[];
    for (final t in sorted) {
      if (t.member.toUpperCase() != no) continue;
      double inA = 0;
      double outA = 0;
      if (t.dir == 'in' && t.sectorKey == SectorModel.keyShareholder) {
        inA = t.amount;
      }
      if (t.isProfitPayout) {
        outA = t.amount;
        totPay += t.amount;
      } else if (t.dir == 'out' && t.sectorKey == SectorModel.keyShareholder) {
        outA = t.amount;
        totCap += t.amount;
      }
      bal += capitalDelta(t);
      totIn += inA;
      totOut += outA;
      out.add(LedgerRow(
        trx: t,
        inAmount: inA,
        outAmount: outA,
        balance: showBalance ? bal : null,
        affectsBalance: true,
      ));
    }
    return LedgerReport(
      memberMode: true,
      showBalance: showBalance,
      opening: opening,
      rows: out,
      totalIn: totIn,
      totalOut: totOut,
      closing: bal,
      totalPayout: totPay,
      totalCapitalReturn: totCap,
    );
  }
}

class _Acc {
  final String name;
  int count = 0;
  double amount = 0;
  _Acc(this.name);
}

class ReportRepo {
  static final _firestore = FirebaseFirestore.instance;

  static Future<double> _cash0() async {
    final doc = await _firestore.collection('settings').doc('org_config').get();
    return ((doc.data()?['cash0']) as num?)?.toDouble() ?? 0.0;
  }

  /// Admin only for organisation views. A shareholder may load their own member statement
  /// (TransactionsRepo already limits them to their own vouchers).
  static Future<_ReportData> _load({bool memberOnly = false}) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder' && !memberOnly) {
      throw ApiException(message: 'আর্থিক প্রতিবেদন শুধু অ্যাডমিনের জন্য');
    }
    try {
      final txs = await TransactionsRepo.getTransactions();
      final projects = await SetupRepo.getProjects();
      final members = await MembersRepo.getMembers(bypassSecurity: true);
      final banks = await BankRepo.getBankAccounts();
      final cash0 = await _cash0();
      return _ReportData(txs, projects, members, banks, cash0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'প্রতিবেদনের ডেটা লোড করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  static Future<FinancialReportModel> buildFinancialReport(ReportPeriod period) async {
    final d = await _load();
    return ReportCalculator.compute(
      txs: d.txs,
      period: period,
      projects: d.projects,
      members: d.members,
      banks: d.banks,
      cash0: d.cash0,
    );
  }

  /// [filter] narrows the rows (dir, sector, project). Balance and totals use the filtered rows.
  static Future<LedgerReport> buildLedger({
    required ReportPeriod period,
    String? memberNo,
    bool showBalance = true,
    bool Function(TransactionModel t)? filter,
  }) async {
    final d = await _load(memberOnly: memberNo != null);
    final opening = ReportCalculator.compute(
      txs: d.txs,
      period: period,
      projects: d.projects,
      members: d.members,
      banks: d.banks,
      cash0: d.cash0,
    ).openingFunds;

    var rows = d.txs.where((t) => period.contains(t.date));
    if (memberNo != null) {
      final no = memberNo.toUpperCase();
      rows = rows.where((t) => t.member.toUpperCase() == no);
    }
    if (filter != null) rows = rows.where(filter);

    return ReportCalculator.ledger(
      all: d.txs,
      rows: rows.toList(),
      period: period,
      openingFunds: opening,
      showBalance: showBalance,
      memberNo: memberNo,
    );
  }
}

class _ReportData {
  final List<TransactionModel> txs;
  final List<ProjectModel> projects;
  final List<MemberModel> members;
  final List<BankAccountModel> banks;
  final double cash0;
  _ReportData(this.txs, this.projects, this.members, this.banks, this.cash0);
}
