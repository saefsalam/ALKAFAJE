import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';
import '../models/product_model.dart';
import 'favorites_screen.dart';
import '../main.dart';

class ProductDetailScreen extends StatefulWidget {
  final Item item;

  const ProductDetailScreen({super.key, required this.item});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  int _quantity = 1;
  bool _isAddingToCart = false;

  // Supabase
  static final _supabase = Supabase.instance.client;
  static int? _currentCustomerId = 1; // مؤقت للاختبار
  static int? _currentCartId;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesService.checkIfFavorite(widget.item.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
      _isCheckingFavorite = false;
    });
  }

  Future<int?> _getOrCreateCart() async {
    if (_currentCustomerId == null) return null;
    if (_currentCartId != null) return _currentCartId;

    try {
      final existingCart = await _supabase
          .from('carts')
          .select('id')
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('customer_id', _currentCustomerId!)
          .maybeSingle();

      if (existingCart != null) {
        _currentCartId = existingCart['id'];
        return _currentCartId;
      }

      final newCart = await _supabase
          .from('carts')
          .insert({
            'shop_id': SupabaseConfig.shopId,
            'customer_id': _currentCustomerId,
          })
          .select('id')
          .single();

      _currentCartId = newCart['id'];
      return _currentCartId;
    } catch (e) {
      print('❌ خطأ في الحصول على السلة: $e');
      return null;
    }
  }

  Future<void> _addToCart() async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    try {
      final cartId = await _getOrCreateCart();
      if (cartId == null) {
        throw Exception('لا يمكن الحصول على السلة');
      }

      final existingItem = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('cart_id', cartId)
          .eq('item_id', widget.item.id)
          .maybeSingle();

      if (existingItem != null) {
        final newQuantity = existingItem['quantity'] + _quantity;
        await _supabase
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingItem['id']);
      } else {
        await _supabase.from('cart_items').insert({
          'cart_id': cartId,
          'item_id': widget.item.id,
          'quantity': _quantity,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إضافة $_quantity من ${widget.item.title} إلى السلة',
              style: GoogleFonts.cairo(),
              textAlign: TextAlign.center,
            ),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _quantity = 1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء الإضافة للسلة',
              style: GoogleFonts.cairo(),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final newState = await FavoritesService.toggleFavorite(widget.item.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = newState;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newState ? 'تمت الإضافة للمفضلة' : 'تم الحذف من المفضلة',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: AppColors.primaryColor.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openImageGallery(int initialIndex) {
    final images = widget.item.images.map((img) => img.imagePath).toList();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) =>
            ImageGalleryScreen(images: images, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
          // الخلفية
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: AppColors.primaryColor.withOpacity(0.05)),
          ),
          // المحتوى
          Column(
            children: [
              // الهيدر
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          BubbleButton(
                            icon: Icons.share,
                            onTap: () {
                              // مشاركة المنتج
                            },
                          ),
                          const SizedBox(width: 8),
                          BubbleButton(
                            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                            iconColor: _isFavorite ? Colors.red : AppColors.primaryColor,
                            onTap: _toggleFavorite,
                          ),
                        ],
                      ),
                      Text(
                        "تفاصيل المنتج",
                        style: GoogleFonts.cairo(
                          color: AppColors.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      BubbleButton(
                        icon: Icons.arrow_forward,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              // المحتوى القابل للتمرير
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // معرض الصور
                      Container(
                        height: 350,
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // عرض الصور
                              PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemCount: widget.item.images.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _openImageGallery(index),
                                    child: Container(
                                      color: Colors.white,
                                      child: Image.network(
                                        widget.item.images[index].imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: AppColors.primaryColor
                                                    .withOpacity(0.1),
                                                child: Icon(
                                                  Icons.image,
                                                  size: 80,
                                                  color: AppColors.primaryColor
                                                      .withOpacity(0.3),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // زر المفضلة
                              Positioned(
                                top: 15,
                                right: 15,
                                child: GestureDetector(
                                  onTap: _toggleFavorite,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: _isCheckingFavorite
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primaryColor,
                                            ),
                                          )
                                        : Icon(
                                            _isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: _isFavorite
                                                ? Colors.red
                                                : AppColors.primaryColor,
                                            size: 24,
                                          ),
                                  ),
                                ),
                              ),
                              // مؤشر الصور
                              if (widget.item.images.length > 1)
                                Positioned(
                                  bottom: 15,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.item.images.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        width: _currentImageIndex == index
                                            ? 24
                                            : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          color: _currentImageIndex == index
                                              ? AppColors.primaryColor
                                              : Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // أسهم التنقل
                              if (widget.item.images.length > 1)
                                Positioned(
                                  left: 10,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_currentImageIndex > 0) {
                                          _pageController.previousPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.chevron_left,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.item.images.length > 1)
                                Positioned(
                                  right: 10,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_currentImageIndex <
                                            widget.item.images.length - 1) {
                                          _pageController.nextPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.chevron_right,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // معلومات المنتج
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // العنوان والسعر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.item.title,
                                        style: GoogleFonts.cairo(
                                          color: AppColors.primaryColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        widget.item.category?.name ?? '',
                                        style: GoogleFonts.cairo(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // السعر
                                    if (widget.item.hasDiscount) ...[
                                      // السعر القديم مشطوب
                                      Text(
                                        '${widget.item.price.toStringAsFixed(0)} د.ع',
                                        style: GoogleFonts.cairo(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor: Colors.grey[500],
                                          decorationThickness: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      // السعر الجديد مع بادج الخصم
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // السعر الجديد
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE53935),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFFE53935,
                                                  ).withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '${widget.item.finalPrice.toStringAsFixed(0)} د.ع',
                                              style: GoogleFonts.cairo(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // نسبة الخصم
                                          if (widget.item.discountPercent !=
                                              null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE53935),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '-${widget.item.discountPercent}%',
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ] else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '${widget.item.price.toStringAsFixed(0)} د.ع',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            // الوصف
                            Text(
                              'الوصف',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.item.description ??
                                  'منتج عالي الجودة مصنوع من أفضل المواد. يتميز بتصميم أنيق وعصري يناسب جميع الأذواق. مثالي للاستخدام اليومي أو كهدية مميزة.',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor.withOpacity(0.8),
                                fontSize: 16,
                                height: 1.8,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 25),
                            // المواصفات
                            Text(
                              'المواصفات',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildSpecItem(
                              'التصنيف',
                              widget.item.category?.name ?? 'غير محدد',
                            ),
                            _buildSpecItem(
                              'الحالة',
                              widget.item.isActive ? 'متوفر' : 'غير متوفر',
                            ),
                            _buildSpecItem('رقم المنتج', '#${widget.item.id}'),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // زر الإضافة للسلة
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // زر الإضافة للسلة
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAddingToCart ? null : _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: _isAddingToCart
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'إضافة إلى السلة',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // زر الكمية
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() => _quantity++);
                          },
                          icon: const Icon(
                            Icons.add,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          '$_quantity',
                          style: GoogleFonts.cairo(
                            color: AppColors.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_quantity > 1) {
                              setState(() => _quantity--);
                            }
                          },
                          icon: Icon(
                            Icons.remove,
                            color: _quantity > 1
                                ? AppColors.primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.cairo(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: AppColors.primaryColor.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// شاشة معرض الصور بملء الشاشة
class ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // عرض الصور بملء الشاشة
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.white54,
                      );
                    },
                  ),
                ),
              );
            },
          ),
          // زر الإغلاق
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // عداد الصور
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // مؤشر الصور في الأسفل
          if (widget.images.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 30 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
