import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import '../models/order_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// خدمة الطلبات - إنشاء وإدارة الطلبات
// ═══════════════════════════════════════════════════════════════════════════

class OrderService {
  static final _supabase = Supabase.instance.client;
  static const String _shopId = AuthService.DEFAULT_SHOP_ID;

  static double _resolveEffectivePrice(Map<String, dynamic> item) {
    final double basePrice = (item['price'] as num).toDouble();
    final num? discountPriceRaw = item['discount_price'] as num?;
    final int discountPercent =
        (item['discount_percent'] as num?)?.toInt() ?? 0;

    if (discountPriceRaw != null) {
      final double discountPrice = discountPriceRaw.toDouble();
      if (discountPrice > 0 && discountPrice < basePrice) {
        return discountPrice;
      }
    }

    if (discountPercent > 0 && discountPercent < 100) {
      return basePrice * (1 - (discountPercent / 100));
    }

    return basePrice;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // مناطق التوصيل (Delivery Zones)
  // ═══════════════════════════════════════════════════════════════════════════

  /// جلب جميع مناطق التوصيل المتاحة
  static Future<List<Map<String, dynamic>>> getDeliveryZones() async {
    try {
      final data = await _supabase
          .from('delivery_zones')
          .select('id, city, price')
          .eq('shop_id', _shopId)
          .order('city');

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ خطأ في جلب مناطق التوصيل: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إنشاء طلب جديد
  // ═══════════════════════════════════════════════════════════════════════════

  /// إنشاء طلب من عناصر السلة الحالية
  /// [city] المنطقة المختارة للتوصيل
  /// [deliveryFee] رسوم التوصيل
  /// [note] ملاحظة اختيارية
  /// [address] عنوان التوصيل التفصيلي
  static Future<Map<String, dynamic>> createOrder({
    String? note,
    String? address,
    int? locationId, // إضافة location_id
  }) async {
    if (!AuthService.isLoggedIn) {
      return {'success': false, 'message': 'يجب تسجيل الدخول أولاً'};
    }

    try {
      // 1. الحصول على customer_id
      final customerId = await AuthService.getCustomerId();
      if (customerId == null) {
        return {'success': false, 'message': 'لم يتم العثور على حساب العميل'};
      }

      // 2. جلب عناصر السلة
      final cartItems = await AuthService.getCartItems();
      if (cartItems.isEmpty) {
        return {'success': false, 'message': 'السلة فارغة'};
      }

      // 3. حساب المبلغ الفرعي
      double subtotal = 0;
      List<Map<String, dynamic>> orderItemsData = [];

      for (var cartItem in cartItems) {
        final item = cartItem['items'];
        if (item == null) continue;

        final quantity = cartItem['quantity'] as int;
        final double originalUnitPrice = (item['price'] as num).toDouble();
        final int discountPercent =
            (item['discount_percent'] as num?)?.toInt() ?? 0;
        final unitPrice = _resolveEffectivePrice(item);
        final lineTotal = unitPrice * quantity;
        subtotal += lineTotal;

        orderItemsData.add({
          'item_id': cartItem['item_id'],
          'quantity': quantity,
          'original_unit_price': originalUnitPrice,
          'discount_percent_snapshot': discountPercent,
          'unit_price': unitPrice,
          'line_total': lineTotal,
          'title_snapshot': item['title'] ?? '',
        });
      }

      final total = subtotal; // لا يوجد رسوم توصيل

      // 4. تحديث عنوان العميل إذا كان موجوداً
      if (address != null) {
        await AuthService.updateCustomerInfo(
          address: address,
        );
      }

      // 5. إنشاء الطلب
      final orderData = {
        'shop_id': _shopId,
        'customer_id': customerId,
        'status': 'pending',
        'subtotal': subtotal,
        'delivery_fee': 0.0, // لا توجد رسوم توصيل
        'total': total,
        'note': note,
      };

      // إضافة location_id إذا كان موجوداً
      if (locationId != null) {
        orderData['assigned_location_id'] = locationId;
      }

      final orderResult = await _supabase
          .from('orders')
          .insert(orderData)
          .select('id')
          .single();

      final orderId = orderResult['id'] as int;

      // 6. إضافة عناصر الطلب
      for (var orderItem in orderItemsData) {
        orderItem['order_id'] = orderId;
      }

      await _supabase.from('order_items').insert(orderItemsData);

      // 7. إضافة سجل حالة الطلب
      await _supabase.from('order_status_history').insert({
        'order_id': orderId,
        'status': 'pending',
        'changed_by': AuthService.authUserId,
        'notes': 'تم إنشاء الطلب',
      });

      // 8. تفريغ السلة بعد إنشاء الطلب بنجاح
      await AuthService.clearCart();

      print('✅ تم إنشاء الطلب بنجاح - order_id: $orderId');

      return {
        'success': true,
        'message': 'تم إنشاء الطلب بنجاح',
        'orderId': orderId,
        'total': total,
      };
    } catch (e) {
      print('❌ خطأ في إنشاء الطلب: $e');
      return {'success': false, 'message': 'فشل في إنشاء الطلب. حاول مرة أخرى'};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // جلب طلبات العميل
  // ═══════════════════════════════════════════════════════════════════════════

  /// جلب جميع طلبات العميل الحالي
  static Future<List<Order>> getMyOrders() async {
    if (!AuthService.isLoggedIn) return [];

    try {
      final customerId = await AuthService.getCustomerId();
      if (customerId == null) return [];

      final data = await _supabase
          .from('orders')
          .select('*')
          .eq('shop_id', _shopId)
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return data.map<Order>((json) => Order.fromJson(json)).toList();
    } catch (e) {
      print('❌ خطأ في جلب الطلبات: $e');
      return [];
    }
  }

  /// جلب طلبات العميل بحسب الحالة
  static Future<List<Order>> getMyOrdersByStatus(List<String> statuses) async {
    if (!AuthService.isLoggedIn) return [];

    try {
      final customerId = await AuthService.getCustomerId();
      if (customerId == null) return [];

      final data = await _supabase
          .from('orders')
          .select('*')
          .eq('shop_id', _shopId)
          .eq('customer_id', customerId)
          .inFilter('status', statuses)
          .order('created_at', ascending: false);

      return data.map<Order>((json) => Order.fromJson(json)).toList();
    } catch (e) {
      print('❌ خطأ في جلب الطلبات: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تفاصيل طلب واحد
  // ═══════════════════════════════════════════════════════════════════════════

  /// جلب تفاصيل طلب مع عناصره
  static Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      // جلب الطلب
      final orderData = await _supabase
          .from('orders')
          .select('*, customers(name, phone, city, address)')
          .eq('id', orderId)
          .single();

      // جلب عناصر الطلب مع بيانات المنتج والصور
      final itemsData = await _supabase.from('order_items').select('''
            id,
            item_id,
            quantity,
            unit_price,
            line_total,
            title_snapshot,
            items (
              id,
              title,
              item_images (
                image_path,
                is_primary
              )
            )
          ''').eq('order_id', orderId).order('created_at');

      // جلب سجل حالات الطلب
      final statusHistory = await _supabase
          .from('order_status_history')
          .select('id, status, notes, created_at')
          .eq('order_id', orderId)
          .order('created_at');

      return {
        'order': orderData,
        'items': itemsData,
        'status_history': statusHistory,
      };
    } catch (e) {
      print('❌ خطأ في جلب تفاصيل الطلب: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إلغاء طلب
  // ═══════════════════════════════════════════════════════════════════════════

  /// إلغاء طلب (فقط إذا كان pending)
  static Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    if (!AuthService.isLoggedIn) {
      return {'success': false, 'message': 'يجب تسجيل الدخول'};
    }

    try {
      // التحقق من حالة الطلب
      final order = await _supabase
          .from('orders')
          .select('status, customer_id')
          .eq('id', orderId)
          .single();

      if (order['status'] != 'pending') {
        return {
          'success': false,
          'message': 'لا يمكن إلغاء الطلب بعد تأكيده',
        };
      }

      // التحقق من أن الطلب يخص العميل الحالي
      final customerId = await AuthService.getCustomerId();
      if (order['customer_id'] != customerId) {
        return {'success': false, 'message': 'لا يمكنك إلغاء هذا الطلب'};
      }

      // تحديث الحالة
      await _supabase.from('orders').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // إضافة سجل الحالة
      await _supabase.from('order_status_history').insert({
        'order_id': orderId,
        'status': 'cancelled',
        'changed_by': AuthService.authUserId,
        'notes': 'تم إلغاء الطلب بواسطة العميل',
      });

      return {'success': true, 'message': 'تم إلغاء الطلب بنجاح'};
    } catch (e) {
      print('❌ خطأ في إلغاء الطلب: $e');
      return {'success': false, 'message': 'فشل في إلغاء الطلب'};
    }
  }
}
