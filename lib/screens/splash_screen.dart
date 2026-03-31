import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utls/constants.dart';
import '../main.dart';
import 'home/home_controller.dart';
import 'no_connection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // بدء تحميل البيانات في الخلفية
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final homeController = Get.put(HomeController());

    // تحميل البيانات
    await homeController.loadData();

    // الانتظار ثانية إضافية على الأقل لإظهار الشعار
    await Future.delayed(const Duration(milliseconds: 1500));

    // التحقق من حالة التحميل
    if (homeController.hasError.value) {
      // إذا كان هناك خطأ، اذهب لشاشة عدم الاتصال
      Get.off(() => const NoConnectionScreen(), transition: Transition.fadeIn);
    } else {
      // إذا نجح التحميل، اذهب للشاشة الرئيسية
      Get.off(() => const MainScreen(), transition: Transition.fadeIn);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار التطبيق
              Icon(
                Icons.store,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              // اسم التطبيق
              Text(
                'الكفاجي',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // مؤشر تحميل
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
