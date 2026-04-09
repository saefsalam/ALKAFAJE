import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../utls/constants.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/discount_code_service.dart';
import '../services/location_service.dart';
import '../models/customer_location_model.dart';
import '../models/discount_code_model.dart';
import '../models/product_model.dart';
import '../widget/bubble_button.dart';
import '../widget/loading_animation.dart';
import '../main.dart';
import 'orders/order_detail_screen.dart';
import 'addresses/select_location_bottom_sheet.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة إتمام الطلب (Checkout)
// ═══════════════════════════════════════════════════════════════════════════

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final String? initialPromoCode;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    this.initialPromoCode,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
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
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════

  CustomerLocation? _selectedLocation;
  bool _isLoadingZones = true;
  bool _isSubmitting = false;
  bool _isApplyingPromoCode = false;

  final _noteController = TextEditingController();
  final _addressController = TextEditingController();
  final _promoCodeController = TextEditingController();
  DiscountCodeCalculation? _discountCalculation;

  @override
  void initState() {
    super.initState();
    _loadData();
    final String initialPromoCode = widget.initialPromoCode?.trim() ?? '';
    if (initialPromoCode.isNotEmpty) {
      _promoCodeController.text = initialPromoCode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyPromoCode(showSuccessMessage: false);
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _addressController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadData() async {
    // الحصول على معلومات العميل أولاً
    final customerInfo = await AuthService.getCustomerInfo();
    if (customerInfo == null) {
      if (mounted) {
        _showMessage('الرجاء تسجيل الدخول أولاً', isError: true);
      }
      return;
    }

    final customerId = customerInfo['id'] as int;

    // تحميل الموقع الرئيسي
    final defaultLocation =
        await LocationService.getDefaultLocation(customerId: customerId);

    if (mounted) {
      setState(() {
        _selectedLocation = defaultLocation;
        _isLoadingZones = false;

        // ملء العنوان من الموقع
        if (defaultLocation != null) {
          _addressController.text = defaultLocation.displayText;
        } else if (customerInfo['address'] != null) {
          // استخدام العنوان القديم كبديل
          _addressController.text = customerInfo['address'];
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الحسابات
  // ═══════════════════════════════════════════════════════════════════════════

  double get _discountAmount => _discountCalculation?.discountAmount ?? 0;

  double get _total => _discountCalculation?.finalTotal ?? widget.subtotal;

  Future<void> _applyPromoCode({bool showSuccessMessage = true}) async {
    final String rawCode = _promoCodeController.text.trim();
    if (rawCode.isEmpty) {
      _showMessage('أدخل البرومو كود أولًا', isError: true);
      return;
    }

    setState(() => _isApplyingPromoCode = true);
    final DiscountCodeCalculation calculation =
        await DiscountCodeService.validateCode(
      rawCode: rawCode,
      subtotal: widget.subtotal,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isApplyingPromoCode = false;
      _discountCalculation = calculation.isApplicable ? calculation : null;
    });

    if (calculation.isApplicable) {
      _promoCodeController.text =
          calculation.discountCode?.normalizedCode ?? rawCode.toUpperCase();
      if (showSuccessMessage) {
        _showMessage(
          'تم تطبيق البرومو كود وخصم ${calculation.discountAmount.toStringAsFixed(0)} د.ع',
        );
      }
      return;
    }

    _showMessage(
      calculation.message ?? 'تعذر تطبيق البرومو كود',
      isError: true,
    );
  }

  void _removePromoCode() {
    setState(() {
      _discountCalculation = null;
      _promoCodeController.clear();
    });
    _showMessage('تم حذف البرومو كود من الطلب');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إنشاء الطلب
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _submitOrder() async {
    // تأكيد الطلب
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تأكيد الطلب',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل تريد تأكيد الطلب؟',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 15),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
                'المنتجات', '${widget.subtotal.toStringAsFixed(0)} د.ع'),
            if (_discountAmount > 0) ...[
              const Divider(height: 16),
              _buildSummaryRow(
                'خصم البرومو',
                '-${_discountAmount.toStringAsFixed(0)} د.ع',
              ),
            ],
            const Divider(height: 16),
            _buildSummaryRow(
              'الإجمالي',
              '${_total.toStringAsFixed(0)} د.ع',
              isBold: true,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'تأكيد الطلب',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final result = await OrderService.createOrderWithPromo(
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      discountCode: _discountCalculation?.discountCode,
      locationId: _selectedLocation?.id, // إرسال location_id مع الطلب
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (mounted) {
        // عرض شاشة النجاح
        _showOrderSuccessDialog(
          result['orderId'] as int,
          (result['total'] as num?)?.toDouble() ?? _total,
        );
      }
    } else {
      _showMessage(result['message'] ?? 'فشل في إنشاء الطلب', isError: true);
    }
  }

  void _showOrderSuccessDialog(int orderId, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تم تأكيد طلبك! 🎉',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'رقم الطلب: #$orderId',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'الإجمالي: ${total.toStringAsFixed(0)} د.ع',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'سيتم مراجعة طلبك وتأكيده قريباً',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // إغلاق الـ dialog
                // الانتقال لتفاصيل الطلب
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen(orderId: orderId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'متابعة الطلب',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق الـ dialog
              // الرجوع للشاشة الرئيسية
              Get.offAll(() => const MainScreen());
            },
            child: Text(
              'العودة للتسوق',
              style: GoogleFonts.cairo(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // فتح Bottom Sheet لاختيار/إضافة الموقع
  Future<void> _selectLocation() async {
    final result = await showModalBottomSheet<CustomerLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      builder: (context) => SelectLocationBottomSheet(
        currentLocation: _selectedLocation,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result;
        _addressController.text = result.displayText;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الواجهة
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // صورة الخلفية
            Positioned.fill(
              child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
            ),
            // المحتوى
            SafeArea(
              bottom: false, // السماح للمحتوى بالظهور خلف Bottom Nav
              child: _isLoadingZones
                  ? const Center(
                      child: LoadingAnimation(size: 200),
                    )
                  : Padding(
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
                                const SizedBox(width: 40), // للتوازن
                                Text(
                                  'إتمام الطلب',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.primaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Transform.scale(
                                  scaleX: -1, // عكس الأيقونة أفقياً
                                  child: BubbleButton(
                                    icon: Icons.arrow_back,
                                    onTap: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // المحتوى القابل للتمرير
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 100),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ─── ملخص المنتجات ───
                                  _buildSectionTitle(
                                      'المنتجات (${widget.cartItems.length})',
                                      Icons.shopping_bag_outlined),
                                  const SizedBox(height: 8),
                                  _buildProductsSummary(),

                                  const SizedBox(height: 20),

                                  _buildSectionTitle('البرومو كود',
                                      Icons.local_offer_outlined),
                                  const SizedBox(height: 8),
                                  _buildPromoCodeCard(),

                                  const SizedBox(height: 20),

                                  // ─── موقع التوصيل ───
                                  _buildSectionTitle('موقع التوصيل',
                                      Icons.my_location_outlined),
                                  const SizedBox(height: 8),
                                  _buildLocationSelector(),

                                  const SizedBox(height: 20),

                                  // ─── العنوان التفصيلي ───
                                  _buildSectionTitle(
                                      'العنوان التفصيلي', Icons.home_outlined),
                                  const SizedBox(height: 8),
                                  _buildAddressField(),

                                  const SizedBox(height: 20),

                                  // ─── ملاحظات ───
                                  _buildSectionTitle(
                                      'ملاحظات (اختياري)', Icons.note_outlined),
                                  const SizedBox(height: 8),
                                  _buildNoteField(),

                                  const SizedBox(height: 24),

                                  // ─── ملخص الأسعار ───
                                  _buildPriceSummary(),

                                  const SizedBox(height: 20),

                                  // ─── زر تأكيد الطلب ───
                                  _buildSubmitButton(),

                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  // ─── ملخص المنتجات ───────────────────────────────────────────────────

  Widget _buildProductsSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ...widget.cartItems.map((cartItem) {
            final item = cartItem['items'];
            if (item == null) return const SizedBox.shrink();

            final title = item['title'] ?? 'منتج';
            final ProductOptionSelection selection =
                ProductOptionSelection.fromJson(cartItem);
            final quantity = cartItem['quantity'] as int;
            final unitPrice = _resolveEffectivePrice(item);
            final lineTotal = unitPrice * quantity;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // الكمية
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '×$quantity',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // اسم المنتج
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.cairo(
                              fontSize: 14, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (selection.label.isNotEmpty)
                          Text(
                            selection.label,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // السعر
                  Text(
                    '${lineTotal.toStringAsFixed(0)} د.ع',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── حقل العنوان ───────────────────────────────────────────────────────

  Widget _buildPromoCodeCard() {
    final bool hasAppliedPromo = _discountCalculation?.isApplicable == true &&
        _discountCalculation?.discountCode != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
                    hintText: 'أدخل رمز الخصم',
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
                          hasAppliedPromo ? 'إعادة التحقق' : 'تطبيق',
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _discountCalculation!.discountCode!.normalizedCode,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تم خصم ${_discountAmount.toStringAsFixed(0)} د.ع من الطلب',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
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

  Widget _buildAddressField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _addressController,
        maxLines: 2,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'مثال: حي الكرامة، شارع 20، قرب مستشفى...',
          hintStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ─── حقل الملاحظات ────────────────────────────────────────────────────

  Widget _buildNoteField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _noteController,
        maxLines: 3,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'أي ملاحظات إضافية على الطلب...',
          hintStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ─── ملخص الأسعار ─────────────────────────────────────────────────────

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'المنتجات',
            '${widget.subtotal.toStringAsFixed(0)} د.ع',
          ),
          if (_discountAmount > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
            _buildSummaryRow(
              'خصم البرومو',
              '-${_discountAmount.toStringAsFixed(0)} د.ع',
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _buildSummaryRow(
            'الإجمالي',
            '${_total.toStringAsFixed(0)} د.ع',
            isBold: true,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.primaryColor : Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: isLarge ? 17 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColors.primaryColor : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // ─── زر تأكيد الطلب ──────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final canSubmit = !_isSubmitting;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitOrder : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'تأكيد الطلب • ${_total.toStringAsFixed(0)} د.ع',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // قسم اختيار الموقع
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLocationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: _selectedLocation == null
          ? InkWell(
              onTap: _selectLocation,
              child: Row(
                children: [
                  Icon(
                    Icons.add_location_alt,
                    color: AppColors.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إضافة موقع التوصيل',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          'اختر من المواقع المحفوظة أو أضف جديد',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_left,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedLocation!.isDefault
                        ? AppColors.primaryColor
                        : AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedLocation!.isDefault
                        ? Icons.home
                        : Icons.location_on,
                    color: _selectedLocation!.isDefault
                        ? Colors.white
                        : AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _selectedLocation!.name,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedLocation!.isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'رئيسي',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedLocation!.displayText,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_location_alt,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: _selectLocation,
                  tooltip: 'تغيير الموقع',
                ),
              ],
            ),
    );
  }
}
