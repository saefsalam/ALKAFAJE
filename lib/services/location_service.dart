import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_location_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// خدمة إدارة المواقع الجغرافية للعملاء
// ═══════════════════════════════════════════════════════════════════════════

class LocationService {
  static final _supabase = Supabase.instance.client;

  // shop_id من main.dart
  static const String DEFAULT_SHOP_ID = '550e8400-e29b-41d4-a716-446655440001';

  // ═══════════════════════════════════════════════════════════════════════════
  // الحصول على جميع المواقع المحفوظة للعميل (باستثناء المحذوفة)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<CustomerLocation>> getCustomerLocations({
    required int customerId,
  }) async {
    try {
      final response = await _supabase
          .from('location')
          .select()
          .eq('customer_id', customerId)
          .eq('shop_id', DEFAULT_SHOP_ID)
          .or('is_deleted.is.null,is_deleted.eq.false') // استثناء المحذوفة
          .order('is_default', ascending: false) // الموقع الرئيسي أولاً
          .order('created_at', ascending: false);

      final List<CustomerLocation> locations = (response as List)
          .map((json) => CustomerLocation.fromJson(json))
          .toList();

      print('✅ تم جلب ${locations.length} موقع للعميل $customerId');
      return locations;
    } catch (e) {
      print('❌ خطأ في جلب المواقع: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الحصول على الموقع الرئيسي للعميل
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<CustomerLocation?> getDefaultLocation({
    required int customerId,
  }) async {
    try {
      final response = await _supabase
          .from('location')
          .select()
          .eq('customer_id', customerId)
          .eq('shop_id', DEFAULT_SHOP_ID)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) {
        print('⚠️ لا يوجد موقع رئيسي للعميل $customerId');
        return null;
      }

      return CustomerLocation.fromJson(response);
    } catch (e) {
      print('❌ خطأ في جلب الموقع الرئيسي: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إضافة موقع جديد
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<CustomerLocation?> addLocation({
    required int customerId,
    required String name,
    required double latitude,
    required double longitude,
    String? locationName,
    String? fullAddress,
    String? notes,
    bool setAsDefault = false,
  }) async {
    try {
      // إذا كان هذا الموقع سيصبح رئيسي، نلغي الرئيسي القديم
      if (setAsDefault) {
        await _clearDefaultLocation(customerId: customerId);
      }

      // إذا لم يكن هناك أي موقع، اجعل هذا الموقع رئيسي تلقائياً
      final existingLocations =
          await getCustomerLocations(customerId: customerId);
      final isFirstLocation = existingLocations.isEmpty;

      final locationData = {
        'shop_id': DEFAULT_SHOP_ID,
        'customer_id': customerId,
        'name': name,
        'L_y': latitude, // استخدام اسم العمود الصحيح من قاعدة البيانات
        'L_X': longitude, // استخدام اسم العمود الصحيح من قاعدة البيانات
        'location_name': locationName,
        'full_address': fullAddress,
        'notes': notes,
        'is_default': setAsDefault || isFirstLocation,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('location')
          .insert(locationData)
          .select()
          .single();

      final newLocation = CustomerLocation.fromJson(response);
      print(
          '✅ تم إضافة موقع جديد: ${newLocation.name} (ID: ${newLocation.id})');
      return newLocation;
    } catch (e) {
      print('❌ خطأ في إضافة الموقع: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تحديث موقع موجود
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> updateLocation({
    required int locationId,
    int? customerId,
    String? name,
    double? latitude,
    double? longitude,
    String? locationName,
    String? fullAddress,
    String? notes,
    bool? setAsDefault,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (latitude != null) updateData['L_y'] = latitude; // اسم العمود الصحيح
      if (longitude != null) updateData['L_X'] = longitude; // اسم العمود الصحيح
      if (locationName != null) updateData['location_name'] = locationName;
      if (fullAddress != null) updateData['full_address'] = fullAddress;
      if (notes != null) updateData['notes'] = notes;

      // إذا كان سيصبح رئيسي، نلغي الرئيسي القديم
      if (setAsDefault == true && customerId != null) {
        await _clearDefaultLocation(customerId: customerId);
        updateData['is_default'] = true;
      }

      await _supabase.from('location').update(updateData).eq('id', locationId);

      print('✅ تم تحديث الموقع $locationId');
      return true;
    } catch (e) {
      print('❌ خطأ في تحديث الموقع: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // حذف موقع (Soft Delete إذا كان مرتبط بطلبات)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> deleteLocation({
    required int locationId,
    required int customerId,
  }) async {
    try {
      // التحقق من أنه ليس الموقع الرئيسي الوحيد
      final allLocations = await getCustomerLocations(customerId: customerId);
      final locationToDelete = allLocations.firstWhere(
        (loc) => loc.id == locationId,
        orElse: () => throw Exception('الموقع غير موجود'),
      );

      // التحقق من عدم وجود طلبات مرتبطة بهذا الموقع
      final ordersCount = await _supabase
          .from('orders')
          .select('id')
          .eq('assigned_location_id', locationId)
          .count();

      final hasOrders = ordersCount.count > 0;

      if (hasOrders) {
        // إذا كان هناك طلبات مرتبطة، نقوم بـ Soft Delete
        // نضيف علامة للموقع أنه محذوف (نغير الاسم ونضيف is_deleted)
        await _supabase.from('location').update({
          'is_deleted': true,
          'is_default': false,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', locationId);

        print('✅ تم تعطيل الموقع $locationId (Soft Delete - مرتبط بطلبات)');
      } else {
        // إذا لم يكن هناك طلبات، نحذف فعلياً
        await _supabase.from('location').delete().eq('id', locationId);
        print('✅ تم حذف الموقع $locationId نهائياً');
      }

      // إذا كان الموقع المحذوف هو الرئيسي، اجعل أول موقع آخر رئيسي
      if (locationToDelete.isDefault && allLocations.length > 1) {
        final nextLocation = allLocations.firstWhere(
          (loc) => loc.id != locationId,
          orElse: () => allLocations.first,
        );
        if (nextLocation.id != null && nextLocation.id != locationId) {
          await updateLocation(
            locationId: nextLocation.id!,
            customerId: customerId,
            setAsDefault: true,
          );
        }
      }

      return {
        'success': true,
        'softDeleted': hasOrders,
        'message': hasOrders
            ? 'تم إخفاء الموقع (مرتبط بطلبات سابقة)'
            : 'تم حذف الموقع بنجاح',
      };
    } catch (e) {
      print('❌ خطأ في حذف الموقع: $e');

      // إذا فشل الحذف بسبب Foreign Key، نحاول Soft Delete
      if (e.toString().contains('foreign key') ||
          e.toString().contains('23503')) {
        try {
          await _supabase.from('location').update({
            'is_deleted': true,
            'is_default': false,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', locationId);

          print('✅ تم تعطيل الموقع $locationId (Soft Delete - fallback)');
          return {
            'success': true,
            'softDeleted': true,
            'message': 'تم إخفاء الموقع (مرتبط بطلبات سابقة)',
          };
        } catch (softDeleteError) {
          print('❌ فشل Soft Delete أيضاً: $softDeleteError');
        }
      }

      return {
        'success': false,
        'softDeleted': false,
        'message': 'فشل في حذف الموقع',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // جعل موقع معين هو الرئيسي
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> setAsDefaultLocation({
    required int locationId,
    required int customerId,
  }) async {
    try {
      // إلغاء الموقع الرئيسي القديم
      await _clearDefaultLocation(customerId: customerId);

      // جعل الموقع الحالي رئيسي
      await _supabase.from('location').update({
        'is_default': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', locationId);

      print('✅ تم جعل الموقع $locationId رئيسي');
      return true;
    } catch (e) {
      print('❌ خطأ في جعل الموقع رئيسي: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إلغاء الموقع الرئيسي الحالي (دالة مساعدة خاصة)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _clearDefaultLocation({
    required int customerId,
  }) async {
    try {
      await _supabase
          .from('location')
          .update({'is_default': false})
          .eq('customer_id', customerId)
          .eq('shop_id', DEFAULT_SHOP_ID)
          .eq('is_default', true);
    } catch (e) {
      print('⚠️ خطأ في إلغاء الموقع الرئيسي القديم: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الحصول على موقع محدد بالـ ID
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<CustomerLocation?> getLocationById({
    required int locationId,
  }) async {
    try {
      final response = await _supabase
          .from('location')
          .select()
          .eq('id', locationId)
          .single();

      return CustomerLocation.fromJson(response);
    } catch (e) {
      print('❌ خطأ في جلب الموقع: $e');
      return null;
    }
  }
}
