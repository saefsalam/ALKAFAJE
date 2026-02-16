import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';
import '../widget/custom_search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
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
                        // وظيفة زر الرجوع
                      },
                    ),
                    // النص في الوسط
                    Text(
                      "المنتجات",
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    // مساحة فارغة للتوازن
                    const SizedBox(width: 5),

                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            // شريط البحث الثابت مع زر
            Row(
              children: [
                BubbleButton(
                  icon: Icons.tune_rounded,
                  onTap: () {
                    // وظيفة الفلتر
                  },
                ),
                const SizedBox(width: 5),
                const Expanded(child: CustomSearchBar()),
              ],
            ),
            const SizedBox(height: 5),
            // المحتوى المتحرك
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 90.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العمود الأيمن - العناصر الزوجية (0, 2, 4, ...)
                    Expanded(
                      child: Column(
                        children: List.generate(10, (index) {
                          final actualIndex = index * 2;
                          return _buildCard(actualIndex);
                        }),
                      ),
                    ),
                    const SizedBox(width: 25),
                    // العمود الأيسر - العناصر الفردية (1, 3, 5, ...)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Column(
                          children: List.generate(10, (index) {
                            final actualIndex = index * 2 + 1;
                            return _buildCard(actualIndex);
                          }),
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

  Widget _buildCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الصورة الرئيسية
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Image.asset(
              'assets/img/main.png',
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 140,
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image,
                    size: 50,
                    color: AppColors.primaryColor.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
          // المحتوى
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان الرئيسي
                Text(
                  'تطبيقة دلة',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // النص الفرعي
                Text(
                  'الموديل تركي',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                // السعر
                Text(
                  '10,000',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
