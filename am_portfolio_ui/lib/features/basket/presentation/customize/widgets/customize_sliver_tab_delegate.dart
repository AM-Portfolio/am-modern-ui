import 'package:flutter/material.dart';

class CustomizeSliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  CustomizeSliverTabDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(
          color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);

  @override
  bool shouldRebuild(CustomizeSliverTabDelegate old) => false;
}
