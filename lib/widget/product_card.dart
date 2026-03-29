import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/product_model.dart';
import '../utls/constants.dart';
import '../screens/product_detail_screen.dart';
import '../services/auth_service.dart';
import '../services/local_cart_service.dart';
import '../main.dart';

// ═══════════════════════════════════════════════════════════════════════════
// كارت المنتج الموحد - للاستخدام في كل الواجهات
// ═══════════════════════════════════════════════════════════════════════════

/// كارت المنتج - يعرض معلومات المنتج بشكل موحد
class ProductCard extends StatefulWidget {
  final dynamic item; // يقبل Map<String, dynamic> أو Item model
  final double? width;
  final double imageHeight;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.item,
    this.width,
    this.imageHeight = 140,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _extractImages();
    _startAutoSlide();
  }

  void _extractImages() {
    _images = [];
    if (widget.item is Map) {
      if (widget.item['item_images'] != null &&
          (widget.item['item_images'] as List).isNotEmpty) {
        for (var img in widget.item['item_images']) {
          final path = img['image_path'];
          if (path != null && path.toString().isNotEmpty) {
            // تحويل المسار إلى URL كامل من Supabase Storage
            _images.add(_getImageUrl(path));
          }
        }
      }
    } else {
      if (widget.item.images != null && widget.item.images.isNotEmpty) {
        for (var img in widget.item.images) {
          if (img.imagePath.isNotEmpty) {
            // تحويل المسار إلى URL كامل من Supabase Storage
            _images.add(_getImageUrl(img.imagePath));
          }
        }
      }
    }
    // إذا لم توجد صور، أضف صورة افتراضية
    if (_images.isEmpty) {
      _images.add('assets/img/main.png');
    }
  }

  // تحويل مسار الصورة إلى URL كامل
  String _getImageUrl(String imagePath) {
    // إذا كانت URL كامل بالفعل، ارجعها كما هي
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // إذا كانت صورة محلية، ارجعها كما هي
    if (imagePath.startsWith('assets/')) {
      return imagePath;
    }

    // بناء URL من Supabase Storage
    final supabase = Supabase.instance.client;
    return supabase.storage.from('items').getPublicUrl(imagePath);
  }

  void _startAutoSlide() {
    if (_images.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted && _pageController.hasClients) {
          _currentPage = (_currentPage + 1) % _images.length;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخراج البيانات
    final String title =
        widget.item is Map ? (widget.item['title'] ?? '') : widget.item.title;
    final String? description = widget.item is Map
        ? widget.item['description']
        : widget.item.description;
    final dynamic price =
        widget.item is Map ? widget.item['price'] : widget.item.price;
    final dynamic discountPrice = widget.item is Map
        ? widget.item['discount_price']
        : widget.item.discountPrice;
    final int? discountPercent = widget.item is Map
        ? widget.item['discount_percent']
        : widget.item.discountPercent;
    final bool hasDiscount = discountPrice != null && discountPrice < price;

    return GestureDetector(
      onTap: widget.onTap ??
          () {
            final itemModel =
                widget.item is Map ? Item.fromJson(widget.item) : widget.item;
            Get.to(() => ProductDetailScreen(item: itemModel));
          },
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صور المنتج - سلايدر تلقائي
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: widget.imageHeight,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _images.length,
                        onPageChanged: (index) {
                          _currentPage = index;
                        },
                        itemBuilder: (context, index) {
                          final imagePath = _images[index];
                          return imagePath.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: imagePath,
                                  height: widget.imageHeight,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: widget.imageHeight,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryColor
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    height: widget.imageHeight,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      size: 50,
                                      color: AppColors.primaryColor
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  imagePath,
                                  height: widget.imageHeight,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: widget.imageHeight,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.image,
                                        size: 50,
                                        color: AppColors.primaryColor
                                            .withOpacity(0.3),
                                      ),
                                    );
                                  },
                                );
                        },
                      ),
                    ),
                    // بادج الخصم
                    if (hasDiscount && discountPercent != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // معلومات المنتج
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 4.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اسم المنتج
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),

                  // الوصف (إذا موجود) - سطر واحد فقط
                  if (description != null && description.isNotEmpty)
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: Colors.grey[600],
                        fontSize: 9,
                        height: 1.2,
                      ),
                    ),

                  // السعر
                  if (hasDiscount)
                    Column(
                      children: [
                        // السعر القديم مشطوب
                        Text(
                          '${price is double ? price.toStringAsFixed(0) : price} د.ع',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: Colors.grey[500],
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey[500],
                            decorationThickness: 2,
                            height: 1.3,
                          ),
                        ),
                        // السعر الجديد
                        Text(
                          '${discountPrice is double ? discountPrice.toStringAsFixed(0) : discountPrice} د.ع',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFE53935),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${price is double ? price.toStringAsFixed(0) : price} د.ع',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),

                  const SizedBox(height: 4),

                  // زر إضافة للسلة
                  _AddToCartButton(
                    itemId:
                        widget.item is Map ? widget.item['id'] : widget.item.id,
                    title: title,
                    price: price,
                    imagePath:
                        _images.isNotEmpty ? _images[0] : 'assets/img/main.png',
                    description: description,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// زر إضافة للسلة - يفتح Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════
class _AddToCartButton extends StatefulWidget {
  final int itemId;
  final String title;
  final dynamic price;
  final String imagePath;
  final String? description;

  const _AddToCartButton({
    required this.itemId,
    required this.title,
    required this.price,
    required this.imagePath,
    this.description,
  });

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  int _quantity = 0;
  static final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadQuantity();
  }

  // تحميل الكمية حسب حالة تسجيل الدخول
  Future<void> _loadQuantity() async {
    int qty = 0;

    if (AuthService.isLoggedIn) {
      // تحميل من قاعدة البيانات
      qty = await _getItemQuantityFromDB(widget.itemId);
    } else {
      // تحميل من السلة المحلية
      final localCart = await LocalCartService.loadLocalCart();
      qty = localCart[widget.itemId] ?? 0;
    }

    if (mounted) {
      setState(() => _quantity = qty);
    }
  }

  // الحصول على كمية المنتج من قاعدة البيانات
  Future<int> _getItemQuantityFromDB(int itemId) async {
    if (!AuthService.isLoggedIn) return 0;

    try {
      final cartId = await _getOrCreateCart();
      if (cartId == null) return 0;

      final item = await _supabase
          .from('cart_items')
          .select('quantity')
          .eq('cart_id', cartId)
          .eq('item_id', itemId)
          .maybeSingle();

      return item?['quantity'] ?? 0;
    } catch (e) {
      print('❌ خطأ في تحميل الكمية: $e');
      return 0;
    }
  }

  // الحصول على أو إنشاء سلة في قاعدة البيانات
  Future<int?> _getOrCreateCart() async {
    if (!AuthService.isLoggedIn) return null;

    try {
      // الحصول على customer_id (bigint) من auth_user_id
      final customerId = await AuthService.getCustomerId();
      if (customerId == null) {
        print('❌ لم يتم العثور على سجل العميل');
        return null;
      }

      final existingCart = await _supabase
          .from('carts')
          .select('id')
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('customer_id', customerId)
          .maybeSingle();

      if (existingCart != null) {
        return existingCart['id'] as int;
      }

      final newCart = await _supabase
          .from('carts')
          .insert({
            'shop_id': SupabaseConfig.shopId,
            'customer_id': customerId,
          })
          .select('id')
          .single();

      return newCart['id'] as int;
    } catch (e) {
      print('❌ خطأ في السلة: $e');
      return null;
    }
  }

  // تحديث الكمية
  Future<bool> _updateQuantity(int itemId, int newQuantity) async {
    if (AuthService.isLoggedIn) {
      // تحديث في قاعدة البيانات
      return await _updateQuantityInDB(itemId, newQuantity);
    } else {
      // تحديث محلياً
      return await LocalCartService.updateLocalCartItem(itemId, newQuantity);
    }
  }

  // تحديث الكمية في قاعدة البيانات
  Future<bool> _updateQuantityInDB(int itemId, int newQuantity) async {
    final cartId = await _getOrCreateCart();
    if (cartId == null) return false;

    try {
      if (newQuantity <= 0) {
        await _supabase
            .from('cart_items')
            .delete()
            .eq('cart_id', cartId)
            .eq('item_id', itemId);
        return true;
      }

      final existingItem = await _supabase
          .from('cart_items')
          .select('id')
          .eq('cart_id', cartId)
          .eq('item_id', itemId)
          .maybeSingle();

      if (existingItem != null) {
        await _supabase.from('cart_items').update({
          'quantity': newQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingItem['id']);
      } else {
        await _supabase.from('cart_items').insert({
          'cart_id': cartId,
          'item_id': itemId,
          'quantity': newQuantity,
        });
      }
      return true;
    } catch (e) {
      print('❌ خطأ في تحديث الكمية: $e');
      return false;
    }
  }

  void _showCartBottomSheet() {
    int selectedQuantity = _quantity > 0 ? _quantity : 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // شريط السحب
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // زر الإغلاق X
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // صورة المنتج
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    height: 150,
                    width: 150,
                    child: widget.imagePath.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: widget.imagePath,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 50),
                            ),
                          )
                        : Image.asset(
                            widget.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 50),
                              );
                            },
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // اسم المنتج
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // الوصف
                if (widget.description != null &&
                    widget.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      widget.description!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // السعر
                Text(
                  '${widget.price is double ? widget.price.toStringAsFixed(0) : widget.price} د.ع',
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // عداد الكمية
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر زيادة
                      GestureDetector(
                        onTap: () {
                          setSheetState(() => selectedQuantity++);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // الكمية
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Text(
                          '$selectedQuantity',
                          style: GoogleFonts.cairo(
                            color: AppColors.primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // زر إنقاص
                      GestureDetector(
                        onTap: () {
                          if (selectedQuantity > 1) {
                            setSheetState(() => selectedQuantity--);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selectedQuantity > 1
                                ? AppColors.primaryColor
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // المجموع
                Text(
                  'المجموع: ${((widget.price is double ? widget.price : (widget.price as num).toDouble()) * selectedQuantity).toStringAsFixed(0)} د.ع',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                // زر إضافة للسلة
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      // حفظ مرجع الـ ScaffoldMessenger قبل إغلاق الـ BottomSheet
                      final messenger = ScaffoldMessenger.of(this.context);
                      Navigator.pop(context);
                      // تحديث الكمية حسب حالة تسجيل الدخول
                      final success = await _updateQuantity(
                        widget.itemId,
                        selectedQuantity,
                      );
                      if (success && mounted) {
                        setState(() => _quantity = selectedQuantity);
                        // رسالة نجاح
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              _quantity > 0
                                  ? 'تم تحديث السلة بنجاح'
                                  : 'تمت الإضافة إلى السلة',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } else if (mounted) {
                        // رسالة خطأ
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'حدث خطأ، حاول مرة أخرى',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      _quantity > 0 ? 'تحديث السلة' : 'أضف للسلة',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showCartBottomSheet,
      child: Container(
        height: 30,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _quantity > 0
              ? AppColors.primaryColor.withOpacity(0.1)
              : AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
          border: _quantity > 0
              ? Border.all(color: AppColors.primaryColor.withOpacity(0.3))
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _quantity > 0 ? Icons.shopping_cart : Icons.add_shopping_cart,
                color: _quantity > 0 ? AppColors.primaryColor : Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _quantity > 0 ? 'في السلة ($_quantity)' : 'أضف للسلة',
                style: GoogleFonts.cairo(
                  color: _quantity > 0 ? AppColors.primaryColor : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// كارد المنتج المصغر - للعرض في القوائم الأفقية
class ProductCardMini extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;

  const ProductCardMini({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الصورة
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  item.primaryImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 30,
                          color: AppColors.primaryColor.withOpacity(0.3),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // المعلومات
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.formattedPrice} د.ع',
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
