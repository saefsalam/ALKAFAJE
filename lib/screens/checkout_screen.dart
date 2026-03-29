import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utls/constants.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import 'orders/order_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة إتمام الطلب (Checkout)
// ═══════════════════════════════════════════════════════════════════════════

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _deliveryZones = [];
  Map<String, dynamic>? _selectedZone;
  bool _isLoadingZones = true;
  bool _isSubmitting = false;

  final _noteController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadData() async {
    // تحميل مناطق التوصيل ومعلومات العميل بالتوازي
    final results = await Future.wait([
      OrderService.getDeliveryZones(),
      AuthService.getCustomerInfo(),
    ]);

    final zones = results[0] as List<Map<String, dynamic>>;
    final customerInfo = results[1] as Map<String, dynamic>?;

    if (mounted) {
      setState(() {
        _deliveryZones = zones;
        _isLoadingZones = false;

        // ملء العنوان تلقائياً إذا كان موجوداً
        if (customerInfo != null) {
          if (customerInfo['address'] != null) {
            _addressController.text = customerInfo['address'];
          }
          // اختيار المنطقة تلقائياً إذا كانت محفوظة
          if (customerInfo['city'] != null && zones.isNotEmpty) {
            final existingZone = zones.where(
              (z) => z['city'] == customerInfo['city'],
            );
            if (existingZone.isNotEmpty) {
              _selectedZone = existingZone.first;
            }
          }
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الحسابات
  // ═══════════════════════════════════════════════════════════════════════════

  double get _deliveryFee {
    if (_selectedZone == null) return 0;
    return (_selectedZone!['price'] as num).toDouble();
  }

  double get _total => widget.subtotal + _deliveryFee;

  // ═══════════════════════════════════════════════════════════════════════════
  // إنشاء الطلب
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _submitOrder() async {
    // التحقق من اختيار منطقة التوصيل
    if (_selectedZone == null) {
      _showMessage('الرجاء اختيار منطقة التوصيل', isError: true);
      return;
    }

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
            _buildSummaryRow('المنتجات', '${widget.subtotal.toStringAsFixed(0)} د.ع'),
            _buildSummaryRow('التوصيل', '${_deliveryFee.toStringAsFixed(0)} د.ع'),
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

    final result = await OrderService.createOrder(
      city: _selectedZone!['city'] as String,
      deliveryFee: _deliveryFee,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (mounted) {
        // عرض شاشة النجاح
        _showOrderSuccessDialog(result['orderId'] as int, _total);
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
              Navigator.pop(context, true); // الرجوع للسلة مع إشارة النجاح
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

  // ═══════════════════════════════════════════════════════════════════════════
  // الواجهة
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'إتمام الطلب',
          style: GoogleFonts.cairo(
            color: AppColors.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingZones
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── ملخص المنتجات ───
                  _buildSectionTitle('المنتجات (${widget.cartItems.length})', Icons.shopping_bag_outlined),
                  const SizedBox(height: 8),
                  _buildProductsSummary(),

                  const SizedBox(height: 20),

                  // ─── منطقة التوصيل ───
                  _buildSectionTitle('منطقة التوصيل', Icons.location_on_outlined),
                  const SizedBox(height: 8),
                  _buildDeliveryZoneSelector(),

                  const SizedBox(height: 20),

                  // ─── العنوان التفصيلي ───
                  _buildSectionTitle('العنوان التفصيلي', Icons.home_outlined),
                  const SizedBox(height: 8),
                  _buildAddressField(),

                  const SizedBox(height: 20),

                  // ─── ملاحظات ───
                  _buildSectionTitle('ملاحظات (اختياري)', Icons.note_outlined),
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
            final quantity = cartItem['quantity'] as int;
            final unitPrice = (item['price'] as num).toDouble();
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
                    child: Text(
                      title,
                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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

  // ─── اختيار منطقة التوصيل ─────────────────────────────────────────────

  Widget _buildDeliveryZoneSelector() {
    if (_deliveryZones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'لا توجد مناطق توصيل متاحة حالياً',
                style: GoogleFonts.cairo(color: Colors.orange[800], fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

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
        children: _deliveryZones.map((zone) {
          final isSelected = _selectedZone?['id'] == zone['id'];
          final price = (zone['price'] as num).toDouble();

          return InkWell(
            onTap: () {
              setState(() => _selectedZone = zone);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withOpacity(0.05)
                    : Colors.transparent,
                border: isSelected
                    ? Border.all(color: AppColors.primaryColor.withOpacity(0.3))
                    : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Radio
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // اسم المنطقة
                  Expanded(
                    child: Text(
                      zone['city'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.black87,
                      ),
                    ),
                  ),
                  // سعر التوصيل
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: price == 0
                          ? Colors.green.withOpacity(0.1)
                          : AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      price == 0 ? 'مجاني' : '${price.toStringAsFixed(0)} د.ع',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: price == 0 ? Colors.green : AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── حقل العنوان ───────────────────────────────────────────────────────

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
          const SizedBox(height: 8),
          _buildSummaryRow(
            'التوصيل',
            _selectedZone == null
                ? 'اختر المنطقة'
                : (_deliveryFee == 0
                    ? 'مجاني'
                    : '${_deliveryFee.toStringAsFixed(0)} د.ع'),
          ),
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: isLarge ? 17 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColors.primaryColor : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ─── زر تأكيد الطلب ──────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final canSubmit = _selectedZone != null && !_isSubmitting;

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
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
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
}
