import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ActivHealth "Midnight Coach" design system.
///
/// Single source of truth for color, spacing, radius, and type.
/// Screens must never use raw Colors.* / Color(0x...) literals — pull
/// everything from [Ah] (tokens) or Theme.of(context).
abstract final class Ah {
  // -- Surfaces (dark-first) --
  static const Color bg = Color(0xFF0B0D12);
  static const Color surface1 = Color(0xFF13161F);
  static const Color surface2 = Color(0xFF1B2029);
  static const Color surface3 = Color(0xFF242A36);
  static const Color hairline = Color(0x14FFFFFF); // white @ 8%

  // -- Brand & semantic --
  static const Color accent = Color(0xFFFF5A5F); // Pulse Coral
  static const Color ember = Color(0xFFFF9966); // gradient partner
  static const Color mint = Color(0xFF3DDC97); // success / streak alive
  static const Color info = Color(0xFF6C8EFF);
  static const Color warning = Color(0xFFFFB454);
  static const Color danger = Color(0xFFFF4D4D);

  // -- Text --
  static const Color textPrimary = Color(0xFFF2F5F9);
  static const Color textSecondary = Color(0xFF98A2B3);
  static const Color textTertiary = Color(0xFF5C6678);
  static const Color onAccent = Color(0xFF0B0D12);

  /// The single sanctioned brand gradient: coral -> ember.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [accent, ember],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // -- Spacing (4pt grid) --
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double gutter = 20;

  // -- Radius --
  static const double rSm = 10;
  static const double rMd = 14;
  static const double rLg = 20;
  static const double rXl = 28;

  /// Soft glow used behind accent elements (ring, hero CTA).
  static List<BoxShadow> accentGlow({double opacity = 0.25}) => [
        BoxShadow(
          color: accent.withValues(alpha: opacity),
          blurRadius: 24,
          spreadRadius: 1,
        ),
      ];

  /// Subtle tint container for a habit / semantic color.
  static Color tint(Color c) => c.withValues(alpha: 0.16);
}

/// Builds the app-wide dark theme.
ThemeData buildMidnightTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Ah.accent,
    onPrimary: Ah.onAccent,
    secondary: Ah.mint,
    onSecondary: Ah.onAccent,
    tertiary: Ah.info,
    onTertiary: Ah.onAccent,
    error: Ah.danger,
    onError: Ah.onAccent,
    surface: Ah.bg,
    onSurface: Ah.textPrimary,
    surfaceContainerLowest: Ah.bg,
    surfaceContainerLow: Ah.surface1,
    surfaceContainer: Ah.surface2,
    surfaceContainerHigh: Ah.surface3,
    surfaceContainerHighest: Ah.surface3,
    onSurfaceVariant: Ah.textSecondary,
    outline: Ah.hairline,
    outlineVariant: Ah.hairline,
  );

  final sora = GoogleFonts.sora();
  final inter = GoogleFonts.inter();

  TextStyle soraStyle(double size, FontWeight weight,
          {Color color = Ah.textPrimary, double? height}) =>
      sora.copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  TextStyle interStyle(double size, FontWeight weight,
          {Color color = Ah.textPrimary, double? height}) =>
      inter.copyWith(
          fontSize: size, fontWeight: weight, color: color, height: height);

  final textTheme = TextTheme(
    displayLarge: soraStyle(40, FontWeight.w700),
    displayMedium: soraStyle(34, FontWeight.w700),
    headlineLarge: soraStyle(28, FontWeight.w700),
    headlineMedium: soraStyle(24, FontWeight.w700),
    headlineSmall: soraStyle(20, FontWeight.w600),
    titleLarge: soraStyle(20, FontWeight.w600),
    titleMedium: interStyle(16, FontWeight.w600),
    titleSmall: interStyle(14, FontWeight.w600),
    bodyLarge: interStyle(16, FontWeight.w400, height: 1.5),
    bodyMedium: interStyle(14, FontWeight.w400, height: 1.45),
    bodySmall: interStyle(12, FontWeight.w400, color: Ah.textSecondary),
    labelLarge: interStyle(14, FontWeight.w600),
    labelMedium: interStyle(13, FontWeight.w500, color: Ah.textSecondary),
    labelSmall: interStyle(11, FontWeight.w500, color: Ah.textTertiary),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Ah.bg,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Ah.bg,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: soraStyle(20, FontWeight.w600),
      iconTheme: const IconThemeData(color: Ah.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: Ah.surface1,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Ah.rLg),
        side: const BorderSide(color: Ah.hairline),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Ah.surface1,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Ah.tint(Ah.accent),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => interStyle(
          12,
          FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? Ah.accent
              : Ah.textSecondary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Ah.accent
              : Ah.textSecondary,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Ah.accent,
        foregroundColor: Ah.onAccent,
        textStyle: interStyle(16, FontWeight.w600, color: Ah.onAccent),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ah.rMd),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Ah.textPrimary,
        side: const BorderSide(color: Ah.hairline),
        textStyle: interStyle(16, FontWeight.w600),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ah.rMd),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Ah.accent,
        textStyle: interStyle(14, FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Ah.surface2,
      selectedColor: Ah.tint(Ah.accent),
      checkmarkColor: Ah.accent,
      labelStyle: interStyle(13, FontWeight.w500),
      side: const BorderSide(color: Ah.hairline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Ah.rSm),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Ah.surface2,
      hintStyle: interStyle(14, FontWeight.w400, color: Ah.textTertiary),
      labelStyle: interStyle(14, FontWeight.w500, color: Ah.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Ah.rMd),
        borderSide: const BorderSide(color: Ah.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Ah.rMd),
        borderSide: const BorderSide(color: Ah.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Ah.rMd),
        borderSide: const BorderSide(color: Ah.accent, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Ah.surface2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Ah.rLg),
      ),
      titleTextStyle: soraStyle(20, FontWeight.w600),
      contentTextStyle: interStyle(14, FontWeight.w400, height: 1.45),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Ah.surface2,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Ah.rXl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Ah.surface3,
      contentTextStyle: interStyle(14, FontWeight.w500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Ah.rMd),
        side: const BorderSide(color: Ah.hairline),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Ah.surface2,
        foregroundColor: Ah.textSecondary,
        selectedBackgroundColor: Ah.tint(Ah.accent),
        selectedForegroundColor: Ah.accent,
        side: const BorderSide(color: Ah.hairline),
        textStyle: interStyle(13, FontWeight.w500),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Ah.accent,
      inactiveTrackColor: Ah.surface3,
      thumbColor: Ah.textPrimary,
      overlayColor: Color(0x29FF5A5F),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Ah.onAccent
            : Ah.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Ah.accent : Ah.surface3,
      ),
    ),
    dividerTheme: const DividerThemeData(color: Ah.hairline, thickness: 1),
    listTileTheme: ListTileThemeData(
      iconColor: Ah.textSecondary,
      titleTextStyle: interStyle(15, FontWeight.w500),
      subtitleTextStyle:
          interStyle(13, FontWeight.w400, color: Ah.textSecondary, height: 1.4),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Ah.accent,
      linearTrackColor: Ah.surface3,
      circularTrackColor: Ah.surface3,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: interStyle(14, FontWeight.w500),
    ),
  );
}
