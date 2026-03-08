import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../utls/constants.dart';
import '../screens/product_detail_screen.dart';

/// ═══════════════════════════════════════════════════════════
/// قسم المنتجات الأفقي - يعرض مجموعة من المنتجات بشكل أفقي
/// يستخدم لعرض أقسام مثل: التخفيضات، رمضان، المنتجات الجديدة
/// ═══════════════════════════════════════════════════════════
class HorizontalProductSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final List<Item> items;
  final VoidCallback? onViewAllTap;
  final void Function(Item)? onItemTap;
  final bool showViewAll;
  final EdgeInsets padding;

  const HorizontalProductSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    required this.items,
    this.onViewAllTap,
    this.onItemTap,
    this.showViewAll = true,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // العنوان
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _buildHeader(),
          ),
          const SizedBox(height: 12),
          // قائمة المنتجات الأفقية
          SizedBox(
            height: 260,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _HorizontalProductCard(
                    item: items[index],
                    onTap: () {
                      if (onItemTap != null) {
                        onItemTap!(items[index]);
                      } else {
                        Get.to(() => ProductDetailScreen(item: items[index]));
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // العنوان مع الأيقونة
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primaryColor).withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.cairo(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // زر عرض الكل
          if (showViewAll)
            GestureDetector(
              onTap: onViewAllTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'عرض الكل',
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor,
                        fontSize: 12,
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
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// كارد المنتج الأفقي - يعرض المنتج مع دعم التخفيضات والتاغات
/// ═══════════════════════════════════════════════════════════
class _HorizontalProductCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;

  const _HorizontalProductCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الصورة مع التاغات
            Stack(
              children: [
                // الصورة
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      item.primaryImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // التاغات
                if (item.tags.isNotEmpty)
                  Positioned(top: 8, right: 8, child: _buildTags()),
                // نسبة التخفيض
                if (item.hasDiscount && item.discountPercent != null)
                  Positioned(top: 8, left: 8, child: _buildDiscountBadge()),
              ],
            ),
            // المعلومات
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // اسم المنتج
                    Text(
                      item.title,
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // السعر
                    _buildPriceSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    // نعرض أول تاغ فقط
    final tag = item.tags.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColorFromHex(tag.color),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _getColorFromHex(tag.color).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        tag.label,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDiscountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${item.discountPercent}%-',
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    if (item.hasDiscount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // السعر القديم (مشطوب)
          Text(
            '${item.formattedPrice} د.ع',
            style: GoogleFonts.cairo(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.grey[500],
            ),
          ),
          // السعر الجديد
          Text(
            '${item.formattedDiscountPrice} د.ع',
            style: GoogleFonts.cairo(
              color: const Color(0xFFE53935),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Text(
      '${item.formattedPrice} د.ع',
      style: GoogleFonts.cairo(
        color: AppColors.primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Color _getColorFromHex(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

/// ═══════════════════════════════════════════════════════════
/// قسم منتجات رمضان - بتصميم خاص
/// ═══════════════════════════════════════════════════════════
class RamadanSection extends StatelessWidget {
  final List<Item> items;
  final VoidCallback? onViewAllTap;

  const RamadanSection({super.key, required this.items, this.onViewAllTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF6A1B9A).withValues(alpha: 0.1),
            const Color(0xFF4A148C).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(0),
      ),
      child: HorizontalProductSection(
        title: 'عروض رمضان',
        subtitle: 'أجواء رمضانية مميزة',
        icon: Icons.star_outline_rounded,
        iconColor: const Color(0xFF6A1B9A),
        items: items,
        onViewAllTap: onViewAllTap,
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// قسم التخفيضات - بتصميم خاص
/// ═══════════════════════════════════════════════════════════
class DiscountSection extends StatelessWidget {
  final List<Item> items;
  final VoidCallback? onViewAllTap;

  const DiscountSection({super.key, required this.items, this.onViewAllTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFFE53935).withValues(alpha: 0.1),
            const Color(0xFFC62828).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(0),
      ),
      child: HorizontalProductSection(
        title: 'تخفيضات حصرية',
        subtitle: 'وفر أكثر على مشترياتك',
        icon: Icons.local_offer_outlined,
        iconColor: const Color(0xFFE53935),
        items: items,
        onViewAllTap: onViewAllTap,
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// قسم المنتجات الجديدة - بتصميم خاص
/// ═══════════════════════════════════════════════════════════
class NewArrivalsSection extends StatelessWidget {
  final List<Item> items;
  final VoidCallback? onViewAllTap;

  const NewArrivalsSection({super.key, required this.items, this.onViewAllTap});

  @override
  Widget build(BuildContext context) {
    return HorizontalProductSection(
      title: 'وصل حديثاً',
      subtitle: 'أحدث المنتجات',
      icon: Icons.new_releases_outlined,
      iconColor: const Color(0xFF43A047),
      items: items,
      onViewAllTap: onViewAllTap,
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// قسم الأكثر مبيعاً - بتصميم خاص
/// ═══════════════════════════════════════════════════════════
class BestSellersSection extends StatelessWidget {
  final List<Item> items;
  final VoidCallback? onViewAllTap;

  const BestSellersSection({super.key, required this.items, this.onViewAllTap});

  @override
  Widget build(BuildContext context) {
    return HorizontalProductSection(
      title: 'الأكثر مبيعاً',
      subtitle: 'اختيارات عملائنا',
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFFFB8C00),
      items: items,
      onViewAllTap: onViewAllTap,
    );
  }
}
