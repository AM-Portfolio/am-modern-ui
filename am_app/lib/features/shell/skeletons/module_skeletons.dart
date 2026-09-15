import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Shimmer placeholder block used by route skeletons.
class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    this.width,
    this.radius = 10,
    this.accent,
  });

  final double height;
  final double? width;
  final double radius;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final resolved = skeletonShimmerColors(context, accentColor: accent);
    final borderAccent = (accent ?? context.colors.actionPrimaryBg)
        .withValues(alpha: 0.22);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: resolved.base,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderAccent),
      ),
    );
  }
}

/// Market indices grid skeleton (fixed card heights — avoids layout overflow).
class MarketModuleSkeleton extends StatelessWidget {
  const MarketModuleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.market;
    return ColoredBox(
      color: context.colors.scaffoldBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBlock(height: 28, width: 200, accent: accent),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: List.generate(
                6,
                (_) => _SkeletonBlock(height: 100, accent: accent),
              ),
            ),
            const SizedBox(height: 20),
            _SkeletonBlock(height: 80, accent: accent),
          ],
        ),
      ),
    );
  }
}

class TradeModuleSkeleton extends StatelessWidget {
  const TradeModuleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.trade;
    return ColoredBox(
      color: context.colors.scaffoldBackground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBlock(height: 24, width: 160, accent: accent),
            const SizedBox(height: 16),
            ...List.generate(
              6,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SkeletonBlock(
                  height: 44,
                  width: double.infinity,
                  accent: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PortfolioModuleSkeleton extends StatelessWidget {
  const PortfolioModuleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.portfolio;
    return ColoredBox(
      color: context.colors.scaffoldBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _SkeletonBlock(height: 72, accent: accent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SkeletonBlock(height: 200, accent: accent),
            const SizedBox(height: 20),
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SkeletonBlock(height: 40, accent: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GenericModuleSkeleton extends StatelessWidget {
  const GenericModuleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    return ColoredBox(
      color: context.colors.scaffoldBackground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBlock(height: 28, width: 220, accent: accent),
            const SizedBox(height: 24),
            _SkeletonBlock(height: 120, accent: accent),
            const SizedBox(height: 16),
            _SkeletonBlock(height: 120, accent: accent),
            const SizedBox(height: 16),
            _SkeletonBlock(height: 120, accent: accent),
          ],
        ),
      ),
    );
  }
}
