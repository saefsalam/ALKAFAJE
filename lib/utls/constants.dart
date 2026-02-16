import 'package:flutter/material.dart';

class AppColors {
  // اللون الأساسي للتطبيق
  static const Color primaryColor = Color(0xFF312F92);

  // درجات من اللون الأساسي
  static const Color primaryLight = Color(0xFF4A47B0);
  static const Color primaryDark = Color(0xFF1F1D5C);

  // ألوان إضافية
  static const Color white = Colors.white;
  static Color whiteTransparent = Colors.white.withOpacity(0.2);
  static Color whiteTransparent30 = Colors.white.withOpacity(0.3);
  static Color whiteTransparent55 = Colors.white.withOpacity(0.55);
  static Color whiteTransparent70 = Colors.white.withOpacity(0.7);
  static Color whiteTransparent80 = Colors.white.withOpacity(0.8);
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 18,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 16,
  );

  static const TextStyle button = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
}
