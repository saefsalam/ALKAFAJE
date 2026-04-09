import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utls/constants.dart';

/// Widget مخصص لعرض أنيميشن اللودنج باستخدام ملف Shark.json المحلي
/// المواصفات الافتراضية: حجم 350، سرعة 3.5x، اللون الأزرق الغامق
class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final Color? animationColor;
  final bool useOriginalColor;
  final double speed;

  const LoadingAnimation({
    super.key,
    this.size = 350, // الحجم الافتراضي 350
    this.backgroundColor,
    this.animationColor,
    this.useOriginalColor = false,
    this.speed = 3.5, // السرعة الافتراضية 3.5x
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.useOriginalColor
        ? null
        : (widget.animationColor ?? AppColors.primaryColor);

    Widget animation = Lottie.asset(
      'assets/animations/Shark.json',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      controller: _controller,
      onLoaded: (composition) {
        _controller
          ..duration = Duration(
            milliseconds:
                (composition.duration.inMilliseconds / widget.speed).round(),
          )
          ..repeat();
      },
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primaryColor,
          ),
        );
      },
    );

    if (color != null) {
      animation = ColorFiltered(
        colorFilter: ColorFilter.mode(
          color.withOpacity(0.85),
          BlendMode.srcATop,
        ),
        child: animation,
      );
    }

    return Container(
      color: widget.backgroundColor,
      child: Center(child: animation),
    );
  }
}

/// Widget لعرض اللودنج بملء الشاشة
class FullScreenLoading extends StatelessWidget {
  final Color? backgroundColor;
  final double size;

  const FullScreenLoading({
    super.key,
    this.backgroundColor,
    this.size = 350,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      body: const Center(
        child: LoadingAnimation(),
      ),
    );
  }
}

/// Widget بسيط للودنج في المنتصف (للاستخدام داخل الصفحات)
class CenteredLoading extends StatelessWidget {
  final double size;

  const CenteredLoading({
    super.key,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimation(size: size),
    );
  }
}

/// Widget للودنج الصغير (للأزرار والعناصر الصغيرة)
class SmallLoading extends StatelessWidget {
  final double size;

  const SmallLoading({
    super.key,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingAnimation(size: size);
  }
}
