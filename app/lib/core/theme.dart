import 'package:flutter/material.dart';

/// Daily Deen brand colours.
class AppColors {
  static const emerald = Color(0xFF0B4D35);
  static const emeraldMid = Color(0xFF13704C);
  static const emeraldLight = Color(0xFF1E8F62);
  static const gold = Color(0xFFC9A44C);
  static const goldLight = Color(0xFFF1D98C);
  // "Sahifa" paper & ink (manuscript look), keeping the green/gold identity.
  static const cream = Color(0xFFF5EEE2); // paper
  static const creamDark = Color(0xFFEADFC8); // deep paper
  static const paperCard = Color(0xFFFBF7EF);
  static const hairline = Color(0xFFDDD1BC);
  static const ink = Color(0xFF251A20); // plum-black text
  static const mutedInk = Color(0xFF6E5F66);
  static const rubric = Color(0xFFB23A2E); // manuscript red, used sparingly (Jumma, headings)
  // Night manuscript (dark mode).
  static const darkBg = Color(0xFF17111A);
  static const darkSurface = Color(0xFF221A24);
  static const darkSurfaceHigh = Color(0xFF2D2330);
  static const nightInk = Color(0xFFF0E7D8);

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

/// Nastaleeq renders the single ligature ﷺ as a huge glyph that runs into the
/// lines above and below; Urdu text spells it out instead.
String urduText(String s) => s.replaceAll('\uFDFA', 'صلی اللہ علیہ وسلم');

/// Scales long-form reading text with the screen width so it reads the same
/// on small and large phones.
double readingScale(BuildContext context) =>
    (MediaQuery.sizeOf(context).width / 400).clamp(0.88, 1.08).toDouble();

/// Style for Urdu text such as translations.
TextStyle urduStyle(BuildContext context, {double size = 17, Color? color, FontWeight weight = FontWeight.w400}) {
  return TextStyle(
    fontFamily: urduFont,
    fontSize: size * readingScale(context),
    height: 2.15,
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
    fontSize: size * readingScale(context),
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
    surface: light ? AppColors.paperCard : AppColors.darkSurface,
    onSurface: light ? AppColors.ink : AppColors.nightInk,
    onSurfaceVariant: light ? AppColors.mutedInk : const Color(0xFFB9A6AE),
    outline: light ? AppColors.mutedInk : const Color(0xFFB9A6AE),
    outlineVariant: light ? AppColors.hairline : const Color(0xFF453543),
    surfaceContainerHighest: light ? AppColors.creamDark : AppColors.darkSurfaceHigh,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
    // Urdu: Latin letters and digits stay in the clean system font (Roboto);
    // Urdu script falls back to Nastaleeq.
    fontFamilyFallback: urdu ? const [urduFont, arabicFont] : const [arabicFont],
  );
  // Nastaleeq is very tall: Urdu text needs extra line height or lines
  // overlap.
  TextStyle? lh(TextStyle? t, double h) => urdu ? t?.copyWith(height: h) : t;
  final tt = base.textTheme;
  return base.copyWith(
    scaffoldBackgroundColor: light ? AppColors.cream : AppColors.darkBg,
    textTheme: tt.copyWith(
      displayLarge: lh(tt.displayLarge, 1.5),
      displayMedium: lh(tt.displayMedium, 1.5),
      displaySmall: lh(tt.displaySmall, 1.6),
      headlineLarge: lh(tt.headlineLarge, 1.6),
      headlineMedium: lh(tt.headlineMedium, 1.7),
      headlineSmall: lh(tt.headlineSmall, 1.7),
      titleLarge: lh(tt.titleLarge?.copyWith(fontWeight: FontWeight.w700), 1.8),
      titleMedium: lh(tt.titleMedium?.copyWith(fontWeight: FontWeight.w700), 1.85),
      titleSmall: lh(tt.titleSmall, 1.9),
      bodyLarge: lh(tt.bodyLarge, 1.95),
      bodyMedium: lh(tt.bodyMedium, 1.95),
      bodySmall: lh(tt.bodySmall, 2.0),
      labelLarge: lh(tt.labelLarge, 1.8),
      labelMedium: lh(tt.labelMedium, 1.9),
      labelSmall: lh(tt.labelSmall, 1.9),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: light ? AppColors.hairline : const Color(0xFF3A2E3A)),
      ),
      color: light ? AppColors.paperCard : AppColors.darkSurface,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: AppColors.emerald,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: light ? AppColors.paperCard : AppColors.darkSurface,
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
      fillColor: light ? AppColors.paperCard : AppColors.darkSurfaceHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: light ? AppColors.hairline : const Color(0xFF3A2E3A), space: 1),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}

/// Serif style for big English numbers / titles (falls back to Nastaleeq in
/// Urdu where the theme font applies).
TextStyle displayStyle({double size = 22, FontWeight weight = FontWeight.w800, Color? color}) =>
    TextStyle(fontSize: size, fontWeight: weight, color: color);
