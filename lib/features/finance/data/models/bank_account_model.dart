import 'package:cloud_firestore/cloud_firestore.dart';

class BankAccountModel {
  final String id;
  final String bankName;
  final String accountName;
  final String accountNo;
  final String branch;
  final String routingNo;
  final double initialBalance;
  final double currentBalance;
  final String note;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const BankAccountModel({
    required this.id,
    required this.bankName,
    this.accountName = 'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম',
    required this.accountNo,
    this.branch = '',
    this.routingNo = '',
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    this.note = '',
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get statusTitle => isActive ? 'সক্রিয়' : 'নিষ্ক্রিয়';

  String get displayName => branch.isNotEmpty ? '$bankName ($branch)' : bankName;

  Map<String, dynamic> toMap() => {
        'id': id,
        'bankName': bankName,
        'accountName': accountName,
        'accountNo': accountNo,
        'branch': branch,
        'routingNo': routingNo,
        'initialBalance': initialBalance,
        'note': note,
        'isActive': isActive,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory BankAccountModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return BankAccountModel(
      id: docId ?? (map['id'] as String? ?? ''),
      bankName: map['bankName'] as String? ?? '',
      accountName: map['accountName'] as String? ?? 'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম',
      accountNo: map['accountNo'] as String? ?? '',
      branch: map['branch'] as String? ?? '',
      routingNo: map['routingNo'] as String? ?? '',
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] as String? ?? '',
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }

  factory BankAccountModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BankAccountModel.fromMap(data, doc.id);
  }

  BankAccountModel copyWith({
    String? id,
    String? bankName,
    String? accountName,
    String? accountNo,
    String? branch,
    String? routingNo,
    double? initialBalance,
    double? currentBalance,
    String? note,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNo: accountNo ?? this.accountNo,
      branch: branch ?? this.branch,
      routingNo: routingNo ?? this.routingNo,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
