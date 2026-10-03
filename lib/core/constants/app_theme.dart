import 'package:flutter/material.dart';

import 'brand_tokens.dart';

/// Couleurs de l'application, issues de la charte 2SM commune au site
/// (2sm-laravel/resources/brand/tokens.json → brand_tokens.dart).
class AppColors {
  static const Color primary = BrandTokens.vert600;
  static const Color primaryDark = BrandTokens.vert700;
  static const Color primaryLight = BrandTokens.vert500;
  static const Color accent = BrandTokens.vert300;

  static const Color secondary = BrandTokens.marine900;
  static const Color secondaryLight = BrandTokens.marine800;
  static const Color secondaryDark = BrandTokens.marine950;

  static const Color background = BrandTokens.fond;
  static const Color surface = BrandTokens.surface;
  static const Color surfaceVariant = Color(0xFFECEFF5);
  static const Color card = BrandTokens.surface;
  static const Color border = BrandTokens.ligne;

  static const Color textPrimary = BrandTokens.encre;
  static const Color textSecondary = BrandTokens.texte;
  static const Color textTertiary = BrandTokens.attenue;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color success = BrandTokens.victoire;
  static const Color warning = BrandTokens.nul;
  static const Color error = BrandTokens.defaite;
  static const Color info = BrandTokens.info;

  static const Color matchWin = BrandTokens.victoire;
  static const Color matchDraw = BrandTokens.nul;
  static const Color matchLoss = BrandTokens.defaite;
  static const Color matchPending = Color(0xFF9AA6B2);
  static const Color matchLive = BrandTokens.direct;

  /// Ombre douce teintée marine (comme sur le site).
  static Color shadow = secondary.withAlpha(22);

  /// Dégradé principal (boutons, éléments actifs) — identique au site.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [BrandTokens.vert500, BrandTokens.vert700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé sombre (en-têtes, tableau de score) — identique au site.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [BrandTokens.marine950, BrandTokens.marine800],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Styles hors thème : chiffres « tableau d'affichage » (scores, chronomètre, statistiques).
class AppTextStyles {
  static const TextStyle score = TextStyle(
    fontFamily: BrandTokens.fontChiffres,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.0,
  );

  static const TextStyle stat = TextStyle(
    fontFamily: BrandTokens.fontChiffres,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.05,
  );
}

/// Titres en Sora (gras, lettres resserrées), texte en Plus Jakarta Sans — comme sur le site.
TextTheme _buildTextTheme(Color primaryText, Color secondaryText, Color tertiaryText) {
  // Polices intégrées (assets/fonts) : Sora pour les titres, Plus Jakarta Sans pour le texte.
  final display = ThemeData.light().textTheme.apply(fontFamily: BrandTokens.fontTitres);
  final body = ThemeData.light().textTheme.apply(fontFamily: BrandTokens.fontTexte);

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
          borderRadius: BorderRadius.circular(BrandTokens.rayonCarte),
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
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, color: AppColors.textOnPrimary),
        ).copyWith(
          shadowColor: const WidgetStatePropertyAll(Color(0x5516A34A)),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(Colors.white.withAlpha(25)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withAlpha(100), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, color: AppColors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: const StadiumBorder(),
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
          borderRadius: BorderRadius.circular(BrandTokens.rayonChamp),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BrandTokens.rayonChamp),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BrandTokens.rayonChamp),
          borderSide: BorderSide(color: AppColors.primary.withAlpha(140), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BrandTokens.rayonChamp),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BrandTokens.rayonChamp),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
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
        shape: const StadiumBorder(),
        extendedTextStyle: const TextStyle(fontFamily: BrandTokens.fontTitres, fontWeight: FontWeight.w700),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withAlpha(30),
        indicatorShape: const StadiumBorder(),
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
        indicatorShape: const StadiumBorder(),
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
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
