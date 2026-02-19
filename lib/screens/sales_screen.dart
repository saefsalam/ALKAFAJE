import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';

class SalesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final int totalPrice;

  const SalesScreen({
    super.key,
    required this.cartItems,
    required this.totalPrice,
  });

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = 'cash'; // cash, card, wallet

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              color: AppColors.primaryColor.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
            child: Column(
              children: [
                // الهيدر
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BubbleButton(
                          icon: Icons.arrow_back,
                          onTap: () {
                            Get.back();
                          },
                        ),
                        Text(
                          'إتمام الطلب',
                          style: GoogleFonts.cairo(
                            color: AppColors.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // المحتوى
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        // ملخص المنتجات
                        _buildSectionTitle('ملخص الطلب', Icons.receipt_long),
                        const SizedBox(height: 12),
                        _buildOrderSummaryCard(),
                        const SizedBox(height: 24),

                        // معلومات المشتري
                        _buildSectionTitle('معلومات المشتري', Icons.person_outline),
                        const SizedBox(height: 12),
                        _buildBuyerInfoCard(),
                        const SizedBox(height: 24),

                        // عنوان التوصيل
                        _buildSectionTitle('عنوان التوصيل', Icons.location_on_outlined),
                        const SizedBox(height: 12),
                        _buildDeliveryAddressCard(),
                        const SizedBox(height: 24),

                        // طريقة الدفع
                        _buildSectionTitle('طريقة الدفع', Icons.payment),
                        const SizedBox(height: 12),
                        _buildPaymentMethodCard(),
                        const SizedBox(height: 24),

                        // ملاحظات
                        _buildSectionTitle('ملاحظات إضافية', Icons.note_alt_outlined),
                        const SizedBox(height: 12),
                        _buildNotesCard(),
                        const SizedBox(height: 24),

                        // ملخص الأسعار
                        _buildPriceSummaryCard(),
                        const SizedBox(height: 20),

                        // زر تأكيد الطلب
                        _buildConfirmButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            color: AppColors.primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // بطاقة ملخص الطلب
  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // عناصر السلة
          ...widget.cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // أيقونة المنتج
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: AppColors.primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // اسم المنتج والكمية
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: GoogleFonts.cairo(
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الكمية: ${item['quantity']}',
                            style: GoogleFonts.cairo(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // السعر
                    Text(
                      '${(item['price'] as int) * (item['quantity'] as int)} د.ع',
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )),
          // فاصل
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 8),
          // عدد المنتجات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عدد المنتجات',
                style: GoogleFonts.cairo(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.cartItems.length} منتج',
                style: GoogleFonts.cairo(
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بطاقة معلومات المشتري
  Widget _buildBuyerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildInputField(
            controller: _nameController,
            hint: 'الاسم الكامل',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          _buildInputField(
            controller: _phoneController,
            hint: 'رقم الهاتف',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // بطاقة عنوان التوصيل
  Widget _buildDeliveryAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildInputField(
            controller: _addressController,
            hint: 'العنوان التفصيلي (المنطقة، الشارع، أقرب نقطة دالة)',
            icon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          // زر اختيار من الخريطة
          InkWell(
            onTap: () {
              // يمكن ربطه بواجهة الموقع لاحقاً
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اختيار من الخريطة',
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة طريقة الدفع
  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildPaymentOption(
            title: 'الدفع عند الاستلام',
            subtitle: 'ادفع نقداً عند التوصيل',
            icon: Icons.money,
            value: 'cash',
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            title: 'بطاقة الدفع',
            subtitle: 'فيزا / ماستركارد',
            icon: Icons.credit_card,
            value: 'card',
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            title: 'محفظة إلكترونية',
            subtitle: 'زين كاش / آسيا حوالة',
            icon: Icons.account_balance_wallet_outlined,
            value: 'wallet',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.08)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withOpacity(0.15)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryColor : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey[800],
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
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
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة الملاحظات
  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: _buildInputField(
        controller: _notesController,
        hint: 'أي ملاحظات خاصة بالطلب (اختياري)',
        icon: Icons.note_alt_outlined,
        maxLines: 3,
      ),
    );
  }

  // ملخص الأسعار
  Widget _buildPriceSummaryCard() {
    const int deliveryFee = 5000;
    final int total = widget.totalPrice + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildPriceRow('المجموع الفرعي', '${widget.totalPrice} د.ع'),
          const SizedBox(height: 12),
          _buildPriceRow('رسوم التوصيل', '$deliveryFee د.ع'),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الكلي',
                style: GoogleFonts.cairo(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$total د.ع',
                style: GoogleFonts.cairo(
                  color: AppColors.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          price,
          style: GoogleFonts.cairo(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // زر تأكيد الطلب
  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          // التحقق من المدخلات
          if (_nameController.text.isEmpty) {
            _showWarning('الرجاء إدخال الاسم');
            return;
          }
          if (_phoneController.text.isEmpty) {
            _showWarning('الرجاء إدخال رقم الهاتف');
            return;
          }
          if (_addressController.text.isEmpty) {
            _showWarning('الرجاء إدخال عنوان التوصيل');
            return;
          }

          // تأكيد الطلب
          Get.bottomSheet(
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.green[600],
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'تأكيد الطلب',
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'هل أنت متأكد من إرسال الطلب؟',
                    style: GoogleFonts.cairo(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'تراجع',
                            style: GoogleFonts.cairo(
                              color: Colors.grey[700],
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back(); // إغلاق البوتوم شيت
                            Get.back(); // الرجوع للسلة

                            Get.snackbar(
                              'تم إرسال الطلب بنجاح',
                              'سيتم التواصل معك قريباً لتأكيد الطلب',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 12,
                              duration: const Duration(seconds: 4),
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.green[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'تأكيد الإرسال',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isDismissible: true,
            enableDrag: true,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'تأكيد الطلب',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWarning(String message) {
    Get.snackbar(
      'تنبيه',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    );
  }

  // حقل إدخال
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
        color: AppColors.primaryColor,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryColor, size: 22),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // تنسيق البطاقة
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          spreadRadius: 1,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
