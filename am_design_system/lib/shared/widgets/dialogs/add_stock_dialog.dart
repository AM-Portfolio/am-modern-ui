import 'package:flutter/material.dart';

/// Dialog for adding stocks to portfolio
class AddStockDialog extends StatefulWidget {
  const AddStockDialog({super.key});

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();

  /// Show the add stock dialog
  static Future<bool?> show(BuildContext context) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AddStockDialog(),
  );
}

class _AddStockDialogState extends State<AddStockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) => FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: _buildTitle(),
          content: _buildContent(),
          actions: _buildActions(),
        ),
      ),
    ),
  );

  Widget _buildTitle() => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.add_circle_outline,
          color: Color(0xFF2196F3),
          size: 24,
        ),
      ),
      const SizedBox(width: 16),
      const Text(
        'Add Stock',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _buildContent() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Quick stock addition feature is coming soon!',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 12),
      const Text(
        "You'll be able to add stocks directly from this quick action with features like:",
        style: TextStyle(fontSize: 14),
      ),
      const SizedBox(height: 16),
      _buildFeatureItem(Icons.search, 'Search stocks by symbol or name'),
      _buildFeatureItem(Icons.trending_up, 'Real-time price updates'),
      _buildFeatureItem(Icons.calculate, 'Automatic portfolio calculations'),
      _buildFeatureItem(Icons.notifications, 'Price alerts and notifications'),
    ],
  );

  Widget _buildFeatureItem(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2196F3)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    ),
  );

  List<Widget> _buildActions() => [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: Text(
        'Got it',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ];
}
