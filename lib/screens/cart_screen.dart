import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';
import '../main.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة السلة - عرض وإدارة عناصر السلة
// كود نظيف وبسيط - سهل التعديل والفهم
// ═══════════════════════════════════════════════════════════════════════════

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with RouteAware, WidgetsBindingObserver {
  // ═══════════════════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  double _totalPrice = 0;
  bool _isVisible = false;

  // Supabase
  static final _supabase = Supabase.instance.client;
  static int? _currentCustomerId = 1; // مؤقت للاختبار
  static int? _currentCartId;

  // ═══════════════════════════════════════════════════════════════════════════
  // دوال السلة المحلية
  // ═══════════════════════════════════════════════════════════════════════════

  static void setCustomerId(int customerId) {
    _currentCustomerId = customerId;
    _currentCartId = null;
  }

  Future<int?> _getOrCreateCart() async {
    if (_currentCustomerId == null) {
      print('❌ لا يوجد عميل مسجل');
      return null;
    }
    if (_currentCartId != null) return _currentCartId;

    try {
      final existingCart =
          await _supabase
              .from('carts')
              .select('id')
              .eq('shop_id', SupabaseConfig.shopId)
              .eq('customer_id', _currentCustomerId!)
              .maybeSingle();

      if (existingCart != null) {
        _currentCartId = existingCart['id'];
        return _currentCartId;
      }

      final newCart =
          await _supabase
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

  Future<List<Map<String, dynamic>>> _getCartItemsFromDB() async {
    final cartId = await _getOrCreateCart();
    if (cartId == null) return [];

    try {
      final data = await _supabase
          .from('cart_items')
          .select('''
            id,
            quantity,
            item_id,
            items (
              id,
              title,
              description,
              price,
              item_images (
                image_path,
                is_primary
              )
            )
          ''')
          .eq('cart_id', cartId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ خطأ في جلب عناصر السلة: $e');
      return [];
    }
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var cartItem in items) {
      final quantity = cartItem['quantity'] as int;
      final item = cartItem['items'];
      if (item != null) {
        final price = (item['price'] as num).toDouble();
        total += price * quantity;
      }
    }
    return total;
  }

  Future<bool> _addToCartDB(int itemId, {int quantity = 1}) async {
    final cartId = await _getOrCreateCart();
    if (cartId == null) return false;

    try {
      final existingItem =
          await _supabase
              .from('cart_items')
              .select('id, quantity')
              .eq('cart_id', cartId)
              .eq('item_id', itemId)
              .maybeSingle();

      if (existingItem != null) {
        final newQuantity = existingItem['quantity'] + quantity;
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
          'item_id': itemId,
          'quantity': quantity,
        });
      }
      return true;
    } catch (e) {
      print('❌ خطأ في إضافة المنتج: $e');
      return false;
    }
  }

  Future<bool> _removeFromCartDB(int itemId, {int quantity = 1}) async {
    final cartId = await _getOrCreateCart();
    if (cartId == null) return false;

    try {
      final existingItem =
          await _supabase
              .from('cart_items')
              .select('id, quantity')
              .eq('cart_id', cartId)
              .eq('item_id', itemId)
              .maybeSingle();

      if (existingItem == null) return false;

      final currentQuantity = existingItem['quantity'] as int;
      final newQuantity = currentQuantity - quantity;

      if (newQuantity <= 0) {
        await _supabase
            .from('cart_items')
            .delete()
            .eq('id', existingItem['id']);
      } else {
        await _supabase
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingItem['id']);
      }
      return true;
    } catch (e) {
      print('❌ خطأ في إزالة المنتج: $e');
      return false;
    }
  }

  Future<bool> _deleteFromCartDB(int itemId) async {
    final cartId = await _getOrCreateCart();
    if (cartId == null) return false;

    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('cart_id', cartId)
          .eq('item_id', itemId);
      return true;
    } catch (e) {
      print('❌ خطأ في حذف المنتج: $e');
      return false;
    }
  }

  Future<bool> _clearCartDB() async {
    final cartId = await _getOrCreateCart();
    if (cartId == null) return false;

    try {
      await _supabase.from('cart_items').delete().eq('cart_id', cartId);
      return true;
    } catch (e) {
      print('❌ خطأ في تفريغ السلة: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCartItems();

    // الاستماع لإشعارات إعادة التحميل
    cartReloadNotifier.addListener(_onReloadNotification);
  }

  void _onReloadNotification() {
    print('🔔 تم استلام إشعار إعادة تحميل السلة');
    _loadCartItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }

    // إعادة التحميل عند التبديل للشاشة
    if (!_isVisible) {
      _isVisible = true;
      Future.microtask(() => _loadCartItems());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    cartReloadNotifier.removeListener(_onReloadNotification);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isVisible) {
      // إعادة التحميل عند العودة للتطبيق
      _loadCartItems();
    }
  }

  // استدعاء عند ظهور الشاشة (الدخول إليها)
  @override
  void didPopNext() {
    // تم الرجوع إلى هذه الشاشة من شاشة أخرى
    _isVisible = true;
    print('🔄 تم الرجوع للسلة - إعادة التحميل');
    _loadCartItems();
  }

  // استدعاء عند الدخول لأول مرة
  @override
  void didPush() {
    // تم الدخول إلى هذه الشاشة
    _isVisible = true;
    print('🔄 تم الدخول للسلة');
  }

  // استدعاء عند مغادرة الشاشة
  @override
  void didPushNext() {
    _isVisible = false;
  }

  @override
  void didPop() {
    _isVisible = false;
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);

    try {
      final items = await _getCartItemsFromDB();
      final total = _calculateTotal(items);

      setState(() {
        _cartItems = items;
        _totalPrice = total;
        _isLoading = false;
      });

      print('🛒 تم تحميل ${_cartItems.length} عنصر - المجموع: $_totalPrice');
    } catch (e) {
      print('❌ خطأ في تحميل السلة: $e');
      setState(() => _isLoading = false);
    }
  }

  // دالة عامة لإعادة تحميل السلة (يمكن استدعاؤها من الخارج)
  void reloadCart() {
    print('🔄 إعادة تحميل السلة من الخارج');
    _loadCartItems();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // عمليات السلة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _incrementQuantity(int itemId) async {
    // نأخذ الكمية الحالية
    final index = _cartItems.indexWhere((item) => item['item_id'] == itemId);
    if (index == -1) return;

    final currentQuantity = _cartItems[index]['quantity'] as int;
    final newQuantity = currentQuantity + 1;

    // تحديث مباشر
    await _updateQuantity(itemId, currentQuantity, newQuantity);
  }

  Future<void> _decrementQuantity(int itemId, int currentQuantity) async {
    if (currentQuantity <= 1) {
      await _deleteItem(itemId);
    } else {
      final newQuantity = currentQuantity - 1;
      await _updateQuantity(itemId, currentQuantity, newQuantity);
    }
  }

  Future<void> _deleteItem(int itemId) async {
    // Optimistic Update - حذف من الواجهة فوراً
    setState(() {
      _cartItems.removeWhere((item) => item['item_id'] == itemId);
      _totalPrice = _calculateTotal(_cartItems);
    });

    // حذف من قاعدة البيانات
    final success = await _deleteFromCartDB(itemId);
    if (!success) {
      _loadCartItems();
    }
  }

  Future<void> _clearCart() async {
    // تأكيد الحذف
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
              'هل أنت متأكد من تفريغ السلة؟',
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
                  style: GoogleFonts.cairo(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await _clearCartDB();
      if (success) {
        _loadCartItems();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // عرض نافذة تعديل الكمية (نفس modal إضافة المنتج)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _showEditQuantityModal(
    int itemId,
    int currentQuantity,
    String title,
    String imagePath,
    double price,
    String? description,
  ) async {
    int selectedQuantity = currentQuantity;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
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
                        child:
                            imagePath.startsWith('http')
                                ? CachedNetworkImage(
                                  imageUrl: imagePath,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image,
                                          size: 50,
                                        ),
                                      ),
                                )
                                : Image.asset(
                                  imagePath,
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
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // الوصف
                    if (description != null && description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          description,
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
                      '${price.toStringAsFixed(0)} د.ع',
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
                              if (selectedQuantity > 0) {
                                setSheetState(() => selectedQuantity--);
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    selectedQuantity > 0
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
                      'المجموع: ${(price * selectedQuantity).toStringAsFixed(0)} د.ع',
                      style: GoogleFonts.cairo(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // زر التحديث
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);

                          if (selectedQuantity == 0) {
                            // حذف المنتج
                            await _deleteItem(itemId);
                          } else if (selectedQuantity != currentQuantity) {
                            // تحديث الكمية
                            await _updateQuantity(
                              itemId,
                              currentQuantity,
                              selectedQuantity,
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
                          selectedQuantity == 0
                              ? 'حذف من السلة'
                              : 'تحديث الكمية',
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

  // ═══════════════════════════════════════════════════════════════════════════
  // تحديث الكمية مباشرة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _updateQuantity(
    int itemId,
    int oldQuantity,
    int newQuantity,
  ) async {
    // Optimistic Update
    setState(() {
      final index = _cartItems.indexWhere((item) => item['item_id'] == itemId);
      if (index != -1) {
        _cartItems[index]['quantity'] = newQuantity;
        _totalPrice = _calculateTotal(_cartItems);
      }
    });

    // تحديث قاعدة البيانات
    final cartId = await _getOrCreateCart();
    if (cartId == null) {
      _loadCartItems();
      return;
    }

    try {
      final existingItem =
          await _supabase
              .from('cart_items')
              .select('id')
              .eq('cart_id', cartId)
              .eq('item_id', itemId)
              .maybeSingle();

      if (existingItem != null) {
        await _supabase
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingItem['id']);
      }
    } catch (e) {
      print('❌ خطأ في تحديث الكمية: $e');
      _loadCartItems(); // إعادة التحميل عند الفشل
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // استخراج الصورة من بيانات المنتج
  // ═══════════════════════════════════════════════════════════════════════════

  String _getImagePath(Map<String, dynamic> cartItem) {
    final item = cartItem['items'];
    if (item == null) return 'assets/img/main.png';

    final images = item['item_images'] as List?;
    if (images == null || images.isEmpty) return 'assets/img/main.png';

    // البحث عن الصورة الرئيسية
    for (var img in images) {
      if (img['is_primary'] == true) {
        return img['image_path'] ?? 'assets/img/main.png';
      }
    }

    return images.first['image_path'] ?? 'assets/img/main.png';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الواجهة
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════════════
            // الهيدر
            // ═══════════════════════════════════════════════════════════════
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر تفريغ السلة
                    BubbleButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: _cartItems.isEmpty ? () {} : _clearCart,
                    ),
                    // العنوان
                    Text(
                      'سلة المشتريات',
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // زر إعادة التحميل
                    BubbleButton(icon: Icons.refresh, onTap: _loadCartItems),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // ═══════════════════════════════════════════════════════════════
            // محتوى السلة
            // ═══════════════════════════════════════════════════════════════
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      )
                      : _cartItems.isEmpty
                      ? _buildEmptyCart()
                      : Column(
                        children: [
                          // قائمة المنتجات
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadCartItems,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 10),
                                itemCount: _cartItems.length,
                                itemBuilder: (context, index) {
                                  return _buildCartItem(_cartItems[index]);
                                },
                              ),
                            ),
                          ),

                          // شريط المجموع
                          _buildTotalBar(),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // واجهة السلة الفارغة
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.primaryColor.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'السلة فارغة',
            style: GoogleFonts.cairo(
              color: AppColors.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف منتجات للبدء بالتسوق',
            style: GoogleFonts.cairo(
              color: AppColors.primaryColor.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // عنصر في السلة
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCartItem(Map<String, dynamic> cartItem) {
    final item = cartItem['items'] as Map<String, dynamic>?;
    if (item == null) return const SizedBox.shrink();

    final itemId = cartItem['item_id'] as int;
    final quantity = cartItem['quantity'] as int;
    final title = item['title'] ?? '';
    final price = (item['price'] as num).toDouble();
    final imagePath = _getImagePath(cartItem);
    final itemTotal = price * quantity;

    return Dismissible(
      key: Key('cart_item_$itemId'),
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
      onDismissed: (_) => _deleteItem(itemId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
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
                child:
                    imagePath.startsWith('http')
                        ? CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: AppColors.primaryColor.withOpacity(0.08),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryColor.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: AppColors.primaryColor.withOpacity(0.08),
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
                                color: AppColors.primaryColor.withOpacity(0.3),
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
                  const SizedBox(height: 2),
                  Text(
                    'المجموع: ${itemTotal.toStringAsFixed(0)} د.ع',
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // أزرار الكمية
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر الإضافة
                  _buildQuantityButton(
                    icon: Icons.add,
                    onTap: () => _incrementQuantity(itemId),
                  ),
                  // الكمية - قابلة للضغط لتعديلها
                  GestureDetector(
                    onTap: () {
                      final item = cartItem['items'] as Map<String, dynamic>?;
                      if (item != null) {
                        _showEditQuantityModal(
                          itemId,
                          quantity,
                          title,
                          imagePath,
                          price,
                          item['description'],
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$quantity',
                        style: GoogleFonts.cairo(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // زر الإنقاص
                  _buildQuantityButton(
                    icon: quantity == 1 ? Icons.delete_outline : Icons.remove,
                    onTap: () => _decrementQuantity(itemId, quantity),
                    isDelete: quantity == 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // زر الكمية
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: isDelete ? Colors.red : AppColors.primaryColor,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // شريط المجموع
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTotalBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 90),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // المجموع
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المجموع',
                style: GoogleFonts.cairo(
                  color: AppColors.primaryColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                '${_totalPrice.toStringAsFixed(0)} د.ع',
                style: GoogleFonts.cairo(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // عدد العناصر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_cartItems.length} منتج',
              style: GoogleFonts.cairo(
                color: AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
