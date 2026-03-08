import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utls/constants.dart';

/// ويدجت عنوان القسم - مع خيار "عرض المزيد"
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // العنوان
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primaryColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            // زر الإجراء
            if (actionText != null)
              GestureDetector(
                onTap: onActionTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText!,
                        style: GoogleFonts.cairo(
                          color: AppColors.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.primaryColor,
                        size: 12,
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

/// ويدجت شريط العنوان الزجاجي
class GlassyTitleBar extends StatelessWidget {
  final String title;

  const GlassyTitleBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
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
        title,
        style: GoogleFonts.cairo(
          color: AppColors.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
