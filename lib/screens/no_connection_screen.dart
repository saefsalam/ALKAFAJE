import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';
import '../main.dart';
import 'home/home_controller.dart';

class NoConnectionScreen extends StatelessWidget {
  const NoConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Scaffold(
      body: Stack(
        children: [
          // صورة الخلفية
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          // المحتوى
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة عدم الاتصال
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 70,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // عنوان
                  Text(
                    'لا يوجد اتصال',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // نص بسيط
                  Text(
                    'تحقق من الإنترنت',
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.primaryColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // زر إعادة المحاولة باستخدام BubbleButton
                  Obx(() => homeController.isLoading.value
                      ? SizedBox(
                          width: 70,
                          height: 70,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.25),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryColor),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: BubbleButton(
                                icon: Icons.refresh_rounded,
                                onTap: () async {
                                  await homeController.loadData();
                                  if (!homeController.hasError.value) {
                                    // الذهاب للشاشة الرئيسية بعد نجاح التحميل
                                    Get.off(() => const MainScreen(),
                                        transition: Transition.fadeIn);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'إعادة المحاولة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
