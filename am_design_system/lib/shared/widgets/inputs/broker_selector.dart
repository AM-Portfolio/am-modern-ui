import 'package:flutter/material.dart';
import '../../models/import_data/import_data_models.dart';

/// Widget for selecting broker types
class BrokerSelector extends StatelessWidget {
  const BrokerSelector({
    required this.selectedBroker,
    required this.onBrokerSelected,
    super.key,
  });
  final BrokerType? selectedBroker;
  final ValueChanged<BrokerType> onBrokerSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Select your broker:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          var crossAxisCount = 2;
          if (screenWidth > 600) {
            crossAxisCount = 3;
          } else if (screenWidth < 400) {
            crossAxisCount = 1;
          }

          final spacing = (screenWidth * 0.02).clamp(8.0, 16.0);
          final itemHeight = (screenHeight * 0.08).clamp(60.0, 100.0);

          final itemsPerRow = crossAxisCount;
          final numberOfRows = (BrokerType.values.length / itemsPerRow).ceil();
          final gridHeight =
              (numberOfRows * itemHeight) + ((numberOfRows - 1) * spacing);

          return SizedBox(
            height: gridHeight.clamp(200.0, screenHeight * 0.4),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: screenWidth > 400 ? 2.2 : 3.0,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemCount: BrokerType.values.length,
              itemBuilder: (context, index) {
                final broker = BrokerType.values[index];
                return _buildBrokerOption(broker);
              },
            ),
          );
        },
      ),
    ],
  );

  Widget _buildBrokerOption(BrokerType broker) {
    final isSelected = selectedBroker == broker;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? broker.color : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? broker.color.withOpacity(0.05) : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onBrokerSelected(broker),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: broker.logoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            broker.logoPath!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildBrokerFallbackIcon(broker),
                          ),
                        )
                      : _buildBrokerFallbackIcon(broker),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    broker.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? broker.color : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: broker.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrokerFallbackIcon(BrokerType broker) => Container(
    decoration: BoxDecoration(
      color: broker.color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(broker.fallbackIcon, size: 18, color: broker.color),
  );
}
