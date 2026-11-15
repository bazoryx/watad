import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors from the approved design (requirements doc, "الهوية البصرية").
class WColors {
  static const deepGreen = Color(0xFF0E3B32);
  static const mosqueGreen = Color(0xFF1A7A50);
  static const gold = Color(0xFFD4A73C);
  static const goldLight = Color(0xFFE0B85C);
  static const background = Color(0xFFF7F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF10231E);
  static const inkMuted = Color(0xFF4F625D);
  static const line = Color(0xFFEEECE6);
  static const chip = Color(0xFFF0EEE8);
  static const greenTint = Color(0xFFE9F2EE);
  static const goldTint = Color(0xFFFBF5E6);
  static const onDarkMuted = Color(0xFFCFE3DA);
  static const missed = Color(0xFFCFCBC0);
  static const frozen = Color(0xFFA9CBE8);
  static const excused = Color(0xFFC9D3DD);
}

/// [googleFonts] is turned off in tests, which have no network.
ThemeData buildTheme({bool googleFonts = true}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: WColors.mosqueGreen,
      primary: WColors.mosqueGreen,
      secondary: WColors.gold,
      surface: WColors.surface,
    ),
    scaffoldBackgroundColor: WColors.background,
  );
  final text = (googleFonts
          ? GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme)
          : base.textTheme)
      .apply(bodyColor: WColors.ink, displayColor: WColors.ink);
  return base.copyWith(
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: WColors.background,
      foregroundColor: WColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: WColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: WColors.surface,
      indicatorColor: WColors.greenTint,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: WColors.surface,
      indicatorColor: WColors.greenTint,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? WColors.mosqueGreen : WColors.missed),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

/// Width breakpoint from the foldable design: below this, the phone and the
/// iPhone Duo / Galaxy Z Fold8 outer screen (one column, bottom bar); at or
/// above it, the inner screen (side rail, two panes). Chosen by window
/// width, never by device name.
const double kWideBreakpoint = 600;
