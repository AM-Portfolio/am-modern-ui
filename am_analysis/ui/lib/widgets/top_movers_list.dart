import 'package:flutter/material.dart';
import 'package:am_analysis_core/am_analysis_core.dart';

class TopMoversList extends StatelessWidget {
  final List<MoverItem> items;
  final String title;

  const TopMoversList({
    Key? key,
    required this.items,
    this.title = 'Top Movers',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isPositive = item.changePercentage >= 0;
              return ListTile(
                title: Text(item.symbol),
                subtitle: Text(item.name),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${item.changePercentage.toStringAsFixed(2)}% (${item.changeAmount.toStringAsFixed(2)})',
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
