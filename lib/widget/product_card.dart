import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../utls/constants.dart';

/// كارد المنتج - يعرض معلومات المنتج بشكل جذاب
class ProductCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.item,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة المنتج مع زر المفضلة
            Stack(
              children: [
                // الصورة
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                                color: AppColors.primaryColor.withOpacity(0.3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // زر المفضلة
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // نسبة التخفيض
                if (item.hasDiscount && item.discountPercent != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${item.discountPercent}%-',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // التاغات
                if (item.tags.isNotEmpty && !item.hasDiscount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildTagBadge(item.tags.first),
                  ),
                // عدد الصور
                if (item.images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.images.length}',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // معلومات المنتج
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المنتج
                  Text(
                    item.title,
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // التصنيف
                  if (item.category != null)
                    Text(
                      item.category!.name,
                      style: GoogleFonts.cairo(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // السعر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildPriceSection()),
                      // زر إضافة للسلة
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قسم السعر مع دعم التخفيضات
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
              fontSize: 12,
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
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Text(
      '${item.formattedPrice} د.ع',
      style: GoogleFonts.cairo(
        color: AppColors.primaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  /// بناء شارة التاغ
  Widget _buildTagBadge(ItemTag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColorFromHex(tag.color),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _getColorFromHex(tag.color).withOpacity(0.4),
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

  Color _getColorFromHex(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

/// كارد المنتج المصغر - للعرض في القوائم الأفقية
class ProductCardMini extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;

  const ProductCardMini({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          size: 30,
                          color: AppColors.primaryColor.withOpacity(0.3),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // المعلومات
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.formattedPrice} د.ع',
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
