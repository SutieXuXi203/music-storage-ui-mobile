import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
export '../../widgets/bouncing_widget.dart';
export '../../widgets/app_cover_image.dart';

class AppTheme {
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  static const double radiusXs = 4.0;
  static const double radiusSm = 4.0;
  static const double radiusMd = 4.0;
  static const double radiusLg = 4.0;
  static const double radiusSheet = 4.0;
  static const double radiusPill = 4.0;

  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F7F7);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextMuted = Color(0xFF999999);
  static const Color lightAction = Color(0xFF111111);
  static const Color lightActionText = Color(0xFFFFFFFF);
  static const Color lightDanger = Color(0xFFD92D20);

  static const Color darkBg = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF0B0B0B);
  static const Color darkSurfaceElevated = Color(0xFF111111);
  static const Color darkBorder = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkTextMuted = Color(0xFF666666);
  static const Color darkAction = Color(0xFFFFFFFF);
  static const Color darkActionText = Color(0xFF000000);
  static const Color darkDanger = Color(0xFFFF4D4F);

  static const Color background = darkBg;
  static const Color backgroundColor = darkBg;
  static const Color surface = darkSurface;
  static const Color surfaceColor = darkSurface;
  static const Color surfaceLight = darkSurfaceElevated;
  static const Color surfaceCard = darkSurface;
  static const Color border = darkBorder;
  static const Color cardBorder = darkBorder;
  static const Color borderHighlight = Color(0xFF333333);
  static const Color primary = darkAction;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color terminalGreen = Color(0xFF22C55E);
  static const Color pixelGreen = Color(0xFF22C55E);
  static const Color pixelCyan = Color(0xFF00E5FF);
  static const Color pixelAmber = Color(0xFFFFB800);
  static const Color error = darkDanger;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBg(BuildContext context) =>
      isDark(context) ? darkBg : lightBg;

  static Color getSurface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color getSurfaceElevated(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : lightSurfaceElevated;

  static Color getSurfaceCard(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color getSurfaceSubtle(BuildContext context) =>
      isDark(context) ? const Color(0xFF141414) : const Color(0xFFF0F0F0);

  static Color getBorder(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color getText(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color getTextMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  static Color getAction(BuildContext context) =>
      isDark(context) ? darkAction : lightAction;

  static Color getActionText(BuildContext context) =>
      isDark(context) ? darkActionText : lightActionText;

  static Color getDanger(BuildContext context) =>
      isDark(context) ? darkDanger : lightDanger;

  static TextStyle pixelStyle({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double letterSpacing = 0.5,
  }) {
    return monoStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle monoStyle({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0.5,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static Widget techBadge({
    required BuildContext context,
    required String label,
    IconData? icon,
    bool isLive = false,
  }) {
    final borderCol = getBorder(context);
    final textCol = getTextSecondary(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: getSurface(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 10, color: textCol),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: monoStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: textCol,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  static Border subtleBorder(BuildContext context,
      {double width = 1.0, Color? color}) {
    return Border.all(color: color ?? getBorder(context), width: width);
  }

  static Border neoBorder(BuildContext context,
      {double width = 1.0, Color? color}) {
    return subtleBorder(context, width: width, color: color);
  }

  static BoxDecoration cardBox(
    BuildContext context, {
    Color? color,
    BorderRadius? borderRadius,
    double borderWidth = 1.0,
    Color? borderColor,
    bool hasShadow = false,
  }) {
    final dark = isDark(context);
    final bg = color ?? (dark ? darkSurface : lightSurface);
    final bColor = borderColor ?? (dark ? darkBorder : lightBorder);
    final radius = borderRadius ?? BorderRadius.circular(radiusMd);

    return BoxDecoration(
      color: bg,
      borderRadius: radius,
      border: Border.all(color: bColor, width: borderWidth),
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.3 : 0.04),
                offset: const Offset(0, 1.5),
                blurRadius: 4,
              ),
            ]
          : null,
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(seconds: 2),
    bool isError = false,
  }) {
    final isDarkMode = isDark(context);
    final bg = isError
        ? (isDarkMode ? const Color(0xFF241014) : const Color(0xFFFEF2F2))
        : (isDarkMode ? const Color(0xFF181818) : lightSurfaceElevated);
    final textCol = isError
        ? (isDarkMode ? const Color(0xFFFF6B6B) : lightDanger)
        : (isDarkMode ? Colors.white : lightTextPrimary);
    final borderCol = isError
        ? const Color(0xFFFF4D4F).withValues(alpha: 0.6)
        : (isDarkMode ? const Color(0xFF383838) : const Color(0xFFD0D0D0));
    final defaultIcon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    final defaultIconColor = isError
        ? const Color(0xFFFF6B6B)
        : (isDarkMode ? const Color(0xFF4ADE80) : const Color(0xFF16A34A));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: BorderSide(color: borderCol, width: 1.0),
        ),
        content: Row(
          children: [
            Icon(
              icon ?? defaultIcon,
              size: 18,
              color: iconColor ?? defaultIconColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: monoStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textCol,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration pixelBox(
    BuildContext context, {
    Color? color,
    BorderRadius? borderRadius,
    double borderWidth = 1.0,
    Color? borderColor,
    bool hasHardShadow = true,
  }) {
    return cardBox(
      context,
      color: color,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      borderColor: borderColor,
      hasShadow: false,
    );
  }

  static BoxDecoration neoBox(
    BuildContext context, {
    Color? color,
    BorderRadius? borderRadius,
    double borderWidth = 1.0,
    Color? borderColor,
    Offset? shadowOffset,
    Color? shadowColor,
    bool hasShadow = false,
  }) {
    return cardBox(
      context,
      color: color,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      borderColor: borderColor,
      hasShadow: false,
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme =
        GoogleFonts.jetBrainsMonoTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      brightness: Brightness.light,
      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
      scaffoldBackgroundColor: lightBg,
      primaryColor: lightAction,
      colorScheme: const ColorScheme.light(
        primary: lightAction,
        secondary: lightAction,
        surface: lightSurface,
        error: lightDanger,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: lightTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: lightTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: lightTextPrimary,
          fontSize: 14,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: lightTextSecondary,
          fontSize: 13,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: lightTextMuted,
          fontSize: 11,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: lightTextPrimary, size: 20),
        titleTextStyle: GoogleFonts.jetBrainsMono(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: lightBorder, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAction,
          foregroundColor: lightActionText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightBorder, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle:
            GoogleFonts.jetBrainsMono(color: lightTextMuted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: lightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: lightTextPrimary, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: lightBorder, width: 1.0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightSurfaceElevated,
        contentTextStyle: GoogleFonts.jetBrainsMono(
          color: lightTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: const BorderSide(color: lightBorder, width: 1.0),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme =
        GoogleFonts.jetBrainsMonoTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
      scaffoldBackgroundColor: darkBg,
      primaryColor: darkAction,
      colorScheme: const ColorScheme.dark(
        primary: darkAction,
        secondary: darkAction,
        surface: darkSurface,
        error: darkDanger,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: darkTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: darkTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: darkTextPrimary,
          fontSize: 14,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: darkTextSecondary,
          fontSize: 13,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: darkTextMuted,
          fontSize: 11,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkTextPrimary, size: 20),
        titleTextStyle: GoogleFonts.jetBrainsMono(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAction,
          foregroundColor: darkActionText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkBorder, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle:
            GoogleFonts.jetBrainsMono(color: darkTextMuted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: darkTextPrimary, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceElevated,
        contentTextStyle: GoogleFonts.jetBrainsMono(
          color: darkTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
