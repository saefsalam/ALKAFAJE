import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../utls/constants.dart';
import '../screens/product_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// كارت المنتج الموحد - للاستخدام في كل الواجهات
// ═══════════════════════════════════════════════════════════════════════════

/// كارت المنتج - يعرض معلومات المنتج بشكل موحد
class ProductCard extends StatelessWidget {
  final dynamic item; // يقبل Map<String, dynamic> أو Item model
  final double? width;
  final double imageHeight;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.item,
    this.width,
    this.imageHeight = 140,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // استخراج البيانات
    final String title = item is Map ? (item['title'] ?? '') : item.title;
    final String? description =
        item is Map ? item['description'] : item.description;
    final dynamic price = item is Map ? item['price'] : item.price;

    // استخراج الصورة
    String imagePath = 'assets/img/main.png';
    if (item is Map) {
      if (item['item_images'] != null &&
          (item['item_images'] as List).isNotEmpty) {
        imagePath = item['item_images'][0]['image_path'] ?? imagePath;
      }
    } else {
      if (item.images != null && item.images.isNotEmpty) {
        try {
          final primaryImage = item.images.firstWhere(
            (img) => img.isPrimary,
            orElse: () => item.images.first,
          );
          imagePath = primaryImage.imagePath;
        } catch (e) {
          // في حالة حدوث أي خطأ، استخدم الصورة الافتراضية
          imagePath = 'assets/img/main.png';
        }
      }
    }

    return GestureDetector(
      onTap:
          onTap ??
          () {
            final itemModel = item is Map ? Item.fromJson(item) : item;
            Get.to(() => ProductDetailScreen(item: itemModel));
          },
      child: Container(
        width: width,
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
            // صورة المنتج
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child:
                    imagePath.startsWith('http')
                        ? Image.network(
                          imagePath,
                          height: imageHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: imageHeight,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: AppColors.primaryColor.withOpacity(0.3),
                              ),
                            );
                          },
                        )
                        : Image.asset(
                          imagePath,
                          height: imageHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: imageHeight,
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

            // معلومات المنتج
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اسم المنتج
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // الوصف (إذا موجود)
                  if (description != null && description.isNotEmpty) ...[
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: Colors.grey[600],
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ] else
                    const SizedBox(height: 4),

                  // السعر
                  Text(
                    '${price is double ? price.toStringAsFixed(0) : price} د.ع',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
