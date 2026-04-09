import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import '../models/discount_code_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'discount_code_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// خدمة الطلبات - إنشاء وإدارة الطلبات
// ═══════════════════════════════════════════════════════════════════════════

class OrderService {
  static final _supabase = Supabase.instance.client;
  static const String _shopId = AuthService.DEFAULT_SHOP_ID;
  static bool? _orderOptionsSchemaSupported;
  static bool? _orderDiscountSchemaSupported;
  static const String _orderOptionsMigrationMessage =
      'قاعدة البيانات تحتاج تحديث دعم الألوان والأحجام قبل إكمال الطلبات التي تحتوي على خيارات المنتج.';

  static const String _orderDiscountMigrationMessage =
      'قاعدة البيانات تحتاج تحديث دعم البرومو كود قبل إكمال الطلب.';

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

  static bool _isMissingOrderOptionsSchemaError(Object error) {
    if (error is! PostgrestException) {
      return false;
    }

    final String details =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
            .toLowerCase();

    return details.contains('42703') &&
        (details.contains('selected_color') ||
            details.contains('selected_size'));
  }

  static bool _isMissingOrderDiscountSchemaError(Object error) {
    if (error is! PostgrestException) {
      return false;
    }

    final String details =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
            .toLowerCase();

    return (details.contains('42703') || details.contains('42p01')) &&
        (details.contains('discount_code') ||
            details.contains('discount_amount'));
  }

  static String? _mapDiscountCodeDatabaseError(Object error) {
    final String details = error.toString().toUpperCase();

    if (details.contains('DISCOUNT_CODE_NOT_FOUND')) {
      return 'رمز الخصم المحدد لم يعد موجودًا';
    }

    if (details.contains('DISCOUNT_CODE_INACTIVE')) {
      return 'هذا البرومو كود غير مفعل حاليًا';
    }

    if (details.contains('DISCOUNT_CODE_EXPIRED')) {
      return 'انتهت صلاحية البرومو كود';
    }

    if (details.contains('DISCOUNT_CODE_MIN_PURCHASE_NOT_MET')) {
      return 'لم يعد الحد الأدنى المطلوب للبرومو كود متحققًا';
    }

    if (details.contains('DISCOUNT_CODE_LIMIT_REACHED')) {
      return 'تم استهلاك هذا البرومو كود بالكامل';
    }

    if (details.contains('DISCOUNT_CODE_INVALID_AMOUNT')) {
      return 'تعذر احتساب خصم صالح لهذا البرومو كود';
    }

    return null;
  }

  static bool _containsSelectedOptions(
    List<Map<String, dynamic>> orderItemsData,
  ) {
    return orderItemsData.any(
      (item) => !ProductOptionSelection.fromJson(item).isEmpty,
    );
  }

  static Map<String, dynamic> _buildLegacyOrderItemPayload(
    Map<String, dynamic> item,
  ) {
    return <String, dynamic>{
      'order_id': item['order_id'],
      'item_id': item['item_id'],
      'quantity': item['quantity'],
      'original_unit_price': item['original_unit_price'],
      'discount_percent_snapshot': item['discount_percent_snapshot'],
      'unit_price': item['unit_price'],
      'line_total': item['line_total'],
      'title_snapshot': item['title_snapshot'],
    };
  }

  static Future<bool> _insertOrderItems(
    List<Map<String, dynamic>> orderItemsData,
  ) async {
    if (_orderOptionsSchemaSupported == false) {
      if (_containsSelectedOptions(orderItemsData)) {
        return false;
      }

      await _supabase.from('order_items').insert(
            orderItemsData.map(_buildLegacyOrderItemPayload).toList(),
          );
      return true;
    }

    try {
      await _supabase.from('order_items').insert(orderItemsData);
      _orderOptionsSchemaSupported = true;
      return true;
    } catch (e) {
      if (!_isMissingOrderOptionsSchemaError(e)) {
        rethrow;
      }

      _orderOptionsSchemaSupported = false;
      if (_containsSelectedOptions(orderItemsData)) {
        return false;
      }

      await _supabase.from('order_items').insert(
            orderItemsData.map(_buildLegacyOrderItemPayload).toList(),
          );
      return true;
    }
  }

  static Map<String, dynamic> _buildLegacyOrderPayload(
    Map<String, dynamic> orderData,
  ) {
    return <String, dynamic>{
      'shop_id': orderData['shop_id'],
      'customer_id': orderData['customer_id'],
      'status': orderData['status'],
      'subtotal': orderData['subtotal'],
      'delivery_fee': orderData['delivery_fee'],
      'total': orderData['total'],
      'note': orderData['note'],
      if (orderData['assigned_location_id'] != null)
        'assigned_location_id': orderData['assigned_location_id'],
    };
  }

  static Future<Map<String, dynamic>?> _insertOrder({
    required Map<String, dynamic> orderData,
    required bool usesDiscountCode,
  }) async {
    if (_orderDiscountSchemaSupported == false) {
      if (usesDiscountCode) {
        return null;
      }

      return await _supabase
          .from('orders')
          .insert(_buildLegacyOrderPayload(orderData))
          .select('id, total')
          .single();
    }

    try {
      final Map<String, dynamic> orderResult = await _supabase
          .from('orders')
          .insert(orderData)
          .select('id, total, discount_amount, discount_code_snapshot')
          .single();
      _orderDiscountSchemaSupported = true;
      return orderResult;
    } catch (error) {
      if (!_isMissingOrderDiscountSchemaError(error)) {
        rethrow;
      }

      _orderDiscountSchemaSupported = false;
      if (usesDiscountCode) {
        return null;
      }

      return await _supabase
          .from('orders')
          .insert(_buildLegacyOrderPayload(orderData))
          .select('id, total')
          .single();
    }
  }

  static Map<String, dynamic> _buildLegacyOrderItem(
    Map<String, dynamic> item,
  ) {
    return <String, dynamic>{
      ...item,
      'selected_color_id': null,
      'selected_color_name': null,
      'selected_color_hex': null,
      'selected_size_id': null,
      'selected_size_name': null,
    };
  }

  static Future<List<Map<String, dynamic>>> _getOrderItemsWithOptions(
    int orderId,
  ) async {
    final data = await _supabase.from('order_items').select('''
          id,
          item_id,
          quantity,
          unit_price,
          line_total,
          title_snapshot,
          selected_color_id,
          selected_color_name,
          selected_color_hex,
          selected_size_id,
          selected_size_name,
          items (
            id,
            title,
            item_images (
              image_path,
              is_primary
            )
          )
        ''').eq('order_id', orderId).order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> _getLegacyOrderItems(
    int orderId,
  ) async {
    final data = await _supabase.from('order_items').select('''
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

    return List<Map<String, dynamic>>.from(data)
        .map(_buildLegacyOrderItem)
        .toList();
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

        final ProductOptionSelection selection =
            ProductOptionSelection.fromJson(cartItem);
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
          'selected_color_id': selection.colorId,
          'selected_color_name': selection.colorName,
          'selected_color_hex': selection.colorHex,
          'selected_size_id': selection.sizeId,
          'selected_size_name': selection.sizeName,
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

      print('📦 بيانات الطلب المرسلة: $orderData');

      final orderResult = await _supabase
          .from('orders')
          .insert(orderData)
          .select('id')
          .single();

      final orderId = orderResult['id'] as int;
      print('📦 تم إنشاء الطلب بـ ID: $orderId');

      // 6. إضافة عناصر الطلب
      for (var orderItem in orderItemsData) {
        orderItem['order_id'] = orderId;
      }
      print('📦 عدد عناصر الطلب: ${orderItemsData.length}');

      final bool orderItemsInserted = await _insertOrderItems(orderItemsData);
      if (!orderItemsInserted) {
        await _supabase.from('orders').delete().eq('id', orderId);
        return {
          'success': false,
          'message': _orderOptionsMigrationMessage,
        };
      }
      print('✅ تم إضافة عناصر الطلب');

      // 7. إضافة سجل الحالة الأولى للطلب (pending)
      try {
        await _supabase.from('order_status_history').insert({
          'order_id': orderId,
          'status': 'pending',
          'notes': 'تم إنشاء الطلب من قبل العميل',
          'created_at': DateTime.now().toIso8601String(),
        });
        print('✅ تم إضافة سجل حالة الطلب الأولية (order_status_history)');
      } catch (e) {
        print('❌ خطأ في إضافة سجل الحالة: $e');
        // نستمر حتى لو فشل إضافة السجل
      }

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
  static Future<Map<String, dynamic>> createOrderWithPromo({
    String? note,
    String? address,
    int? locationId,
    DiscountCodeModel? discountCode,
  }) async {
    if (!AuthService.isLoggedIn) {
      return {'success': false, 'message': 'يجب تسجيل الدخول أولًا'};
    }

    try {
      final int? customerId = await AuthService.getCustomerId();
      if (customerId == null) {
        return {'success': false, 'message': 'لم يتم العثور على حساب العميل'};
      }

      final List<Map<String, dynamic>> cartItems =
          await AuthService.getCartItems();
      if (cartItems.isEmpty) {
        return {'success': false, 'message': 'السلة فارغة'};
      }

      double subtotal = 0;
      final List<Map<String, dynamic>> orderItemsData =
          <Map<String, dynamic>>[];

      for (final Map<String, dynamic> cartItem in cartItems) {
        final Map<String, dynamic>? item =
            cartItem['items'] as Map<String, dynamic>?;
        if (item == null) {
          continue;
        }

        final ProductOptionSelection selection =
            ProductOptionSelection.fromJson(cartItem);
        final int quantity = cartItem['quantity'] as int;
        final double originalUnitPrice = (item['price'] as num).toDouble();
        final int discountPercent =
            (item['discount_percent'] as num?)?.toInt() ?? 0;
        final double unitPrice = _resolveEffectivePrice(item);
        final double lineTotal = unitPrice * quantity;
        subtotal += lineTotal;

        orderItemsData.add(<String, dynamic>{
          'item_id': cartItem['item_id'],
          'quantity': quantity,
          'original_unit_price': originalUnitPrice,
          'discount_percent_snapshot': discountPercent,
          'unit_price': unitPrice,
          'line_total': lineTotal,
          'title_snapshot': item['title'] ?? '',
          'selected_color_id': selection.colorId,
          'selected_color_name': selection.colorName,
          'selected_color_hex': selection.colorHex,
          'selected_size_id': selection.sizeId,
          'selected_size_name': selection.sizeName,
        });
      }

      DiscountCodeCalculation? discountCalculation;
      if (discountCode != null) {
        discountCalculation = await DiscountCodeService.validateCode(
          rawCode: discountCode.code,
          subtotal: subtotal,
        );

        if (!discountCalculation.isApplicable ||
            discountCalculation.discountCode == null) {
          return <String, dynamic>{
            'success': false,
            'message': discountCalculation.message ??
                'تعذر تطبيق البرومو كود على الطلب',
          };
        }
      }

      final double discountAmount = discountCalculation?.discountAmount ?? 0;
      final double total = discountCalculation?.finalTotal ?? subtotal;

      if (address != null) {
        await AuthService.updateCustomerInfo(address: address);
      }

      final Map<String, dynamic> orderData = <String, dynamic>{
        'shop_id': _shopId,
        'customer_id': customerId,
        'status': 'pending',
        'subtotal': subtotal,
        'delivery_fee': 0.0,
        'discount_amount': discountAmount,
        'total': total,
        'note': note,
      };

      if (discountCalculation?.discountCode != null) {
        orderData['discount_code_id'] = discountCalculation!.discountCode!.id;
        orderData['discount_code_snapshot'] =
            discountCalculation.discountCode!.normalizedCode;
      }

      if (locationId != null) {
        orderData['assigned_location_id'] = locationId;
      }

      final Map<String, dynamic>? orderResult = await _insertOrder(
        orderData: orderData,
        usesDiscountCode: discountCalculation?.discountCode != null,
      );

      if (orderResult == null) {
        return <String, dynamic>{
          'success': false,
          'message': _orderDiscountMigrationMessage,
        };
      }

      final int orderId = orderResult['id'] as int;
      final double confirmedTotal =
          (orderResult['total'] as num?)?.toDouble() ?? total;
      final double confirmedDiscountAmount =
          (orderResult['discount_amount'] as num?)?.toDouble() ??
              discountAmount;
      final String? confirmedDiscountCode =
          orderResult['discount_code_snapshot']?.toString();

      for (final Map<String, dynamic> orderItem in orderItemsData) {
        orderItem['order_id'] = orderId;
      }

      final bool orderItemsInserted = await _insertOrderItems(orderItemsData);
      if (!orderItemsInserted) {
        await _supabase.from('orders').delete().eq('id', orderId);
        return <String, dynamic>{
          'success': false,
          'message': _orderOptionsMigrationMessage,
        };
      }

      await _supabase.from('order_status_history').insert(<String, dynamic>{
        'order_id': orderId,
        'status': 'pending',
        'notes': 'تم إنشاء الطلب من قبل العميل',
        'created_at': DateTime.now().toIso8601String(),
      });

      await AuthService.clearCart();

      return <String, dynamic>{
        'success': true,
        'message': 'تم إنشاء الطلب بنجاح',
        'orderId': orderId,
        'total': confirmedTotal,
        'discountAmount': confirmedDiscountAmount,
        'discountCode': confirmedDiscountCode,
      };
    } catch (error) {
      final String? discountError = _mapDiscountCodeDatabaseError(error);
      if (discountError != null) {
        return <String, dynamic>{'success': false, 'message': discountError};
      }

      print('❌ خطأ في إنشاء الطلب مع البرومو كود: $error');
      return <String, dynamic>{
        'success': false,
        'message': 'فشل في إنشاء الطلب. حاول مرة أخرى',
      };
    }
  }

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
      late final List<Map<String, dynamic>> itemsData;
      if (_orderOptionsSchemaSupported == false) {
        itemsData = await _getLegacyOrderItems(orderId);
      } else {
        try {
          itemsData = await _getOrderItemsWithOptions(orderId);
          _orderOptionsSchemaSupported = true;
        } catch (e) {
          if (!_isMissingOrderOptionsSchemaError(e)) {
            rethrow;
          }

          _orderOptionsSchemaSupported = false;
          itemsData = await _getLegacyOrderItems(orderId);
        }
      }

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
