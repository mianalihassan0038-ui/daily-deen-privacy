import 'package:flutter/material.dart';

/// Daily Deen brand colours.
class AppColors {
  static const emerald = Color(0xFF0B4D35);
  static const emeraldMid = Color(0xFF13704C);
  static const emeraldLight = Color(0xFF1E8F62);
  static const gold = Color(0xFFC9A44C);
  static const goldLight = Color(0xFFF1D98C);
  static const cream = Color(0xFFFAF6EC);
  static const creamDark = Color(0xFFF1EADA);
  static const darkBg = Color(0xFF0D1813);
  static const darkSurface = Color(0xFF16261F);
  static const darkSurfaceHigh = Color(0xFF1E3229);

  static const onTime = Color(0xFF1E8F62);
  static const jamaat = Color(0xFF0B6E4F);
  static const delayed = Color(0xFFE09A2D);
  static const missed = Color(0xFFD9534F);
  static const pending = Color(0xFFE5A23C);

  static const headerGradient = LinearGradient(
    colors: [Color(0xFF0E5A3E), emerald],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

const String arabicFont = 'NotoNaskhArabic';

/// Urdu (Nastaleeq) font used for all Urdu text in the app.
const String urduFont = 'NotoNastaliqUrdu';

/// Indo-Pak Quran font (King Fahd Complex Nastaleeq).
const String indoPakFont = 'KFGQPCNastaleeq';

/// Style for Urdu text such as translations.
TextStyle urduStyle(BuildContext context, {double size = 17, Color? color, FontWeight weight = FontWeight.w400}) {
  return TextStyle(
    fontFamily: urduFont,
    fontSize: size,
    height: 2.0,
    fontWeight: weight,
    color: color ?? Theme.of(context).colorScheme.onSurface,
  );
}

/// Style for the Quran text in the chosen script.
TextStyle quranStyle(BuildContext context, {required bool indoPak, double size = 28, Color? color}) {
  return TextStyle(
    fontFamily: indoPak ? indoPakFont : arabicFont,
    fontSize: indoPak ? size + 2 : size,
    height: indoPak ? 2.3 : 1.9,
    color: color ?? Theme.of(context).colorScheme.onSurface,
  );
}

/// Style for Quranic / Arabic text.
TextStyle arabicStyle(BuildContext context, {double size = 24, Color? color, FontWeight weight = FontWeight.w400}) {
  return TextStyle(
    fontFamily: arabicFont,
    fontSize: size,
    height: 1.9,
    fontWeight: weight,
    color: color ?? Theme.of(context).colorScheme.onSurface,
  );
}

ThemeData buildTheme(Brightness brightness, {bool urdu = false}) {
  final light = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.emerald, brightness: brightness).copyWith(
    primary: light ? AppColors.emerald : const Color(0xFF5FD39A),
    onPrimary: light ? Colors.white : const Color(0xFF00281A),
    secondary: AppColors.gold,
    onSecondary: const Color(0xFF2B2000),
    tertiary: AppColors.gold,
    surface: light ? Colors.white : AppColors.darkSurface,
    surfaceContainerHighest: light ? AppColors.creamDark : AppColors.darkSurfaceHigh,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
    fontFamily: urdu ? urduFont : null,
  );
  return base.copyWith(
    scaffoldBackgroundColor: light ? AppColors.cream : AppColors.darkBg,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: light ? const Color(0x14000000) : const Color(0x1FFFFFFF)),
      ),
      color: light ? Colors.white : AppColors.darkSurface,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: AppColors.emerald,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: light ? Colors.white : AppColors.darkSurface,
      indicatorColor: (light ? AppColors.emerald : const Color(0xFF5FD39A)).withValues(alpha: 0.14),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: light ? AppColors.emerald : Colors.white70),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light ? Colors.white : AppColors.darkSurfaceHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: light ? const Color(0x14000000) : const Color(0x1FFFFFFF), space: 1),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
