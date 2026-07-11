import 'package:flutter/material.dart';

/// Shimmer placeholder block used by route skeletons.
class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    this.width,
    this.radius = 10,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF334155)),
      ),
    );
  }
}

/// Market indices grid skeleton (fixed card heights — avoids layout overflow).
class MarketModuleSkeleton extends StatelessWidget {
  const MarketModuleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B1120),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonBlock(height: 28, width: 200),
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
                (_) => const _SkeletonBlock(height: 100),
              ),
            ),
            const SizedBox(height: 20),
            const _SkeletonBlock(height: 80),
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
    return ColoredBox(
      color: const Color(0xFF0B1120),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonBlock(height: 24, width: 160),
            const SizedBox(height: 16),
            ...List.generate(
              6,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SkeletonBlock(height: 44, width: double.infinity),
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
    return ColoredBox(
      color: const Color(0xFF0B1120),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                3,
                (_) => const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: _SkeletonBlock(height: 72),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _SkeletonBlock(height: 200),
            const SizedBox(height: 20),
            ...List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _SkeletonBlock(height: 40),
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
    return ColoredBox(
      color: const Color(0xFF0B1120),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkeletonBlock(height: 28, width: 220),
            const SizedBox(height: 24),
            const _SkeletonBlock(height: 120),
            const SizedBox(height: 16),
            const _SkeletonBlock(height: 120),
            const SizedBox(height: 16),
            const _SkeletonBlock(height: 120),
          ],
        ),
      ),
    );
  }
}
