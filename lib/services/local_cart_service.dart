import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'cart_update_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// خدمة السلة المحلية - تخزين السلة محلياً قبل تسجيل الدخول
// ═══════════════════════════════════════════════════════════════════════════

class LocalCartService {
  static const String _cartKey = 'local_cart';
  static final _supabase = Supabase.instance.client;

  // حفظ السلة محلياً
  static Future<bool> saveLocalCart(Map<int, int> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(
        cartItems.map((key, value) => MapEntry(key.toString(), value)),
      );
      await prefs.setString(_cartKey, cartJson);
      return true;
    } catch (e) {
      print('❌ خطأ في حفظ السلة محلياً: $e');
      return false;
    }
  }

  // تحميل السلة المحلية
  static Future<Map<int, int>> loadLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson == null) return {};

      final Map<String, dynamic> decoded = jsonDecode(cartJson);
      return decoded.map(
        (key, value) => MapEntry(int.parse(key), value as int),
      );
    } catch (e) {
      print('❌ خطأ في تحميل السلة المحلية: $e');
      return {};
    }
  }

  // مسح السلة المحلية
  static Future<bool> clearLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      return true;
    } catch (e) {
      print('❌ خطأ في مسح السلة المحلية: $e');
      return false;
    }
  }

  // نقل السلة المحلية إلى قاعدة البيانات
  static Future<bool> syncCartToDatabase(String authUserId) async {
    try {
      final localCart = await loadLocalCart();
      if (localCart.isEmpty) return true;

      // الحصول على customer_id (bigint) من auth_user_id (uuid)
      final customerResponse = await _supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (customerResponse == null) {
        print('❌ لم يتم العثور على سجل العميل');
        return false;
      }

      final customerId = customerResponse['id'] as int;

      // التحقق من وجود سلة موجودة أو إنشاء سلة جديدة
      var cartResponse = await _supabase
          .from('carts')
          .select('id')
          .eq('customer_id', customerId)
          .eq('shop_id', SupabaseConfig.shopId)
          .maybeSingle();

      int cartId;
      if (cartResponse != null) {
        cartId = cartResponse['id'] as int;
      } else {
        // إنشاء سلة جديدة
        final newCart = await _supabase
            .from('carts')
            .insert({
              'shop_id': SupabaseConfig.shopId,
              'customer_id': customerId,
            })
            .select('id')
            .single();
        cartId = newCart['id'] as int;
      }

      // إضافة المنتجات
      for (var entry in localCart.entries) {
        // التحقق من وجود المنتج في السلة
        final existingItem = await _supabase
            .from('cart_items')
            .select('id, quantity')
            .eq('cart_id', cartId)
            .eq('item_id', entry.key)
            .maybeSingle();

        if (existingItem != null) {
          // تحديث الكمية
          await _supabase.from('cart_items').update({
            'quantity': (existingItem['quantity'] as int) + entry.value,
          }).eq('id', existingItem['id']);
        } else {
          // إضافة منتج جديد
          await _supabase.from('cart_items').insert({
            'cart_id': cartId,
            'item_id': entry.key,
            'quantity': entry.value,
          });
        }
      }

      // مسح السلة المحلية
      await clearLocalCart();

      print('✅ تم نقل ${localCart.length} منتج إلى قاعدة البيانات');
      
      // إشعار بتغيير السلة
      CartUpdateService.notifyCartChanged();
      
      return true;
    } catch (e) {
      print('❌ خطأ في نقل السلة إلى قاعدة البيانات: $e');
      return false;
    }
  }

  // إضافة منتج للسلة المحلية
  static Future<bool> addToLocalCart(int itemId, int quantity) async {
    try {
      final cart = await loadLocalCart();
      cart[itemId] = (cart[itemId] ?? 0) + quantity;
      final result = await saveLocalCart(cart);
      if (result) CartUpdateService.notifyCartChanged();
      return result;
    } catch (e) {
      print('❌ خطأ في إضافة المنتج للسلة المحلية: $e');
      return false;
    }
  }

  // تحديث كمية منتج في السلة المحلية
  static Future<bool> updateLocalCartItem(int itemId, int quantity) async {
    try {
      final cart = await loadLocalCart();
      if (quantity <= 0) {
        cart.remove(itemId);
      } else {
        cart[itemId] = quantity;
      }
      final result = await saveLocalCart(cart);
      if (result) CartUpdateService.notifyCartChanged();
      return result;
    } catch (e) {
      print('❌ خطأ في تحديث المنتج في السلة المحلية: $e');
      return false;
    }
  }

  // حذف منتج من السلة المحلية
  static Future<bool> removeFromLocalCart(int itemId) async {
    try {
      final cart = await loadLocalCart();
      cart.remove(itemId);
      final result = await saveLocalCart(cart);
      if (result) CartUpdateService.notifyCartChanged();
      return result;
    } catch (e) {
      print('❌ خطأ في حذف المنتج من السلة المحلية: $e');
      return false;
    }
  }

  // الحصول على عدد المنتجات في السلة المحلية
  static Future<int> getLocalCartCount() async {
    final cart = await loadLocalCart();
    return cart.values.fold<int>(0, (sum, qty) => sum + qty);
  }

  /// جلب عناصر السلة المحلية مع تفاصيل المنتجات
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final cart = await loadLocalCart();
    if (cart.isEmpty) return [];

    final List<Map<String, dynamic>> items = [];

    try {
      // جلب تفاصيل كل منتج من قاعدة البيانات
      for (var entry in cart.entries) {
        final itemId = entry.key;
        final quantity = entry.value;

        try {
          final itemData = await _supabase.from('items').select('''
                id,
                title,
                description,
                price,
                discount_price,
                discount_percent,
                item_images (
                  image_path,
                  is_primary
                )
              ''').eq('id', itemId).single();

          // إيجاد الصورة الأساسية
          String? imagePath;
          final images = itemData['item_images'] as List?;
          if (images != null && images.isNotEmpty) {
            final primaryImage = images.firstWhere(
              (img) => img['is_primary'] == true,
              orElse: () => images.first,
            );
            imagePath = primaryImage['image_path'];
          }

          items.add({
            'id': itemId,
            'quantity': quantity,
            'title': itemData['title'],
            'description': itemData['description'],
            'price': itemData['price'],
            'discount_price': itemData['discount_price'],
            'discount_percent': itemData['discount_percent'],
            'image': imagePath,
          });
        } catch (e) {
          print('⚠️ فشل جلب تفاصيل المنتج $itemId: $e');
        }
      }

      return items;
    } catch (e) {
      print('❌ خطأ في جلب عناصر السلة: $e');
      return [];
    }
  }

  // إعادة تسمية الدوال القديمة لتكون أكثر وضوحاً
  static Future<bool> addToCart(int itemId, int quantity) =>
      addToLocalCart(itemId, quantity);
  static Future<bool> updateQuantity(int itemId, int quantity) =>
      updateLocalCartItem(itemId, quantity);
  static Future<bool> removeFromCart(int itemId) => removeFromLocalCart(itemId);
  static Future<bool> clearCart() => clearLocalCart();
}
