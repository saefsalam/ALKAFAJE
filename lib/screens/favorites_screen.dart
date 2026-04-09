import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../utls/constants.dart';
import '../models/product_model.dart';
import '../widget/bubble_button.dart';
import '../widget/Mytext.dart';
import '../widget/loading_animation.dart';
import 'product_detail_screen.dart';
import '../main.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// خدمة إدارة المفضلة - للاستخدام من أي صفحة
// ═══════════════════════════════════════════════════════════════════════════
class FavoritesService {
  // StreamController لإرسال إشعارات بالتغييرات
  static final _favoritesChangeController = StreamController<bool>.broadcast();

  // Stream للاستماع للتغييرات
  static Stream<bool> get favoritesChangeStream =>
      _favoritesChangeController.stream;

  // دالة لإرسال إشعار بالتغيير
  static void _notifyChange() {
    if (!_favoritesChangeController.isClosed) {
      _favoritesChangeController.add(true);
    }
  }

  static Future<bool> checkIfFavorite(int itemId) async {
    final customerId = await AuthService.getCustomerId();
    if (customerId == null) return false;

    try {
      final supabase = Supabase.instance.client;
      final existing = await supabase
          .from('favorites')
          .select('id')
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('customer_id', customerId)
          .eq('item_id', itemId)
          .maybeSingle();

      return existing != null;
    } catch (e) {
      print('❌ خطأ في التحقق من المفضلة: $e');
      return false;
    }
  }

  static Future<bool> toggleFavorite(int itemId) async {
    final customerId = await AuthService.getCustomerId();
    if (customerId == null) return false;

    try {
      final supabase = Supabase.instance.client;
      final existing = await supabase
          .from('favorites')
          .select('id')
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('customer_id', customerId)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existing != null) {
        // إزالة من المفضلة
        await supabase
            .from('favorites')
            .delete()
            .eq('shop_id', SupabaseConfig.shopId)
            .eq('customer_id', customerId)
            .eq('item_id', itemId);

        // إرسال إشعار بالتغيير
        _notifyChange();
        return false; // ليس مفضلاً بعد الحذف
      } else {
        // إضافة للمفضلة
        await supabase.from('favorites').insert({
          'shop_id': SupabaseConfig.shopId,
          'customer_id': customerId,
          'item_id': itemId,
        });

        // إرسال إشعار بالتغيير
        _notifyChange();
        return true; // مفضل بعد الإضافة
      }
    } catch (e) {
      print('❌ خطأ في تبديل حالة المفضلة: $e');
      return false;
    }
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════

  List<Item> _favorites = [];
  bool _isLoading = true;
  StreamSubscription<bool>? _favoritesSubscription;

  // Supabase
  final _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال المفضلة
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadFavorites();

    // الاستماع للتغييرات من FavoritesService
    _favoritesSubscription = FavoritesService.favoritesChangeStream.listen((_) {
      print('🔔 تم استقبال إشعار بتغيير في المفضلة');
      _loadFavorites();
    });
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final customerId = await AuthService.getCustomerId();
    if (customerId == null) {
      print('❌ لا يوجد عميل مسجل');
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await _supabase
          .from('favorites')
          .select('''
            id,
            item_id,
            items (
              id,
              shop_id,
              category_id,
              title,
              description,
              price,
              discount_price,
              discount_percent,
              is_active,
              is_deleted,
              item_images (
                id,
                item_id,
                image_path,
                sort_order,
                is_primary
              ),
              item_colors (*),
              item_sizes (*)
            )
          ''')
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      List<Item> favoriteItems = [];
      for (var fav in data) {
        final itemData = fav['items'];
        if (itemData != null) {
          favoriteItems.add(
            Item.fromJson(Map<String, dynamic>.from(itemData)),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _favorites = favoriteItems;
        _isLoading = false;
      });

      print('✅ تم تحميل ${_favorites.length} منتج مفضل');
    } catch (e) {
      print('❌ خطأ في تحميل المفضلات: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _removeFromFavoritesDB(int itemId) async {
    final customerId = await AuthService.getCustomerId();
    if (customerId == null) return false;

    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('customer_id', customerId)
          .eq('item_id', itemId);

      return true;
    } catch (e) {
      print('❌ خطأ في حذف المنتج من المفضلة: $e');
      return false;
    }
  }

  Future<bool> _clearFavoritesDB() async {
    final customerId = await AuthService.getCustomerId();
    if (customerId == null) return false;

    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('customer_id', customerId);

      return true;
    } catch (e) {
      print('❌ خطأ في حذف جميع المفضلات: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // عمليات المفضلة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _removeItem(int index) async {
    final itemId = _favorites[index].id;
    final success = await _removeFromFavoritesDB(itemId);

    if (success) {
      await _loadFavorites();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الحذف من المفضلة', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.primaryColor.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _clearAllFavorites() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'حذف جميع المفضلات',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف جميع المنتجات المفضلة؟',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _clearFavoritesDB();
      if (success) {
        await _loadFavorites();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف جميع المفضلات', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.primaryColor.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _navigateToProductDetail(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetailScreen(item: item)),
    );
    // لا حاجة للانتظار - الStream سيتعامل مع التغييرات تلقائياً
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // الهيدر
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BubbleButton(icon: Icons.favorite_border, onTap: () {}),
                  const MyText(text: 'المفضلة', fontSize: 20),
                  BubbleButton(
                    icon: Icons.delete_outline,
                    onTap: _favorites.isEmpty ? () {} : _clearAllFavorites,
                  ),
                ],
              ),
            ),
          ),
          // المحتوى
          Expanded(
            child: _isLoading
                ? const Center(
                    child: LoadingAnimation(size: 200),
                  )
                : _favorites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 80,
                              color: AppColors.primaryColor.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد منتجات مفضلة',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ابدأ بإضافة منتجاتك المفضلة',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          return _buildFavoriteItem(_favorites[index], index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(Item item, int index) {
    final itemId = item.id;
    final title = item.title;
    final price = item.price;
    final imagePath = item.images.isNotEmpty
        ? item.images.first.imagePath
        : 'assets/img/main.png';

    return Dismissible(
      key: Key('favorite_item_$itemId'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (_) => _removeItem(index),
      child: GestureDetector(
        onTap: () => _navigateToProductDetail(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.25),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: -1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // صورة المنتج
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: imagePath.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.primaryColor.withOpacity(
                              0.08,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.primaryColor.withOpacity(
                              0.08,
                            ),
                            child: Icon(
                              Icons.image,
                              color: AppColors.primaryColor.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                        )
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.primaryColor.withOpacity(0.08),
                              child: Icon(
                                Icons.image,
                                color: AppColors.primaryColor.withOpacity(
                                  0.3,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // تفاصيل المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${price.toStringAsFixed(0)} د.ع',
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
