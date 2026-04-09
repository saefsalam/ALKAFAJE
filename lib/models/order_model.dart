import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
// حالات الطلب (Order Status)
// ═══════════════════════════════════════════════════════════

/// حالات الطلب حسب قاعدة البيانات
enum OrderStatus {
  pending, // قيد الانتظار
  confirmed, // مؤكد
  preparing, // قيد التحضير
  shipped, // تم الشحن
  delivered, // تم التوصيل
  cancelled, // ملغي
}

/// امتداد للحصول على معلومات حالة الطلب
extension OrderStatusExtension on OrderStatus {
  /// الاسم العربي للحالة
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'قيد الانتظار';
      case OrderStatus.confirmed:
        return 'مؤكد';
      case OrderStatus.preparing:
        return 'قيد التحضير';
      case OrderStatus.shipped:
        return 'تم الشحن';
      case OrderStatus.delivered:
        return 'تم التوصيل';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }

  /// اللون المناسب للحالة
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return const Color(0xFF1976D2); // أزرق
      case OrderStatus.preparing:
        return const Color(0xFF9C27B0); // بنفسجي
      case OrderStatus.shipped:
        return const Color(0xFF0288D1); // أزرق فاتح
      case OrderStatus.delivered:
        return const Color(0xFF388E3C); // أخضر
      case OrderStatus.cancelled:
        return const Color(0xFFD32F2F); // أحمر
    }
  }

  /// الأيقونة المناسبة للحالة
  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_menu_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  /// نسبة التقدم (للطلبات الجارية)
  double get progress {
    switch (this) {
      case OrderStatus.pending:
        return 0.0;
      case OrderStatus.confirmed:
        return 0.25;
      case OrderStatus.preparing:
        return 0.5;
      case OrderStatus.shipped:
        return 0.75;
      case OrderStatus.delivered:
        return 1.0;
      case OrderStatus.cancelled:
        return 0.0;
    }
  }

  /// هل الطلب نشط (ليس مكتمل أو ملغي)
  bool get isActive {
    return this != OrderStatus.delivered && this != OrderStatus.cancelled;
  }

  /// هل الطلب مكتمل
  bool get isCompleted {
    return this == OrderStatus.delivered;
  }

  /// هل الطلب ملغي
  bool get isCancelled {
    return this == OrderStatus.cancelled;
  }

  /// تحويل من String إلى OrderStatus
  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  /// تحويل إلى String
  String toDbString() {
    return toString().split('.').last;
  }
}

// ═══════════════════════════════════════════════════════════
// نموذج الطلب (Order)
// ═══════════════════════════════════════════════════════════

class Order {
  final int id;
  final String shopId;
  final int customerId;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final int? discountCodeId;
  final String? discountCodeSnapshot;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  // علاقات
  final String? customerName;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.total,
    this.discountCodeId,
    this.discountCodeSnapshot,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.items,
  });

  /// تحويل من JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      shopId: json['shop_id'],
      customerId: json['customer_id'],
      status: OrderStatusExtension.fromString(json['status'] ?? 'pending'),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      discountCodeId: (json['discount_code_id'] as num?)?.toInt(),
      discountCodeSnapshot: json['discount_code_snapshot']?.toString(),
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      customerName: json['customer_name'],
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : null,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'customer_id': customerId,
      'status': status.toDbString(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount_amount': discountAmount,
      'total': total,
      'discount_code_id': discountCodeId,
      'discount_code_snapshot': discountCodeSnapshot,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// عدد المنتجات في الطلب
  int get itemCount => items?.length ?? 0;

  /// نسخ مع تعديل
  Order copyWith({
    int? id,
    String? shopId,
    int? customerId,
    OrderStatus? status,
    double? subtotal,
    double? deliveryFee,
    double? discountAmount,
    double? total,
    int? discountCodeId,
    String? discountCodeSnapshot,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      discountCodeId: discountCodeId ?? this.discountCodeId,
      discountCodeSnapshot: discountCodeSnapshot ?? this.discountCodeSnapshot,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// نموذج عنصر الطلب (Order Item)
// ═══════════════════════════════════════════════════════════

class OrderItem {
  final int id;
  final int orderId;
  final int itemId;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? titleSnapshot;
  final int? selectedColorId;
  final String? selectedColorName;
  final String? selectedColorHex;
  final int? selectedSizeId;
  final String? selectedSizeName;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.titleSnapshot,
    this.selectedColorId,
    this.selectedColorName,
    this.selectedColorHex,
    this.selectedSizeId,
    this.selectedSizeName,
    required this.createdAt,
  });

  String get formattedSelection {
    final List<String> parts = <String>[];
    if (selectedColorName != null && selectedColorName!.trim().isNotEmpty) {
      parts.add('اللون: ${selectedColorName!.trim()}');
    }
    if (selectedSizeName != null && selectedSizeName!.trim().isNotEmpty) {
      parts.add('الحجم: ${selectedSizeName!.trim()}');
    }
    return parts.join(' - ');
  }

  /// تحويل من JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      itemId: json['item_id'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      lineTotal: (json['line_total'] ?? 0).toDouble(),
      titleSnapshot: json['title_snapshot'],
      selectedColorId: (json['selected_color_id'] as num?)?.toInt(),
      selectedColorName: json['selected_color_name']?.toString(),
      selectedColorHex: json['selected_color_hex']?.toString(),
      selectedSizeId: (json['selected_size_id'] as num?)?.toInt(),
      selectedSizeName: json['selected_size_name']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'item_id': itemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
      'title_snapshot': titleSnapshot,
      'selected_color_id': selectedColorId,
      'selected_color_name': selectedColorName,
      'selected_color_hex': selectedColorHex,
      'selected_size_id': selectedSizeId,
      'selected_size_name': selectedSizeName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
