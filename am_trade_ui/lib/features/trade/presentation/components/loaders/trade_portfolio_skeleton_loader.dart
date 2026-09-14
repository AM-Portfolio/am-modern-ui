import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TradePortfolioSkeletonLoader extends StatelessWidget {
  const TradePortfolioSkeletonLoader({super.key, this.isWebView = true});

  final bool isWebView;

  Color _block(BuildContext context) =>
      skeletonShimmerColors(context, accentColor: ModuleColors.trade).base;

  Color _shimmer(BuildContext context) =>
      skeletonShimmerColors(context, accentColor: ModuleColors.trade).highlight;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.trade;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 150,
                height: 32,
                decoration: BoxDecoration(
                  color: _block(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.15)),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 1200.ms,
                    color: accent.withValues(alpha: 0.22),
                  ),
              const Spacer(),
              Container(
                width: 100,
                height: 32,
                decoration: BoxDecoration(
                  color: _block(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.15)),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 1200.ms,
                    delay: 200.ms,
                    color: _shimmer(context),
                  ),
            ],
          ),
        ),
        Expanded(
          child: isWebView
              ? _buildGridSkeleton(context)
              : _buildListSkeleton(context),
        ),
      ],
    );
  }

  Widget _buildGridSkeleton(BuildContext context) {
    final accent = ModuleColors.trade;
    return LayoutBuilder(
      builder: (context, constraints) {
        late int crossAxisCount;
        late double childAspectRatio;

        if (constraints.maxWidth >= 1400) {
          crossAxisCount = 3;
          childAspectRatio = 1.5;
        } else if (constraints.maxWidth >= 900) {
          crossAxisCount = 2;
          childAspectRatio = 1.4;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.2;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 1.3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: _block(context).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.14)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _block(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _block(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _block(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _block(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _block(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _block(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1200.ms,
                  delay: (100 * index).ms,
                  color: accent.withValues(alpha: 0.2),
                );
          },
        );
      },
    );
  }

  Widget _buildListSkeleton(BuildContext context) {
    final accent = ModuleColors.trade;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _block(context).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.14)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _block(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _block(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _block(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: 1200.ms,
              delay: (100 * index).ms,
              color: accent.withValues(alpha: 0.2),
            );
      },
    );
  }
}
