import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {

  static const Color primary = Color(0xFF2F5BB0);
  static const Color darkBlue = Color(0xFF284E98);
  static const Color headerBlue = Color(0xFF223F7C);
  static const Color background = Color(0xFFF3F7FF);
  static const Color cardBg = Colors.white;
  static const Color inputBg = Color(0xFFEEF3FC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cancelRed = Color(0xFFE57373);
  static const Color cancelBg = Color(0xFFFFEBEE);



  /// Amarelo solar: cor das ações principais (CTA). Usa texto escuro por cima.
  static const Color accent = Color(0xFFFFB000);
  static const Color accentSoft = Color(0xFFFFF4D6);
  static const Color onAccent = Color(0xFF0A1F5C);
  /// Tom escuro do amarelo, para ícones e textos sobre fundo claro.
  static const Color accentInk = Color(0xFFB86E00);

  static const Color navy = Color(0xFF1E3A70);
  static const Color skyBlue = Color(0xFF4A75C4);

  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningBg = Color(0xFFFFF8E1);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerBg = Color(0xFFFFEBEE);
  static const Color infoBg = Color(0xFFE3F2FD);

  static const Color border = Color(0xFFDCE6F5);
  static const Color textSubtle = Color(0xFF94A3B8);

  /// Fundo das telas de leitura NFC.
  static const LinearGradient scanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, navy],
  );

  // Raios de borda
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  /// Sombra suave padrão para cartões.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Sombra colorida para cartões de ação (ex.: cartão azul de "Novo check-in").
  static List<BoxShadow> coloredShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  /// Fonte de títulos (arredondada, estilo parque aquático).
  static TextStyle display({
    double size = 24,
    Color? color,
    FontWeight weight = FontWeight.w800,
    double height = 1.15,
  }) =>
      TextStyle(fontFamily: 'Baloo2', fontSize: size, color: color, fontWeight: weight, height: height);

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineSmall: (base.headlineSmall?.copyWith(fontFamily: 'Baloo2', 
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: textDark,
      )),
      titleLarge: (base.titleLarge?.copyWith(fontFamily: 'Baloo2', 
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textDark,
      )),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodySmall: base.bodySmall?.copyWith(color: textMuted),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: textMuted,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final textTheme = _textTheme(
      base.textTheme.apply(fontFamily: 'Nunito', bodyColor: textDark, displayColor: textDark),
    );

    return ThemeData(
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: darkBlue,
        onPrimaryContainer: Colors.white,
        secondary: accent,
        onSecondary: onAccent,
        secondaryContainer: accentSoft,
        onSecondaryContainer: accentInk,
        tertiary: success,
        onTertiary: Colors.white,
        tertiaryContainer: successBg,
        onTertiaryContainer: success,
        surface: cardBg,
        onSurface: textDark,
        onSurfaceVariant: textMuted,
        surfaceContainerHighest: inputBg,
        error: cancelRed,
        onError: Colors.white,
        errorContainer: cancelBg,
        onErrorContainer: cancelRed,
        outline: Color(0xFFCBD5E1),
        outlineVariant: border,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        hintStyle: const TextStyle(color: textSubtle, fontSize: 14),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: const TextStyle(
          color: danger,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger, width: 1.8),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: primary, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primary,
        disabledColor: inputBg,
        showCheckmark: false,
        side: const BorderSide(color: border),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textSubtle;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return inputBg;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return border;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: textMuted,
        selectedColor: primary,
        selectedTileColor: primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: Colors.transparent,
      ),
    );
  }
}
