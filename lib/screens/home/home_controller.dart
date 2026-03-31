import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeController extends GetxController {
  final _supabase = Supabase.instance.client;
  final String shopId = '550e8400-e29b-41d4-a716-446655440001';

  // البيانات
  var banners = <Map<String, dynamic>>[].obs;
  var parts = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var hasError = false.obs;

  // ═══════════════════════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> loadData() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      // 1. جلب البانرات
      final bannersData = await _supabase
          .from('banner_ads')
          .select()
          .eq('shop_id', shopId)
          .eq('is_active', true)
          .order('sort_order');

      // 2. جلب البارتات
      final partsData = await _supabase
          .from('parts')
          .select()
          .eq('shop_id', shopId)
          .eq('is_active', true)
          .order('sort_order', ascending: false);

      // 3. لكل بارت، جلب المنتجات
      List<Map<String, dynamic>> partsWithItems = [];

      for (var part in partsData) {
        // جلب معرفات المنتجات المرتبطة بالبارت
        final partItemsData = await _supabase
            .from('part_items')
            .select('item_id')
            .eq('part_id', part['id']);

        List<int> itemIds =
            (partItemsData as List).map((e) => e['item_id'] as int).toList();

        // جلب المنتجات
        List<Map<String, dynamic>> items = [];
        if (itemIds.isNotEmpty) {
          final itemsData = await _supabase
              .from('items')
              .select('*, item_images(*)')
              .inFilter('id', itemIds)
              .eq('is_active', true)
              .eq('is_deleted', false);

          items = (itemsData as List).map((item) {
            List images = item['item_images'] ?? [];
            for (var img in images) {
              img["image_path"] =
                  "https://ibwawjjqewuikmmnxqgo.supabase.co/storage/v1/object/public/items/${img["image_path"]}";
              if (img["is_primary"] == true) {
                item["cover_image"] = img["image_path"];
              }
            }
            item['image_path'] = images.isNotEmpty
                ? images
                : 'assets/img/product_placeholder.png';
            return item as Map<String, dynamic>;
          }).toList();
        }

        partsWithItems.add({
          'id': part['id'],
          'name': part['name'],
          'items': items,
        });
      }

      banners.value = (bannersData as List).map((data) {
        data['image_path'] =
            "https://ibwawjjqewuikmmnxqgo.supabase.co/storage/v1/object/public/ads/${data['image_path']}";
        return data as Map<String, dynamic>;
      }).toList();

      parts.value = partsWithItems;
      isLoading.value = false;

      print('عدد البانرات: ${banners.length}');
      print('عدد البارتات: ${parts.length}');
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
      hasError.value = true;
      isLoading.value = false;
    }
  }
}
