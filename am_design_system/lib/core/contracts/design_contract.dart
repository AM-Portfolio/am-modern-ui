import 'package:flutter/material.dart';

/// Base interface for all UI Design Contracts.
///
/// A [DesignContract] explicitly defines how a feature module can
/// deviate from the standard design system. It is "Immutable by Default".
///
/// Usage:
/// Any component that allows styling overrides must accept a nullable
/// `DesignContract` object. If null, strict standard styling is applied.
abstract class DesignContract {
  const DesignContract();
}

/// A generic contract for overriding basic container styles.
/// Use this sparingly.
class ContainerStyleOverride extends DesignContract {
  final Color? backgroundColor;
  final Border? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;

  const ContainerStyleOverride({
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.padding,
  });
}

/// A generic contract for overriding text styles.
class TextStyleOverride extends DesignContract {
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? letterSpacing;

  const TextStyleOverride({
    this.color,
    this.fontSize,
    this.fontWeight,
    this.letterSpacing,
  });
}
