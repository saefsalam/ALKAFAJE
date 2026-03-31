import 'package:flutter/material.dart';

import 'order_model.dart';

class AppNotification {
  final String id;
  final int? databaseId;
  final int? orderId;
  final OrderStatus? orderStatus;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String source;
  final Map<String, dynamic>? payload;

  const AppNotification({
    required this.id,
    this.databaseId,
    this.orderId,
    this.orderStatus,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.source,
    this.payload,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      databaseId: json['database_id'] as int?,
      orderId: json['order_id'] as int?,
      orderStatus: json['order_status'] != null
          ? OrderStatusExtension.fromString(json['order_status'] as String)
          : null,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      source: json['source'] as String? ?? 'local',
      payload: json['payload'] != null
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
    );
  }

  factory AppNotification.fromSupabaseRow(Map<String, dynamic> row) {
    return AppNotification(
      id: 'db_${row['id']}',
      databaseId: row['id'] as int?,
      orderId: row['order_id'] as int?,
      orderStatus: row['order_status'] != null
          ? OrderStatusExtension.fromString(row['order_status'] as String)
          : null,
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
      isRead: row['is_read'] as bool? ?? false,
      source: 'database',
      payload: row['payload'] != null
          ? Map<String, dynamic>.from(row['payload'] as Map)
          : null,
    );
  }

  factory AppNotification.fromStatusHistory(
    Map<String, dynamic> row, {
    bool isRead = false,
  }) {
    final orderId = row['order_id'] as int?;
    final orderStatus = OrderStatusExtension.fromString(
      row['status'] as String? ?? 'pending',
    );
    final message = NotificationMessageBuilder.forOrderStatus(
      status: orderStatus,
      orderId: orderId ?? 0,
      notes: row['notes'] as String?,
    );

    return AppNotification(
      id: 'history_${row['id']}',
      orderId: orderId,
      orderStatus: orderStatus,
      title: message.title,
      body: message.body,
      createdAt: DateTime.parse(row['created_at'] as String),
      isRead: isRead,
      source: 'history',
      payload: {
        'history_id': row['id'],
        'notes': row['notes'],
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'database_id': databaseId,
      'order_id': orderId,
      'order_status': orderStatus?.toDbString(),
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'source': source,
      'payload': payload,
    };
  }

  AppNotification copyWith({
    String? id,
    int? databaseId,
    int? orderId,
    OrderStatus? orderStatus,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? source,
    Map<String, dynamic>? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      orderId: orderId ?? this.orderId,
      orderStatus: orderStatus ?? this.orderStatus,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      source: source ?? this.source,
      payload: payload ?? this.payload,
    );
  }

  Color get accentColor => orderStatus?.color ?? Colors.blueGrey;

  IconData get icon => orderStatus?.icon ?? Icons.notifications_active_rounded;
}

class NotificationMessage {
  final String title;
  final String body;

  const NotificationMessage({required this.title, required this.body});
}

class NotificationMessageBuilder {
  static NotificationMessage forOrderStatus({
    required OrderStatus status,
    required int orderId,
    String? notes,
  }) {
    final orderCode = '#$orderId';
    final cleanNotes = _normalizeNotes(notes);

    switch (status) {
      case OrderStatus.pending:
        return NotificationMessage(
          title: 'تم استلام طلبك $orderCode',
          body: cleanNotes ?? 'وصلنا طلبك وسيتم مراجعته وتأكيده خلال وقت قصير.',
        );
      case OrderStatus.confirmed:
        return NotificationMessage(
          title: 'تم تأكيد طلبك $orderCode',
          body: cleanNotes ?? 'تم اعتماد الطلب وبدأنا تجهيز الخطوة التالية له.',
        );
      case OrderStatus.preparing:
        return NotificationMessage(
          title: 'طلبك $orderCode قيد التحضير',
          body: cleanNotes ?? 'يتم الآن تجهيز المنتجات استعدادًا لإرسالها.',
        );
      case OrderStatus.shipped:
        return NotificationMessage(
          title: 'طلبك $orderCode في الطريق',
          body: cleanNotes ?? 'تم شحن الطلب وهو الآن في طريقه إليك.',
        );
      case OrderStatus.delivered:
        return NotificationMessage(
          title: 'تم تسليم طلبك $orderCode',
          body: cleanNotes ?? 'اكتمل الطلب بنجاح. نتمنى أن تكون التجربة ممتازة.',
        );
      case OrderStatus.cancelled:
        return NotificationMessage(
          title: 'تم إلغاء طلبك $orderCode',
          body: cleanNotes ?? 'تم إلغاء الطلب. إذا لم تطلب الإلغاء، تواصل معنا.',
        );
    }
  }

  static String? _normalizeNotes(String? notes) {
    final trimmed = notes?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}