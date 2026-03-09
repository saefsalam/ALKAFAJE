import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utls/constants.dart';
import 'part_items_screen.dart';
import '../../widget/product_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
// الشاشة الرئيسية - كود بسيط بدون widgets خارجية
// كل شيء مكتوب هنا مباشرة - سهل التعديل والفهم
// ═══════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════

  final _supabase = Supabase.instance.client;
  final String shopId = '550e8400-e29b-41d4-a716-446655440001';

  // البيانات
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _parts = [];

  bool _isLoading = true;
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();

  // ═══════════════════════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

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

          items = List<Map<String, dynamic>>.from(itemsData);
        }

        partsWithItems.add({
          'id': part['id'],
          'name': part['name'],
          'items': items,
        });
      }

      setState(() {
        _banners = List<Map<String, dynamic>>.from(bannersData);
        _parts = partsWithItems;
        _isLoading = false;
      });

      // للتصحيح - احذفه لاحقاً
      print('عدد البانرات: ${_banners.length}');
      print('عدد البارتات: ${_parts.length}');
      if (_banners.isNotEmpty) {
        print('أول بانر: ${_banners[0]}');
      }
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
      setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الواجهة الرئيسية
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
                : SafeArea(
                  bottom: false,
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          // ═══════════════════════════════════════════════════
                          // الهيدر
                          // ═══════════════════════════════════════════════════
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              'شركة القرش',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          // ═══════════════════════════════════════════════════
                          // البانرات
                          // ═══════════════════════════════════════════════════
                          if (_banners.isNotEmpty) ...[
                            SizedBox(
                              height: 160,
                              child: PageView.builder(
                                controller: _bannerController,
                                onPageChanged: (index) {
                                  setState(() => _currentBannerIndex = index);
                                },
                                itemCount: _banners.length,
                                itemBuilder: (context, index) {
                                  final banner = _banners[index];
                                  final bannerImagePath =
                                      banner['image_path'] ??
                                      'assets/img/main.png';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image:
                                            bannerImagePath.startsWith('http')
                                                ? NetworkImage(bannerImagePath)
                                                : AssetImage(bannerImagePath)
                                                    as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // النقاط
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _banners.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: _currentBannerIndex == index ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color:
                                        _currentBannerIndex == index
                                            ? AppColors.primaryColor
                                            : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ═══════════════════════════════════════════════════
                          // البارتات (الأقسام)
                          // ═══════════════════════════════════════════════════
                          ..._parts.map((part) {
                            final items =
                                part['items'] as List<Map<String, dynamic>>;
                            if (items.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // عنوان البارت
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        part['name'] ?? '',
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Get.to(
                                            () => PartItemsScreen(
                                              partName: part['name'] ?? '',
                                              items: items,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'عرض الكل',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // قائمة المنتجات الأفقية
                                SizedBox(
                                  height: 240,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: ProductCard(
                                          item: items[index],
                                          width: 150,
                                          imageHeight: 120,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
