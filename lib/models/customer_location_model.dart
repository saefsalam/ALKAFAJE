import 'package:latlong2/latlong.dart';

// ═══════════════════════════════════════════════════════════════════════════
// نموذج موقع العميل (Customer Location)
// ═══════════════════════════════════════════════════════════════════════════

class CustomerLocation {
  final int? id;
  final String? shopId;
  final int? customerId;
  final String name; // مثال: "المنزل", "العمل", "بيت أمي"
  final double latitude; // L_y في قاعدة البيانات
  final double longitude; // L_X في قاعدة البيانات
  final String? locationName; // اسم المكان من الخريطة
  final String? fullAddress; // العنوان الكامل
  final String? notes; // ملاحظات وعلامات مميزة
  final bool isDefault; // الموقع الرئيسي؟
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerLocation({
    this.id,
    this.shopId,
    this.customerId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.fullAddress,
    this.notes,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  // تحويل من JSON (قاعدة البيانات)
  factory CustomerLocation.fromJson(Map<String, dynamic> json) {
    // PostgreSQL case-sensitive: الأعمدة في قاعدة البيانات هي L_X و L_y
    final latitude = (json['L_y'] as num?)?.toDouble() ??
        (json['l_y'] as num?)?.toDouble() ??
        0.0;
    final longitude = (json['L_X'] as num?)?.toDouble() ??
        (json['l_x'] as num?)?.toDouble() ??
        0.0;

    return CustomerLocation(
      id: json['id'] as int?,
      shopId: json['shop_id'] as String?,
      customerId: json['customer_id'] as int?,
      name: json['name'] as String? ?? 'موقع',
      latitude: latitude,
      longitude: longitude,
      locationName: json['location_name'] as String?,
      fullAddress: json['full_address'] as String?,
      notes: json['notes'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // تحويل إلى JSON (للإرسال لقاعدة البيانات)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (shopId != null) 'shop_id': shopId,
      if (customerId != null) 'customer_id': customerId,
      'name': name,
      'L_y': latitude, // استخدام الأسماء الصحيحة من قاعدة البيانات
      'L_X': longitude, // استخدام الأسماء الصحيحة من قاعدة البيانات
      if (locationName != null) 'location_name': locationName,
      if (fullAddress != null) 'full_address': fullAddress,
      if (notes != null) 'notes': notes,
      'is_default': isDefault,
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // الحصول على LatLng للخريطة
  LatLng get position => LatLng(latitude, longitude);

  // نسخ مع تغييرات
  CustomerLocation copyWith({
    int? id,
    String? shopId,
    int? customerId,
    String? name,
    double? latitude,
    double? longitude,
    String? locationName,
    String? fullAddress,
    String? notes,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerLocation(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      fullAddress: fullAddress ?? this.fullAddress,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // عرض النص المختصر للموقع
  String get displayText {
    if (fullAddress != null && fullAddress!.isNotEmpty) {
      return fullAddress!;
    }
    if (locationName != null && locationName!.isNotEmpty) {
      return locationName!;
    }
    return 'موقع غير محدد';
  }

  @override
  String toString() {
    return 'CustomerLocation(id: $id, name: $name, lat: $latitude, lng: $longitude, isDefault: $isDefault)';
  }
}
