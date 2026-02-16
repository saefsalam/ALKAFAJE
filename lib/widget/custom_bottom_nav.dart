import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../utls/constants.dart';

class CustomBottomNav extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNav({
    required this.selectedIndex,
    required this.onItemTapped,
    super.key,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(CustomBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _bounceController.forward(from: 0.0);
      _dragOffset = 0.0;
      setState(() {
        _isTransitioning = true;
      });
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() {
            _isTransitioning = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double itemWidth) {
    setState(() {
      _dragOffset += details.delta.dx;
      final maxOffset = itemWidth * (3 - widget.selectedIndex);
      final minOffset = -itemWidth * widget.selectedIndex;
      _dragOffset = _dragOffset.clamp(minOffset, maxOffset);
    });
  }

  void _onDragEnd(DragEndDetails details, double itemWidth) {
    final currentPosition = widget.selectedIndex * itemWidth + _dragOffset;
    final newIndex = (currentPosition / itemWidth).round().clamp(0, 3);

    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });

    if (newIndex != widget.selectedIndex) {
      HapticFeedback.lightImpact();
      widget.onItemTapped(newIndex);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 40) / 4;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // الفقاعة الكبيرة (Background)
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            alignment: Alignment.center,
            height: (_isDragging || _isTransitioning) ? 70 : 65,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  (_isDragging || _isTransitioning) ? 32 : 30,
                ),
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  // ظل خارجي لامع على الحواف
                  BoxShadow(
                    color: Colors.white.withOpacity(0.25),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                  // ظل داكن خفيف لإبراز الشكل
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: -1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // المحتوى الرئيسي
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      final icons = [
                        Icons.house_rounded,
                        Icons.search_rounded,
                        Icons.favorite_rounded,
                        Icons.person_rounded,
                      ];

                      final isSelected = widget.selectedIndex == index;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onItemTapped(index),
                          behavior: HitTestBehavior.translucent,
                          child: Container(
                            height: 65,
                            alignment: Alignment.center,
                            child: AnimatedScale(
                              scale: isSelected ? 1.0 : 0.88,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                icons[index],
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.primaryColor.withOpacity(0.55),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          // الفقاعة الصغيرة المتحركة
          AnimatedPositioned(
            duration: _isDragging
                ? const Duration(milliseconds: 0)
                : const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            left:
                widget.selectedIndex * itemWidth +
                itemWidth * 0.12 +
                _dragOffset,
            top: _isDragging ? -2 : 5,
            child: GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: (details) =>
                  _onDragUpdate(details, itemWidth),
              onHorizontalDragEnd: (details) => _onDragEnd(details, itemWidth),
              child: AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  final elasticCurve = Curves.easeOutBack.transform(
                    _bounceController.value,
                  );

                  final scale = _isDragging
                      ? 1.0
                      : (0.92 + (elasticCurve * 0.08));

                  final targetWidth = _isDragging
                      ? itemWidth * 0.90
                      : itemWidth * 0.76;
                  final targetHeight = _isDragging ? 68.0 : 55.0;

                  return Transform.scale(
                    scale: scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 750),
                      curve: Curves.elasticOut,
                      width: targetWidth,
                      height: targetHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          _isDragging ? 32.5 : 24,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          _isDragging ? 32.5 : 24,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: _isDragging ? 12 : 5,
                            sigmaY: _isDragging ? 12 : 5,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                _isDragging ? 32.5 : 24,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(
                                    _isDragging ? 0.2 : 0.15,
                                  ),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(
                                  _isDragging ? 0.3 : 0.22,
                                ),
                                width: _isDragging ? 1.2 : 0.8,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    [
                                      Icons.house_rounded,
                                      Icons.search_rounded,
                                      Icons.favorite_rounded,
                                      Icons.person_rounded,
                                    ][widget.selectedIndex],
                                    color: AppColors.primaryColor,
                                    size: 28,
                                  ),
                                ),
                                Positioned(
                                  top: 1,
                                  left: 8,
                                  right: 8,
                                  child: Container(
                                    height: _isDragging ? 18 : 12,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(
                                          _isDragging ? 32.5 : 24,
                                        ),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withOpacity(
                                            _isDragging ? 0.35 : 0.3,
                                          ),
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
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
