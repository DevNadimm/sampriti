import 'package:flutter_test/flutter_test.dart';
import 'package:sampriti/core/services/pdf_document_service.dart';
import 'package:sampriti/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/models/nominee_model.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockMember = MemberModel(
    no: 'S102',
    nameBn: 'মোঃ জালাল হোসেন',
    nameEn: 'Md. Jalal Hosen',
    father: 'জহির আহমেদ',
    mother: 'শিরিন আক্তার',
    spouse: 'সামিরা আক্তার',
    nid: '5511647785',
    birth: '1988-10-01',
    address: 'গোসচি, বাগোয়ান, রাউজান, চট্টগ্রাম',
    job: 'ব্যবসা',
    mobile: '01819000000',
    shares: 10,
    nominees: [
      NomineeModel(
        name: 'সামিরা আক্তার',
        relation: 'স্ত্রী',
        share: '100',
        mobile: '01819111111',
        nid: '5511647786',
      ),
    ],
  );

  final mockTransaction = TransactionModel(
    id: 'trx_1025',
    vno: 'V-1025',
    date: '10-11-2026',
    type: 'share_in',
    member: 'S102',
    inst: '',
    acct: '0123456789',
    mode: 'bank',
    amount: 50000,
    note: 'মাসিক শেয়ার কিস্তি জমা',
  );

  final mockSummary = DashboardSummaryModel(
    totalMembers: 12,
    totalInvestment: 1200000,
    bankBalance: 450000,
    cashBalance: 50000,
    totalFunds: 500000,
    institutionIncome: 75000,
    totalExpense: 25000,
    recentTransactions: [mockTransaction],
  );

  group('Unified PDF Header Generation Tests', () {
    test('1. generates Share Certificate PDF successfully', () async {
      final bytes = await PdfDocumentService.generateShareCertificate(mockMember);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('2. generates Shareholder Form PDF successfully with HTML layout', () async {
      final bytes = await PdfDocumentService.generateShareholderForm(mockMember);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('3. generates Nominee Form PDF successfully', () async {
      final bytes = await PdfDocumentService.generateNomineeForm(mockMember);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('4. generates Voucher PDF successfully', () async {
      final bytes = await PdfDocumentService.generateVoucherPdf(mockTransaction, memberName: 'মোঃ জালাল হোসেন');
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('5. generates Financial Report PDF successfully', () async {
      final bytes = await PdfDocumentService.generateFinancialReportPdf(mockSummary);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('6. generates Shareholder List PDF successfully', () async {
      final bytes = await PdfDocumentService.generateShareholderListPdf([mockMember]);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('7. generates Member PIN Sheet PDF successfully', () async {
      final bytes = await PdfDocumentService.generateMemberPinsPdf([mockMember]);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('8. generates Ledger PDF successfully', () async {
      final bytes = await PdfDocumentService.generateLedgerPdf([mockTransaction]);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });
}
