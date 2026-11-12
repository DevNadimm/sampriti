import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/data/repos/transactions_repo.dart';

class BankRepo {
  static final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'bank_accounts';

  /// Fetch all bank accounts with computed real-time balances
  static Future<List<BankAccountModel>> getBankAccounts() async {
    try {
      final snap = await _firestore.collection(_collection).get();
      List<BankAccountModel> accounts =
          snap.docs.map((doc) => BankAccountModel.fromFirestore(doc)).toList();

      // Self-healing: seed initial bank accounts if none exist
      if (accounts.isEmpty) {
        accounts = await _seedDefaultBankAccounts();
      }

      // Fetch transactions to calculate real-time bank balances
      final txSnap = await _firestore.collection('transactions').get();
      final txList = txSnap.docs.map((d) => TransactionModel.fromFirestore(d)).toList();

      final List<BankAccountModel> enriched = accounts.map((bank) {
        double balance = bank.initialBalance;

        for (final t in txList) {
          final isTargetBank = t.mode == 'bank' &&
              (t.acct == bank.id || t.acct == bank.accountNo || (t.acct.isEmpty && accounts.length == 1));
          if (!isTargetBank) continue;

          if (t.kind == 'bank_dep') {
            balance += t.amount;
          } else if (t.kind == 'bank_wd') {
            balance -= t.amount;
          } else if (t.isInflow) {
            balance += t.amount;
          } else if (t.isOutflow) {
            balance -= t.amount;
          }
        }

        return bank.copyWith(currentBalance: balance);
      }).toList();

      // Sort: Active first, then name alphabetically
      enriched.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return a.bankName.compareTo(b.bankName);
      });

      return enriched;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'ব্যাংক হিসাব লোড করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।',
      );
    }
  }

  /// Auto-seed default accounts for initial setup
  static Future<List<BankAccountModel>> _seedDefaultBankAccounts() async {
    final now = DateTime.now().toIso8601String();
    final defaults = [
      BankAccountModel(
        id: 'b1',
        bankName: 'ইসলামী ব্যাংক বাংলাদেশ লিঃ',
        accountName: 'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম',
        branch: 'নোয়াপাড়া শাখা',
        accountNo: '২০৫০১০১০০২২৫৫৮',
        initialBalance: 385000.0,
        currentBalance: 385000.0,
        note: 'মূল প্রাতিষ্ঠানিক সঞ্চয়ী হিসাব',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      BankAccountModel(
        id: 'b2',
        bankName: 'সোনালী ব্যাংক পিএলসি',
        accountName: 'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম',
        branch: 'বাগোয়ান শাখা',
        accountNo: '০১০৩২০১০০৫৫৮৬',
        initialBalance: 150000.0,
        currentBalance: 150000.0,
        note: 'প্রকল্প পরিচালনা ও রিজার্ভ তহবিল',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    try {
      final batch = _firestore.batch();
      for (final acc in defaults) {
        batch.set(_firestore.collection(_collection).doc(acc.id), acc.toMap());
      }
      await batch.commit();
    } catch (_) {}

    return defaults;
  }

  /// Save or update a bank account (Admin only)
  static Future<void> saveBankAccount(BankAccountModel account) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'ব্যাংক হিসাব পরিবর্তনের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    try {
      final now = DateTime.now().toIso8601String();
      final isNew = account.id.trim().isEmpty;
      final docId = isNew ? 'bank_${DateTime.now().millisecondsSinceEpoch}' : account.id;

      final updated = account.copyWith(
        id: docId,
        createdAt: isNew ? now : (account.createdAt.isNotEmpty ? account.createdAt : now),
        updatedAt: now,
      );

      await _firestore.collection(_collection).doc(docId).set(updated.toMap());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'ব্যাংক হিসাব সংরক্ষণ ব্যর্থ হয়েছে: $e');
    }
  }

  /// Delete a bank account (Admin only)
  static Future<void> deleteBankAccount(String id) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'ব্যাংক হিসাব মুছে ফেলার অনুমতি নেই');
    }

    try {
      // 1. Verify if any transaction is associated with this bank
      final txSnap = await _firestore
          .collection('transactions')
          .where('mode', isEqualTo: 'bank')
          .where('acct', isEqualTo: id)
          .limit(1)
          .get();

      if (txSnap.docs.isNotEmpty) {
        throw ApiException(
          message: 'এই ব্যাংক হিসাবে লেনদেন বা ভাউচার সংরক্ষিত রয়েছে। হিসাবের সুরক্ষার জন্য এটি মুছে ফেলা যাবে না; আপনি চাইলে এটি নিষ্ক্রিয় করে রাখতে পারেন।',
        );
      }

      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'ব্যাংক হিসাব মুছে ফেলা সম্ভব হয়নি: $e');
    }
  }

  /// Admin only. Sets the opening cash balance (settings/org_config.cash0).
  static Future<void> saveCashOpening(double amount) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'প্রারম্ভিক স্থিতি পরিবর্তনের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }
    if (amount < 0) {
      throw ApiException(message: 'প্রারম্ভিক স্থিতি ঋণাত্মক হতে পারে না');
    }
    try {
      await _firestore
          .collection('settings')
          .doc('org_config')
          .set({'cash0': amount}, SetOptions(merge: true));
    } catch (e) {
      throw ApiException(message: 'প্রারম্ভিক স্থিতি সংরক্ষণ করা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Get current Cash in Hand balance and Total Bank balance
  static Future<Map<String, double>> getFundSummary() async {
    try {
      final accounts = await getBankAccounts();
      final totalBank = accounts.fold<double>(0.0, (s, a) => s + a.currentBalance);

      // Compute Cash Balance
      final txSnap = await _firestore.collection('transactions').get();
      final txList = txSnap.docs.map((d) => TransactionModel.fromFirestore(d)).toList();

      final cfgDoc = await _firestore.collection('settings').doc('org_config').get();
      final double cash0 = ((cfgDoc.data()?['cash0']) as num?)?.toDouble() ?? 0.0;

      double cashIn = 0.0;
      double cashOut = 0.0;

      for (final t in txList) {
        if (t.kind == 'bank_dep') {
          cashOut += t.amount;
        } else if (t.kind == 'bank_wd') {
          cashIn += t.amount;
        } else if (t.mode == 'cash') {
          if (t.isInflow) cashIn += t.amount;
          if (t.isOutflow) cashOut += t.amount;
        }
      }

      final cashBalance = cash0 + cashIn - cashOut;

      return {
        'totalBank': totalBank,
        'cashBalance': cashBalance,
        'cashOpening': cash0,
        'cashIn': cashIn,
        'cashOut': cashOut,
      };
    } catch (e) {
      return {'totalBank': 0.0, 'cashBalance': 0.0};
    }
  }

  /// Record a dedicated Bank Transfer (Deposit from Cash OR Withdraw to Cash)
  static Future<TransactionModel> recordBankTransfer({
    required bool isDeposit,
    required String bankId,
    required double amount,
    required String date,
    String slipNo = '',
    String note = '',
  }) async {
    if (amount <= 0) {
      throw ApiException(message: 'সঠিক টাকার পরিমাণ দিন');
    }

    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'ব্যাংক লেনদেনের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    // Balance checks
    final summary = await getFundSummary();
    final cashBalance = summary['cashBalance'] ?? 0.0;

    final accounts = await getBankAccounts();
    final targetBank = accounts.firstWhere(
      (a) => a.id == bankId,
      orElse: () => throw ApiException(message: 'নির্দিষ্ট ব্যাংক হিসাবটি খুঁজে পাওয়া যায়নি'),
    );

    if (isDeposit) {
      if (cashBalance < amount) {
        final formatter = NumberFormat('#,##,###');
        throw ApiException(
          message: 'পর্যাপ্ত ক্যাশ ব্যালেন্স নেই। বর্তমান ক্যাশ ইন হ্যান্ড: ৳ ${formatter.format(cashBalance.round())}',
        );
      }
    } else {
      if (targetBank.currentBalance < amount) {
        final formatter = NumberFormat('#,##,###');
        throw ApiException(
          message: 'উক্ত ব্যাংক হিসাবে পর্যাপ্ত ব্যালেন্স নেই। বর্তমান স্থিতি: ৳ ${formatter.format(targetBank.currentBalance.round())}',
        );
      }
    }

    // Build Transfer Note with Slip/Cheque No
    final parts = <String>[];
    if (isDeposit) {
      parts.add('নগদ তহবিল হতে ${targetBank.displayName}-এ জমা');
      if (slipNo.trim().isNotEmpty) parts.add('স্লিপ নং: ${slipNo.trim()}');
    } else {
      parts.add('${targetBank.displayName} হতে নগদ তহবিল উত্তোলন');
      if (slipNo.trim().isNotEmpty) parts.add('চেক/উত্তোলন নং: ${slipNo.trim()}');
    }
    if (note.trim().isNotEmpty) parts.add(note.trim());
    final fullNote = parts.join(' | ');

    final nextVNo = await TransactionsRepo.getNextVoucherNo();

    final trx = TransactionModel(
      id: '',
      vno: nextVNo,
      date: DateFormatter.yyyyMMdd(date),
      dir: 'xfer',
      sectorKey: 'bank_transfer',
      sectorName: isDeposit ? 'নগদ থেকে ব্যাংকে জমা' : 'ব্যাংক থেকে নগদ উত্তোলন',
      kind: isDeposit ? 'bank_dep' : 'bank_wd',
      amount: amount,
      mode: 'bank',
      acct: targetBank.id,
      note: fullNote,
    );

    await TransactionsRepo.addTransaction(trx);
    return trx;
  }
}
