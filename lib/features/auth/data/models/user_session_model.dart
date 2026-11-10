enum UserRole {
  admin,
  shareholder,
}

class UserSessionModel {
  final UserRole role;
  final String? memberNo; // e.g. "S101" for shareholder
  final String? name;
  final String? photoUrl;

  const UserSessionModel({
    required this.role,
    this.memberNo,
    this.name,
    this.photoUrl,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isShareholder => role == UserRole.shareholder;

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'memberNo': memberNo,
        'name': name,
        'photoUrl': photoUrl,
      };

  factory UserSessionModel.fromJson(Map<String, dynamic> json) => UserSessionModel(
        role: json['role'] == 'admin' ? UserRole.admin : UserRole.shareholder,
        memberNo: json['memberNo'] as String?,
        name: json['name'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );
}
