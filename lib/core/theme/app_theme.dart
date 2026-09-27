import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF08756F);
  static const primaryBright = Color(0xFF00A79D);
  static const primaryDark = Color(0xFF063F3C);
  static const accent = Color(0xFF56C9A8);
  static const coral = Color(0xFFFF8A72);
  static const ink = Color(0xFF132B2A);
  static const muted = Color(0xFF607573);
  static const surface = Color(0xFFF7FAF9);
  static const mintSoft = Color(0xFFE1F5EF);
  static const blueSoft = Color(0xFFE7EFFE);
  static const lilacSoft = Color(0xFFF0E9FF);
  static const border = Color(0xFFDCE8E5);
}

abstract final class AppGradients {
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryBright],
  );
}

@immutable
class CareThemeColors extends ThemeExtension<CareThemeColors> {
  const CareThemeColors({
    required this.card,
    required this.border,
    required this.muted,
    required this.softSurface,
  });

  final Color card;
  final Color border;
  final Color muted;
  final Color softSurface;

  @override
  CareThemeColors copyWith({
    Color? card,
    Color? border,
    Color? muted,
    Color? softSurface,
  }) => CareThemeColors(
    card: card ?? this.card,
    border: border ?? this.border,
    muted: muted ?? this.muted,
    softSurface: softSurface ?? this.softSurface,
  );

  @override
  CareThemeColors lerp(CareThemeColors? other, double t) {
    if (other == null) return this;
    return CareThemeColors(
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
    );
  }
}

extension CareThemeContext on BuildContext {
  CareThemeColors get careColors =>
      Theme.of(this).extension<CareThemeColors>()!;
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );

    return _build(
      colorScheme,
      const CareThemeColors(
        card: Colors.white,
        border: AppColors.border,
        muted: AppColors.muted,
        softSurface: Color(0xFFF0F7F5),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      surface: const Color(0xFF0E1B1A),
    );

    return _build(
      colorScheme,
      const CareThemeColors(
        card: Color(0xFF172725),
        border: Color(0xFF304541),
        muted: Color(0xFFA9BCB8),
        softSurface: Color(0xFF203330),
      ),
    );
  }

  static ThemeData _build(ColorScheme colorScheme, CareThemeColors careColors) {
    final isDark = colorScheme.brightness == Brightness.dark;
    const primary = AppColors.primary;
    final foreground = colorScheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [careColors],
      scaffoldBackgroundColor: colorScheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: careColors.card,
      dividerColor: careColors.border,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: careColors.card,
        indicatorColor: isDark
            ? AppColors.primary.withValues(alpha: 0.45)
            : AppColors.mintSoft,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: careColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: careColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: careColors.border),
        ),
      ),
      textTheme: TextTheme(
        displaySmall: TextStyle(
          color: foreground,
          fontSize: 38,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        titleLarge: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(
          color: careColors.muted,
          fontSize: 16,
          height: 1.55,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: careColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
