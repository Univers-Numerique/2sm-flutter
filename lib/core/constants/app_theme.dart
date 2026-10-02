import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette derived from the 2SM logo (assets/branding/logo.png): a vivid
/// green (the runner/ball mark) paired with a deep navy (the "SM"
/// wordmark).
class AppColors {
  static const Color primary = Color(0xFF16A34A);
  static const Color primaryDark = Color(0xFF0D6B32);
  static const Color primaryLight = Color(0xFF4CC96A);

  static const Color secondary = Color(0xFF0B2540);
  static const Color secondaryLight = Color(0xFF16324F);
  static const Color secondaryDark = Color(0xFF05142A);

  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7EAEE);

  static const Color textPrimary = Color(0xFF0B2540);
  static const Color textSecondary = Color(0xFF5B6B7C);
  static const Color textTertiary = Color(0xFF95A1AD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF22A559);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE53E4D);
  static const Color info = Color(0xFF2E90FA);

  static const Color matchWin = Color(0xFF22A559);
  static const Color matchDraw = Color(0xFFF59E0B);
  static const Color matchLoss = Color(0xFFE53E4D);
  static const Color matchPending = Color(0xFF9AA6B2);
  static const Color matchLive = Color(0xFFE53E4D);

  /// Soft, brand-tinted shadow — used in place of plain black shadows for a
  /// less "Material default" and more contemporary sense of depth.
  static Color shadow = secondary.withAlpha(20);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [secondaryDark, secondary, Color(0xFF0F3D2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Type system: Manrope (extra-bold, tight tracking) for anything that
/// needs presence — display/headline/title — paired with Inter for body
/// and label text, where plain legibility at small sizes matters more than
/// character. This is the "two-font, high size/weight contrast" pattern
/// common to modern sport/consumer apps, replacing the previous flat
/// single-weight Poppins scale.
TextTheme _buildTextTheme(Color primaryText, Color secondaryText, Color tertiaryText) {
  final display = GoogleFonts.manropeTextTheme();
  final body = GoogleFonts.interTextTheme();

  return TextTheme(
    displayLarge: display.displayLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      height: 1.08,
      color: primaryText,
    ),
    displayMedium: display.displayMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      height: 1.1,
      color: primaryText,
    ),
    displaySmall: display.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.15,
      color: primaryText,
    ),
    headlineLarge: display.headlineLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1.18,
      color: primaryText,
    ),
    headlineMedium: display.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.2,
      color: primaryText,
    ),
    headlineSmall: display.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.22,
      color: primaryText,
    ),
    titleLarge: display.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: primaryText,
    ),
    titleMedium: display.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: primaryText,
    ),
    titleSmall: display.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: primaryText,
    ),
    bodyLarge: body.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: primaryText,
    ),
    bodyMedium: body.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: secondaryText,
    ),
    bodySmall: body.bodySmall?.copyWith(
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: tertiaryText,
    ),
    labelLarge: body.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: primaryText,
    ),
    labelMedium: body.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: secondaryText,
    ),
    labelSmall: body.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: tertiaryText,
    ),
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary, AppColors.textTertiary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textOnPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontSize: 21),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        color: AppColors.card,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withAlpha(110),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, color: AppColors.textOnPrimary),
        ).copyWith(
          shadowColor: const WidgetStatePropertyAll(Color(0x552FA35A)),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(Colors.white.withAlpha(25)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, color: AppColors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 14, color: AppColors.primary),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceVariant,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: AppColors.textOnPrimary),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withAlpha(30),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.textTertiary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: AppColors.textTertiary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withAlpha(30),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primary : AppColors.textTertiary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textTertiary,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(Colors.white, const Color(0xFFB8C4D0), const Color(0xFF7E8CA0));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.secondaryDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.primary,
        surface: AppColors.secondary,
        error: AppColors.error,
        onPrimary: AppColors.secondaryDark,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textOnPrimary,
        onError: AppColors.textOnPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.secondaryDark,
        foregroundColor: AppColors.textOnPrimary,
        titleTextStyle: textTheme.headlineSmall?.copyWith(fontSize: 21),
      ),
      cardTheme: CardThemeData(
        color: AppColors.secondary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.secondaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
