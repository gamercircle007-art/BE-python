class UserModel {
  const UserModel({
    required this.id,
    this.email,
    this.phone,
    this.fullName,
    required this.isActive,
    required this.isVerified,
    required this.emailVerified,
    required this.phoneVerified,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final bool isActive;
  final bool isVerified;
  final bool emailVerified;
  final bool phoneVerified;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
    );
  }
}