import 'package:flutter_test/flutter_test.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/reports/data/models/report_period.dart';
import 'package:sampriti/features/reports/data/repos/report_repo.dart';
import 'package:sampriti/features/setup/data/models/project_model.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

TransactionModel tx({
  required String id,
  required String date,
  required String dir,
  required double amount,
  String sectorId = '',
  String sectorKey = SectorModel.keyCustom,
  String sectorName = '',
  String project = '',
  String member = '',
  String kind = '',
  String mode = 'cash',
  String acct = '',
}) =>
    TransactionModel(
      id: id,
      vno: 'V-$id',
      date: date,
      dir: dir,
      sectorId: sectorId,
      sectorKey: sectorKey,
      sectorName: sectorName,
      project: project,
      member: member,
      kind: kind,
      mode: mode,
      acct: acct,
      amount: amount,
    );

void main() {
  // ---- Shared fixture: November 2026, cash0 = 1000, one bank with 5000 opening ----
  final nov = ReportPeriod.custom(DateTime(2026, 11, 1), DateTime(2026, 11, 30));
  final banks = [
    const BankAccountModel(id: 'b1', bankName: 'ইসলামী ব্যাংক', accountNo: '111', initialBalance: 5000),
  ];
  final projects = [
    const ProjectModel(id: 'p1', name: 'প্রকল্প ১', memberNos: ['S1'], budget: 10000),
  ];
  final members = [
    const MemberModel(no: 'S1', nameBn: 'আবদুল', shares: 2, founder: true),
  ];

  final txs = [
    // Before window: member invests 300 in cash → cash opening 1300, capital 300
    tx(
      id: '1',
      date: '2026-10-15',
      dir: 'in',
      amount: 300,
      sectorId: SectorModel.idIncShareholder,
      sectorKey: SectorModel.keyShareholder,
      sectorName: 'শেয়ারহোল্ডার',
      member: 'S1',
    ),
    // In window
    tx(
      id: '2',
      date: '2026-11-02',
      dir: 'in',
      amount: 800,
      sectorId: SectorModel.idIncProkolpo,
      sectorKey: SectorModel.keyProkolpo,
      sectorName: 'প্রকল্প',
      project: 'p1',
    ),
    tx(id: '3', date: '2026-11-03', dir: 'out', amount: 200, sectorName: 'অন্যান্য সাধারণ ব্যয়'),
    tx(
      id: '4',
      date: '2026-11-04',
      dir: 'out',
      amount: 100,
      sectorId: SectorModel.idExpShareholder,
      sectorKey: SectorModel.keyShareholder,
      sectorName: 'শেয়ারহোল্ডার',
      member: 'S1',
      kind: 'profit_payout',
    ),
    tx(id: '5', date: '2026-11-05', dir: 'xfer', amount: 500, kind: 'bank_dep', sectorKey: 'bank_transfer', mode: 'bank', acct: 'b1'),
    tx(
      id: '6',
      date: '2026-11-06',
      dir: 'in',
      amount: 400,
      sectorId: SectorModel.idIncShareholder,
      sectorKey: SectorModel.keyShareholder,
      sectorName: 'শেয়ারহোল্ডার',
      member: 'S1',
      mode: 'bank',
      acct: 'b1',
    ),
    tx(
      id: '7',
      date: '2026-11-07',
      dir: 'out',
      amount: 50,
      sectorId: SectorModel.idExpShareholder,
      sectorKey: SectorModel.keyShareholder,
      sectorName: 'শেয়ারহোল্ডার',
      member: 'S1',
    ),
  ];

  final report = ReportCalculator.compute(
    txs: txs,
    period: nov,
    projects: projects,
    members: members,
    banks: banks,
    cash0: 1000,
  );

  group('ReportPeriod', () {
    test('this month spans first to last day', () {
      final p = ReportPeriod.preset(ReportPeriodPreset.thisMonth, now: DateTime(2026, 11, 12));
      expect(p.from, '2026-11-01');
      expect(p.to, '2026-11-30');
      expect(p.contains('2026-11-30'), isTrue);
      expect(p.contains('2026-12-01'), isFalse);
    });

    test('last month across year boundary', () {
      final p = ReportPeriod.preset(ReportPeriodPreset.lastMonth, now: DateTime(2026, 1, 5));
      expect(p.from, '2025-12-01');
      expect(p.to, '2025-12-31');
    });

    test('all time contains everything', () {
      final p = ReportPeriod.preset(ReportPeriodPreset.all);
      expect(p.isAll, isTrue);
      expect(p.contains('1999-01-01'), isTrue);
    });
  });

  group('ReportCalculator funds', () {
    test('cash opening, in, out and closing', () {
      final cash = report.funds.first;
      expect(cash.isCash, isTrue);
      expect(cash.opening, 1300); // 1000 + 300 member invest before window
      expect(cash.inflow, 800);
      expect(cash.outflow, 850); // 200 expense + 100 payout + 50 capital + 500 bank deposit
      expect(cash.closing, 1250);
    });

    test('bank opening, in and closing', () {
      final bank = report.funds[1];
      expect(bank.opening, 5000);
      expect(bank.inflow, 900); // 500 deposit + 400 member invest via bank
      expect(bank.outflow, 0);
      expect(bank.closing, 5900);
    });

    test('funds reconcile: opening + income - expense - payout = closing (transfers net zero)', () {
      expect(report.closingFunds, report.openingFunds + report.totalIncome - report.totalExpense - report.totalPayout);
      expect(report.closingFunds, 7150);
    });
  });

  group('ReportCalculator flows', () {
    test('income excludes transfers and capital is counted as income only in shareholder sector', () {
      expect(report.totalIncome, 1200); // 800 project + 400 member invest
      expect(report.totalTransfer, 500);
      expect(report.totalPayout, 100);
      expect(report.totalExpense, 250); // 200 general + 50 capital return
    });

    test('profit payout never counts as expense', () {
      expect(report.payoutCount, 1);
      expect(report.expenseCount, 2);
    });

    test('sector percentages of income sum to 100', () {
      final total = report.incomeSectors.fold<double>(0, (s, r) => s + r.percent);
      expect(total, closeTo(100, 0.0001));
    });
  });

  group('ReportCalculator project and member', () {
    test('project income matches prokolpo sector', () {
      final p = report.projects.first;
      expect(p.income, 800);
      expect(p.expense, 0);
      expect(p.net, 800);
      expect(p.memberCount, 1);
    });

    test('member net capital = investment minus capital returned', () {
      final m = report.members.first;
      expect(m.investment, 400); // window only
      expect(m.profitReceived, 100);
      expect(m.capitalReturn, 50);
      expect(m.netCapital, 350);
    });
  });

  group('ReportCalculator ledger', () {
    test('organisation ledger running balance ends at closing funds', () {
      final ledger = ReportCalculator.ledger(
        all: txs,
        rows: txs.where((t) => nov.contains(t.date)).toList(),
        period: nov,
        openingFunds: report.openingFunds,
        showBalance: true,
      );
      expect(ledger.opening, 6300);
      expect(ledger.closing, report.closingFunds);
      expect(ledger.rows.last.balance, report.closingFunds);
      // transfer row does not move the balance
      final transfer = ledger.rows.firstWhere((r) => r.trx.id == '5');
      expect(transfer.affectsBalance, isFalse);
    });

    test('member ledger: opening capital, payouts do not reduce capital', () {
      final ledger = ReportCalculator.ledger(
        all: txs,
        rows: txs.where((t) => nov.contains(t.date) && t.member == 'S1').toList(),
        period: nov,
        openingFunds: report.openingFunds,
        showBalance: true,
        memberNo: 'S1',
      );
      expect(ledger.memberMode, isTrue);
      expect(ledger.opening, 300);
      expect(ledger.totalPayout, 100);
      expect(ledger.totalCapitalReturn, 50);
      expect(ledger.closing, 650); // 300 opening + 400 invested - 50 capital returned
    });

    test('hidden balance column keeps totals', () {
      final ledger = ReportCalculator.ledger(
        all: txs,
        rows: txs.where((t) => nov.contains(t.date)).toList(),
        period: nov,
        openingFunds: report.openingFunds,
        showBalance: false,
      );
      expect(ledger.rows.every((r) => r.balance == null), isTrue);
      expect(ledger.closing, report.closingFunds);
    });
  });
}
