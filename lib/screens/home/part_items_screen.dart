import 'package:alkafage/widget/bubble_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../utls/constants.dart';
import '../../widget/product_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة عرض منتجات البارت - كود بسيط ومباشر
// ═══════════════════════════════════════════════════════════════════════════

class PartItemsScreen extends StatelessWidget {
  final String partName;
  final List<Map<String, dynamic>> items;

  const PartItemsScreen({
    super.key,
    required this.partName,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      // ═══════════════════════════════════════════════════════════════════════
      // المحتوى
      // ═══════════════════════════════════════════════════════════════════════
      body: Stack(
        children: [
          // صورة الخلفية
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          // الفلتر الأزرق الفاتح
          Positioned.fill(
            child: Container(color: AppColors.primaryColor.withOpacity(0.1)),
          ),
          // المحتوى
          items.isEmpty
              ? Center(
                child: Text(
                  'لا توجد منتجات',
                  style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                ),
              )
              : Padding(
                padding: const EdgeInsets.only(
                  left: 15.0,
                  right: 15.0,
                  top: 5.0,
                ),
                child: Column(
                  children: [
                    // الهيدر الثابت
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // زر الرجوع على اليسار
                            BubbleButton(
                              icon: Icons.arrow_back,
                              onTap: () {
                                Get.back();
                              },
                            ),
                            // النص في الوسط
                            Text(
                              partName,
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            // مساحة فارغة للتوازن (شفاف)
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Grid من المنتجات
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.65,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return ProductCard(item: items[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
