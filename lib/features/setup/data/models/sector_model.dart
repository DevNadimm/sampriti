import 'package:cloud_firestore/cloud_firestore.dart';

enum SectorType {
  income,
  expense,
}

class SectorModel {
  // Fixed System Keys
  static const String keyShareholder = 'shareholder';
  static const String keyProkolpo = 'prokolpo';
  static const String keyDonation = 'donation';
  static const String keyCustom = 'custom';

  // Fixed System Document IDs
  static const String idIncShareholder = 'sys_inc_shareholder';
  static const String idIncProkolpo = 'sys_inc_prokolpo';
  static const String idExpShareholder = 'sys_exp_shareholder';
  static const String idExpProkolpo = 'sys_exp_prokolpo';
  static const String idExpDonation = 'sys_exp_donation';

  final String id;
  final String name;
  final String description;
  final SectorType type;
  final String key;
  final bool isSystem;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const SectorModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    this.key = keyCustom,
    this.isSystem = false,
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get typeTitle => type == SectorType.income ? 'আয়ের খাত' : 'ব্যয়ের খাত';

  /// Predefined permanent system sectors list
  static List<SectorModel> getSystemSectors(SectorType type) {
    if (type == SectorType.income) {
      return [
        const SectorModel(
          id: idIncShareholder,
          name: 'শেয়ারহোল্ডার',
          description: 'শেয়ার মূলধন, মাসিক সঞ্চয় বা শেয়ারহোল্ডারদের জমা',
          type: SectorType.income,
          key: keyShareholder,
          isSystem: true,
          isActive: true,
        ),
        const SectorModel(
          id: idIncProkolpo,
          name: 'প্রকল্প',
          description: 'প্রকল্পের ইনভেস্টমেন্ট হতে প্রাপ্ত আয় ও লভ্যাংশ',
          type: SectorType.income,
          key: keyProkolpo,
          isSystem: true,
          isActive: true,
        ),
      ];
    } else {
      return [
        const SectorModel(
          id: idExpShareholder,
          name: 'শেয়ারহোল্ডার',
          description: 'শেয়ারহোল্ডারদের মুনাফা বণ্টন বা মূলধন ফেরত',
          type: SectorType.expense,
          key: keyShareholder,
          isSystem: true,
          isActive: true,
        ),
        const SectorModel(
          id: idExpProkolpo,
          name: 'প্রকল্প',
          description: 'নতুন প্রকল্পে বিনিয়োগ বা প্রকল্প পরিচালন ব্যয়',
          type: SectorType.expense,
          key: keyProkolpo,
          isSystem: true,
          isActive: true,
        ),
        const SectorModel(
          id: idExpDonation,
          name: 'ডোনেশন',
          description: 'সামাজিক অনুদান বা কল্যাণ তহবিল ব্যয়',
          type: SectorType.expense,
          key: keyDonation,
          isSystem: true,
          isActive: true,
        ),
      ];
    }
  }

  /// Custom khats created once by the migration for old voucher types.
  /// Deliberately NOT system (no `sys_` prefix) so the admin can rename or delete them.
  static List<SectorModel> getSeededLegacySectors(SectorType type) {
    if (type == SectorType.income) {
      return const [
        SectorModel(
          id: 'legacy_inc_loan_return',
          name: 'লোন ফেরত প্রাপ্তি',
          description: 'প্রতিষ্ঠানের দেওয়া লোন ফেরত',
          type: SectorType.income,
          key: keyCustom,
        ),
        SectorModel(
          id: 'legacy_inc_donation_received',
          name: 'প্রাপ্ত ডোনেশন / অনুদান',
          description: 'বাইরে থেকে প্রাপ্ত ডোনেশন বা অনুদান',
          type: SectorType.income,
          key: keyCustom,
        ),
      ];
    }
    return const [
      SectorModel(
        id: 'legacy_exp_inst_loan',
        name: 'প্রতিষ্ঠানকে লোন প্রদান',
        description: 'প্রতিষ্ঠানকে প্রদত্ত লোন',
        type: SectorType.expense,
        key: keyCustom,
      ),
      SectorModel(
        id: 'legacy_exp_subsidy',
        name: 'ভর্তুকি প্রদান',
        description: 'ভর্তুকি হিসেবে প্রদত্ত অর্থ',
        type: SectorType.expense,
        key: keyCustom,
      ),
      SectorModel(
        id: 'legacy_exp_eid_bonus',
        name: 'ঈদ বোনাস প্রদান',
        description: 'ঈদ বোনাস',
        type: SectorType.expense,
        key: keyCustom,
      ),
      SectorModel(
        id: 'legacy_exp_general',
        name: 'অন্যান্য সাধারণ ব্যয়',
        description: 'বিবিধ সাধারণ ব্যয়',
        type: SectorType.expense,
        key: keyCustom,
      ),
    ];
  }

  SectorModel copyWith({
    String? id,
    String? name,
    String? description,
    SectorType? type,
    String? key,
    bool? isSystem,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return SectorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      key: key ?? this.key,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'description': description.trim(),
        'type': type.name,
        'key': key.trim().isEmpty ? keyCustom : key.trim(),
        'isSystem': isSystem,
        'isActive': isActive,
        'createdAt': createdAt.isNotEmpty ? createdAt : DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  factory SectorModel.fromMap(Map<String, dynamic> map, [String? docId, SectorType? fallbackType]) {
    final typeStr = map['type']?.toString();
    final parsedType = typeStr == 'expense'
        ? SectorType.expense
        : (typeStr == 'income' ? SectorType.income : (fallbackType ?? SectorType.income));

    final docIdStr = docId ?? map['id']?.toString() ?? '';
    final isExplicitSystem = map['isSystem'] is bool ? map['isSystem'] as bool : false;
    final isSystem = isExplicitSystem || docIdStr.startsWith('sys_');

    String sectorKey = (map['key'] ?? '').toString().trim();
    if (sectorKey.isEmpty) {
      if (docIdStr == idIncShareholder || docIdStr == idExpShareholder) {
        sectorKey = keyShareholder;
      } else if (docIdStr == idIncProkolpo || docIdStr == idExpProkolpo) {
        sectorKey = keyProkolpo;
      } else if (docIdStr == idExpDonation) {
        sectorKey = keyDonation;
      } else {
        sectorKey = isSystem ? docIdStr.replaceFirst('sys_inc_', '').replaceFirst('sys_exp_', '') : keyCustom;
      }
    }

    return SectorModel(
      id: docIdStr,
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      type: parsedType,
      key: sectorKey,
      isSystem: isSystem,
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      createdAt: (map['createdAt'] ?? '').toString(),
      updatedAt: (map['updatedAt'] ?? '').toString(),
    );
  }

  factory SectorModel.fromFirestore(DocumentSnapshot doc, [SectorType? type]) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return SectorModel.fromMap(data, doc.id, type);
  }
}
