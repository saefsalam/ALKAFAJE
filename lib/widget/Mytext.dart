import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utls/constants.dart';

class MyText extends StatelessWidget {
  const MyText({super.key, required this.text, this.fontSize = 22});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          AppColors.primaryColor,
          AppColors.primaryColor.withOpacity(0.8),
          AppColors.primaryColor,
        ],
      ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
