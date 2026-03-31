import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../firebase_options.dart';
import '../main.dart';
import 'auth_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// معالج الإشعارات في الخلفية - يجب أن يكون دالة top-level
// ═══════════════════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 إشعار في الخلفية: ${message.notification?.title}');
}

// ═══════════════════════════════════════════════════════════════════════════
// خدمة Firebase Cloud Messaging
// ═══════════════════════════════════════════════════════════════════════════
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final SupabaseClient _supabase = Supabase.instance.client;

  bool _initialized = false;
  String? _currentToken;

  // قناة الإشعارات لـ Android
  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
    'alkafaje_orders',
    'إشعارات الطلبات',
    description: 'إشعارات تغيير حالة الطلبات والعروض',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _promoChannel =
      AndroidNotificationChannel(
    'alkafaje_promos',
    'العروض والإعلانات',
    description: 'عروض وخصومات وإعلانات المتجر',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // التهيئة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. تهيئة Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. معالج الإشعارات في الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. طلب صلاحيات الإشعارات
    await _requestPermission();

    // 4. تهيئة الإشعارات المحلية
    await _initLocalNotifications();

    // 5. إنشاء قنوات Android
    await _createNotificationChannels();

    // 6. الحصول على التوكن وحفظه
    await _getAndSaveToken();

    // 7. الاشتراك في Topic عام للمتجر (للعروض الجماعية)
    await _subscribeToShopTopic();

    // 8. الاستماع للإشعارات
    _setupForegroundListener();
    _setupInteractionHandlers();

    // 9. الاستماع لتجديد التوكن
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    _initialized = true;
    debugPrint('✅ FCM Service initialized');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // طلب الصلاحيات
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('📱 صلاحيات الإشعارات: ${settings.authorizationStatus}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تهيئة الإشعارات المحلية (لعرض الإشعار لما التطبيق مفتوح)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إنشاء قنوات الإشعارات (Android)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_orderChannel);
      await androidPlugin.createNotificationChannel(_promoChannel);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الحصول على FCM Token وحفظه
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _getAndSaveToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        debugPrint('🔑 FCM Token: ${_currentToken!.substring(0, 20)}...');
        await _saveTokenToDatabase(_currentToken!);
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على FCM Token: $e');
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('🔄 تجديد FCM Token');
    _currentToken = newToken;
    await _saveTokenToDatabase(newToken);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    if (!AuthService.isLoggedIn) return;

    final customerId = await AuthService.getCustomerId();
    if (customerId == null) return;

    try {
      final platform = _getPlatform();

      // upsert: إذا التوكن موجود حدّثه، وإلا أضف جديد
      await _supabase.from('fcm_tokens').upsert(
        {
          'shop_id': SupabaseConfig.shopId,
          'customer_id': customerId,
          'token': token,
          'platform': platform,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'customer_id,token',
      );

      debugPrint('✅ تم حفظ FCM Token في قاعدة البيانات');
    } catch (e) {
      debugPrint('⚠️ خطأ في حفظ FCM Token (الجدول قد لا يكون موجوداً بعد): $e');
    }
  }

  /// حفظ التوكن بعد تسجيل الدخول
  Future<void> saveTokenAfterLogin() async {
    if (_currentToken != null) {
      await _saveTokenToDatabase(_currentToken!);
    } else {
      await _getAndSaveToken();
    }
    await _subscribeToShopTopic();
  }

  /// إلغاء تفعيل التوكن عند تسجيل الخروج
  Future<void> deactivateTokenOnLogout() async {
    if (_currentToken == null || !AuthService.isLoggedIn) return;

    final customerId = await AuthService.getCustomerId();
    if (customerId == null) return;

    try {
      await _supabase
          .from('fcm_tokens')
          .update({'is_active': false})
          .eq('customer_id', customerId)
          .eq('token', _currentToken!);
    } catch (e) {
      debugPrint('⚠️ خطأ في إلغاء تفعيل التوكن: $e');
    }
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الاشتراك في Topic (للعروض الجماعية)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _subscribeToShopTopic() async {
    try {
      // كل مستخدمي التطبيق يشتركون في topic المتجر
      final shopTopic = 'shop_${SupabaseConfig.shopId.replaceAll('-', '_')}';
      await _messaging.subscribeToTopic(shopTopic);
      debugPrint('✅ تم الاشتراك في Topic: $shopTopic');
    } catch (e) {
      debugPrint('⚠️ خطأ في الاشتراك بالـ Topic: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الاستماع للإشعارات (التطبيق مفتوح)
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 إشعار والتطبيق مفتوح: ${message.notification?.title}');

      final notification = message.notification;
      if (notification == null) return;

      // تحديد القناة حسب نوع الإشعار
      final type = message.data['type'] ?? 'order_status';
      final channelId =
          type == 'promotion' ? _promoChannel.id : _orderChannel.id;
      final channelName =
          type == 'promotion' ? _promoChannel.name : _orderChannel.name;

      // عرض الإشعار كـ Local Notification
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );

      // عرض بانر داخل التطبيق
      if (Get.context != null) {
        Get.snackbar(
          notification.title ?? '',
          notification.body ?? '',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(12),
          borderRadius: 14,
          backgroundColor: Colors.white,
          colorText: Colors.black87,
          icon: Icon(
            type == 'promotion'
                ? Icons.local_offer_rounded
                : Icons.delivery_dining_rounded,
            color: const Color(0xFF312F92),
          ),
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // معالجة النقر على الإشعار
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupInteractionHandlers() {
    // عند النقر على الإشعار والتطبيق بالخلفية
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // عند فتح التطبيق من إشعار (التطبيق كان مغلقاً)
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 تم النقر على إشعار: ${message.data}');

    final orderId = message.data['order_id'];
    if (orderId != null) {
      // التنقل لشاشة تفاصيل الطلب
      Get.toNamed('/order-detail', arguments: int.tryParse(orderId.toString()));
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final orderId = data['order_id'];
      if (orderId != null) {
        Get.toNamed('/order-detail',
            arguments: int.tryParse(orderId.toString()));
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في معالجة النقر على الإشعار: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Getter
  // ═══════════════════════════════════════════════════════════════════════════

  String? get currentToken => _currentToken;
}
