import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/setup/data/models/project_model.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/setup/data/repos/setup_repo.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

/// One member's share of a project profit distribution.
class ProjectPayoutRow {
  final MemberModel member;
  final double amount; // rounded, final
  final double basis; // invested amount, or shares when no investment recorded

  const ProjectPayoutRow({required this.member, required this.amount, required this.basis});
}

/// Full preview of a project profit distribution (pure calculation, no writes).
class ProjectPayoutPreview {
  final ProjectModel project;
  final List<ProjectPayoutRow> rows;
  final double founderPool;
  final double laborPool;
  final double mainPool;
  final bool founderPoolOrphan; // no founder member in project → 20% stays undistributed
  final bool laborPoolOrphan;
  final bool usesInvestmentBasis; // false → member.shares ratio fallback

  const ProjectPayoutPreview({
    required this.project,
    required this.rows,
    required this.founderPool,
    required this.laborPool,
    required this.mainPool,
    required this.founderPoolOrphan,
    required this.laborPoolOrphan,
    required this.usesInvestmentBasis,
  });

  double get totalDistributed => rows.fold(0.0, (acc, r) => acc + r.amount);
}

class TransactionsRepo {
  static final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'transactions';

  /// Get all transactions with optional filters.
  /// If user is a shareholder, strictly isolates results to only their own memberNo.
  static Future<List<TransactionModel>> getTransactions({
    String? memberNo,
    String? dir,
    String? sectorId,
    String? kind,
    String? projectId,
    String? from, // YYYY-MM-DD, inclusive
    String? to, // YYYY-MM-DD, inclusive
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
    if (dir != null && dir.isNotEmpty && dir != 'all') {
      list = list.where((t) => t.dir == dir).toList();
    }
    if (sectorId != null && sectorId.isNotEmpty) {
      list = list.where((t) => t.sectorId == sectorId).toList();
    }
    if (kind != null && kind.isNotEmpty) {
      list = list.where((t) => t.kind == kind).toList();
    }
    if (projectId != null && projectId.isNotEmpty) {
      list = list.where((t) => t.project == projectId).toList();
    }
    if (from != null && from.isNotEmpty) {
      list = list.where((t) => t.date.compareTo(from) >= 0).toList();
    }
    if (to != null && to.isNotEmpty) {
      list = list.where((t) => t.date.compareTo(to) <= 0).toList();
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
    return _nextVoucherNoFrom(list, 0);
  }

  static String _nextVoucherNoFrom(List<TransactionModel> list, int offset) {
    int maxNum = 0;
    for (final t in list) {
      final digits = t.vno.replaceAll(RegExp(r'[^0-9]'), '');
      final val = int.tryParse(digits) ?? 0;
      if (val > maxNum) maxNum = val;
    }
    return 'V-${(maxNum + 1 + offset).toString().padLeft(4, '0')}';
  }

  // ==================== PROJECT PROFIT DISTRIBUTION ====================

  /// Per-member investment in one project (আয় → শেয়ারহোল্ডার, project-tagged). Key = upper-case member no.
  static Future<Map<String, double>> getProjectMemberInvestments(String projectId) async {
    final list = await getTransactions();
    final inv = <String, double>{};
    for (final t in list) {
      if (t.dir == 'in' &&
          t.sectorKey == SectorModel.keyShareholder &&
          t.project == projectId &&
          t.member.isNotEmpty) {
        final no = t.member.toUpperCase();
        inv[no] = (inv[no] ?? 0) + t.amount;
      }
    }
    return inv;
  }

  /// Project income minus project expense, used to prefill the distribution amount.
  static Future<double> getProjectNetProfit(String projectId) async {
    final list = await getTransactions(projectId: projectId);
    double net = 0;
    for (final t in list) {
      if (t.sectorKey != SectorModel.keyProkolpo) continue;
      if (t.dir == 'in') net += t.amount;
      if (t.dir == 'out') net -= t.amount;
    }
    return net;
  }

  /// Pure calculation. Does not write anything.
  static Future<ProjectPayoutPreview> previewProjectDistribution({
    required String projectId,
    required double totalProfit,
  }) async {
    final projects = await SetupRepo.getProjects();
    final project = projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => throw ApiException(message: 'নির্বাচিত প্রকল্পটি খুঁজে পাওয়া যায়নি'),
    );

    final allMembers = await MembersRepo.getMembers(bypassSecurity: true);
    final projectNos = project.memberNos.map((e) => e.toUpperCase()).toSet();
    final members = allMembers.where((m) => projectNos.contains(m.no.toUpperCase())).toList();
    if (members.isEmpty) {
      throw ApiException(message: 'এই প্রকল্পে কোনো শেয়ারহোল্ডার নির্বাচিত নেই');
    }

    final founders = members.where((m) => m.founder).toList();
    final laborMembers = members.where((m) => m.labor).toList();

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

    final founderPool = totalProfit * fPct;
    final laborPool = totalProfit * lPct;
    final mainPool = totalProfit * mPct;
    final founderOrphan = founders.isEmpty;
    final laborOrphan = laborMembers.isEmpty;

    final perFounder = founders.isEmpty ? 0.0 : founderPool / founders.length;
    final perLabor = laborMembers.isEmpty ? 0.0 : laborPool / laborMembers.length;

    // Main pool basis: project investment if any recorded, else member.shares
    final inv = await getProjectMemberInvestments(projectId);
    final usesInv = inv.values.fold(0.0, (a, b) => a + b) > 0;
    final basis = <String, double>{};
    for (final m in members) {
      final no = m.no.toUpperCase();
      basis[no] = usesInv ? (inv[no] ?? 0) : m.shares.toDouble();
    }
    final totalBasis = basis.values.fold(0.0, (a, b) => a + b);
    if (totalBasis <= 0) {
      throw ApiException(message: 'বণ্টনের ভিত্তি (বিনিয়োগ/শেয়ার) শূন্য, বণ্টন সম্ভব নয়');
    }

    final rawRows = <ProjectPayoutRow>[];
    for (final m in members) {
      final no = m.no.toUpperCase();
      final b = basis[no]!;
      final fromMain = mainPool * b / totalBasis;
      double amt = fromMain;
      if (m.founder) amt += perFounder;
      if (m.labor) amt += perLabor;
      rawRows.add(ProjectPayoutRow(member: m, amount: amt.roundToDouble(), basis: b));
    }

    // Rounding residue goes to the largest basis member, so the total matches the pools.
    final distributedTarget = (founderOrphan ? 0.0 : founderPool) +
        (laborOrphan ? 0.0 : laborPool) +
        mainPool;
    final roundedSum = rawRows.fold(0.0, (s, r) => s + r.amount);
    final residue = distributedTarget.roundToDouble() - roundedSum;

    final sorted = [...rawRows]..sort((a, b) => b.basis.compareTo(a.basis));
    final adjusted = <ProjectPayoutRow>[];
    for (final r in rawRows) {
      final isFirst = identical(r, sorted.first);
      adjusted.add(ProjectPayoutRow(
        member: r.member,
        amount: isFirst ? r.amount + residue : r.amount,
        basis: r.basis,
      ));
    }

    return ProjectPayoutPreview(
      project: project,
      rows: adjusted,
      founderPool: founderPool,
      laborPool: laborPool,
      mainPool: mainPool,
      founderPoolOrphan: founderOrphan,
      laborPoolOrphan: laborOrphan,
      usesInvestmentBasis: usesInv,
    );
  }

  /// Writes one profit_payout voucher per member with amount > 0, in one atomic batch.
  static Future<int> doProjectProfitDistribution({
    required String projectId,
    required double totalProfit,
    required String date,
    required String mode,
    required String acct,
    String note = 'মুনাফা বণ্টন',
  }) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'মুনাফা বণ্টনের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }
    if (totalProfit <= 0) {
      throw ApiException(message: 'সঠিক মুনাফার পরিমাণ দিন');
    }

    final preview = await previewProjectDistribution(projectId: projectId, totalProfit: totalProfit);
    final existing = await getTransactions();

    try {
      final batch = _firestore.batch();
      int offset = 0;
      int count = 0;
      final basisLabel = preview.usesInvestmentBasis ? 'বিনিয়োগ' : 'শেয়ার';

      for (final r in preview.rows) {
        if (r.amount <= 0) continue;
        final docRef = _firestore.collection(_collection).doc();
        final vno = _nextVoucherNoFrom(existing, offset);
        offset++;

        final m = r.member;
        final trx = TransactionModel(
          id: docRef.id,
          vno: vno,
          date: date,
          dir: 'out',
          sectorId: SectorModel.idExpShareholder,
          sectorKey: SectorModel.keyShareholder,
          sectorName: 'শেয়ারহোল্ডার',
          project: projectId,
          member: m.no,
          kind: 'profit_payout',
          mode: mode,
          acct: acct,
          amount: r.amount,
          note: '$note — ${preview.project.name} '
              '($basisLabel: ${r.basis.round()}, প্রতিষ্ঠাতা: ${m.founder ? "হ্যাঁ" : "না"}, শ্রম: ${m.labor ? "হ্যাঁ" : "না"})',
        );
        batch.set(docRef, trx.toMap());
        count++;
      }

      await batch.commit();
      return count;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'মুনাফা বণ্টন সংরক্ষণ করা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Get institutions list strictly from Firestore
  static Future<List<String>> getInstitutions() async {
    try {
      final snap = await _firestore.collection('institutions').get();
      return snap.docs
          .map((doc) => (doc.data()['name'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .map((s) => s.contains('স্কুল') ? s.replaceAll('স্কুল', 'স্কু‌ল') : s)
          .toList();
    } catch (e) {
      throw ApiException(message: 'প্রতিষ্ঠান তালিকা লোড করা যায়নি। ইন্টারনেট সংযোগ চেক করুন।');
    }
  }
}
