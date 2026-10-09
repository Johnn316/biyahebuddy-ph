import 'package:flutter/animation.dart';

/// Spacing on a 4dp grid (docs/DESIGN.md §4).
abstract final class AppSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const x2l = 32.0;
  static const x3l = 40.0;
  static const x4l = 56.0;
}

/// Corner radii (docs/DESIGN.md §4).
abstract final class AppRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const full = 999.0;
}

/// Icon sizes (docs/DESIGN.md §6).
abstract final class AppIcon {
  static const sm = 16.0;
  static const md = 22.0;
  static const lg = 28.0;
  static const xl = 40.0;
}

/// Motion tokens (docs/DESIGN.md §7). Loops stop under reduce motion.
abstract final class AppMotion {
  static const press = Duration(milliseconds: 100);
  static const quick = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 260);
  static const emphasized = Duration(milliseconds: 380);
  static const sosBreath = Duration(milliseconds: 2400);
  static const typing = Duration(milliseconds: 1200);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const breathe = Curves.easeInOutSine;
}
