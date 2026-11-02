import 'package:flutter/material.dart';

/// Centralized design tokens and color palette matching the high-contrast
/// retail touch POS terminal interface.
class AppColors {
  AppColors._();

  // Terminal Base Colors (Image 2 style)
  static const Color posDarkBg = Color(0xFF101010);
  static const Color posScreenBg = Color(0xFF181818);
  static const Color posPanelDark = Color(0xFF202020);
  static const Color posBorder = Color(0xFF2C2C2C);
  static const Color posTileBorder = Color(0xFF333333);

  // Vibrant Terminal Button Accents (from Image 2)
  static const Color posLimeGreen = Color(0xFF8DC63F);
  static const Color posLimeGreenDark = Color(0xFF6FA12D);
  static const Color posOlive = Color(0xFF6B7E43);
  static const Color posOliveDark = Color(0xFF556534);
  static const Color posTeal = Color(0xFF2E6F7A);
  static const Color posBlue = Color(0xFF1565C0);
  static const Color posDarkBlue = Color(0xFF0D47A1);
  static const Color posOrange = Color(0xFFFFA000);
  static const Color posRed = Color(0xFFD32F2F);
  static const Color posDarkRed = Color(0xFFA81C1C);

  // Keypad & Tender Buttons
  static const Color posKeypadBg = Color(0xFF252525);
  static const Color posKeypadPressed = Color(0xFF353535);
  static const Color posCashChipBg = Color(0xFF1E1E1E);

  // Product Tile Colors
  static const Color posTileBg = Colors.white;
  static const Color posTileText = Color(0xFF1A1A1A);
  static const Color posTileAccent = Color(0xFF6FA12D);

  // Legacy compatibility mappings
  static const Color primary = posLimeGreen;
  static const Color primaryDark = posLimeGreenDark;
  static const Color primaryLight = Color(0xFFA6DE58);
  static const Color primaryContainer = Color(0xFFE8F5D6);
  static const Color onPrimary = Colors.black;

  static const Color accent = posOrange;
  static const Color accentLight = Color(0xFFFFECB3);

  static const Color background = posDarkBg;
  static const Color surface = posPanelDark;
  static const Color surfaceSubtle = Color(0xFF252525);
  static const Color surfaceDark = posDarkBg;
  static const Color panelBackground = posDarkBg;

  static const Color border = posBorder;
  static const Color borderStrong = Color(0xFF444444);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF777777);
  static const Color textOnDark = Colors.white;

  static const Color success = posLimeGreen;
  static const Color successBg = Color(0xFF223812);
  static const Color warning = posOrange;
  static const Color warningBg = Color(0xFF3D2A05);
  static const Color error = posRed;
  static const Color errorBg = Color(0xFF3B1212);
  static const Color info = posBlue;
  static const Color infoBg = Color(0xFF102847);

  static const Color cartTotalBg = Color(0xFF0A0A0A);
  static const Color badgeInStock = posLimeGreen;
  static const Color badgeLowStock = posOrange;
  static const Color badgeOutOfStock = posRed;
}
