import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/cart_update_service.dart';
import '../utls/constants.dart';
import '../widget/Mytext.dart';
import '../widget/loading_animation.dart';
import 'addresses/select_location_bottom_sheet.dart';
import 'auth_screen.dart';
import 'notifications_screen.dart';
import 'orders/orders_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة الملف الشخصي
// ═══════════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _customerInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  // تحميل معلومات العميل
  Future<void> _loadCustomerInfo() async {
    if (AuthService.isLoggedIn) {
      final info = await AuthService.getCustomerInfo();
      if (mounted) {
        setState(() {
          _customerInfo = info;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // تسجيل الخروج
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AuthService.signOut();
      if (success && mounted) {
        // إشعار بتغيير السلة (التبديل من السلة في قاعدة البيانات إلى السلة المحلية)
        CartUpdateService.notifyCartChanged();

        setState(() {
          _customerInfo = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تسجيل الخروج بنجاح',
              style: GoogleFonts.cairo(),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // فتح شاشة التسجيل/تسجيل الدخول
  Future<void> _openAuthScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      _loadCustomerInfo();
    }
  }

  // عرض bottom sheet للمواقع المحفوظة
  Future<void> _showLocationsBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: false,
      builder: (context) => const SelectLocationBottomSheet(),
    );
  }

  // عرض دايلوج تعديل الملف الشخصي
  Future<void> _showEditProfileDialog() async {
    final phone = _customerInfo?['phone'] ?? '';
    final customerId = _customerInfo?['id'];

    if (phone.isEmpty || customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن التحقق من الهوية',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // المرحلة 1: إرسال OTP
    final otpSent = await _sendOtpForVerification(phone, customerId);
    if (!otpSent) return;

    // المرحلة 2: التحقق من OTP
    final verified = await _showOtpVerificationDialog(phone, customerId);

    // إذا تم التحقق بنجاح، افتح دايلوج التعديل
    if (verified == true && mounted) {
      _showNameEditDialog();
    }
  }

  // إرسال OTP للتحقق
  Future<bool> _sendOtpForVerification(String phone, int customerId) async {
    try {
      // إرسال OTP جديد
      final result = await AuthService.resendOtp(
        phone: phone,
        customerId: customerId,
      );

      if (result['success'] == true) {
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'فشل إرسال الرمز',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء إرسال الرمز',
              style: GoogleFonts.cairo(),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // عرض دايلوج التحقق من OTP
  Future<bool?> _showOtpVerificationDialog(String phone, int customerId) async {
    final TextEditingController otpController = TextEditingController();

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تأكيد الهوية',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تم إرسال رمز التحقق إلى رقم WhatsApp',
              style: GoogleFonts.cairo(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              phone,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 5,
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '00000',
                hintStyle: GoogleFonts.cairo(
                  color: Colors.grey[300],
                  letterSpacing: 8,
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                // إعادة إرسال OTP
                await _sendOtpForVerification(phone, customerId);
              },
              child: Text(
                'إعادة إرسال الرمز',
                style: GoogleFonts.cairo(
                  color: AppColors.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (otpController.text.length != 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'الرجاء إدخال رمز مكون من 5 أرقام',
                      style: GoogleFonts.cairo(),
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // التحقق من OTP
              final result = await AuthService.verifyOtp(
                phone: phone,
                otp: otpController.text,
                customerId: customerId,
              );

              if (result['success'] == true) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'الرمز غير صحيح',
                      style: GoogleFonts.cairo(),
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // عرض دايلوج تعديل الاسم
  Future<void> _showNameEditDialog() async {
    final TextEditingController nameController = TextEditingController(
      text: _customerInfo?['full_name'] ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تعديل الاسم',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        content: TextField(
          controller: nameController,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'الاسم الكامل',
            hintStyle: GoogleFonts.cairo(color: Colors.grey),
            prefixIcon:
                Icon(Icons.person_outline, color: AppColors.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'الرجاء إدخال الاسم',
                      style: GoogleFonts.cairo(),
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    // إذا تم التأكيد، احفظ الاسم الجديد
    if (confirmed == true && mounted) {
      final newName = nameController.text.trim();
      final success = await AuthService.updateCustomerName(newName);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تحديث الاسم بنجاح',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            ),
          );
          // إعادة تحميل معلومات العميل
          _loadCustomerInfo();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'حدث خطأ أثناء التحديث',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(
                child: LoadingAnimation(size: 200),
              )
            : SafeArea(
                bottom: false, // السماح للمحتوى بالظهور خلف Bottom Nav
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      children: [
                        // الهيدر
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: const MyText(text: 'الحساب', fontSize: 24),
                        ),

                        const SizedBox(height: 10),

                        // بطاقة المستخدم أو تسجيل الدخول
                        AuthService.isLoggedIn
                            ? _buildUserCard()
                            : _buildLoginCard(),

                        const SizedBox(height: 20),

                        // بطاقة القائمة
                        _buildMenuCard(),

                        const SizedBox(height: 30),

                        // نص المطورين
                        _buildDeveloperText(),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // نص المطورين - بسيط في الأسفل
  Widget _buildDeveloperText() {
    return Column(
      children: [
        Text(
          'Powered by',
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'S&K للحلول البرمجية ®',
          style: GoogleFonts.cairo(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '07838999658',
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // بطاقة تسجيل الدخول
  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withOpacity(0.1),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.primaryColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مرحباً بك!',
            style: GoogleFonts.cairo(
              color: AppColors.primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سجل دخولك للاستمتاع بجميع المزايا',
            style: GoogleFonts.cairo(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _openAuthScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'تسجيل الدخول / إنشاء حساب',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة المستخدم
  Widget _buildUserCard() {
    final name =
        _customerInfo?['name'] ?? _customerInfo?['full_name'] ?? 'مستخدم';
    final phone = _customerInfo?['phone'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // صورة المستخدم
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withOpacity(0.1),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primaryColor,
              size: 32,
            ),
          ),

          const SizedBox(width: 12),

          // بيانات المستخدم
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: GoogleFonts.cairo(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // أيقونة التعديل
          InkWell(
            onTap: _showEditProfileDialog,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة القائمة
  Widget _buildMenuCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
        children: [
          // متابعة الطلبات (فقط للمسجلين)
          if (AuthService.isLoggedIn) ...[
            MyMenuItem(
              icon: Icons.receipt_long_rounded,
              title: 'متابعة الطلبات',
              iconColor: AppColors.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrdersScreen(),
                  ),
                );
              },
            ),
            const CustomDivider(),
          ],

          // الموقع
          MyMenuItem(
            icon: Icons.map_rounded,
            title: 'الموقع',
            iconColor: AppColors.primaryColor,
            onTap: () {
              if (!AuthService.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'يجب تسجيل الدخول أولاً',
                      style: GoogleFonts.cairo(),
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              _showLocationsBottomSheet();
            },
          ),

          const CustomDivider(),

          // الاشعارات
          MyMenuItem(
            icon: Icons.notifications_rounded,
            title: 'الاشعارات',
            iconColor: AppColors.primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),

          // تسجيل الخروج (فقط للمسجلين)
          if (AuthService.isLoggedIn) ...[
            const CustomDivider(),
            MyMenuItem(
              icon: Icons.logout_rounded,
              title: 'تسجيل الخروج',
              iconColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),
              onTap: _handleLogout,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// عنصر القائمة
// ═══════════════════════════════════════════════════════════════════════════

class MyMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color? backgroundColor;
  final VoidCallback onTap;

  const MyMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor ?? iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// فاصل مخصص
// ═══════════════════════════════════════════════════════════════════════════

class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 1, color: Colors.grey[200]),
    );
  }
}
