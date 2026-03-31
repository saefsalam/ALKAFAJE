import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
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
                    BubbleButton(icon: Icons.arrow_back, onTap: () {}),
                    Text(
                      'الحساب',
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

            const SizedBox(height: 20),

            // المحتوى
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 90),
                      child: Column(
                        children: [
                          // بطاقة المستخدم أو تسجيل الدخول
                          AuthService.isLoggedIn
                              ? _buildUserCard()
                              : _buildLoginCard(),

                          const SizedBox(height: 20),

                          // بطاقة القائمة
                          _buildMenuCard(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
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
    final name = _customerInfo?['full_name'] ?? 'مستخدم';
    final phone = _customerInfo?['phone'] ?? '';
    final address = _customerInfo?['address'] ?? 'لم يتم تحديد العنوان';

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
          // أيقونة التعديل
          InkWell(
            onTap: () {
              // TODO: فتح شاشة تعديل الملف الشخصي
            },
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

          const SizedBox(width: 12),

          // بيانات المستخدم
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: GoogleFonts.cairo(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: GoogleFonts.cairo(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

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
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor ?? iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
