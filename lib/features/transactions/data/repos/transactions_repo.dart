import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

class TransactionsRepo {
  static final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'transactions';

  /// Get all transactions with optional filters.
  /// If user is a shareholder, strictly isolates results to only their own memberNo.
  static Future<List<TransactionModel>> getTransactions({
    String? memberNo,
    String? type,
  }) async {
    final role = await AppPreferences.getUserRole();
    String? effectiveMemberNo = memberNo;

    if (role == 'shareholder') {
      final myNo = (await AppPreferences.getMemberNo()).trim();
      effectiveMemberNo = myNo.isNotEmpty ? myNo : 'FORBIDDEN';
    }

    List<TransactionModel> list = [];
    try {
      final snap = await _firestore.collection(_collection).orderBy('date', descending: true).get();
      list = snap.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ApiException(
        message: 'ইন্টারনেট সংযোগ নেই বা লেনদেনের বিবরণী লোড করা সম্ভব হয়নি। অনুগ্রহ করে ইন্টারনেট চেক করুন।',
      );
    }

    if (effectiveMemberNo != null && effectiveMemberNo.isNotEmpty) {
      final clean = effectiveMemberNo.toUpperCase();
      list = list.where((t) => t.member.toUpperCase() == clean).toList();
    }

    if (type != null && type.isNotEmpty && type != 'all') {
      list = list.where((t) => t.type == type).toList();
    }

    // Sort descending by date, then by voucher no
    list.sort((a, b) {
      final dateComp = b.date.compareTo(a.date);
      if (dateComp != 0) return dateComp;
      return b.vno.compareTo(a.vno);
    });

    return list;
  }

  /// Add new transaction (Admin Only)
  static Future<void> addTransaction(TransactionModel trx) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'লেনদেন যোগ করার অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    try {
      final docRef = _firestore.collection(_collection).doc();
      final modelWithId = trx.id.isEmpty ? TransactionModel.fromMap(trx.toMap(), docRef.id) : trx;
      await docRef.set(modelWithId.toMap());
    } catch (e) {
      throw ApiException(message: 'লেনদেন সংরক্ষণ করা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Delete transaction (Admin Only)
  static Future<void> deleteTransaction(String id) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'ভাউচার মুছে ফেলার অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw ApiException(message: 'ভাউচার মুছে ফেলা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Generate next voucher number, e.g. V-0001, V-0002
  static Future<String> getNextVoucherNo() async {
    final list = await getTransactions();
    int maxNum = 0;
    for (final t in list) {
      final digits = t.vno.replaceAll(RegExp(r'[^0-9]'), '');
      final val = int.tryParse(digits) ?? 0;
      if (val > maxNum) maxNum = val;
    }
    return 'V-${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  /// Bulk Profit Distribution Payout (matches HTML doBulkPay algorithm)
  static Future<int> doBulkDividendPayout({
    required double totalFund,
    required String date,
    required String mode,
    required String acct,
    String note = 'মুনাফা বণ্টন',
  }) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'মুনাফা বণ্টনের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    final members = await MembersRepo.getMembers(bypassSecurity: true);
    if (members.isEmpty || totalFund <= 0) return 0;

    final founders = members.where((m) => m.founder).toList();
    final laborMembers = members.where((m) => m.labor).toList();
    final totalShares = members.fold<int>(0, (total, m) => total + m.shares);

    // Distribution percentages from Firestore org_config
    double fPct = 0.20;
    double lPct = 0.20;
    double mPct = 0.60;
    try {
      final cfgDoc = await _firestore.collection('settings').doc('org_config').get();
      if (cfgDoc.exists && cfgDoc.data() != null) {
        final cfg = cfgDoc.data()!;
        fPct = ((cfg['founderPct'] ?? cfg['f'] ?? 20) as num).toDouble() / 100;
        lPct = ((cfg['laborPct'] ?? cfg['l'] ?? 20) as num).toDouble() / 100;
        mPct = ((cfg['mainFundPct'] ?? cfg['m'] ?? 60) as num).toDouble() / 100;
      }
    } catch (_) {}

    final founderPool = totalFund * fPct;
    final laborPool = totalFund * lPct;
    final mainPool = totalFund * mPct;

    final perFounder = founders.isNotEmpty ? founderPool / founders.length : 0.0;
    final perLabor = laborMembers.isNotEmpty ? laborPool / laborMembers.length : 0.0;
    final perShare = totalShares > 0 ? mainPool / totalShares : 0.0;

    int createdCount = 0;
    int nextVNoNum = 0;
    final existingList = await getTransactions();
    for (final t in existingList) {
      final digits = t.vno.replaceAll(RegExp(r'[^0-9]'), '');
      final val = int.tryParse(digits) ?? 0;
      if (val > nextVNoNum) nextVNoNum = val;
    }

    for (final member in members) {
      double myAmount = 0;
      if (member.founder) myAmount += perFounder;
      if (member.labor) myAmount += perLabor;
      myAmount += (member.shares * perShare);

      final rounded = myAmount.roundToDouble();
      if (rounded > 0) {
        nextVNoNum++;
        final vno = 'V-${nextVNoNum.toString().padLeft(4, '0')}';
        final trx = TransactionModel(
          id: '',
          vno: vno,
          date: date,
          type: 'payout',
          member: member.no,
          amount: rounded,
          mode: mode,
          acct: acct,
          note: '$note (শেয়ার: ${member.shares}, প্রতিষ্ঠাতা: ${member.founder ? "হ্যাঁ" : "না"}, শ্রম: ${member.labor ? "হ্যাঁ" : "না"})',
        );

        await addTransaction(trx);
        createdCount++;
      }
    }

    return createdCount;
  }

  /// Get institutions list strictly from Firestore
  static Future<List<String>> getInstitutions() async {
    try {
      final snap = await _firestore.collection('institutions').get();
      return snap.docs
          .map((doc) => (doc.data()['name'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .map((s) => s.contains('স্কুল') ? s.replaceAll('স্কুল', 'স্কু\u200Cল') : s)
          .toList();
    } catch (e) {
      throw ApiException(message: 'প্রতিষ্ঠান তালিকা লোড করা যায়নি। ইন্টারনেট সংযোগ চেক করুন।');
    }
  }
}
