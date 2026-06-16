import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color darkBlue = Color(0xFF2D323A);
  static const Color mediumBlue = Color(0xFF42464C);
  static const Color screenBackground = Color(0xFFEBE4C8);
  static const Color cardBackground = Color(0xFFF1ECD9);
  static const Color lightGray = Color(0xFFD9D9D9);
  static const Color gray = Color(0xFFBFBFBF);
  static const Color wight = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF7F7F7F);
  static const Color olive = Color(0xFFCCC3A0);
  static const Color red = Color(0xFFD93535);
  static const Color yellow = Color(0xFFE3BE2A);
  static const Color green = Color(0xFF6AD45C);
  static const Color accentBrown = Color(0xFFA49B78);
  static const Color darkBrown = Color(0xFFB8AF8D);
}

class AppSizes {
  static const double title = 40;
  static const double header = 26;
  static const double subHeader = 22;
  static const double body = 16;
  static const double search = 14;
  static const double caption = 12;
}

class AppWeight {
  static const FontWeight lightFontWeight = FontWeight.w300;
  static const FontWeight normalFontWeight = FontWeight.w400;
  static const FontWeight extraLightFontWeight = FontWeight.w200;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.screenBackground,
      textTheme: GoogleFonts.astaSansTextTheme().copyWith(
        displayLarge: const TextStyle(fontSize: AppSizes.title, fontWeight: FontWeight.normal, color: AppColors.darkBlue),
        titleLarge: const TextStyle(fontSize: AppSizes.header, fontWeight: FontWeight.normal, color: AppColors.darkBlue),
        bodyLarge: const TextStyle(fontSize: AppSizes.body, fontWeight: FontWeight.normal, color: AppColors.darkBlue),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.darkBlue),
        labelSmall: const TextStyle(fontSize: AppSizes.caption, fontWeight: FontWeight.w300, color: AppColors.darkGray),
      ),
    );
  }
}