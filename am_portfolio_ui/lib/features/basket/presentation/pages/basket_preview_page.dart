
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/basket_provider.dart';
import '../widgets/basket_hero_card.dart';
import '../widgets/basket_composition_list.dart';

class BasketPreviewPage extends ConsumerWidget {
  final String basketId;

  const BasketPreviewPage({
    Key? key,
    required this.basketId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basketAsync = ref.watch(basketNotifierProvider(basketId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Basket Preview',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A1128),
              const Color(0xFF001F54),
              Colors.blueGrey.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: basketAsync.when(
            data: (basket) => Column(
              children: [
                // Hero Card (slides in from top)
                TweenAnimationBuilder<Offset>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (context, offset, child) {
                    return Transform.translate(
                      offset: Offset(0, offset.dy * 100),
                      child: child,
                    );
                  },
                  child: BasketHeroCard(
                    etfName: basket.etfName,
                    matchScore: basket.matchScore,
                    missingStockCount: basket.missingStockCount,
                  ),
                ),

                // Composition List
                Expanded(
                  child: BasketCompositionList(
                    items: basket.items,
                  ),
                ),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load basket details',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
