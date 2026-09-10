import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../paper_oms_cubit.dart';
import 'paper_order_ticket.dart';

/// Compact Buy/Sell ticket as a half-height bottom sheet (narrow / mobile).
Future<void> showPaperOrderTicketSheet({
  required BuildContext context,
  required String symbol,
  required String side,
  required ValueChanged<String> onSymbolChanged,
  required ValueChanged<String> onSideChanged,
  VoidCallback? onOrderPlaced,
  VoidCallback? onOpenFundamentalAnalysis,
}) {
  final colors = context.colors;
  // Modal routes sit above the desk tree — re-provide the same cubit.
  final cubit = context.read<PaperOmsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: colors.scaffoldBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height;
      return BlocProvider<PaperOmsCubit>.value(
        value: cubit,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SizedBox(
            // Half page; user can scroll inside the compact ticket.
            height: height * 0.52,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: PaperOrderTicket(
                    symbol: symbol,
                    side: side,
                    compact: true,
                    floating: false,
                    onSymbolChanged: onSymbolChanged,
                    onSideChanged: onSideChanged,
                    onCloseFloat: () => Navigator.of(sheetContext).pop(),
                    onOrderPlaced: () {
                      onOrderPlaced?.call();
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    onOpenFundamentalAnalysis:
                        onOpenFundamentalAnalysis == null
                            ? null
                            : () {
                                Navigator.of(sheetContext).pop();
                                onOpenFundamentalAnalysis();
                              },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
