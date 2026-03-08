import 'package:flutter/material.dart';
import 'dart:async';
import '../models/product_model.dart';
import '../utls/constants.dart';

/// ويدجت البانر المتحرك - يعرض إعلانات البانر التي يتحكم بها الأدمن
class BannerSlider extends StatefulWidget {
  final List<BannerAd> banners;
  final double height;
  final Duration autoPlayDuration;
  final bool autoPlay;
  final Function(BannerAd)? onBannerTap;

  const BannerSlider({
    super.key,
    required this.banners,
    this.height = 160,
    this.autoPlayDuration = const Duration(seconds: 4),
    this.autoPlay = true,
    this.onBannerTap,
  });

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92, initialPage: 0);
    if (widget.autoPlay && widget.banners.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayDuration, (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= widget.banners.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return _buildBannerItem(banner, index);
            },
          ),
        ),
        const SizedBox(height: 12),
        // مؤشرات الصفحات
        if (widget.banners.length > 1) _buildPageIndicators(),
      ],
    );
  }

  Widget _buildBannerItem(BannerAd banner, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = (_pageController.page ?? 0) - index;
          value = (1 - (value.abs() * 0.2)).clamp(0.85, 1.0);
        }
        return Center(child: Transform.scale(scale: value, child: child));
      },
      child: GestureDetector(
        onTap: () => widget.onBannerTap?.call(banner),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // صورة البانر
                Image.asset(
                  banner.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 50,
                          color: AppColors.primaryColor.withOpacity(0.3),
                        ),
                      ),
                    );
                  },
                ),
                // تدرج لوني للنص
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.banners.length, (index) {
        final isSelected = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.primaryColor
                    : AppColors.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                    : null,
          ),
        );
      }),
    );
  }
}
