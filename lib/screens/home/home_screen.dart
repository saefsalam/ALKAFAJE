import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../utls/constants.dart';
import '../../widget/Mytext.dart';
import '../../widget/loading_animation.dart';
import 'part_items_screen.dart';
import '../../widget/product_card.dart';
import '../../widget/bubble_button.dart';
import 'home_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════
// الشاشة الرئيسية - كود بسيط بدون widgets خارجية
// كل شيء مكتوب هنا مباشرة - سهل التعديل والفهم
// ═══════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════

  final homeController = Get.find<HomeController>();
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerAutoPlayTimer;

  // ═══════════════════════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    // البيانات محملة مسبقاً من السبلاش
    // إذا لم تكن محملة، نحملها
    if (homeController.parts.isEmpty && !homeController.isLoading.value) {
      homeController.loadData();
    }
    // بدء التشغيل التلقائي للبانر
    _startBannerAutoPlay();
  }

  /// بدء التشغيل التلقائي للبانر كل 5 ثواني
  void _startBannerAutoPlay() {
    _bannerAutoPlayTimer?.cancel();
    _bannerAutoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients && homeController.banners.isNotEmpty) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage >= homeController.banners.length) {
          nextPage = 0;
        }
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerAutoPlayTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الواجهة الرئيسية
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Obx(() => homeController.isLoading.value
            ? const Center(
                child: LoadingAnimation(size: 200),
              )
            : SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // ═══════════════════════════════════════════════════
                    // الهيدر الثابت - اسم الشركة بتصميم احترافي
                    // ═══════════════════════════════════════════════════
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // الشعار الأيسر
                          Container(
                            width: 45,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.primaryColor.withOpacity(0.5),
                                  AppColors.primaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 15),
                          // اسم الشركة
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MyText(text: 'شركة القرش', fontSize: 28),
                              const SizedBox(height: 2),
                              Text(
                                'AL-QIRSH COMPANY',
                                style: GoogleFonts.poppins(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          // الشعار الأيمن
                          Container(
                            width: 45,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryColor,
                                  AppColors.primaryColor.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ═══════════════════════════════════════════════════
                    // المحتوى المتحرك (Scrollable)
                    // ═══════════════════════════════════════════════════
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: homeController.loadData,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            children: [
                              // ═══════════════════════════════════════════════════
                              // البانرات
                              // ═══════════════════════════════════════════════════
                              if (homeController.banners.isNotEmpty) ...[
                                SizedBox(
                                  height: 160,
                                  child: PageView.builder(
                                    controller: _bannerController,
                                    onPageChanged: (index) {
                                      setState(
                                          () => _currentBannerIndex = index);
                                    },
                                    itemCount: homeController.banners.length,
                                    itemBuilder: (context, index) {
                                      final banner =
                                          homeController.banners[index];
                                      final bannerImagePath =
                                          banner['image_path'] ??
                                              'assets/img/main.png';
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 30,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          image: DecorationImage(
                                            image: bannerImagePath
                                                    .startsWith('http')
                                                ? NetworkImage(bannerImagePath)
                                                : AssetImage(bannerImagePath)
                                                    as ImageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // النقاط
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    homeController.banners.length,
                                    (index) => Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width:
                                          _currentBannerIndex == index ? 20 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _currentBannerIndex == index
                                            ? AppColors.primaryColor
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // ═══════════════════════════════════════════════════
                              // البارتات (الأقسام)
                              // ═══════════════════════════════════════════════════
                              ...homeController.parts.map((part) {
                                final items =
                                    part['items'] as List<Map<String, dynamic>>;
                                if (items.isEmpty)
                                  return const SizedBox.shrink();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // عنوان البارت
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            height: 35,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Colors.white.withOpacity(
                                                    0.25,
                                                  ),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                  offset: const Offset(0, 0),
                                                ),
                                                BoxShadow(
                                                  color:
                                                      Colors.black.withOpacity(
                                                    0.1,
                                                  ),
                                                  blurRadius: 4,
                                                  spreadRadius: -1,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              part['name'] ?? '',
                                              style: GoogleFonts.cairo(
                                                color: AppColors.primaryColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          TextBubbleButton(
                                            text: 'عرض الكل',
                                            onTap: () {
                                              Get.to(
                                                () => PartItemsScreen(
                                                  partName: part['name'] ?? '',
                                                  items: items,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // قائمة المنتجات الأفقية
                                    SizedBox(
                                      height: 240,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                        ),
                                        itemCount: items.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(left: 12),
                                            child: ProductCard(
                                              item: items[index],
                                              width: 150,
                                              imageHeight: 120,
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 20),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
      ),
    );
  }
}
