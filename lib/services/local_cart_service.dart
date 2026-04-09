import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../models/product_model.dart';
import 'cart_update_service.dart';

class LocalCartService {
  static const String _cartKey = 'local_cart';
  static final _supabase = Supabase.instance.client;

  static bool? _cartOptionsSchemaSupported;
  static String? _lastCartOperationError;

  static const String _cartOptionsMigrationMessage =
      'قاعدة البيانات تحتاج تحديث دعم الألوان والأحجام قبل نقل هذا المنتج إلى السلة.';
  static const String _genericLocalCartMessage =
      'تعذر تحديث السلة المحلية حالياً. حاول مرة أخرى.';
  static const String _genericSyncMessage =
      'تعذر نقل السلة إلى الحساب حالياً. حاول مرة أخرى.';

  static String? get lastCartOperationError => _lastCartOperationError;

  static void _clearCartOperationError() {
    _lastCartOperationError = null;
  }

  static void _setCartOperationError(String message) {
    _lastCartOperationError = message;
  }

  static bool _isMissingCartOptionsSchemaError(Object error) {
    if (error is! PostgrestException) {
      return false;
    }

    final String details =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
            .toLowerCase();

    return details.contains('42703') &&
        (details.contains('selection_key') ||
            details.contains('selected_color') ||
            details.contains('selected_size'));
  }

  static bool _containsProductOptions(List<Map<String, dynamic>> entries) {
    return entries.any(
      (entry) => !ProductOptionSelection.fromJson(entry).isEmpty,
    );
  }

  static Map<String, dynamic> _normalizeEntry(Map<String, dynamic> raw) {
    final int itemId =
        (raw['item_id'] as num?)?.toInt() ?? (raw['id'] as num?)?.toInt() ?? 0;
    final int quantity = (raw['quantity'] as num?)?.toInt() ?? 1;
    final ProductOptionSelection selection =
        ProductOptionSelection.fromJson(raw);
    final String selectionKey =
        raw['selection_key']?.toString().trim().isNotEmpty == true
            ? raw['selection_key'].toString()
            : selection.selectionKey;
    final String lineId =
        raw['cart_line_id']?.toString().trim().isNotEmpty == true
            ? raw['cart_line_id'].toString()
            : '${itemId}_$selectionKey';

    return <String, dynamic>{
      'cart_line_id': lineId,
      'item_id': itemId,
      'quantity': quantity < 1 ? 1 : quantity,
      ...selection.toCartPayload(),
      'selection_key': selectionKey,
    };
  }

  static Future<List<Map<String, dynamic>>> _loadEntries() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cartJson = prefs.getString(_cartKey);
      if (cartJson == null || cartJson.trim().isEmpty) {
        return <Map<String, dynamic>>[];
      }

      final dynamic decoded = jsonDecode(cartJson);

      if (decoded is Map<String, dynamic>) {
        return decoded.entries
            .map(
              (entry) => _normalizeEntry(<String, dynamic>{
                'cart_line_id': '${entry.key}_${buildProductSelectionKey()}',
                'item_id': int.tryParse(entry.key) ?? 0,
                'quantity': entry.value,
              }),
            )
            .where((entry) => (entry['item_id'] as int) > 0)
            .toList();
      }

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (entry) => _normalizeEntry(
                Map<String, dynamic>.from(entry.cast<String, dynamic>()),
              ),
            )
            .where((entry) => (entry['item_id'] as int) > 0)
            .toList();
      }

      return <Map<String, dynamic>>[];
    } catch (e) {
      print('❌ خطأ في تحميل السلة المحلية: $e');
      return <Map<String, dynamic>>[];
    }
  }

  static Future<bool> _saveEntries(List<Map<String, dynamic>> entries) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String cartJson = jsonEncode(entries);
      await prefs.setString(_cartKey, cartJson);
      return true;
    } catch (e) {
      _setCartOperationError(_genericLocalCartMessage);
      print('❌ خطأ في حفظ السلة محلياً: $e');
      return false;
    }
  }

  static Future<bool> saveLocalCart(Map<int, int> cartItems) async {
    _clearCartOperationError();
    final List<Map<String, dynamic>> entries = cartItems.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => _normalizeEntry(<String, dynamic>{
            'cart_line_id': '${entry.key}_${buildProductSelectionKey()}',
            'item_id': entry.key,
            'quantity': entry.value,
          }),
        )
        .toList();

    return _saveEntries(entries);
  }

  static Future<Map<int, int>> loadLocalCart() async {
    final List<Map<String, dynamic>> entries = await _loadEntries();
    final Map<int, int> cart = <int, int>{};

    for (final Map<String, dynamic> entry in entries) {
      final int itemId = entry['item_id'] as int;
      final int quantity = entry['quantity'] as int;
      cart[itemId] = (cart[itemId] ?? 0) + quantity;
    }

    return cart;
  }

  static Future<bool> clearLocalCart() async {
    try {
      _clearCartOperationError();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      return true;
    } catch (e) {
      _setCartOperationError(_genericLocalCartMessage);
      print('❌ خطأ في مسح السلة المحلية: $e');
      return false;
    }
  }

  static Future<bool> syncCartToDatabase(String authUserId) async {
    try {
      _clearCartOperationError();
      final List<Map<String, dynamic>> entries = await _loadEntries();
      if (entries.isEmpty) return true;

      final Map<String, dynamic>? customerResponse = await _supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (customerResponse == null) {
        _setCartOperationError('لم يتم العثور على حساب العميل لربط السلة.');
        print('❌ لم يتم العثور على سجل العميل');
        return false;
      }

      final int customerId = customerResponse['id'] as int;

      final Map<String, dynamic>? cartResponse = await _supabase
          .from('carts')
          .select('id')
          .eq('customer_id', customerId)
          .eq('shop_id', SupabaseConfig.shopId)
          .maybeSingle();

      final int cartId;
      if (cartResponse != null) {
        cartId = cartResponse['id'] as int;
      } else {
        final Map<String, dynamic> newCart = await _supabase
            .from('carts')
            .insert({
              'shop_id': SupabaseConfig.shopId,
              'customer_id': customerId,
            })
            .select('id')
            .single();
        cartId = newCart['id'] as int;
      }

      if (_cartOptionsSchemaSupported == false) {
        final bool syncedLegacy = await _syncLegacyEntries(
          cartId: cartId,
          entries: entries,
        );
        if (!syncedLegacy) {
          return false;
        }
      } else {
        try {
          await _syncEntriesWithOptions(
            cartId: cartId,
            entries: entries,
          );
          _cartOptionsSchemaSupported = true;
        } catch (e) {
          if (!_isMissingCartOptionsSchemaError(e)) {
            rethrow;
          }

          _cartOptionsSchemaSupported = false;
          final bool syncedLegacy = await _syncLegacyEntries(
            cartId: cartId,
            entries: entries,
          );
          if (!syncedLegacy) {
            return false;
          }
        }
      }

      await clearLocalCart();
      CartUpdateService.notifyCartChanged();
      return true;
    } catch (e) {
      _setCartOperationError(
        _lastCartOperationError ?? _genericSyncMessage,
      );
      print('❌ خطأ في نقل السلة إلى قاعدة البيانات: $e');
      return false;
    }
  }

  static Future<void> _syncEntriesWithOptions({
    required int cartId,
    required List<Map<String, dynamic>> entries,
  }) async {
    for (final Map<String, dynamic> entry in entries) {
      final int itemId = entry['item_id'] as int;
      final String selectionKey = entry['selection_key'].toString();
      final int quantity = entry['quantity'] as int;

      final Map<String, dynamic>? existingItem = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('cart_id', cartId)
          .eq('item_id', itemId)
          .eq('selection_key', selectionKey)
          .maybeSingle();

      if (existingItem != null) {
        await _supabase.from('cart_items').update({
          'quantity': (existingItem['quantity'] as int) + quantity,
        }).eq('id', existingItem['id']);
      } else {
        await _supabase.from('cart_items').insert({
          'cart_id': cartId,
          'item_id': itemId,
          'quantity': quantity,
          'selection_key': selectionKey,
          'selected_color_id': entry['selected_color_id'],
          'selected_color_name': entry['selected_color_name'],
          'selected_color_hex': entry['selected_color_hex'],
          'selected_size_id': entry['selected_size_id'],
          'selected_size_name': entry['selected_size_name'],
        });
      }
    }
  }

  static Future<bool> _syncLegacyEntries({
    required int cartId,
    required List<Map<String, dynamic>> entries,
  }) async {
    if (_containsProductOptions(entries)) {
      _setCartOperationError(_cartOptionsMigrationMessage);
      return false;
    }

    for (final Map<String, dynamic> entry in entries) {
      final int itemId = entry['item_id'] as int;
      final int quantity = entry['quantity'] as int;

      final Map<String, dynamic>? existingItem = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('cart_id', cartId)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existingItem != null) {
        await _supabase.from('cart_items').update({
          'quantity': (existingItem['quantity'] as int) + quantity,
        }).eq('id', existingItem['id']);
      } else {
        await _supabase.from('cart_items').insert({
          'cart_id': cartId,
          'item_id': itemId,
          'quantity': quantity,
        });
      }
    }

    return true;
  }

  static Future<bool> addToLocalCart(
    int itemId,
    int quantity, {
    ProductOptionSelection? selection,
  }) async {
    try {
      _clearCartOperationError();
      final List<Map<String, dynamic>> entries = await _loadEntries();
      final ProductOptionSelection normalizedSelection =
          selection ?? const ProductOptionSelection();
      final int index = entries.indexWhere(
        (entry) =>
            entry['item_id'] == itemId &&
            entry['selection_key'] == normalizedSelection.selectionKey,
      );

      if (index >= 0) {
        entries[index]['quantity'] =
            (entries[index]['quantity'] as int) + quantity;
      } else {
        entries.add(
          _normalizeEntry(<String, dynamic>{
            'cart_line_id':
                '${DateTime.now().microsecondsSinceEpoch}_${itemId}_${normalizedSelection.selectionKey}',
            'item_id': itemId,
            'quantity': quantity,
            ...normalizedSelection.toCartPayload(),
          }),
        );
      }

      final bool result = await _saveEntries(entries);
      if (result) {
        CartUpdateService.notifyCartChanged();
      }
      return result;
    } catch (e) {
      _setCartOperationError(_genericLocalCartMessage);
      print('❌ خطأ في إضافة المنتج للسلة المحلية: $e');
      return false;
    }
  }

  static Future<bool> updateLocalCartEntryQuantity(
    String cartLineId,
    int quantity,
  ) async {
    try {
      _clearCartOperationError();
      final List<Map<String, dynamic>> entries = await _loadEntries();
      final int index = entries.indexWhere(
        (entry) => entry['cart_line_id'] == cartLineId,
      );
      if (index < 0) {
        return false;
      }

      if (quantity <= 0) {
        entries.removeAt(index);
      } else {
        entries[index]['quantity'] = quantity;
      }

      final bool result = await _saveEntries(entries);
      if (result) {
        CartUpdateService.notifyCartChanged();
      }
      return result;
    } catch (e) {
      _setCartOperationError(_genericLocalCartMessage);
      print('❌ خطأ في تحديث عنصر السلة المحلية: $e');
      return false;
    }
  }

  static Future<bool> updateLocalCartItem(
    int itemId,
    int quantity, {
    String? selectionKey,
  }) async {
    try {
      _clearCartOperationError();
      final List<Map<String, dynamic>> entries = await _loadEntries();
      final String key = selectionKey ?? buildProductSelectionKey();
      final int index = entries.indexWhere(
        (entry) => entry['item_id'] == itemId && entry['selection_key'] == key,
      );

      if (index < 0) {
        if (quantity <= 0) return true;
        entries.add(
          _normalizeEntry(<String, dynamic>{
            'cart_line_id':
                '${DateTime.now().microsecondsSinceEpoch}_${itemId}_$key',
            'item_id': itemId,
            'quantity': quantity,
            'selection_key': key,
          }),
        );
      } else if (quantity <= 0) {
        entries.removeAt(index);
      } else {
        entries[index]['quantity'] = quantity;
      }

      final bool result = await _saveEntries(entries);
      if (result) {
        CartUpdateService.notifyCartChanged();
      }
      return result;
    } catch (e) {
      _setCartOperationError(_genericLocalCartMessage);
      print('❌ خطأ في تحديث المنتج في السلة المحلية: $e');
      return false;
    }
  }

  static Future<bool> removeLocalCartEntry(String cartLineId) async {
    try {
      _clearCartOperationError();
      final List<Map<String, dynamic>> entries = await _loadEntries();
      entries.removeWhere((entry) => entry['cart_line_id'] == cartLineId);
      final bool result = await _saveEntries(entries);
      if (result) {
        CartUpdateService.notifyCartChanged();
      }
      return result;
    } catch (e) {
      _setCartOperationError(_genericLocalCartMessage);
      print('❌ خطأ في حذف عنصر السلة المحلية: $e');
      return false;
    }
  }

  static Future<bool> removeFromLocalCart(
    int itemId, {
    String? selectionKey,
  }) async {
    try {
      _clearCartOperationError();
      final List<Map<String, dynamic>> entries = await _loadEntries();
      final String key = selectionKey ?? buildProductSelectionKey();
      entries.removeWhere(
        (entry) => entry['item_id'] == itemId && entry['selection_key'] == key,
      );
      final bool result = await _saveEntries(entries);
      if (result) {
        CartUpdateService.notifyCartChanged();
      }
      return result;
    } catch (e) {
      _setCartOperationError(_genericLocalCartMessage);
      print('❌ خطأ في حذف المنتج من السلة المحلية: $e');
      return false;
    }
  }

  static Future<int> getLocalCartCount() async {
    final List<Map<String, dynamic>> entries = await _loadEntries();
    return entries.fold<int>(
      0,
      (sum, entry) => sum + ((entry['quantity'] as int?) ?? 0),
    );
  }

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final List<Map<String, dynamic>> entries = await _loadEntries();
    if (entries.isEmpty) return <Map<String, dynamic>>[];

    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

    try {
      for (final Map<String, dynamic> entry in entries) {
        final int itemId = entry['item_id'] as int;
        final int quantity = entry['quantity'] as int;

        try {
          final Map<String, dynamic> itemData =
              await _supabase.from('items').select('''
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

          String? imagePath;
          final List<dynamic>? images =
              itemData['item_images'] as List<dynamic>?;
          if (images != null && images.isNotEmpty) {
            final dynamic primaryImage = images.firstWhere(
              (img) => img['is_primary'] == true,
              orElse: () => images.first,
            );
            imagePath = primaryImage['image_path']?.toString();
          }

          items.add({
            'cart_line_id': entry['cart_line_id'],
            'selection_key': entry['selection_key'],
            'selected_color_id': entry['selected_color_id'],
            'selected_color_name': entry['selected_color_name'],
            'selected_color_hex': entry['selected_color_hex'],
            'selected_size_id': entry['selected_size_id'],
            'selected_size_name': entry['selected_size_name'],
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
      return <Map<String, dynamic>>[];
    }
  }

  static Future<bool> addToCart(
    int itemId,
    int quantity, {
    ProductOptionSelection? selection,
  }) =>
      addToLocalCart(itemId, quantity, selection: selection);

  static Future<bool> updateQuantity(
    int itemId,
    int quantity, {
    String? selectionKey,
  }) =>
      updateLocalCartItem(itemId, quantity, selectionKey: selectionKey);

  static Future<bool> removeFromCart(
    int itemId, {
    String? selectionKey,
  }) =>
      removeFromLocalCart(itemId, selectionKey: selectionKey);

  static Future<bool> clearCart() => clearLocalCart();
}
