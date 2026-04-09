import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'screens/cart_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/product_screen/Product_Screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'utls/constants.dart';
import 'widget/custom_bottom_nav.dart';

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
  static const Duration _tabTransitionDuration = Duration(milliseconds: 420);
  static const Curve _tabTransitionCurve = Cubic(0.22, 1, 0.36, 1);

  int _selectedIndex = 0;
  int? _previousIndex;
  Timer? _transitionCleanupTimer;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<Widget Function()> _tabBuilders = [
    () => const HomeScreen(),
    () => const ProductScreen(),
    () => const CartScreen(),
    () => const FavoritesScreen(),
    () => const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    _transitionCleanupTimer?.cancel();

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });

    _transitionCleanupTimer = Timer(_tabTransitionDuration, () {
      if (!mounted) return;
      setState(() {
        _previousIndex = null;
      });
    });
  }

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => GetPageRoute(
        settings: settings,
        page: _tabBuilders[index],
        transition: Transition.noTransition,
      ),
    );
  }

  Widget _buildAnimatedTab(int index) {
    final isSelected = index == _selectedIndex;
    final isPrevious = index == _previousIndex;
    final shouldShow = isSelected || isPrevious;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isSelected,
        child: TickerMode(
          enabled: shouldShow,
          child: Offstage(
            offstage: !shouldShow,
            child: AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: _tabTransitionDuration,
              curve: _tabTransitionCurve,
              child: AnimatedSlide(
                offset: isSelected ? Offset.zero : const Offset(0, 0.02),
                duration: _tabTransitionDuration,
                curve: _tabTransitionCurve,
                child: AnimatedScale(
                  scale: isSelected ? 1 : 0.985,
                  duration: _tabTransitionDuration,
                  curve: _tabTransitionCurve,
                  alignment: Alignment.topCenter,
                  child: _buildTabNavigator(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transitionCleanupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          ...List.generate(_tabBuilders.length, _buildAnimatedTab),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
