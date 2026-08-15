import 'package:flutter/material.dart';

/// Corner-radius tokens — prefer these over `BorderRadius.circular(...)` literals.
class AppRadii {
  AppRadii._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static final BorderRadius button = BorderRadius.circular(sm);
  static final BorderRadius input = BorderRadius.circular(md);
  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius dialog = BorderRadius.circular(xl);
  static final BorderRadius chip = BorderRadius.circular(pill);
}
