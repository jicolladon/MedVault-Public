import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const EdgeInsets pagePadding = EdgeInsets.all(lg);

  static const double radiusMd = 12;
  static const double radiusLg = 16;
}
