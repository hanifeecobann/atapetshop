import 'package:flutter/material.dart';

// Sakin turkuaz: göz yormaz, "güven veren" ve "doğal" bir his verir.
const Color kPrimary = Color(0xFF2A9D8F);
const Color kPrimaryDark = Color(0xFF1B6B62);
const Color kTint = Color(0xFFDDF1EE);
const Color kBg = Color(0xFFF5FAF9);
const Color kInk = Color(0xFF16322F);
const Color kMuted = Color(0xFF5E7A76);
const Color kSale = Color(0xFFE76F51); // yalnızca indirim rozetleri ve kalp için

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.light,
  ).copyWith(primary: kPrimary, onPrimary: Colors.white);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kTint,
      height: 68,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
