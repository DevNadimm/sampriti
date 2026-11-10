import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';

class TransactionModel {
  final String id;
  final String vno; // e.g. "V-0001"
  final String date; // In DB: YYYY-MM-DD
  final String type; // share_in, inst_income, donation, loan_return, plan_dep, inst_invest, inst_loan, inst_subsidy, eid_bonus, payout, expense, bank_dep, bank_wd
  final String member; // Member No e.g. "S101"
  final String inst; // Institution ID e.g. "i1"
  final String mode; // bank, cash, inst
  final String acct; // Bank Account ID
  final String plan; // Investment Plan ID
  final double amount;
  final String cat; // e.g. বেতন, মেরামত, ইত্যাদি
  final String note;

  const TransactionModel({
    required this.id,
    required this.vno,
    required this.date,
    required this.type,
    this.member = '',
    this.inst = '',
    this.mode = 'cash',
    this.acct = '',
    this.plan = '',
    required this.amount,
    this.cat = '',
    this.note = '',
  });

  /// Date formatted for UI display (dd/MM/yyyy e.g. 02/02/2026)
  String get uiDate => DateFormatter.ddMMyyyy(date);

  /// Transaction type title in Bengali
  String get typeTitle {
    switch (type) {
      case 'share_in':
        return 'সদস্যের বিনিয়োগ জমা';
      case 'inst_income':
        return 'প্রতিষ্ঠানের আয় জমা';
      case 'donation':
        return 'সদস্য ডোনেশন';
      case 'loan_return':
        return 'লোন ফেরত প্রাপ্তি';
      case 'plan_dep':
        return 'প্রকল্পে কিস্তি জমা';
      case 'inst_invest':
        return 'প্রতিষ্ঠানে বিনিয়োগ';
      case 'inst_loan':
        return 'প্রতিষ্ঠানকে লোন প্রদান';
      case 'inst_subsidy':
        return 'ভর্তুকি প্রদান';
      case 'eid_bonus':
        return 'ঈদ বোনাস প্রদান';
      case 'payout':
        return 'মুনাফা বণ্টন প্রদান';
      case 'expense':
        return 'অন্যান্য ব্যয়';
      case 'bank_dep':
        return 'নগদ থেকে ব্যাংকে জমা';
      case 'bank_wd':
        return 'ব্যাংক থেকে নগদ উত্তোলন';
      default:
        return type;
    }
  }

  /// Sign: +1 (Inflow), -1 (Outflow), 0 (Internal transfer)
  int get sign {
    if (['share_in', 'inst_income', 'donation', 'loan_return', 'plan_dep'].contains(type)) {
      return 1;
    }
    if (['inst_invest', 'inst_loan', 'inst_subsidy', 'eid_bonus', 'payout', 'expense'].contains(type)) {
      return -1;
    }
    return 0; // Internal transfers
  }

  bool get isInflow => sign > 0;
  bool get isOutflow => sign < 0;
  bool get isTransfer => sign == 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'vno': vno,
        'date': DateFormatter.yyyyMMdd(date),
        'type': type,
        'member': member,
        'inst': inst,
        'mode': mode,
        'acct': acct,
        'plan': plan,
        'amount': amount,
        'cat': cat,
        'note': note,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map, [String? docId]) => TransactionModel(
        id: (map['id'] as String?) ?? docId ?? '',
        vno: (map['vno'] as String?) ?? '',
        date: DateFormatter.yyyyMMdd(map['date']),
        type: (map['type'] as String?) ?? 'share_in',
        member: (map['member'] as String?) ?? '',
        inst: (map['inst'] as String?) ?? '',
        mode: (map['mode'] as String?) ?? 'cash',
        acct: (map['acct'] as String?) ?? '',
        plan: (map['plan'] as String?) ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        cat: (map['cat'] as String?) ?? '',
        note: (map['note'] as String?) ?? '',
      );

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TransactionModel.fromMap(data, doc.id);
  }
}
