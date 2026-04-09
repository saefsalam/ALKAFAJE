import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utls/constants.dart';
import '../models/product_model.dart';
import '../models/discount_code_model.dart';
import '../services/auth_service.dart';
import '../services/local_cart_service.dart';
import '../services/cart_update_service.dart';
import '../services/discount_code_service.dart';
import '../widget/bubble_button.dart';
import '../widget/Mytext.dart';
import '../widget/loading_animation.dart';
import 'auth_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  double _totalPrice = 0;
  bool _isLoggedIn = false;
  bool _isApplyingPromoCode = false;
  StreamSubscription<bool>? _cartSubscription;
  final TextEditingController _promoCodeController = TextEditingController();
  DiscountCodeCalculation? _discountCalculation;

  @override
  void initState() {
    super.initState();
    _loadCartItems();

    // الاستماع للتغييرات من CartUpdateService
    _cartSubscription = CartUpdateService.cartChangeStream.listen((_) {
      print('🔔 تم استقبال إشعار بتغيير في السلة');
      _loadCartItems();
    });
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _promoCodeController.dispose();
    super.dispose();
  }

  // تحميل عناصر السلة
  Future<void> _loadCartItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final isLoggedIn = AuthService.isLoggedIn;
    List<Map<String, dynamic>> items;

    if (isLoggedIn) {
      items = await AuthService.getCartItems();
    } else {
      items = await LocalCartService.getCartItems();
    }

    double total = 0;
    for (var cartItem in items) {
      final quantity = cartItem['quantity'] as int;
      if (isLoggedIn) {
        final item = cartItem['items'];
        if (item != null) {
          final price = _resolveEffectivePrice(item);
          total += price * quantity;
        }
      } else {
        final price = _resolveEffectivePrice(cartItem);
        total += price * quantity;
      }
    }

    if (!mounted) return;
    setState(() {
      _cartItems = items;
      _totalPrice = total;
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });

    if (_cartItems.isEmpty) {
      setState(() {
        _discountCalculation = null;
        _promoCodeController.clear();
      });
      return;
    }

    if (_discountCalculation?.discountCode != null) {
      await _refreshPromoCalculation(
        code: _discountCalculation!.discountCode!.code,
        subtotal: total,
        showMessage: false,
      );
    }
  }

  double get _discountAmount => _discountCalculation?.discountAmount ?? 0;

  double get _payableTotal => _discountCalculation?.finalTotal ?? _totalPrice;

  Future<void> _refreshPromoCalculation({
    required String code,
    required double subtotal,
    required bool showMessage,
  }) async {
    final DiscountCodeCalculation calculation =
        await DiscountCodeService.validateCode(
      rawCode: code,
      subtotal: subtotal,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _discountCalculation = calculation.isApplicable ? calculation : null;
      if (calculation.isApplicable && calculation.discountCode != null) {
        _promoCodeController.text = calculation.discountCode!.normalizedCode;
      }
    });

    if (!showMessage) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          calculation.isApplicable
              ? 'تم تطبيق البرومو كود وخصم ${calculation.discountAmount.toStringAsFixed(0)} د.ع'
              : (calculation.message ?? 'تعذر تطبيق البرومو كود'),
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.center,
        ),
        backgroundColor: calculation.isApplicable ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _applyPromoCode() async {
    final String rawCode = _promoCodeController.text.trim();
    if (rawCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أدخل البرومو كود أولًا',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isApplyingPromoCode = true);
    await _refreshPromoCalculation(
      code: rawCode,
      subtotal: _totalPrice,
      showMessage: true,
    );
    if (mounted) {
      setState(() => _isApplyingPromoCode = false);
    }
  }

  void _removePromoCode() {
    setState(() {
      _discountCalculation = null;
      _promoCodeController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حذف البرومو كود من السلة',
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  // تحميل السلة
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

  // حذف منتج
  Future<void> _deleteItem(Map<String, dynamic> cartItem) async {
    bool success;
    if (_isLoggedIn) {
      success = await AuthService.deleteCartItemById(cartItem['id'] as int);
    } else {
      success = await LocalCartService.removeLocalCartEntry(
        cartItem['cart_line_id'].toString(),
      );
    }

    if (success) {
      CartUpdateService.notifyCartChanged();
    }
  }

  // تحديث الكمية
  Future<void> _updateQuantity(
    Map<String, dynamic> cartItem,
    int newQuantity,
  ) async {
    bool success;
    if (_isLoggedIn) {
      success = await AuthService.updateCartItemQuantityById(
        cartItem['id'] as int,
        newQuantity,
      );
    } else {
      success = await LocalCartService.updateLocalCartEntryQuantity(
        cartItem['cart_line_id'].toString(),
        newQuantity,
      );
    }

    if (success) {
      CartUpdateService.notifyCartChanged();
    }
  }

  // تفريغ السلة
  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تفريغ السلة',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
        content: Text('هل أنت متأكد من تفريغ السلة بالكامل؟',
            textAlign: TextAlign.center, style: GoogleFonts.cairo()),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('تفريغ',
                  style: GoogleFonts.cairo(
                      color: Colors.red, fontWeight: FontWeight.bold))),
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
        CartUpdateService.notifyCartChanged();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('تم تفريغ السلة بنجاح',
                    style: GoogleFonts.cairo(), textAlign: TextAlign.center),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
                child: Image.asset('assets/img/main.png', fit: BoxFit.cover)),
            const Center(child: LoadingAnimation(size: 200)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset('assets/img/main.png', fit: BoxFit.cover)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 5.0, bottom: 0),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        const MyText(text: 'السلة', fontSize: 20),
                        if (_cartItems.isNotEmpty)
                          BubbleButton(
                              icon: Icons.delete_outline,
                              onTap: _clearCart,
                              iconColor: Colors.red)
                        else
                          const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Content
                  Expanded(
                    child: _cartItems.isEmpty
                        ? _buildEmptyCart()
                        : Column(
                            children: [
                              if (!_isLoggedIn) _buildLoginPrompt(),
                              _buildPromoCodeCard(),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 180),
                                  itemCount: _cartItems.length,
                                  itemBuilder: (context, index) {
                                    return _buildCartItem(_cartItems[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Bar
          if (_cartItems.isNotEmpty)
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

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text('السلة فارغة',
              style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600])),
          const SizedBox(height: 10),
          Text('أضف منتجات لتبدأ التسوق',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[500])),
        ],
      ),
    );
  }

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
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700]),
          const SizedBox(width: 10),
          Expanded(
              child: Text('سجل دخولك للحفاظ على سلتك ومتابعة الشراء',
                  style: GoogleFonts.cairo(
                      color: Colors.orange[900], fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildPromoCodeCard() {
    final bool hasAppliedPromo = _discountCalculation?.isApplicable == true &&
        _discountCalculation?.discountCode != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _promoCodeController,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    final String? appliedCode =
                        _discountCalculation?.discountCode?.normalizedCode;
                    if (appliedCode != null &&
                        DiscountCodeService.normalizeCode(value) !=
                            appliedCode) {
                      setState(() => _discountCalculation = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'أدخل البرومو كود',
                    hintStyle: GoogleFonts.cairo(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.local_offer_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 1.4,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isApplyingPromoCode ? null : _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isApplyingPromoCode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          hasAppliedPromo ? 'تحديث' : 'تطبيق',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (hasAppliedPromo) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_discountCalculation!.discountCode!.normalizedCode} • خصم ${_discountAmount.toStringAsFixed(0)} د.ع',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _removePromoCode,
                    child: Text(
                      'حذف',
                      style: GoogleFonts.cairo(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> cartItem) {
    final String title;
    final String? imagePath;
    final double price;
    double originalPrice;
    int discountPercent = 0;
    final int quantity = cartItem['quantity'] as int;
    final ProductOptionSelection selection =
        ProductOptionSelection.fromJson(cartItem);

    if (_isLoggedIn) {
      final item = cartItem['items'];
      title = item['title'] ?? 'منتج غير معروف';
      price = _resolveEffectivePrice(item);
      originalPrice = (item['price'] as num).toDouble();
      discountPercent = (item['discount_percent'] as num?)?.toInt() ?? 0;
      final images = item['item_images'] as List?;
      imagePath = images != null && images.isNotEmpty
          ? images.firstWhere((img) => img['is_primary'] == true,
              orElse: () => images.first)['image_path']
          : null;
    } else {
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            placeholder: (_, __) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                            errorWidget: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 30)))
                        : Image.asset(imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 30))))
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 30)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 5),
                  if (selection.label.isNotEmpty) ...[
                    Text(
                      selection.label,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (price < originalPrice) ...[
                    Text('${originalPrice.toStringAsFixed(0)} IQD',
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough)),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Text('${price.toStringAsFixed(0)} IQD',
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600)),
                      if (discountPercent > 0 && price < originalPrice) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.red.shade200)),
                          child: Text('-$discountPercent%',
                              style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (quantity <= 1) {
                                  await _deleteItem(cartItem);
                                } else {
                                  await _updateQuantity(cartItem, quantity - 1);
                                }
                              },
                              child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.remove,
                                      size: 18, color: AppColors.primaryColor)),
                            ),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: Text('$quantity',
                                    style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87))),
                            GestureDetector(
                              onTap: () =>
                                  _updateQuantity(cartItem, quantity + 1),
                              child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.add,
                                      size: 18, color: AppColors.primaryColor)),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text('${subtotal.toStringAsFixed(0)} IQD',
                          style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _deleteItem(cartItem),
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red[50], shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -3))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('المجموع الفرعي:',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                  Text('${_totalPrice.toStringAsFixed(0)} IQD',
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor)),
                ],
              ),
              if (_discountAmount > 0) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('خصم البرومو:',
                        style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700)),
                    Text('-${_discountAmount.toStringAsFixed(0)} IQD',
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الإجمالي:',
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  Text('${_payableTotal.toStringAsFixed(0)} IQD',
                      style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor)),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_isLoggedIn) {
                      final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AuthScreen()));
                      if (result == true && mounted) {
                        CartUpdateService.notifyCartChanged();
                      }
                    } else {
                      final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CheckoutScreen(
                                  cartItems: _cartItems,
                                  subtotal: _totalPrice,
                                  initialPromoCode: _discountCalculation
                                      ?.discountCode?.normalizedCode)));
                      if (result == true && mounted) {
                        CartUpdateService.notifyCartChanged();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 8),
                  child: Text(_isLoggedIn ? 'إتمام الشراء' : 'سجل دخولك للشراء',
                      style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
