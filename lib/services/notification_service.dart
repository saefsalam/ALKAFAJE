import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import 'auth_service.dart';
import 'fcm_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final SupabaseClient _supabase = Supabase.instance.client;

  static const String _cachePrefix = 'app_notifications_cache_';

  final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>(<AppNotification>[]);
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  StreamSubscription<AuthState>? _authSubscription;
  RealtimeChannel? _statusHistoryChannel;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // تهيئة Firebase Cloud Messaging
    await FcmService.instance.initialize();

    await _loadCachedNotifications();

    await _authSubscription?.cancel();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedOut) {
        await FcmService.instance.deactivateTokenOnLogout();
        await _unsubscribeFromRealtime();
        _setNotifications(const <AppNotification>[]);
        return;
      }

      if (AuthService.isLoggedIn) {
        await FcmService.instance.saveTokenAfterLogin();
        await _loadCachedNotifications();
        await refreshNotifications();
        await _subscribeToOrderUpdates();
      }
    });

    if (AuthService.isLoggedIn) {
      await refreshNotifications();
      await _subscribeToOrderUpdates();
    }
  }

  Future<void> refreshNotifications({bool showBannerForNew = false}) async {
    if (!AuthService.isLoggedIn) {
      _setNotifications(const <AppNotification>[]);
      return;
    }

    final previousIds = notifications.value.map((item) => item.id).toSet();
    final fetched = await _fetchNotifications();

    _setNotifications(fetched);
    await _saveCachedNotifications();

    if (!showBannerForNew) return;

    final newItems = fetched
        .where((item) => !previousIds.contains(item.id) && !item.isRead)
        .toList();
    if (newItems.isNotEmpty) {
      _showForegroundBanner(newItems.first);
    }
  }

  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    final updated = notifications.value
        .map(
          (item) =>
              item.id == notification.id ? item.copyWith(isRead: true) : item,
        )
        .toList();

    _setNotifications(updated);
    await _saveCachedNotifications();

    if (notification.databaseId != null) {
      try {
        await _supabase.from('customer_notifications').update(
            {'is_read': true}).eq('id', notification.databaseId as Object);
      } catch (_) {
        // fallback cache remains the source of truth if the table is not applied yet
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (notifications.value.isEmpty) return;

    final updated =
        notifications.value.map((item) => item.copyWith(isRead: true)).toList();

    _setNotifications(updated);
    await _saveCachedNotifications();

    final backendIds = notifications.value
        .where((item) => item.databaseId != null)
        .map((item) => item.databaseId)
        .whereType<int>()
        .toList();

    if (backendIds.isEmpty) return;

    try {
      await _supabase
          .from('customer_notifications')
          .update({'is_read': true}).inFilter('id', backendIds);
    } catch (_) {
      // backend schema may not be applied yet
    }
  }

  Future<List<AppNotification>> _fetchNotifications() async {
    final backendNotifications = await _fetchDatabaseNotifications();
    if (backendNotifications.isNotEmpty) {
      return backendNotifications;
    }

    return _fetchFallbackStatusNotifications();
  }

  Future<List<AppNotification>> _fetchDatabaseNotifications() async {
    final customerId = await AuthService.getCustomerId();
    if (customerId == null) return const <AppNotification>[];

    try {
      final data = await _supabase
          .from('customer_notifications')
          .select(
            'id, order_id, order_status, title, body, payload, is_read, created_at',
          )
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(data)
          .map(AppNotification.fromSupabaseRow)
          .toList();
    } catch (e) {
      debugPrint('NotificationService: customer_notifications unavailable: $e');
      return const <AppNotification>[];
    }
  }

  Future<List<AppNotification>> _fetchFallbackStatusNotifications() async {
    final customerId = await AuthService.getCustomerId();
    if (customerId == null) return const <AppNotification>[];

    final cachedReadState = {
      for (final item in notifications.value) item.id: item.isRead,
    };

    try {
      final data = await _supabase
          .from('order_status_history')
          .select(
              'id, order_id, status, notes, created_at, orders!inner(customer_id)')
          .eq('orders.customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(data).map((row) {
        final id = 'history_${row['id']}';
        return AppNotification.fromStatusHistory(
          row,
          isRead: cachedReadState[id] ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('NotificationService: fallback status history failed: $e');
      return const <AppNotification>[];
    }
  }

  Future<void> _subscribeToOrderUpdates() async {
    await _unsubscribeFromRealtime();

    if (!AuthService.isLoggedIn) return;

    final customerId = await AuthService.getCustomerId();
    if (customerId == null) return;

    _statusHistoryChannel = _supabase
        .channel('order_status_history_$customerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_status_history',
          callback: (_) {
            refreshNotifications(showBannerForNew: true);
          },
        )
        .subscribe();
  }

  Future<void> _unsubscribeFromRealtime() async {
    if (_statusHistoryChannel != null) {
      await _supabase.removeChannel(_statusHistoryChannel!);
      _statusHistoryChannel = null;
    }
  }

  Future<void> _loadCachedNotifications() async {
    final cacheKey = _currentCacheKey;
    if (cacheKey == null) {
      _setNotifications(const <AppNotification>[]);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw == null || raw.isEmpty) {
      _setNotifications(const <AppNotification>[]);
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final cached = decoded
          .map((item) =>
              AppNotification.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _setNotifications(cached);
    } catch (e) {
      debugPrint('NotificationService: failed to read cache: $e');
      _setNotifications(const <AppNotification>[]);
    }
  }

  Future<void> _saveCachedNotifications() async {
    final cacheKey = _currentCacheKey;
    if (cacheKey == null) return;

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      notifications.value.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(cacheKey, encoded);
  }

  String? get _currentCacheKey {
    final authUserId = AuthService.authUserId;
    if (authUserId == null || authUserId.isEmpty) {
      return null;
    }
    return '$_cachePrefix$authUserId';
  }

  void _setNotifications(List<AppNotification> items) {
    final sorted = List<AppNotification>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifications.value = sorted;
    unreadCount.value = sorted.where((item) => !item.isRead).length;
  }

  void _showForegroundBanner(AppNotification notification) {
    if (Get.context == null) return;

    Get.snackbar(
      notification.title,
      notification.body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
    );
  }
}
