import 'package:flutter/material.dart';
import '../utls/constants.dart';

class BubbleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const BubbleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<BubbleButton> createState() => _BubbleButtonState();
}

class _BubbleButtonState extends State<BubbleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              _controller.forward();
            },
            onTapUp: (_) {
              _controller.reverse();
              widget.onTap();
            },
            onTapCancel: () {
              _controller.reverse();
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
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
              child: Icon(
                widget.icon,
                color: widget.iconColor ?? AppColors.primaryColor,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TextBubbleButton - زر فقاعي بنص بدلاً من أيقونة
// ═══════════════════════════════════════════════════════════════════════════

class TextBubbleButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;

  const TextBubbleButton({
    super.key,
    required this.text,
    required this.onTap,
    this.textColor,
    this.fontSize,
    this.fontWeight,
  });

  @override
  State<TextBubbleButton> createState() => _TextBubbleButtonState();
}

class _TextBubbleButtonState extends State<TextBubbleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              _controller.forward();
            },
            onTapUp: (_) {
              _controller.reverse();
              widget.onTap();
            },
            onTapCancel: () {
              _controller.reverse();
            },
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
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
              child: Text(
                widget.text,
                style: TextStyle(
                  color: widget.textColor ?? AppColors.primaryColor,
                  fontSize: widget.fontSize ?? 14,
                  fontWeight: widget.fontWeight ?? FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
