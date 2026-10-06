import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Bảng màu tối giản Đen & Trắng phong cách Terminal
  static const Color background = Color(0xFF000000); // Đen tuyền
  static const Color surface = Color(0xFF0C0C0C);    // Đen surface
  static const Color surfaceLight = Color(0xFF161616); // Đen viền
  static const Color border = Color(0xFF282828);     // Viền terminal mảnh
  static const Color borderHighlight = Color(0xFFFFFFFF);

  // Text colors
  static const Color primary = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF); // Trắng
  static const Color textSecondary = Color(0xFF888888); // Xám bạc
  static const Color textMuted = Color(0xFF555555);

  // Terminal Highlights
  static const Color terminalGreen = Color(0xFF00FF66); // Xanh lá phosphor terminal
  static const Color error = Color(0xFFFF4444);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: textPrimary,
      colorScheme: const ColorScheme.dark(
        primary: textPrimary,
        secondary: terminalGreen,
        surface: surface,
        error: error,
      ),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      // Sử dụng font monospace JetBrains Mono chuẩn phong cách terminal
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.0,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          shape: WidgetStateProperty.all(const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          shape: WidgetStateProperty.all(const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Bỏ bo tròn hoàn toàn
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: background,
          elevation: 0,
          splashFactory: NoSplash.splashFactory,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Vuông vức chuẩn terminal
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          splashFactory: NoSplash.splashFactory,
          side: const BorderSide(color: borderHighlight, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textMuted, fontSize: 13, fontFamily: 'monospace'),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF3A3A3A), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF3A3A3A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: terminalGreen, width: 1.2),
        ),
      ),
    );
  }
}
