import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utls/constants.dart';
import '../services/auth_service.dart';
import '../services/local_cart_service.dart';
import '../widget/bubble_button.dart';
import 'auth_screen.dart';
import 'checkout_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة السلة - عرض وإدارة عناصر السلة
// تدعم النظامين: السلة المحلية (بدون تسجيل) والسلة من قاعدة البيانات (مع تسجيل)
// كود نظيف وبسيط - سهل التعديل والفهم
// ═══════════════════════════════════════════════════════════════════════════

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  double _totalPrice = 0;
  bool _isLoggedIn = false;

  double _resolveEffectivePrice(Map<String, dynamic> item) {
    final double basePrice = (item['price'] as num).toDouble();
    final num? discountPriceRaw = item['discount_price'] as num?;
    final int discountPercent =
        (item['discount_percent'] as num?)?.toInt() ?? 0;

    if (discountPriceRaw != null) {
      final double discountPrice = discountPriceRaw.toDouble();
      if (discountPrice > 0 && discountPrice < basePrice) {
        return discountPrice;
      }
    }

    if (discountPercent > 0 && discountPercent < 100) {
      return basePrice * (1 - (discountPercent / 100));
    }

    return basePrice;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال تحميل السلة (محلية أو قاعدة بيانات)
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحميل عناصر السلة حسب حالة تسجيل الدخول
  Future<void> _loadCartItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // التحقق من حالة تسجيل الدخول
      _isLoggedIn = AuthService.isLoggedIn;

      List<Map<String, dynamic>> items;

      if (_isLoggedIn) {
        // تحميل من قاعدة البيانات
        items = await AuthService.getCartItems();
      } else {
        // تحميل من السلة المحلية
        items = await LocalCartService.getCartItems();
      }

      // حساب الإجمالي
      final total = _calculateTotal(items);

      if (!mounted) return;
      setState(() {
        _cartItems = items;
        _totalPrice = total;
        _isLoading = false;
      });

      print(
          '🛒 تم تحميل ${_cartItems.length} عنصر - المجموع: $_totalPrice (${_isLoggedIn ? "DB" : "Local"})');
    } catch (e) {
      print('❌ خطأ في تحميل السلة: $e');
      if (!mounted) return;
      setState(() {
        _cartItems = [];
        _totalPrice = 0;
        _isLoading = false;
      });
    }
  }

  /// حساب المجموع الكلي
  double _calculateTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var cartItem in items) {
      final quantity = cartItem['quantity'] as int;

      // التعامل مع كلا الحالتين (محلي/قاعدة بيانات)
      if (_isLoggedIn) {
        // البيانات من قاعدة البيانات
        final item = cartItem['items'];
        if (item != null) {
          final price = _resolveEffectivePrice(item);
          total += price * quantity;
        }
      } else {
        // البيانات المحلية
        final price = _resolveEffectivePrice(cartItem);
        total += price * quantity;
      }
    }
    return total;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // عمليات السلة (إضافة، حذف، تحديث)
  // ═══════════════════════════════════════════════════════════════════════════

  /// زيادة كمية منتج
  Future<void> _incrementQuantity(int itemId) async {
    // العثور على العنصر
    final index = _cartItems.indexWhere((item) {
      if (_isLoggedIn) {
        return item['item_id'] == itemId;
      } else {
        return item['id'] == itemId;
      }
    });

    if (index == -1) return;

    final currentQuantity = _cartItems[index]['quantity'] as int;
    final newQuantity = currentQuantity + 1;

    // تحديث محلياً أولاً (Optimistic Update)
    setState(() {
      _cartItems[index]['quantity'] = newQuantity;
      _totalPrice = _calculateTotal(_cartItems);
    });

    // تحديث في قاعدة البيانات أو محلياً
    bool success;
    if (_isLoggedIn) {
      success = await AuthService.updateCartItemQuantity(itemId, newQuantity);
    } else {
      success = await LocalCartService.updateQuantity(itemId, newQuantity);
    }

    // إذا فشل، إعادة التحميل
    if (!success) {
      _loadCartItems();
    }
  }

  /// تقليل كمية منتج
  Future<void> _decrementQuantity(int itemId, int currentQuantity) async {
    if (currentQuantity <= 1) {
      await _deleteItem(itemId);
    } else {
      final newQuantity = currentQuantity - 1;

      // تحديث محلياً أولاً (Optimistic Update)
      final index = _cartItems.indexWhere((item) {
        if (_isLoggedIn) {
          return item['item_id'] == itemId;
        } else {
          return item['id'] == itemId;
        }
      });

      if (index != -1) {
        setState(() {
          _cartItems[index]['quantity'] = newQuantity;
          _totalPrice = _calculateTotal(_cartItems);
        });

        // تحديث في قاعدة البيانات أو محلياً
        bool success;
        if (_isLoggedIn) {
          success =
              await AuthService.updateCartItemQuantity(itemId, newQuantity);
        } else {
          success = await LocalCartService.updateQuantity(itemId, newQuantity);
        }

        // إذا فشل، إعادة التحميل
        if (!success) {
          _loadCartItems();
        }
      }
    }
  }

  /// حذف عنصر من السلة
  Future<void> _deleteItem(int itemId) async {
    // Optimistic Update - حذف من الواجهة فوراً
    setState(() {
      _cartItems.removeWhere((item) {
        if (_isLoggedIn) {
          return item['item_id'] == itemId;
        } else {
          return item['id'] == itemId;
        }
      });
      _totalPrice = _calculateTotal(_cartItems);
    });

    // حذف من قاعدة البيانات أو محلياً
    bool success;
    if (_isLoggedIn) {
      success = await AuthService.deleteFromCart(itemId);
    } else {
      success = await LocalCartService.removeFromCart(itemId);
    }

    // إذا فشل، إعادة التحميل
    if (!success) {
      _loadCartItems();
    }
  }

  /// تفريغ السلة بالكامل
  Future<void> _clearCart() async {
    // تأكيد الحذف
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'تفريغ السلة',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        content: Text(
          'هل أنت متأكد من تفريغ السلة بالكامل؟',
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
            child: Text(
              'تفريغ',
              style: GoogleFonts.cairo(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success;
      if (_isLoggedIn) {
        success = await AuthService.clearCart();
      } else {
        success = await LocalCartService.clearCart();
      }

      if (success) {
        _loadCartItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تفريغ السلة بنجاح',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// عملية الشراء (Checkout)
  Future<void> _checkout() async {
    // التحقق من وجود عناصر في السلة
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'السلة فارغة',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // إذا لم يكن مسجل دخول، الانتقال لصفحة التسجيل
    if (!_isLoggedIn) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        ),
      );

      // إذا تم تسجيل الدخول بنجاح، إعادة تحميل السلة
      if (result == true && mounted) {
        await _loadCartItems();
        // الآن يمكن المتابعة للشراء
        _proceedToCheckout();
      }
      return;
    }

    // المتابعة للشراء
    _proceedToCheckout();
  }

  /// المتابعة لإتمام عملية الشراء
  void _proceedToCheckout() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: _cartItems,
          subtotal: _totalPrice,
        ),
      ),
    );

    // إذا تم الطلب بنجاح، إعادة تحميل السلة (ستكون فارغة)
    if (result == true && mounted) {
      _loadCartItems();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // دورة الحياة (Lifecycle)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // بناء الواجهة (UI)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // صورة الخلفية
          Positioned.fill(
            child: Image.asset(
              'assets/img/main.png',
              fit: BoxFit.cover,
            ),
          ),
          // المحتوى
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 5.0, bottom: 0),
              child: Column(
                children: [
                  // الهيدر
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BubbleButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                        ),
                        Text(
                          'السلة',
                          style: GoogleFonts.cairo(
                            color: AppColors.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // أزرار الإجراءات
                        Row(
                          children: [
                            if (_cartItems.isNotEmpty)
                              BubbleButton(
                                icon: Icons.delete_outline,
                                onTap: _clearCart,
                                iconColor: Colors.red,
                              ),
                            const SizedBox(width: 8),
                            BubbleButton(
                              icon: Icons.refresh,
                              onTap: _loadCartItems,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // المحتوى
                  Expanded(
                    child: _isLoading ? _buildLoadingState() : _buildBody(),
                  ),
                ],
              ),
            ),
          ),
          // الشريط السفلي فوق المحتوى
          if (_cartItems.isNotEmpty && !_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
        ],
      ),
    );
  }

  /// حالة التحميل
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryColor,
      ),
    );
  }

  /// بناء الجسم الرئيسي
  Widget _buildBody() {
    if (_cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return Column(
      children: [
        // رسالة توضيحية إذا لم يكن مسجل دخول
        if (!_isLoggedIn) _buildLoginPrompt(),

        // قائمة المنتجات
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              return _buildCartItem(_cartItems[index]);
            },
          ),
        ),
      ],
    );
  }

  /// رسالة تشجيع على تسجيل الدخول
  Widget _buildLoginPrompt() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'سجل دخولك للحفاظ على سلتك ومتابعة الشراء',
              style: GoogleFonts.cairo(
                color: Colors.orange[900],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر في السلة
  Widget _buildCartItem(Map<String, dynamic> cartItem) {
    // استخراج البيانات حسب النوع (محلي أو قاعدة بيانات)
    final int itemId;
    final String title;
    final String? imagePath;
    final double price;
    double originalPrice;
    int discountPercent = 0;
    final int quantity = cartItem['quantity'] as int;

    if (_isLoggedIn) {
      // بيانات من قاعدة البيانات
      itemId = cartItem['item_id'] as int;
      final item = cartItem['items'];
      title = item['title'] ?? 'منتج غير معروف';
      price = _resolveEffectivePrice(item);
      originalPrice = (item['price'] as num).toDouble();
      discountPercent = (item['discount_percent'] as num?)?.toInt() ?? 0;

      // الصورة الأساسية
      final images = item['item_images'] as List?;
      imagePath = images != null && images.isNotEmpty
          ? images.firstWhere(
              (img) => img['is_primary'] == true,
              orElse: () => images.first,
            )['image_path']
          : null;
    } else {
      // بيانات محلية
      itemId = cartItem['id'] as int;
      title = cartItem['title'] ?? 'منتج غير معروف';
      price = _resolveEffectivePrice(cartItem);
      originalPrice = (cartItem['price'] as num).toDouble();
      discountPercent = (cartItem['discount_percent'] as num?)?.toInt() ?? 0;
      imagePath = cartItem['image'];
    }

    final subtotal = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imagePath != null && imagePath.isNotEmpty
                    ? (imagePath.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imagePath,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 30),
                            ),
                          )
                        : Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 30),
                              );
                            },
                          ))
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 30),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // التفاصيل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // السعر
                  if (price < originalPrice) ...[
                    Text(
                      '${originalPrice.toStringAsFixed(0)} IQD',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Text(
                        '${price.toStringAsFixed(0)} IQD',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (discountPercent > 0 && price < originalPrice) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // الكمية والمجموع الفرعي
                  Row(
                    children: [
                      // أزرار الكمية
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // زر -
                            GestureDetector(
                              onTap: () => _decrementQuantity(itemId, quantity),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),

                            // الكمية
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Text(
                                '$quantity',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            // زر +
                            GestureDetector(
                              onTap: () => _incrementQuantity(itemId),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // المجموع الفرعي
                      Text(
                        '${subtotal.toStringAsFixed(0)} IQD',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // زر الحذف
            GestureDetector(
              onTap: () => _deleteItem(itemId),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// حالة السلة فارغة
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'السلة فارغة',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'أضف منتجات لتبدأ التسوق',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// شريط الأسفل (الإجمالي وزر الشراء)
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الإجمالي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإجمالي:',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${_totalPrice.toStringAsFixed(0)} IQD',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // زر الشراء
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 8,
                  ),
                  child: Text(
                    _isLoggedIn ? 'إتمام الشراء' : 'سجل دخولك للشراء',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
