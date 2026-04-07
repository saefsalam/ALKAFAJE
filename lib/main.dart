import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'utls/constants.dart';
import 'widget/custom_bottom_nav.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/product_screen/Product_Screen.dart';
import 'screens/splash_screen.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://ibwawjjqewuikmmnxqgo.supabase.co';

  static const String supabaseAnonKey =
      'sb_publishable_UDC3-1lmARJgip7zcwAYtg_jE2MMral';

  static const String shopId = '550e8400-e29b-41d4-a716-446655440001';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // تهيئة Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Alkafajy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // صورة الخلفية
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          // المحتوى
          IndexedStack(
            index: _selectedIndex,
            children: [
              Navigator(
                onGenerateRoute: (settings) =>
                    GetPageRoute(page: () => const HomeScreen()),
              ),
              Navigator(
                onGenerateRoute: (settings) =>
                    GetPageRoute(page: () => const ProductScreen()),
              ),
              Navigator(
                onGenerateRoute: (settings) =>
                    GetPageRoute(page: () => const CartScreen()),
              ),
              Navigator(
                onGenerateRoute: (settings) =>
                    GetPageRoute(page: () => const FavoritesScreen()),
              ),
              Navigator(
                onGenerateRoute: (settings) =>
                    GetPageRoute(page: () => const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
