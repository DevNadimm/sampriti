import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/transactions/data/models/legacy_type_map.dart';

class TransactionModel {
  final String id;
  final String vno; // e.g. "V-0001"
  final String date; // DB: YYYY-MM-DD
  final String dir; // 'in' | 'out' | 'xfer'
  final String sectorId; // sector doc id; '' for bank transfers
  final String sectorKey; // shareholder | prokolpo | donation | custom | bank_transfer
  final String sectorName; // Bangla sector name, copied onto the voucher
  final String project; // ProjectModel.id, '' if none
  final String member; // Member No e.g. "S101"
  final String kind; // '' | 'profit_payout' | 'bank_dep' | 'bank_wd'
  final String mode; // cash | bank | inst
  final String acct; // Bank account id or free text
  final String inst; // legacy only, read-only
  final double amount;
  final String note;
  final String legacyType; // original old `type`, '' for new vouchers

  const TransactionModel({
    required this.id,
    required this.vno,
    required this.date,
    required this.dir,
    this.sectorId = '',
    this.sectorKey = SectorModel.keyCustom,
    this.sectorName = '',
    this.project = '',
    this.member = '',
    this.kind = '',
    this.mode = 'cash',
    this.acct = '',
    this.inst = '',
    required this.amount,
    this.note = '',
    this.legacyType = '',
  });

  /// Date formatted for UI display (dd/MM/yyyy)
  String get uiDate => DateFormatter.ddMMyyyy(date);

  /// Voucher title in Bangla
  String get title {
    if (kind == 'bank_dep') return 'নগদ থেকে ব্যাংকে জমা';
    if (kind == 'bank_wd') return 'ব্যাংক থেকে নগদ উত্তোলন';
    if (kind == 'profit_payout') return 'মুনাফা বণ্টন প্রদান';
    final s = sectorName.isNotEmpty ? sectorName : 'অন্যান্য';
    return dir == 'in' ? 'আয় — $s' : 'ব্যয় — $s';
  }

  /// Sign: +1 inflow, -1 outflow, 0 transfer
  int get sign => dir == 'in' ? 1 : (dir == 'out' ? -1 : 0);

  bool get isInflow => sign > 0;
  bool get isOutflow => sign < 0;
  bool get isTransfer => sign == 0;
  bool get isProfitPayout => kind == 'profit_payout';
  bool get isBankTransfer => kind == 'bank_dep' || kind == 'bank_wd';

  /// Writes new schema. Never writes the old `type` key.
  Map<String, dynamic> toMap() => {
        'id': id,
        'vno': vno,
        'date': DateFormatter.yyyyMMdd(date),
        'dir': dir,
        'sectorId': sectorId,
        'sectorKey': sectorKey,
        'sectorName': sectorName,
        'project': project,
        'member': member,
        'kind': kind,
        'mode': mode,
        'acct': acct,
        'amount': amount,
        'note': note,
        if (legacyType.isNotEmpty) 'legacyType': legacyType,
        'schema': 2,
      };

  /// Reads new schema. If `dir` is missing (old doc), derives every
  /// structural field in memory from the legacy `type`.
  factory TransactionModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawDir = ((map['dir'] as String?) ?? '').trim();
    final oldType = (map['type'] as String?) ?? '';
    final isLegacy = rawDir.isEmpty;
    final legacy = isLegacy ? LegacyTypeMap.resolve(oldType) : null;

    String pick(String key, String? fallback) {
      final v = ((map[key] as String?) ?? '').trim();
      if (v.isNotEmpty) return v;
      return fallback ?? '';
    }

    final inst = (map['inst'] as String?) ?? '';
    final storedProject = pick('project', null);
    final project = storedProject.isNotEmpty
        ? storedProject
        : ((legacy?.projectFromInst ?? false) ? inst : '');

    return TransactionModel(
      id: (map['id'] as String?) ?? docId ?? '',
      vno: (map['vno'] as String?) ?? '',
      date: DateFormatter.yyyyMMdd(map['date']),
      dir: isLegacy ? legacy!.dir : rawDir,
      sectorId: pick('sectorId', legacy?.sectorId),
      sectorKey: pick('sectorKey', legacy?.sectorKey ?? SectorModel.keyCustom),
      sectorName: pick('sectorName', legacy?.sectorName),
      project: project,
      member: (map['member'] as String?) ?? '',
      kind: pick('kind', legacy?.kind),
      mode: (map['mode'] as String?) ?? 'cash',
      acct: (map['acct'] as String?) ?? '',
      inst: inst,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      note: (map['note'] as String?) ?? '',
      legacyType: isLegacy ? oldType : ((map['legacyType'] as String?) ?? ''),
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransactionModel.fromMap(data, doc.id);
  }
}
