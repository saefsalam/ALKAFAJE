import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// خدمة المصادقة - تسجيل الدخول والتسجيل
// ═══════════════════════════════════════════════════════════════════════════

class AuthService {
  static final _supabase = Supabase.instance.client;

  // shop_id من main.dart
  static const String DEFAULT_SHOP_ID = '550e8400-e29b-41d4-a716-446655440001';

  // الحصول على المستخدم الحالي
  static User? get currentUser => _supabase.auth.currentUser;

  // هل المستخدم مسجل دخول؟
  static bool get isLoggedIn => currentUser != null;

  // معلومات المستخدم
  static String? get userEmail => currentUser?.email;
  static String? get authUserId => currentUser?.id;

  static String _fallbackCustomerName(User user) {
    final dynamic fullName = user.userMetadata?['full_name'];
    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    final String? email = user.email;
    if (email != null && email.contains('@')) {
      final String prefix = email.split('@').first.trim();
      if (prefix.isNotEmpty) {
        return prefix;
      }
    }

    return 'عميل';
  }

  static String? _extractPhone(User user) {
    final dynamic phone = user.userMetadata?['phone'];
    if (phone is String && phone.trim().isNotEmpty) {
      return phone.trim();
    }

    if (user.phone != null && user.phone!.trim().isNotEmpty) {
      return user.phone!.trim();
    }

    return null;
  }

  static Future<int?> _ensureCustomerRecordForCurrentUser() async {
    if (!isLoggedIn) {
      return null;
    }

    final User user = currentUser!;
    try {
      final existing = await _supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as int;
      }

      final Map<String, dynamic> payload = {
        'shop_id': DEFAULT_SHOP_ID,
        'name': _fallbackCustomerName(user),
        'auth_user_id': user.id,
      };

      final String? phone = _extractPhone(user);
      if (phone != null && phone.isNotEmpty) {
        payload['phone'] = phone;
      }

      final created = await _supabase
          .from('customers')
          .insert(payload)
          .select('id')
          .single();

      print('✅ تم إنشاء سجل عميل تلقائياً - customer_id: ${created['id']}');
      return created['id'] as int;
    } on PostgrestException catch (e) {
      // في حال سبق إنشاؤه من جلسة ثانية، نعيد جلبه.
      if (e.code == '23505') {
        final existing = await _supabase
            .from('customers')
            .select('id')
            .eq('auth_user_id', user.id)
            .maybeSingle();
        return existing?['id'] as int?;
      }
      print('❌ خطأ في ضمان سجل العميل: ${e.message}');
      return null;
    } catch (e) {
      print('❌ خطأ في ضمان سجل العميل: $e');
      return null;
    }
  }

  // تسجيل مستخدم جديد
  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.user != null) {
        // إنشاء سجل العميل في جدول customers
        await _createCustomerRecord(
          authUserId: response.user!.id,
          name: fullName,
          phone: phone,
        );
      }

      return response;
    } on AuthApiException catch (e) {
      // أخطاء Supabase Auth
      print('❌ خطأ في التسجيل: ${e.message}');
      rethrow; // إعادة رمي الخطأ ليتم معالجته في الشاشة
    } catch (e) {
      print('❌ خطأ غير متوقع في التسجيل: $e');
      rethrow;
    }
  }

  // تسجيل الدخول
  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthApiException catch (e) {
      print('❌ خطأ في تسجيل الدخول: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ خطأ غير متوقع في تسجيل الدخول: $e');
      rethrow;
    }
  }

  // تسجيل الخروج
  static Future<bool> signOut() async {
    try {
      await _supabase.auth.signOut();
      return true;
    } catch (e) {
      print('❌ خطأ في تسجيل الخروج: $e');
      return false;
    }
  }

  // إنشاء سجل العميل في جدول customers
  static Future<int?> _createCustomerRecord({
    required String authUserId,
    required String name,
    required String phone,
  }) async {
    try {
      final result = await _supabase
          .from('customers')
          .insert({
            'shop_id': DEFAULT_SHOP_ID,
            'name': name,
            'phone': phone,
            'auth_user_id': authUserId,
          })
          .select('id')
          .single();
// create table public.whatsapp_otps (
//   id bigint generated always as identity not null,
//   shop_id uuid not null,
//   customer_id bigint not null,
//   phone text not null,
//   otp text not null,
//   is_sent boolean not null default false,
//   verified_at timestamp with time zone null,
//   expires_at timestamp with time zone not null default (now() + '00:05:00'::interval),
//   attempts integer not null default 0,
//   created_at timestamp with time zone not null default now(),
//   constraint whatsapp_otps_pkey primary key (id),
//   constraint whatsapp_otps_customer_id_fkey foreign KEY (customer_id) references customers (id) on delete CASCADE,
//   constraint whatsapp_otps_shop_id_fkey foreign KEY (shop_id) references shops (id) on delete CASCADE
// ) TABLESPACE pg_default;
      final otp = _generateOtp();
      await _supabase.from('whatsapp_otps').insert({
        'phone': phone,
        'customer_id': result['id'],
        'shop_id': DEFAULT_SHOP_ID,
        'otp': otp,
        'is_sent': false,
        'expires_at':
            DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      });

      print('📱 تم توليد OTP: $otp');

      print('✅ تم إنشاء سجل العميل بنجاح - customer_id: ${result['id']}');
      return result['id'] as int;
    } catch (e) {
      print('❌ خطأ في إنشاء سجل العميل: $e');
      return null;
    }
  }

  // الحصول على customer_id (bigint) من auth_user_id (uuid)
  static Future<int?> getCustomerId() async {
    if (!isLoggedIn) return null;

    try {
      return await _ensureCustomerRecordForCurrentUser();
    } catch (e) {
      print('❌ خطأ في الحصول على customer_id: $e');
      return null;
    }
  }

  // الحصول على معلومات العميل
  static Future<Map<String, dynamic>?> getCustomerInfo() async {
    if (!isLoggedIn) return null;

    try {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('auth_user_id', authUserId!)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ خطأ في الحصول على معلومات العميل: $e');
      return null;
    }
  }

  // تحديث معلومات العميل
  static Future<bool> updateCustomerInfo({
    String? name,
    String? phone,
    String? city,
    String? location,
    String? address,
  }) async {
    if (!isLoggedIn) return false;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (city != null) updates['city'] = city;
      if (location != null) updates['location'] = location;
      if (address != null) updates['address'] = address;

      await _supabase
          .from('customers')
          .update(updates)
          .eq('auth_user_id', authUserId!);

      return true;
    } catch (e) {
      print('❌ خطأ في تحديث معلومات العميل: $e');
      return false;
    }
  }

  // إعادة تعيين كلمة المرور
  static Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      print('❌ خطأ في إعادة تعيين كلمة المرور: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال OTP (التحقق من رقم الهاتف)
  // ═══════════════════════════════════════════════════════════════════════════

  /// التحقق من رمز OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    required int customerId,
  }) async {
    try {
      // البحث عن آخر OTP صالح لهذا العميل
      final response = await _supabase
          .from('whatsapp_otps')
          .select()
          .eq('customer_id', customerId)
          .eq('phone', phone)
          .isFilter('verified_at', null) // لم يتم التحقق منه بعد
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'message': 'لم يتم العثور على رمز تحقق. أعد الإرسال'
        };
      }

      // التحقق من انتهاء الصلاحية
      final expiresAt = DateTime.parse(response['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        return {'success': false, 'message': 'انتهت صلاحية الرمز. أعد الإرسال'};
      }

      // التحقق من عدد المحاولات
      final attempts = response['attempts'] as int;
      if (attempts >= 5) {
        return {'success': false, 'message': 'تجاوزت عدد المحاولات المسموحة'};
      }

      // تحديث عدد المحاولات
      await _supabase
          .from('whatsapp_otps')
          .update({'attempts': attempts + 1}).eq('id', response['id']);

      // مقارنة الرمز
      if (response['otp'] == otp) {
        // تحديث حالة التحقق
        await _supabase
            .from('whatsapp_otps')
            .update({'verified_at': DateTime.now().toIso8601String()}).eq(
                'id', response['id']);

        print('✅ تم التحقق من رمز OTP بنجاح');
        return {'success': true, 'message': 'تم التحقق بنجاح'};
      } else {
        final remaining = 5 - (attempts + 1);
        return {
          'success': false,
          'message': 'الرمز غير صحيح. المحاولات المتبقية: $remaining',
        };
      }
    } catch (e) {
      print('❌ خطأ في التحقق من OTP: $e');
      return {'success': false, 'message': 'خطأ في التحقق. حاول مرة أخرى'};
    }
  }

  /// إعادة إرسال رمز OTP
  static Future<Map<String, dynamic>> resendOtp({
    required String phone,
    required int customerId,
  }) async {
    try {
      // توليد رمز OTP جديد (5 أرقام)
      final newOtp = _generateOtp();

      // إدراج رمز جديد في قاعدة البيانات
      await _supabase.from('whatsapp_otps').insert({
        'phone': phone,
        'customer_id': customerId,
        'shop_id': DEFAULT_SHOP_ID,
        'otp': newOtp,
        'is_sent': false,
        'expires_at':
            DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      });

      print('✅ تم إنشاء رمز OTP جديد: $newOtp');

      // TODO: إرسال الرمز عبر WhatsApp أو SMS
      // await _sendOtpViaWhatsApp(phone, newOtp);

      return {'success': true, 'message': 'تم إرسال رمز جديد'};
    } catch (e) {
      print('❌ خطأ في إعادة إرسال OTP: $e');
      return {'success': false, 'message': 'فشل في إعادة إرسال الرمز'};
    }
  }

  /// توليد رمز OTP عشوائي (5 أرقام)
  static String _generateOtp() {
    final random = Random();
    // توليد رقم عشوائي من 10000 إلى 99999 (5 أرقام)
    return (10000 + random.nextInt(90000)).toString();
  }

  /// التسجيل عبر رقم الهاتف (يُنشئ حساب Supabase Auth + سجل customer + OTP)
  static Future<Map<String, dynamic>> signUpWithPhone({
    required String fullName,
    required String phone,
  }) async {
    try {
      // التحقق من عدم وجود حساب بهذا الرقم
      final existing = await _supabase
          .from('customers')
          .select('id')
          .eq('phone', phone)
          .eq('shop_id', DEFAULT_SHOP_ID)
          .maybeSingle();

      if (existing != null) {
        return {
          'success': false,
          'message': 'رقم الهاتف مسجل بالفعل. استخدم تسجيل الدخول',
        };
      }

      // إنشاء حساب في Supabase Auth (بريد وهمي + كلمة سر = رقم الهاتف)
      final email =
          '${phone.replaceAll('+', '').replaceAll(' ', '')}@phone.local';
      final password = phone.replaceAll('+', '').replaceAll(' ', '');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.user == null) {
        return {'success': false, 'message': 'فشل في إنشاء الحساب'};
      }

      // إنشاء سجل العميل
      final customerId = await _createCustomerRecord(
        authUserId: response.user!.id,
        name: fullName,
        phone: phone,
      );

      if (customerId == null) {
        return {'success': false, 'message': 'فشل في إنشاء سجل العميل'};
      }

      return {
        'success': true,
        'message': 'تم إنشاء الحساب بنجاح',
        'authUserId': response.user!.id,
        'customerId': customerId,
      };
    } on AuthApiException catch (e) {
      print('❌ خطأ Auth في التسجيل بالهاتف: ${e.message}');

      String errorMessage = 'خطأ في إنشاء الحساب';
      if (e.message.contains('User already registered')) {
        errorMessage = 'هذا الرقم مسجل بالفعل';
      } else if (e.message.contains('Password should be')) {
        errorMessage = 'رقم الهاتف قصير جداً (يجب 6 أرقام على الأقل)';
      } else {
        errorMessage = e.message;
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ خطأ غير متوقع في التسجيل بالهاتف: $e');
      return {'success': false, 'message': 'خطأ غير متوقع. حاول مرة أخرى'};
    }
  }

  /// تسجيل الدخول عبر رقم الهاتف
  static Future<Map<String, dynamic>> signInWithPhone({
    required String phone,
  }) async {
    try {
      // البحث عن العميل بالرقم
      final customer = await _supabase
          .from('customers')
          .select('id, auth_user_id, name')
          .eq('phone', phone)
          .eq('shop_id', DEFAULT_SHOP_ID)
          .maybeSingle();

      if (customer == null) {
        return {
          'success': false,
          'message': 'رقم الهاتف غير مسجل. أنشئ حساباً جديداً',
        };
      }

      // تسجيل الدخول عبر البريد الوهمي
      final email =
          '${phone.replaceAll('+', '').replaceAll(' ', '')}@phone.local';
      final password = phone.replaceAll('+', '').replaceAll(' ', '');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {'success': false, 'message': 'فشل في تسجيل الدخول'};
      }

      // إنشاء OTP جديد للتحقق
      final otp = _generateOtp();
      await _supabase.from('whatsapp_otps').insert({
        'phone': phone,
        'customer_id': customer['id'],
        'shop_id': DEFAULT_SHOP_ID,
        'otp': otp,
        'is_sent': false,
        'expires_at':
            DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      });

      print('📱 تم توليد OTP لتسجيل الدخول: $otp');

      return {
        'success': true,
        'message': 'تم إرسال رمز التحقق',
        'authUserId': response.user!.id,
        'customerId': customer['id'],
        'customerName': customer['name'] ?? '',
      };
    } on AuthApiException catch (e) {
      print('❌ خطأ Auth في تسجيل الدخول بالهاتف: ${e.message}');

      String errorMessage = 'خطأ في تسجيل الدخول';
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'رقم الهاتف غير صحيح أو الحساب غير موجود';
      } else {
        errorMessage = e.message;
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ خطأ غير متوقع في تسجيل الدخول بالهاتف: $e');
      return {'success': false, 'message': 'خطأ غير متوقع. حاول مرة أخرى'};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال السلة (Cart Functions)
  // ═══════════════════════════════════════════════════════════════════════════

  /// الحصول على سلة المستخدم أو إنشاؤها
  static Future<int?> _getOrCreateCart() async {
    if (!isLoggedIn) {
      print('❌ المستخدم غير مسجل دخول');
      return null;
    }

    try {
      // الحصول على customer_id من auth_user_id
      final customerId = await getCustomerId();
      if (customerId == null) {
        print('❌ لم يتم العثور على سجل العميل');
        return null;
      }

      // البحث عن سلة موجودة
      final existingCart = await _supabase
          .from('carts')
          .select('id')
          .eq('customer_id', customerId)
          .eq('shop_id', DEFAULT_SHOP_ID)
          .maybeSingle();

      if (existingCart != null) {
        return existingCart['id'] as int;
      }

      // إنشاء سلة جديدة
      final newCart = await _supabase
          .from('carts')
          .insert({
            'shop_id': DEFAULT_SHOP_ID,
            'customer_id': customerId,
          })
          .select('id')
          .single();

      print('✅ تم إنشاء سلة جديدة - cart_id: ${newCart['id']}');
      return newCart['id'] as int;
    } catch (e) {
      print('❌ خطأ في الحصول على السلة: $e');
      return null;
    }
  }

  /// جلب عناصر السلة من قاعدة البيانات
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final cartId = await _getOrCreateCart();
      if (cartId == null) return [];

      final data = await _supabase.from('cart_items').select('''
        id,
        quantity,
        item_id,
        items (
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
        )
      ''').eq('cart_id', cartId).order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ خطأ في جلب عناصر السلة: $e');
      return [];
    }
  }

  /// إضافة منتج للسلة
  static Future<bool> addToCart(int itemId, int quantity) async {
    try {
      final cartId = await _getOrCreateCart();
      if (cartId == null) return false;

      // التحقق من وجود المنتج في السلة
      final existing = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('cart_id', cartId)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existing != null) {
        // تحديث الكمية
        final newQuantity = (existing['quantity'] as int) + quantity;
        await _supabase
            .from('cart_items')
            .update({'quantity': newQuantity}).eq('id', existing['id']);
      } else {
        // إضافة منتج جديد
        await _supabase.from('cart_items').insert({
          'cart_id': cartId,
          'item_id': itemId,
          'quantity': quantity,
        });
      }

      return true;
    } catch (e) {
      print('❌ خطأ في إضافة المنتج للسلة: $e');
      return false;
    }
  }

  /// حذف منتج من السلة
  static Future<bool> deleteFromCart(int itemId) async {
    try {
      final cartId = await _getOrCreateCart();
      if (cartId == null) return false;

      await _supabase
          .from('cart_items')
          .delete()
          .eq('cart_id', cartId)
          .eq('item_id', itemId);

      return true;
    } catch (e) {
      print('❌ خطأ في حذف المنتج: $e');
      return false;
    }
  }

  /// تحديث كمية منتج في السلة
  static Future<bool> updateCartItemQuantity(
      int itemId, int newQuantity) async {
    try {
      final cartId = await _getOrCreateCart();
      if (cartId == null) return false;

      await _supabase
          .from('cart_items')
          .update({'quantity': newQuantity})
          .eq('cart_id', cartId)
          .eq('item_id', itemId);

      return true;
    } catch (e) {
      print('❌ خطأ في تحديث الكمية: $e');
      return false;
    }
  }

  /// تفريغ السلة بالكامل
  static Future<bool> clearCart() async {
    try {
      final cartId = await _getOrCreateCart();
      if (cartId == null) return false;

      await _supabase.from('cart_items').delete().eq('cart_id', cartId);

      return true;
    } catch (e) {
      print('❌ خطأ في تفريغ السلة: $e');
      return false;
    }
  }
}
