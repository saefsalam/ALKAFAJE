import 'package:flutter/material.dart';
import '../utls/constants.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool readOnly;
  final String hintText;
  final bool showClearButton;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.onClear,
    this.readOnly = false,
    this.hintText = 'بحث...',
    this.showClearButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.primaryColor.withOpacity(0.6),
              size: 22,
            ),
          ),
          suffixIcon: showClearButton &&
                  controller != null &&
                  controller!.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller?.clear();
                    onClear?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
