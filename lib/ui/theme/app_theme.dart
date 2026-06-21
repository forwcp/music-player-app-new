import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D0D0D),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF667eea),
      secondary: Color(0xFF764ba2),
      surface: Color(0xFF1A1A2E),
      onSurface: Colors.white,
    ),
    fontFamily: 'SF Pro Display',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      activeTrackColor: const Color(0xFF667eea),
      inactiveTrackColor: const Color(0xFF2D2D3F),
      thumbColor: const Color(0xFF667eea),
      overlayColor: const Color(0x22667eea),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A2E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFB0B0C0)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF8888A0)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF667eea)),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2D2D3F),
      thickness: 1,
    ),
  );

  static LinearGradient get primaryGradient => _primaryGradient;

  static BoxDecoration get primaryDecoration => const BoxDecoration(
    gradient: _primaryGradient,
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
}
