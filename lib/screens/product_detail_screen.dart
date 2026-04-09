import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/local_cart_service.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';
import 'favorites_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Item item;

  const ProductDetailScreen({super.key, required this.item});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();

  late final List<String> _images;
  String? _resolvedCategoryName;
  ItemColorOption? _selectedColor;
  ItemSizeOption? _selectedSize;
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  bool _isAddingToCart = false;
  int _quantity = 1;

  // Timer للتبديل التلقائي للصور
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _images = _extractImages();
    _initializeSelections();
    _checkFavoriteStatus();
    _loadCategoryName();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // بدء التبديل التلقائي للصور
  void _startAutoSlide() {
    if (_images.length <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextIndex = (_currentImageIndex + 1) % _images.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  List<String> _extractImages() {
    final images = widget.item.imagePaths
        .map(_resolveImagePath)
        .where((path) => path.isNotEmpty)
        .toList();

    return images.isEmpty ? ['assets/img/main.png'] : images;
  }

  String _resolveImagePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('assets/')) {
      return trimmed;
    }

    return Supabase.instance.client.storage.from('items').getPublicUrl(trimmed);
  }

  String _formatPrice(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  String get _description {
    final description = widget.item.description?.trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }
    return 'لا يوجد وصف مفصل لهذا المنتج حالياً.';
  }

  String? get _categoryName {
    final directName = widget.item.category?.name.trim();
    if (directName != null && directName.isNotEmpty) {
      return directName;
    }

    final resolvedName = _resolvedCategoryName?.trim();
    if (resolvedName != null && resolvedName.isNotEmpty) {
      return resolvedName;
    }

    return null;
  }

  int? get _discountPercent => widget.item.effectiveDiscountPercent;

  double get _totalPrice => widget.item.finalPrice * _quantity;

  ProductOptionSelection get _selection => ProductOptionSelection.fromChoices(
        color: _selectedColor,
        size: _selectedSize,
      );

  void _initializeSelections() {
    final List<ItemColorOption> colors = widget.item.availableColors;
    final List<ItemSizeOption> sizes = widget.item.availableSizes;

    if (colors.isNotEmpty) {
      _selectedColor = colors.first;
    }

    if (sizes.isNotEmpty) {
      _selectedSize = sizes.first;
    }
  }

  Future<void> _loadCategoryName() async {
    if (_categoryName != null || widget.item.categoryId.trim().isEmpty) {
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('name')
          .eq('id', widget.item.categoryId)
          .eq('shop_id', widget.item.shopId)
          .maybeSingle();

      final categoryName = response?['name']?.toString().trim();
      if (!mounted || categoryName == null || categoryName.isEmpty) return;

      setState(() {
        _resolvedCategoryName = categoryName;
      });
    } catch (_) {}
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesService.checkIfFavorite(widget.item.id);
    if (!mounted) return;

    setState(() {
      _isFavorite = isFav;
      _isCheckingFavorite = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isCheckingFavorite) return;
    if (!AuthService.isLoggedIn) {
      _showMessage('لا يمكن وضع المنتج في المفضلة إلا بعد تسجيل الدخول');
      return;
    }

    final isFav = await FavoritesService.toggleFavorite(widget.item.id);
    if (!mounted) return;

    setState(() {
      _isFavorite = isFav;
    });

    _showMessage(
      isFav ? 'تمت الإضافة إلى المفضلة' : 'تمت الإزالة من المفضلة',
    );
  }

  Future<void> _addToCart() async {
    if (_isAddingToCart || !widget.item.isActive) return;

    if (widget.item.hasColorOptions && _selectedColor == null) {
      _showMessage('اختر لون المنتج أولاً');
      return;
    }

    if (widget.item.hasSizeOptions && _selectedSize == null) {
      _showMessage('اختر حجم المنتج أولاً');
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      final bool success;
      final String? failureMessage;
      if (AuthService.isLoggedIn) {
        success = await AuthService.addToCart(
          widget.item.id,
          _quantity,
          selection: _selection,
        );
        failureMessage = AuthService.lastCartOperationError;
      } else {
        success = await LocalCartService.addToCart(
          widget.item.id,
          _quantity,
          selection: _selection,
        );
        failureMessage = LocalCartService.lastCartOperationError;
      }

      if (!success) {
        _showMessage(
          failureMessage ?? 'تعذر إضافة المنتج إلى السلة حالياً',
          backgroundColor: Colors.red.shade600,
        );
        return;
      }

      if (!mounted) return;
      _showMessage('تمت إضافة $_quantity من ${widget.item.title} إلى السلة');
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        AuthService.isLoggedIn
            ? (AuthService.lastCartOperationError ??
                'حدث خطأ أثناء إضافة المنتج إلى السلة')
            : (LocalCartService.lastCartOperationError ??
                'حدث خطأ أثناء إضافة المنتج إلى السلة'),
        backgroundColor: Colors.red.shade600,
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  void _showMessage(
    String message, {
    Color backgroundColor = AppColors.primaryColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // دالة للتحقق إذا كان اللون فاتحاً
  bool _isLightColor(Color color) {
    final double luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  // تنسيق اسم اللون - حد أقصى كلمتين
  String _formatColorName(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length <= 2) {
      return name.trim();
    }
    // إذا أكثر من كلمتين، خذ أول كلمتين فقط
    return '${words[0]} ${words[1]}';
  }

  // حجم خط اسم اللون - يصغر إذا كلمتين
  double _getColorNameFontSize(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return 13; // كلمة واحدة - خط كبير
    }
    return 11; // كلمتين أو أكثر - خط أصغر
  }

  void _changeQuantity(int delta) {
    final nextValue = _quantity + delta;
    if (nextValue < 1) return;

    setState(() {
      _quantity = nextValue;
    });
  }

  void _openImageGallery(int index) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) =>
            ImageGalleryScreen(images: _images, initialIndex: index),
      ),
    );
  }

  Color _tagColor(ItemTag tag) {
    final hex = tag.color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: Stack(
          children: [
            // الخلفية العامة للتطبيق
            Positioned.fill(
              child: Image.asset(
                'assets/img/main.png',
                fit: BoxFit.cover,
              ),
            ),
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 170 + bottomPadding),
              child: Column(
                children: [
                  _buildHeroSection(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        if (_images.length > 1) ...[
                          _buildThumbnailStrip(),
                          const SizedBox(height: 16),
                        ],
                        _buildHeaderCard(),
                        if (!widget.item.isActive) ...[
                          const SizedBox(height: 16),
                          _buildUnavailableBanner(),
                        ],
                        if (widget.item.requiresOptionSelection) ...[
                          const SizedBox(height: 16),
                          _buildOptionsSection(),
                        ],
                        const SizedBox(height: 16),
                        _buildDescriptionSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      if (_isCheckingFavorite)
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.14),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        )
                      else
                        BubbleButton(
                          icon: _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          iconColor:
                              _isFavorite ? Colors.red : AppColors.primaryColor,
                          onTap: _toggleFavorite,
                        ),
                      const Spacer(),
                      BubbleButton(
                        icon: Icons.arrow_forward_rounded,
                        iconColor: AppColors.primaryColor,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              left: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: _buildBottomBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 470,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(38),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(38),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openImageGallery(index),
                  child: _ProductImageView(
                    imagePath: _images[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.24),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.item.hasDiscount && _discountPercent != null)
              Positioned(
                top: 86,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'خصم $_discountPercent%',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final categoryName = _categoryName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (categoryName != null || widget.item.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (categoryName != null)
                  _InfoChip(
                    icon: Icons.category_rounded,
                    text: categoryName,
                  ),
                ...widget.item.tags.map((tag) {
                  final color = _tagColor(tag);
                  return _InfoChip(
                    icon: Icons.local_offer_rounded,
                    text: tag.label,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.10),
                  );
                }),
              ],
            ),
          if (categoryName != null || widget.item.tags.isNotEmpty)
            const SizedBox(height: 12),
          Text(
            widget.item.title,
            style: GoogleFonts.cairo(
              color: const Color(0xFF101828),
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryDark,
                  AppColors.primaryColor,
                  AppColors.primaryLight,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السعر',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatPrice(widget.item.finalPrice)} د.ع',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.item.hasDiscount) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${_formatPrice(widget.item.price)} د.ع',
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.64),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.white.withValues(alpha: 0.64),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFFE11D48),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هذا المنتج غير متوفر حالياً',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFB42318),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'يمكنك تصفحه الآن، لكن الإضافة إلى السلة غير متاحة مؤقتاً.',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF7A271A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == _currentImageIndex;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 76,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primaryColor : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.16)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _ProductImageView(
                  imagePath: _images[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _SectionCard(
      title: 'الوصف',
      icon: Icons.notes_rounded,
      child: Text(
        _description,
        style: GoogleFonts.cairo(
          color: const Color(0xFF475467),
          fontSize: 15,
          height: 1.9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return _SectionCard(
      title: 'خيارات المنتج',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.item.hasColorOptions) ...[
            _buildOptionGroupTitle('اللون'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: widget.item.availableColors.map((color) {
                final bool isSelected = _selectedColor?.id == color.id;
                final Color swatch = _resolveColorSwatch(color.hexCode);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 70,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // دائرة اللون
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: swatch,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.black.withValues(alpha: 0.12),
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: swatch.withValues(alpha: 0.35),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: _isLightColor(swatch)
                                      ? Colors.black87
                                      : Colors.white,
                                  size: 22,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        // اسم اللون - يتكيف مع عدد الكلمات
                        Text(
                          _formatColorName(color.name),
                          style: GoogleFonts.cairo(
                            color: isSelected
                                ? AppColors.primaryColor
                                : const Color(0xFF475467),
                            fontSize: _getColorNameFontSize(color.name),
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (widget.item.hasColorOptions && widget.item.hasSizeOptions)
            const SizedBox(height: 18),
          if (widget.item.hasSizeOptions) ...[
            _buildOptionGroupTitle('الحجم'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.item.availableSizes.map((size) {
                final bool isSelected = _selectedSize?.id == size.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSize = size;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : const Color(0xFFE4E7EC),
                      ),
                    ),
                    child: Text(
                      size.name,
                      style: GoogleFonts.cairo(
                        color:
                            isSelected ? Colors.white : const Color(0xFF344054),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionGroupTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        color: const Color(0xFF101828),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Color _resolveColorSwatch(String? hexCode) {
    final String clean = (hexCode ?? '').replaceAll('#', '').trim();
    if (clean.length == 6) {
      try {
        return Color(int.parse('FF$clean', radix: 16));
      } catch (_) {}
    }
    return const Color(0xFF98A2B3);
  }

  Widget _buildBottomBar() {
    final disabled = !widget.item.isActive;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإجمالي',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF667085),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatPrice(_totalPrice)} د.ع',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF101828),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (_selection.label.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selection.label,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF667085),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5FB),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.add_rounded,
                      onTap: disabled ? null : () => _changeQuantity(1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_quantity',
                        style: GoogleFonts.cairo(
                          color: AppColors.primaryColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: disabled || _quantity == 1
                          ? null
                          : () => _changeQuantity(-1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: disabled || _isAddingToCart ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    disabled ? const Color(0xFFB9BECE) : AppColors.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB9BECE),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isAddingToCart
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          disabled
                              ? Icons.lock_outline_rounded
                              : Icons.shopping_bag_rounded,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          disabled ? 'غير متوفر حالياً' : 'إضافة إلى السلة',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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
}

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
  late final PageController _pageController;
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _ProductImageView(
                        imagePath: widget.images[index],
                        fit: BoxFit.contain,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  children: [
                    _TopCircleButton(
                      icon: Icons.close_rounded,
                      iconColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF101828),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color? backgroundColor;

  const _TopCircleButton({
    required this.icon,
    this.onTap,
    this.iconColor = Colors.white,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color backgroundColor;

  const _InfoChip({
    required this.icon,
    required this.text,
    this.color = AppColors.primaryColor,
    this.backgroundColor = const Color(0xFFF3F4FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primaryColor : const Color(0xFFD0D5DD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ProductImageView extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final Color backgroundColor;

  const _ProductImageView({
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.backgroundColor = const Color(0xFFF4F5FB),
  });

  bool get _isRemote =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isRemote) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: fit,
        placeholder: (_, __) => Container(
          color: backgroundColor,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildErrorState(),
      );
    }

    return Image.asset(
      imagePath,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildErrorState(),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 42,
          color: AppColors.primaryColor.withValues(alpha: 0.30),
        ),
      ),
    );
  }
}
