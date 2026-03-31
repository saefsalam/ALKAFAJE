import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utls/constants.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../models/customer_location_model.dart';
import 'orders/order_detail_screen.dart';
import 'addresses/select_location_bottom_sheet.dart';

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

  CustomerLocation? _selectedLocation;
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

  double get _total => widget.subtotal;

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
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      locationId: _selectedLocation?.id, // إرسال location_id مع الطلب
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
                  _buildSectionTitle('المنتجات (${widget.cartItems.length})',
                      Icons.shopping_bag_outlined),
                  const SizedBox(height: 8),
                  _buildProductsSummary(),

                  const SizedBox(height: 20),

                  // ─── موقع التوصيل ───
                  _buildSectionTitle(
                      'موقع التوصيل', Icons.my_location_outlined),
                  const SizedBox(height: 8),
                  _buildLocationSelector(),

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
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: Colors.black87),
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
