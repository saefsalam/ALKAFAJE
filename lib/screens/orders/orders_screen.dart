import 'package:alkafage/widget/Mytext.dart';
import 'package:alkafage/widget/bubble_button.dart';
import 'package:alkafage/screens/orders/pending_screen.dart';
import 'package:alkafage/screens/orders/in_progress_screen.dart';
import 'package:alkafage/screens/orders/completed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../utls/constants.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late AnimationController _bounceController;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _isTransitioning = false;

  final List<String> _tabLabels = const ['قيد الانتظار', 'جارية', 'المكتملة'];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _selectedTabIndex) {
      HapticFeedback.lightImpact();
      _bounceController.forward(from: 0.0);
      setState(() {
        _selectedTabIndex = index;
        _dragOffset = 0.0;
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

  void _onDragStart(DragStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double itemWidth) {
    setState(() {
      _dragOffset += details.delta.dx;
      final maxOffset = itemWidth * (2 - _selectedTabIndex);
      final minOffset = -itemWidth * _selectedTabIndex;
      _dragOffset = _dragOffset.clamp(minOffset, maxOffset);
    });
  }

  void _onDragEnd(DragEndDetails details, double itemWidth) {
    final currentPosition = _selectedTabIndex * itemWidth + _dragOffset;
    final newIndex = (currentPosition / itemWidth).round().clamp(0, 2);

    setState(() {
      _isDragging = false;
      _dragOffset = 0.0;
    });

    if (newIndex != _selectedTabIndex) {
      _onTabTapped(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // صورة الخلفية
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          // الفلتر الأزرق الفاتح
          Positioned.fill(
            child: Container(color: AppColors.primaryColor.withOpacity(0.1)),
          ),
          // المحتوى
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
            child: Column(
              children: [
                // الهيدر الثابت
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // زر الرجوع على اليسار
                        BubbleButton(
                          icon: Icons.arrow_back,
                          onTap: () {
                            Get.back();
                          },
                        ),
                        // النص في الوسط
                        MyText(text: "واجهة الطلبات"),
                        // مساحة فارغة للتوازن
                        BubbleButton(
                          icon: Icons.person,
                          onTap: () {
                            // وظيفة زر الرجوع
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // تاب بار ببلي
                _buildBubbleTabBar(),
                const SizedBox(height: 15),
                // محتوى الصفحات
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleTabBar() {
    final tabBarWidth = MediaQuery.of(context).size.width - 30;
    final itemWidth = tabBarWidth / 3;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // الفقاعة الكبيرة (Background)
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          alignment: Alignment.center,
          height: (_isDragging || _isTransitioning) ? 55 : 50,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                (_isDragging || _isTransitioning) ? 28 : 25,
              ),
              color: Colors.transparent,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final isSelected = _selectedTabIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(index),
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.88,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: Text(
                          _tabLabels[index],
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.primaryColor.withOpacity(0.55),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        // الفقاعة الصغيرة المتحركة
        AnimatedPositioned(
          duration: _isDragging
              ? const Duration(milliseconds: 0)
              : const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          left: _selectedTabIndex * itemWidth + itemWidth * 0.08 + _dragOffset,
          top: _isDragging ? -1 : 3,
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
                    : itemWidth * 0.84;
                final targetHeight = _isDragging ? 53.0 : 44.0;

                return Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.elasticOut,
                    width: targetWidth,
                    height: targetHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        _isDragging ? 28 : 20,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        _isDragging ? 28 : 20,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _isDragging ? 12 : 5,
                          sigmaY: _isDragging ? 12 : 5,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              _isDragging ? 28 : 20,
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
                                child: Text(
                                  _tabLabels[_selectedTabIndex],
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 1,
                                left: 8,
                                right: 8,
                                child: Container(
                                  height: _isDragging ? 14 : 10,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(
                                        _isDragging ? 28 : 20,
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
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const PendingScreen(key: ValueKey(0));
      case 1:
        return const InProgressScreen(key: ValueKey(1));
      case 2:
        return const CompletedScreen(key: ValueKey(2));
      default:
        return const PendingScreen(key: ValueKey(0));
    }
  }
}
