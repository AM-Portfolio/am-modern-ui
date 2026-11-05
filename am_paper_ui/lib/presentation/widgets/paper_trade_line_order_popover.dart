import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

import '../../config/paper_chart_trade_ui_config.dart';

class PaperTradeLineOrderResult {
  const PaperTradeLineOrderResult({
    required this.orderType,
    required this.quantity,
    this.targetPrice,
    this.stopLoss,
    this.trailJump,
  });

  final String orderType;
  final String quantity;
  final String? targetPrice;
  final String? stopLoss;
  final String? trailJump;
}

/// Compact type/qty dialog for editing a placed chart trade line.
Future<PaperTradeLineOrderResult?> showPaperTradeLineOrderPopover({
  required BuildContext context,
  required PaperChartTradeUiConfig config,
  required String symbol,
  required String side,
  String? favoriteOrderType,
  String? initialQuantity,
  String title = 'Edit order line',
  String confirmLabel = 'Update',
}) {
  final types = config.enabledOrderTypes;
  if (types.isEmpty) return Future.value(null);

  var orderType = (favoriteOrderType ?? config.resolveDefaultOrderType())
      .toUpperCase();
  if (!types.contains(orderType)) orderType = types.first;

  final qtyCtrl = TextEditingController(
    text: (initialQuantity ?? config.resolveDefaultQuantity()).trim().isEmpty
        ? config.resolveDefaultQuantity()
        : (initialQuantity ?? config.resolveDefaultQuantity()),
  );
  final targetCtrl = TextEditingController();
  final stopCtrl = TextEditingController();
  final trailCtrl = TextEditingController();

  return showDialog<PaperTradeLineOrderResult>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: context.colors.scaffoldBackground,
        title: Text('$side $symbol — $title'),
        content: StatefulBuilder(
          builder: (ctx, setLocal) {
            return SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in types)
                        ChoiceChip(
                          label: Text(t),
                          selected: orderType == t,
                          onSelected: (_) => setLocal(() => orderType = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (orderType == 'SUPER') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target (optional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stopCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stop loss (optional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (orderType == 'TRAIL') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: trailCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Trail jump',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final qty = qtyCtrl.text.trim();
              if (qty.isEmpty) return;
              Navigator.of(ctx).pop(PaperTradeLineOrderResult(
                orderType: orderType,
                quantity: qty,
                targetPrice: targetCtrl.text.trim().isEmpty
                    ? null
                    : targetCtrl.text.trim(),
                stopLoss: stopCtrl.text.trim().isEmpty
                    ? null
                    : stopCtrl.text.trim(),
                trailJump: trailCtrl.text.trim().isEmpty
                    ? null
                    : trailCtrl.text.trim(),
              ));
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
