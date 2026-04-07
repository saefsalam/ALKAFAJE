import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utls/constants.dart';
import '../services/auth_service.dart';
import '../services/local_cart_service.dart';
import '../widget/bubble_button.dart';
import 'auth_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Key _refreshKey = UniqueKey();

  // إعادة تحميل السلة
  void _refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  bool get _isLoggedIn => AuthService.isLoggedIn;

  // تحميل السلة
  Future<Map<String, dynamic>> _loadCart() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
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

    return {'items': items, 'total': total, 'isLoggedIn': isLoggedIn};
  }

  double _resolveEffectivePrice(Map<String, dynamic> item) {
    final double basePrice = (item['price'] as num).toDouble();
    final num? discountPriceRaw = item['discount_price'] as num?;
    final int discountPercent = (item['discount_percent'] as num?)?.toInt() ?? 0;

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
  Future<void> _deleteItem(int itemId, bool isLoggedIn) async {
    bool success;
    if (isLoggedIn) {
      success = await AuthService.deleteFromCart(itemId);
    } else {
      success = await LocalCartService.removeFromCart(itemId);
    }

    if (success) _refresh();
  }

  // تحديث الكمية
  Future<void> _updateQuantity(int itemId, int newQuantity, bool isLoggedIn) async {
    bool success;
    if (isLoggedIn) {
      success = await AuthService.updateCartItemQuantity(itemId, newQuantity);
    } else {
      success = await LocalCartService.updateQuantity(itemId, newQuantity);
    }

    if (success) _refresh();
  }

  // تفريغ السلة
  Future<void> _clearCart(bool isLoggedIn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تفريغ السلة', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
        content: Text('هل أنت متأكد من تفريغ السلة بالكامل؟', textAlign: TextAlign.center, style: GoogleFonts.cairo()),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('تفريغ', style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      bool success;
      if (isLoggedIn) {
        success = await AuthService.clearCart();
      } else {
        success = await LocalCartService.clearCart();
      }

      if (success) {
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تفريغ السلة بنجاح', style: GoogleFonts.cairo(), textAlign: TextAlign.center), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      key: _refreshKey,
      future: _loadCart(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned.fill(child: Image.asset('assets/img/main.png', fit: BoxFit.cover)),
                const Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text('حدث خطأ', style: GoogleFonts.cairo())),
          );
        }

        final data = snapshot.data!;
        final cartItems = data['items'] as List<Map<String, dynamic>>;
        final totalPrice = data['total'] as double;
        final isLoggedIn = data['isLoggedIn'] as bool;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(child: Image.asset('assets/img/main.png', fit: BoxFit.cover)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 0),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40),
                            Text('السلة', style: GoogleFonts.cairo(color: AppColors.primaryColor, fontSize: 20, fontWeight: FontWeight.w700)),
                            if (cartItems.isNotEmpty)
                              BubbleButton(icon: Icons.delete_outline, onTap: () => _clearCart(isLoggedIn), iconColor: Colors.red)
                            else
                              const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Content
                      Expanded(
                        child: cartItems.isEmpty
                            ? _buildEmptyCart()
                            : Column(
                                children: [
                                  if (!isLoggedIn) _buildLoginPrompt(),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.only(bottom: 100),
                                      itemCount: cartItems.length,
                                      itemBuilder: (context, index) {
                                        return _buildCartItem(cartItems[index], isLoggedIn);
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
              if (cartItems.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomBar(totalPrice, cartItems, isLoggedIn),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text('السلة فارغة', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Text('أضف منتجات لتبدأ التسوق', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[500])),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700]),
          const SizedBox(width: 10),
          Expanded(child: Text('سجل دخولك للحفاظ على سلتك ومتابعة الشراء', style: GoogleFonts.cairo(color: Colors.orange[900], fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> cartItem, bool isLoggedIn) {
    final int itemId;
    final String title;
    final String? imagePath;
    final double price;
    double originalPrice;
    int discountPercent = 0;
    final int quantity = cartItem['quantity'] as int;

    if (isLoggedIn) {
      itemId = cartItem['item_id'] as int;
      final item = cartItem['items'];
      title = item['title'] ?? 'منتج غير معروف';
      price = _resolveEffectivePrice(item);
      originalPrice = (item['price'] as num).toDouble();
      discountPercent = (item['discount_percent'] as num?)?.toInt() ?? 0;
      final images = item['item_images'] as List?;
      imagePath = images != null && images.isNotEmpty ? images.firstWhere((img) => img['is_primary'] == true, orElse: () => images.first)['image_path'] : null;
    } else {
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
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
                        ? CachedNetworkImage(imageUrl: imagePath, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))), errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 30)))
                        : Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 30))))
                    : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 30)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 5),
                  if (price < originalPrice) ...[
                    Text('${originalPrice.toStringAsFixed(0)} IQD', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[500], decoration: TextDecoration.lineThrough)),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Text('${price.toStringAsFixed(0)} IQD', style: GoogleFonts.cairo(fontSize: 14, color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
                      if (discountPercent > 0 && price < originalPrice) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.red.shade200)),
                          child: Text('-$discountPercent%', style: GoogleFonts.cairo(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (quantity <= 1) {
                                  await _deleteItem(itemId, isLoggedIn);
                                } else {
                                  await _updateQuantity(itemId, quantity - 1, isLoggedIn);
                                }
                              },
                              child: Container(padding: const EdgeInsets.all(4), child: const Icon(Icons.remove, size: 18, color: AppColors.primaryColor)),
                            ),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Text('$quantity', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87))),
                            GestureDetector(
                              onTap: () => _updateQuantity(itemId, quantity + 1, isLoggedIn),
                              child: Container(padding: const EdgeInsets.all(4), child: const Icon(Icons.add, size: 18, color: AppColors.primaryColor)),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text('${subtotal.toStringAsFixed(0)} IQD', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _deleteItem(itemId, isLoggedIn),
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle), child: const Icon(Icons.delete_outline, size: 20, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double totalPrice, List<Map<String, dynamic>> cartItems, bool isLoggedIn) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, -3))],
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
                  Text('الإجمالي:', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('${totalPrice.toStringAsFixed(0)} IQD', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!isLoggedIn) {
                      final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
                      if (result == true && mounted) {
                        _refresh();
                      }
                    } else {
                      final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => CheckoutScreen(cartItems: cartItems, subtotal: totalPrice)));
                      if (result == true && mounted) {
                        _refresh();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 8),
                  child: Text(isLoggedIn ? 'إتمام الشراء' : 'سجل دخولك للشراء', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
