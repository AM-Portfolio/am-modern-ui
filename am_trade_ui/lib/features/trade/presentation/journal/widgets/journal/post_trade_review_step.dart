import 'package:flutter/material.dart';
import '../../../../internal/domain/entities/journal_entry.dart';

class PostTradeReviewStep extends StatelessWidget {
  final PostTradeReview? initialReview;
  final PreTradePlan? preTradePlan;
  final String? tradeId;
  final ValueChanged<PostTradeReview> onChanged;

  const PostTradeReviewStep({
    super.key,
    this.initialReview,
    this.preTradePlan,
    this.tradeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Post-Trade Review Step'));
  }
}
