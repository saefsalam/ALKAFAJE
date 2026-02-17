import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';
import '../widget/custom_search_bar.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ScrollController _scrollController = ScrollController();

  // بيانات التصنيفات
  final List<Map<String, String>> _categories = const [
    {'label': 'الكل', 'image': ''},
    {'label': 'الصحون', 'image': 'assets/img/main.png'},
    {'label': 'أكواب', 'image': 'assets/img/main.png'},
    {'label': 'الأكرلك', 'image': 'assets/img/main.png'},
    {'label': 'دلال', 'image': 'assets/img/main.png'},
    {'label': 'أطقم', 'image': 'assets/img/main.png'},
  ];

  // بيانات المنتجات
  final List<Map<String, String>> _products = const [
    {
      'title': 'تطبيقة دلة',
      'subtitle': 'الموديل تركي',
      'price': '10,000',
      'image': 'assets/img/main.png',
    },
    {
      'title': 'صحن تقديم',
      'subtitle': 'خزف ياباني',
      'price': '8,500',
      'image': 'assets/img/main.png',
    },
    {
      'title': 'كوب شاي',
      'subtitle': 'زجاج كريستال',
      'price': '5,000',
      'image': 'assets/img/main.png',
    },
    {
      'title': 'طقم فناجين',
      'subtitle': 'بورسلان تركي',
      'price': '25,000',
      'image': 'assets/img/main.png',
    },
    {
      'title': 'صينية تقديم',
      'subtitle': 'ستانلس ستيل',
      'price': '15,000',
      'image': 'assets/img/main.png',
    },
    {
      'title': 'دلة عربية',
      'subtitle': 'نحاس أصلي',
      'price': '30,000',
      'image': 'assets/img/main.png',
    },
    {
      'title': 'كوب قهوة',
      'subtitle': 'سيراميك مطبوع',
      'price': '7,000',
      'image': 'assets/img/main.png',
    },
    {
      'title': 'صحن ديكور',
      'subtitle': 'مزخرف يدوياً',
      'price': '12,000',
      'image': 'assets/img/main.png',
    },
    {
      'title': 'طقم شاي',
      'subtitle': 'صيني فاخر',
      'price': '45,000',
      'image': 'assets/img/main.png',
    },
    {
      'title': 'كاسة عصير',
      'subtitle': 'زجاج شفاف',
      'price': '3,500',
      'image': 'assets/img/main.png',
    },
  ];

  int _selectedCategoryIndex = 0;

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
                    BubbleButton(
                      icon: Icons.person,
                      onTap: () {
                        // وظيفة زر الرجوع
                      },
                    ),
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
            const SizedBox(height: 10),
            // شريط التصنيفات الأفقي
            SizedBox(
              height: 100,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isAll = category['image']!.isEmpty;
                    final isSelected = _selectedCategoryIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        child: isAll
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primaryColor
                                          : AppColors.primaryColor.withOpacity(
                                              0.6,
                                            ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'الكل',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                1.5,
                                              ),
                                              child: ClipOval(
                                                child: Image.asset(
                                                  category['image']!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Icon(
                                                          Icons.image,
                                                          color: Colors.white
                                                              .withOpacity(0.5),
                                                          size: 30,
                                                        );
                                                      },
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                                top: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  stops: const [0.0, 0.5, 1.0],
                                                  colors: [
                                                    AppColors.primaryColor
                                                        .withOpacity(0.95),
                                                    AppColors.primaryColor
                                                        .withOpacity(0.7),
                                                    AppColors.primaryColor
                                                        .withOpacity(0.0),
                                                  ],
                                                ),
                                              ),
                                              child: Text(
                                                category['label']!,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
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
                  },
                ),
              ),
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
                        children: List.generate((_products.length / 2).ceil(), (
                          index,
                        ) {
                          final actualIndex = index * 2;
                          if (actualIndex >= _products.length)
                            return const SizedBox();
                          return _buildCard(actualIndex);
                        }),
                      ),
                    ),
                    const SizedBox(width: 25),
                    // العمود الأيسر - العناصر الفردية (1, 3, 5, ...)
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: Container(
                              height: 35,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
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
                              child: Text(
                                'المنتجات',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          ...List.generate((_products.length / 2).floor(), (
                            index,
                          ) {
                            final actualIndex = index * 2 + 1;
                            if (actualIndex >= _products.length)
                              return const SizedBox();
                            return _buildCard(actualIndex);
                          }),
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

  Widget _buildCard(int index) {
    final product = _products[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الصورة الرئيسية
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Image.asset(
                product['image']!,
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
          ),
          // المحتوى
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // العنوان الرئيسي
                Text(
                  product['title']!,
                  textAlign: TextAlign.center,
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
                  product['subtitle']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                // السعر
                Text(
                  product['price']!,
                  textAlign: TextAlign.center,
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
