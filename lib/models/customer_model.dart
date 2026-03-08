// ═══════════════════════════════════════════════════════════
// 🔐 نموذج العميل (Customer Model) - مع دعم المصادقة
// ═══════════════════════════════════════════════════════════

class Customer {
  final int id;
  final String shopId;
  final String? authUserId; // ✨ الربط مع auth.users
  final String name;
  final String? phone;
  final String? city;
  final String? location;
  final String? address;
  final bool isActive;
  final bool isBanned;
  final DateTime createdAt;
  final DateTime updatedAt;

  // معلومات إضافية من auth.users (إذا كانت متوفرة)
  final String? authEmail;
  final String? authPhone;
  final DateTime? lastSignInAt;

  Customer({
    required this.id,
    required this.shopId,
    this.authUserId,
    required this.name,
    this.phone,
    this.city,
    this.location,
    this.address,
    this.isActive = true,
    this.isBanned = false,
    required this.createdAt,
    required this.updatedAt,
    this.authEmail,
    this.authPhone,
    this.lastSignInAt,
  });

  // التحويل من JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      shopId: json['shop_id'] as String,
      authUserId: json['auth_user_id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isBanned: json['is_banned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authEmail: json['auth_email'] as String?,
      authPhone: json['auth_phone'] as String?,
      lastSignInAt:
          json['last_sign_in_at'] != null
              ? DateTime.parse(json['last_sign_in_at'] as String)
              : null,
    );
  }

  // التحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'auth_user_id': authUserId,
      'name': name,
      'phone': phone,
      'city': city,
      'location': location,
      'address': address,
      'is_active': isActive,
      'is_banned': isBanned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // نسخ مع تعديلات
  Customer copyWith({
    int? id,
    String? shopId,
    String? authUserId,
    String? name,
    String? phone,
    String? city,
    String? location,
    String? address,
    bool? isActive,
    bool? isBanned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      authUserId: authUserId ?? this.authUserId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      location: location ?? this.location,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // هل العميل لديه حساب مصادقة؟
  bool get hasAuthAccount => authUserId != null;

  // هل يمكن للعميل تسجيل الدخول؟
  bool get canLogin => hasAuthAccount && isActive && !isBanned;

  // العنوان الكامل
  String get fullAddress {
    final parts = <String>[];
    if (address?.isNotEmpty ?? false) parts.add(address!);
    if (location?.isNotEmpty ?? false) parts.add(location!);
    if (city?.isNotEmpty ?? false) parts.add(city!);
    return parts.join(' - ');
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, hasAuth: $hasAuthAccount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
