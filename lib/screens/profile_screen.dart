import 'package:alkafage/screens/orders/orders_screen.dart';
import 'package:alkafage/screens/location_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  children: [
                    // بطاقة المستخدم
                    Container(
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
                          Container(
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
                          const SizedBox(width: 12),
                          // بيانات المستخدم
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'احمد علي سالم',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.primaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '07719752467',
                                  style: GoogleFonts.cairo(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'بغداد - المنصور',
                                  style: GoogleFonts.cairo(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
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
                    ),
                    const SizedBox(height: 20),
                    // بطاقة القائمة
                    Container(
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
                          MyMenuItem(
                            icon: Icons.receipt_long_rounded,
                            title: 'متابعة الطلبات',
                            iconColor: AppColors.primaryColor,
                            onTap: () {
                              Get.to(() => const OrdersScreen());
                            },
                          ),
                          const CustomDivider(),
                          MyMenuItem(
                            icon: Icons.map_rounded,
                            title: 'الموقع',
                            iconColor: AppColors.primaryColor,
                            onTap: () {
                              Get.to(
                                () => const LocationScreen(),
                                opaque: false,
                                transition: Transition.fadeIn,
                              );
                            },
                          ),
                          const CustomDivider(),
                          MyMenuItem(
                            icon: Icons.notifications_rounded,
                            title: 'الاشعارات',
                            iconColor: AppColors.primaryColor,
                            onTap: () {},
                          ),
                          const CustomDivider(),
                          MyMenuItem(
                            icon: Icons.language_rounded,
                            title: 'لغة التطبيق',
                            iconColor: AppColors.primaryColor,
                            onTap: () {},
                          ),
                          const CustomDivider(),
                          MyMenuItem(
                            icon: Icons.logout_rounded,
                            title: 'تسجيل الخروج',
                            iconColor: Colors.red,
                            backgroundColor: Colors.red.withOpacity(0.1),
                            onTap: () {},
                          ),
                        ],
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
}

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
