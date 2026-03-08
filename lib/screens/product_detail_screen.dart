import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final Item item;

  const ProductDetailScreen({super.key, required this.item});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isFavorite = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openImageGallery(int initialIndex) {
    final images = widget.item.images.map((img) => img.imagePath).toList();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder:
            (context) =>
                ImageGalleryScreen(images: images, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // الخلفية
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: AppColors.primaryColor.withOpacity(0.05)),
          ),
          // المحتوى
          Column(
            children: [
              // الهيدر
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BubbleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      Text(
                        "تفاصيل المنتج",
                        style: GoogleFonts.cairo(
                          color: AppColors.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      BubbleButton(
                        icon: Icons.share,
                        onTap: () {
                          // مشاركة المنتج
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // المحتوى القابل للتمرير
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معرض الصور
                      Container(
                        height: 350,
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // عرض الصور
                              PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemCount: widget.item.images.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _openImageGallery(index),
                                    child: Container(
                                      color: Colors.white,
                                      child: Image.asset(
                                        widget.item.images[index].imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            color: AppColors.primaryColor
                                                .withOpacity(0.1),
                                            child: Icon(
                                              Icons.image,
                                              size: 80,
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.3),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // زر المفضلة
                              Positioned(
                                top: 15,
                                right: 15,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isFavorite = !_isFavorite;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:
                                          _isFavorite
                                              ? Colors.red
                                              : AppColors.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              // مؤشر الصور
                              if (widget.item.images.length > 1)
                                Positioned(
                                  bottom: 15,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.item.images.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        width:
                                            _currentImageIndex == index
                                                ? 24
                                                : 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          color:
                                              _currentImageIndex == index
                                                  ? AppColors.primaryColor
                                                  : Colors.white.withOpacity(
                                                    0.6,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // أسهم التنقل
                              if (widget.item.images.length > 1)
                                Positioned(
                                  left: 10,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_currentImageIndex > 0) {
                                          _pageController.previousPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.chevron_left,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.item.images.length > 1)
                                Positioned(
                                  right: 10,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_currentImageIndex <
                                            widget.item.images.length - 1) {
                                          _pageController.nextPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.chevron_right,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // معلومات المنتج
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // العنوان والسعر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.item.title,
                                        style: GoogleFonts.cairo(
                                          color: AppColors.primaryColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        widget.item.category?.name ?? '',
                                        style: GoogleFonts.cairo(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${widget.item.price.toStringAsFixed(0)} د.ع',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            // الوصف
                            Text(
                              'الوصف',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.item.description ??
                                  'منتج عالي الجودة مصنوع من أفضل المواد. يتميز بتصميم أنيق وعصري يناسب جميع الأذواق. مثالي للاستخدام اليومي أو كهدية مميزة.',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor.withOpacity(0.8),
                                fontSize: 16,
                                height: 1.8,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 25),
                            // المواصفات
                            Text(
                              'المواصفات',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildSpecItem(
                              'التصنيف',
                              widget.item.category?.name ?? 'غير محدد',
                            ),
                            _buildSpecItem(
                              'الحالة',
                              widget.item.isActive ? 'متوفر' : 'غير متوفر',
                            ),
                            _buildSpecItem('رقم المنتج', '#${widget.item.id}'),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // زر الإضافة للسلة
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // زر الكمية
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.remove,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          '1',
                          style: GoogleFonts.cairo(
                            color: AppColors.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.add,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  // زر الإضافة للسلة
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // إضافة للسلة
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم إضافة المنتج إلى السلة',
                              style: GoogleFonts.cairo(),
                              textAlign: TextAlign.center,
                            ),
                            backgroundColor: AppColors.primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            'إضافة إلى السلة',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.cairo(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: AppColors.primaryColor.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// شاشة معرض الصور بملء الشاشة
class ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // عرض الصور بملء الشاشة
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.asset(
                    widget.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.white54,
                      );
                    },
                  ),
                ),
              );
            },
          ),
          // زر الإغلاق
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // عداد الصور
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // مؤشر الصور في الأسفل
          if (widget.images.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 30 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color:
                            _currentIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
