import 'package:flutter/material.dart';

// Color scheme

// Backgrounds
const String bg = "010101";
const String bg_container = "0E0E0E";
const String bg_ghost = "191919";

// Text
const String text = "FAFAFA";
const String text_gray = "646464";

// Main colors
const String primmary = "24E124";
const String primmary_hover = "1CB31C";

/// Flutter-ready color tokens.
///
/// Single source of truth. Widgets must use these getters, never raw hex.
abstract final class AppColors {
  static Color get background => const Color(0xFF010101);
  static Color get container => const Color(0xFF0E0E0E);
  static Color get ghost => const Color(0xFF191919);

  static Color get text => const Color(0xFFFAFAFA);
  static Color get textGray => const Color(0xFF646464);

  static Color get primary => const Color(0xFF24E124);
  static Color get primaryHover => const Color(0xFF1CB31C);
}
