import 'package:flutter/material.dart';

/// Centralized dimensions, breakpoints, and layout constraints.
class AppDimens {
  AppDimens._();

  // Screen Breakpoints
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Cart Pane Width on Split-Screen Tablets
  static const double cartPaneWidth = 380.0;
  static const double cartPaneMaxWidth = 440.0;

  // Spacings
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Border Radii
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(6.0));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(10.0));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(24.0));

  // Product Grid sizing
  static const double productCardMinHeight = 170.0;
}
