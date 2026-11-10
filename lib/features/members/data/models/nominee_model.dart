import 'package:sampriti/core/utils/helpers/date_formatter.dart';

class NomineeModel {
  final String name;
  final String father;
  final String mother;
  final String relation;
  final String nid;
  final String birth;
  final String address;
  final String share; // Percentage e.g. "100"
  final String mobile;
  final String? photo;

  const NomineeModel({
    this.name = '',
    this.father = '',
    this.mother = '',
    this.relation = '',
    this.nid = '',
    this.birth = '',
    this.address = '',
    this.share = '100',
    this.mobile = '',
    this.photo,
  });

  /// Birth date formatted for UI display (dd/MM/yyyy e.g. 02/02/2026)
  String get uiBirth => DateFormatter.ddMMyyyy(birth);

  NomineeModel copyWith({
    String? name,
    String? father,
    String? mother,
    String? relation,
    String? nid,
    String? birth,
    String? address,
    String? share,
    String? mobile,
    String? photo,
  }) {
    return NomineeModel(
      name: name ?? this.name,
      father: father ?? this.father,
      mother: mother ?? this.mother,
      relation: relation ?? this.relation,
      nid: nid ?? this.nid,
      birth: birth ?? this.birth,
      address: address ?? this.address,
      share: share ?? this.share,
      mobile: mobile ?? this.mobile,
      photo: photo ?? this.photo,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'father': father,
        'mother': mother,
        'relation': relation,
        'nid': nid,
        'birth': birth.isNotEmpty ? DateFormatter.yyyyMMdd(birth) : '',
        'address': address,
        'share': share,
        'mobile': mobile,
        'photo': photo,
      };

  factory NomineeModel.fromMap(Map<String, dynamic> map) => NomineeModel(
        name: (map['name'] as String?) ?? '',
        father: (map['father'] as String?) ?? '',
        mother: (map['mother'] as String?) ?? '',
        relation: (map['relation'] as String?) ?? '',
        nid: (map['nid'] as String?) ?? '',
        birth: DateFormatter.yyyyMMdd(map['birth']),
        address: (map['address'] as String?) ?? '',
        share: (map['share'] as String?) ?? '100',
        mobile: (map['mobile'] as String?) ?? '',
        photo: map['photo'] as String?,
      );
}
