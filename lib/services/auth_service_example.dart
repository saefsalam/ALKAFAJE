// ═══════════════════════════════════════════════════════════
// 🔐 خدمة المصادقة (AuthService) - مثال تطبيقي
// ═══════════════════════════════════════════════════════════
//
// ملاحظة: هذا مثال توضيحي - ستحتاج إلى:
// 1. تثبيت حزمة Supabase: flutter pub add supabase_flutter
// 2. تهيئة Supabase في main.dart
// 3. إضافة معلومات الاتصال في ملف .env
//
// ═══════════════════════════════════════════════════════════

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

class AuthService {
  // الحصول على instance من Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  // معرف المتجر الثابت (يمكن جعله ديناميكي لاحقاً)
  static const String shopId = 'shop-alkafajy-001';

  // ═══════════════════════════════════════════════════════════
  // الحالة الحالية
  // ═══════════════════════════════════════════════════════════

  /// الحصول على المستخدم المُصادق حالياً
  User? get currentUser => _supabase.auth.currentUser;

  /// هل المستخدم مُسجل دخول؟
  bool get isSignedIn => currentUser != null;

  /// Stream للاستماع لتغييرات حالة المصادقة
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ═══════════════════════════════════════════════════════════
  // تسجيل عميل جديد (Sign Up)
  // ═══════════════════════════════════════════════════════════

  /// تسجيل عميل جديد باستخدام رقم الهاتف وكلمة المرور
  Future<AuthResult> signUpWithPhone({
    required String phone,
    required String password,
    required String name,
    String? city,
    String? location,
    String? address,
  }) async {
    try {
      // 1. التحقق من أن رقم الهاتف غير مسجل مسبقاً
      final existingCustomer = await _findCustomerByPhone(phone);
      if (existingCustomer != null && existingCustomer.hasAuthAccount) {
        return AuthResult.error('هذا الرقم مسجل مسبقاً');
      }

      // 2. إنشاء حساب في auth.users
      final AuthResponse authResponse = await _supabase.auth.signUp(
        phone: _formatPhoneNumber(phone),
        password: password,
      );

      if (authResponse.user == null) {
        return AuthResult.error('فشل إنشاء حساب المصادقة');
      }

      // 3. إنشاء سجل في جدول customers
      final customerData =
          await _supabase
              .from('customers')
              .insert({
                'shop_id': shopId,
                'auth_user_id': authResponse.user!.id,
                'name': name,
                'phone': phone,
                'city': city,
                'location': location,
                'address': address,
                'is_active': true,
                'is_banned': false,
              })
              .select()
              .single();

      final customer = Customer.fromJson(customerData);
      return AuthResult.success(customer);
    } on AuthException catch (e) {
      return AuthResult.error('خطأ في المصادقة: ${e.message}');
    } on PostgrestException catch (e) {
      return AuthResult.error('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e) {
      return AuthResult.error('خطأ غير متوقع: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // تسجيل الدخول (Sign In)
  // ═══════════════════════════════════════════════════════════

  /// تسجيل الدخول باستخدام رقم الهاتف وكلمة المرور
  Future<AuthResult> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      // 1. تسجيل الدخول عبر Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signInWithPassword(
        phone: _formatPhoneNumber(phone),
        password: password,
      );

      if (authResponse.user == null) {
        return AuthResult.error('فشل تسجيل الدخول');
      }

      // 2. جلب بيانات العميل من جدول customers
      final customerData =
          await _supabase
              .from('customers')
              .select()
              .eq('auth_user_id', authResponse.user!.id)
              .single();

      final customer = Customer.fromJson(customerData);

      // 3. التحقق من حالة العميل
      if (customer.isBanned) {
        await signOut(); // تسجيل خروج فوري
        return AuthResult.error('تم حظر حسابك. يرجى التواصل مع الدعم');
      }

      if (!customer.isActive) {
        await signOut();
        return AuthResult.error('حسابك غير نشط');
      }

      return AuthResult.success(customer);
    } on AuthException catch (e) {
      return AuthResult.error('رقم الهاتف أو كلمة المرور غير صحيحة');
    } on PostgrestException catch (e) {
      return AuthResult.error('لم يتم العثور على بيانات العميل');
    } catch (e) {
      return AuthResult.error('خطأ غير متوقع: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // تسجيل الدخول بـ OTP (WhatsApp / SMS)
  // ═══════════════════════════════════════════════════════════

  /// إرسال رمز التحقق OTP إلى رقم الهاتف
  Future<AuthResult> sendOTP(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(phone: _formatPhoneNumber(phone));
      return AuthResult.success(null, message: 'تم إرسال رمز التحقق');
    } on AuthException catch (e) {
      return AuthResult.error('فشل إرسال رمز التحقق: ${e.message}');
    } catch (e) {
      return AuthResult.error('خطأ غير متوقع: $e');
    }
  }

  /// التحقق من رمز OTP وتسجيل الدخول
  Future<AuthResult> verifyOTP({
    required String phone,
    required String token,
  }) async {
    try {
      // 1. التحقق من OTP
      final AuthResponse authResponse = await _supabase.auth.verifyOTP(
        phone: _formatPhoneNumber(phone),
        token: token,
        type: OtpType.sms,
      );

      if (authResponse.user == null) {
        return AuthResult.error('رمز التحقق غير صحيح');
      }

      // 2. البحث عن العميل الموجود
      final existingCustomer =
          await _supabase
              .from('customers')
              .select()
              .eq('auth_user_id', authResponse.user!.id)
              .maybeSingle();

      if (existingCustomer != null) {
        final customer = Customer.fromJson(existingCustomer);

        // التحقق من حالة العميل
        if (customer.isBanned) {
          await signOut();
          return AuthResult.error('تم حظر حسابك');
        }

        return AuthResult.success(customer);
      }

      // 3. عميل جديد - إنشاء سجل
      final newCustomerData =
          await _supabase
              .from('customers')
              .insert({
                'shop_id': shopId,
                'auth_user_id': authResponse.user!.id,
                'phone': phone,
                'name': 'عميل جديد', // سيتم تحديثه لاحقاً
              })
              .select()
              .single();

      final newCustomer = Customer.fromJson(newCustomerData);
      return AuthResult.success(
        newCustomer,
        message: 'مرحباً! يرجى إكمال بياناتك الشخصية',
      );
    } on AuthException catch (e) {
      return AuthResult.error('رمز التحقق غير صحيح أو منتهي الصلاحية');
    } catch (e) {
      return AuthResult.error('خطأ غير متوقع: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // تسجيل الخروج
  // ═══════════════════════════════════════════════════════════

  /// تسجيل خروج المستخدم الحالي
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ═══════════════════════════════════════════════════════════
  // إدارة بيانات العميل
  // ═══════════════════════════════════════════════════════════

  /// الحصول على بيانات العميل الحالي
  Future<Customer?> getCurrentCustomer() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final customerData =
          await _supabase
              .from('customers')
              .select()
              .eq('auth_user_id', user.id)
              .single();

      return Customer.fromJson(customerData);
    } catch (e) {
      print('خطأ في جلب بيانات العميل: $e');
      return null;
    }
  }

  /// تحديث بيانات العميل
  Future<bool> updateCustomer({
    required int customerId,
    String? name,
    String? city,
    String? location,
    String? address,
  }) async {
    try {
      await _supabase
          .from('customers')
          .update({
            if (name != null) 'name': name,
            if (city != null) 'city': city,
            if (location != null) 'location': location,
            if (address != null) 'address': address,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId);

      return true;
    } catch (e) {
      print('خطأ في تحديث بيانات العميل: $e');
      return false;
    }
  }

  /// تغيير كلمة المرور
  Future<AuthResult> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult.success(null, message: 'تم تغيير كلمة المرور بنجاح');
    } catch (e) {
      return AuthResult.error('فشل تغيير كلمة المرور: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // دوال مساعدة خاصة
  // ═══════════════════════════════════════════════════════════

  /// البحث عن عميل بواسطة رقم الهاتف
  Future<Customer?> _findCustomerByPhone(String phone) async {
    try {
      final customerData =
          await _supabase
              .from('customers')
              .select()
              .eq('shop_id', shopId)
              .eq('phone', phone)
              .maybeSingle();

      return customerData != null ? Customer.fromJson(customerData) : null;
    } catch (e) {
      return null;
    }
  }

  /// تنسيق رقم الهاتف (يجب أن يبدأ بـ +)
  String _formatPhoneNumber(String phone) {
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('00')) return '+${phone.substring(2)}';
    if (phone.startsWith('0')) return '+964${phone.substring(1)}'; // العراق
    return '+964$phone';
  }
}

// ═══════════════════════════════════════════════════════════
// نتيجة عملية المصادقة
// ═══════════════════════════════════════════════════════════

class AuthResult {
  final bool success;
  final Customer? customer;
  final String? error;
  final String? message;

  AuthResult._({
    required this.success,
    this.customer,
    this.error,
    this.message,
  });

  factory AuthResult.success(Customer? customer, {String? message}) {
    return AuthResult._(success: true, customer: customer, message: message);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(success: false, error: error);
  }

  @override
  String toString() {
    if (success) {
      return 'AuthResult.success(customer: $customer, message: $message)';
    } else {
      return 'AuthResult.error(error: $error)';
    }
  }
}
