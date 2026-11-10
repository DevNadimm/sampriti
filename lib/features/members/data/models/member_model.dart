import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'nominee_model.dart';

class MemberModel {
  final String no;
  final String nameBn;
  final String nameEn;
  final String father;
  final String mother;
  final String spouse;
  final String nid;
  final String birth;
  final String address;
  final String job;
  final String mobile;
  final int shares;
  final bool founder;
  final bool labor; // শ্রমদাতা
  final String? pin; // Hashed pin
  final String? plainPin; // Plain PIN (visible to admin, used for pin sheets)
  final String? photo; // Photo URL or base64
  final List<NomineeModel> nominees;

  const MemberModel({
    required this.no,
    required this.nameBn,
    this.nameEn = '',
    this.father = '',
    this.mother = '',
    this.spouse = '',
    this.nid = '',
    this.birth = '',
    this.address = '',
    this.job = '',
    this.mobile = '',
    this.shares = 1,
    this.founder = false,
    this.labor = false,
    this.pin,
    this.plainPin,
    this.photo,
    this.nominees = const [],
  });

  String get displayName => nameBn.isNotEmpty ? nameBn : nameEn;

  /// Birth date formatted for UI display (dd/MM/yyyy e.g. 02/02/2026)
  String get uiBirth => DateFormatter.ddMMyyyy(birth);

  MemberModel copyWith({
    String? no,
    String? nameBn,
    String? nameEn,
    String? father,
    String? mother,
    String? spouse,
    String? nid,
    String? birth,
    String? address,
    String? job,
    String? mobile,
    int? shares,
    bool? founder,
    bool? labor,
    String? pin,
    String? plainPin,
    String? photo,
    List<NomineeModel>? nominees,
  }) {
    return MemberModel(
      no: no ?? this.no,
      nameBn: nameBn ?? this.nameBn,
      nameEn: nameEn ?? this.nameEn,
      father: father ?? this.father,
      mother: mother ?? this.mother,
      spouse: spouse ?? this.spouse,
      nid: nid ?? this.nid,
      birth: birth ?? this.birth,
      address: address ?? this.address,
      job: job ?? this.job,
      mobile: mobile ?? this.mobile,
      shares: shares ?? this.shares,
      founder: founder ?? this.founder,
      labor: labor ?? this.labor,
      pin: pin ?? this.pin,
      plainPin: plainPin ?? this.plainPin,
      photo: photo ?? this.photo,
      nominees: nominees ?? this.nominees,
    );
  }

  Map<String, dynamic> toMap() => {
        'no': no,
        'nameBn': nameBn,
        'nameEn': nameEn,
        'father': father,
        'mother': mother,
        'spouse': spouse,
        'nid': nid,
        'birth': birth.isNotEmpty ? DateFormatter.yyyyMMdd(birth) : '',
        'address': address,
        'job': job,
        'mobile': mobile,
        'shares': shares,
        'founder': founder,
        'labor': labor,
        'pin': pin,
        if (plainPin != null) 'plainPin': plainPin,
        'photo': photo,
        'nominees': nominees.map((n) => n.toMap()).toList(),
      };

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    final rawNominees = map['nominees'] as List<dynamic>? ?? [];
    return MemberModel(
      no: (map['no'] as String?) ?? '',
      nameBn: (map['nameBn'] as String?) ?? '',
      nameEn: (map['nameEn'] as String?) ?? '',
      father: (map['father'] as String?) ?? '',
      mother: (map['mother'] as String?) ?? '',
      spouse: (map['spouse'] as String?) ?? '',
      nid: (map['nid'] as String?) ?? '',
      birth: DateFormatter.yyyyMMdd(map['birth']),
      address: (map['address'] as String?) ?? '',
      job: (map['job'] as String?) ?? '',
      mobile: (map['mobile'] as String?) ?? '',
      shares: (map['shares'] as num?)?.toInt() ?? 1,
      founder: (map['founder'] as bool?) ?? false,
      labor: (map['labor'] as bool?) ?? false,
      pin: map['pin'] as String?,
      plainPin: map['plainPin'] as String?,
      photo: map['photo'] as String?,
      nominees: rawNominees
          .whereType<Map<String, dynamic>>()
          .map((n) => NomineeModel.fromMap(n))
          .toList(),
    );
  }

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MemberModel.fromMap(data);
  }
}
