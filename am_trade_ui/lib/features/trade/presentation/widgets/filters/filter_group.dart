import 'package:flutter/material.dart';

/// Base class for all filter groups
abstract class FilterGroup {
  String get title;
  IconData get icon;
  bool get hasActiveFilters;
  Widget buildContent(BuildContext context);
  void reset();
}
