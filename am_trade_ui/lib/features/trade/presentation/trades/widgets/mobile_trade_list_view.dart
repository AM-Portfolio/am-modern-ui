import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../models/trade_holding_view_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MobileTradeListView extends StatelessWidget {
  final List<TradeHoldingViewModel> holdings;
  final Function(TradeHoldingViewModel) onSelectTrade;

  const MobileTradeListView({
    required this.holdings,
    required this.onSelectTrade,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.scaffoldBackground,
      child: Column(
        children: [
          _buildMobileHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 16),
                _buildFilterSection(context),
                const SizedBox(height: 24),
                _buildColumnHeaders(context),
                const SizedBox(height: 12),
                ...holdings.map((holding) => _buildMobileTradeItem(context, holding)),
                const SizedBox(height: 80), // Bottom padding for nav bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: context.cardColor,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: context.textPrimary),
            onPressed: () {
               if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Text(
              'Trade Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 24), // Balance back button space
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Container(
       height: 70, // Container for the whole filter block
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16)
       ),
       child: Row(
          children: [
             // Filter Icon
             Container(
                height: 48, width: 48,
                decoration: BoxDecoration(color: context.colors.actionPrimaryBg.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.tune, color: context.colors.actionPrimaryBg),
             ),
             const SizedBox(width: 12),
             Expanded(
                child: ListView(
                   scrollDirection: Axis.horizontal,
                   children: [
                      // "Filters" Label
                      Center(child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text("Filters", style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
                      )),
                      Icon(Icons.bookmark, color: context.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      
                      // Add Button
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         decoration: BoxDecoration(color: context.colors.actionPrimaryBg.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                         child: Row(
                            children: [
                               Icon(Icons.add, size: 16, color: context.colors.actionPrimaryBg),
                               const SizedBox(width: 4),
                               Text("+ Add", style: TextStyle(color: context.colors.actionPrimaryBg, fontWeight: FontWeight.bold))
                            ],
                         ),
                      ),
                       const SizedBox(width: 12),
                      _buildFilterPill(context, "All", true),
                      const SizedBox(width: 12),
                      _buildFilterPill(context, "Profit", false),
                      const SizedBox(width: 12),
                      _buildFilterPill(context, "Loss", false),
                   ],
                )
             )
          ],
       ),
    );
  }

  Widget _buildFilterPill(BuildContext context, String label, bool isSelected) {
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Container(
           decoration: BoxDecoration(
              color: isSelected ? context.colors.actionPrimaryBg : Colors.transparent, 
              borderRadius: BorderRadius.circular(18),
              border: isSelected ? null : Border.all(color: context.colors.border)
           ),
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           child: Text(
              label,
              style: TextStyle(
                 color: isSelected ? context.colors.actionPrimaryFg : context.textSecondary,
                 fontWeight: FontWeight.bold
              ),
           ),
        )
     );
  }

  Widget _buildColumnHeaders(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
           const SizedBox(width: 48), // Space for Radio/SymbolBox
           Expanded(flex: 3, child: Text("SYMBOL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textSecondary))),
           Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textSecondary), textAlign: TextAlign.center)),
           Expanded(flex: 2, child: Text("PRICE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textSecondary), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildMobileTradeItem(BuildContext context, TradeHoldingViewModel holding) {
     String statusText = holding.displayStatus.toUpperCase();
     Color bgPillColor;
     Color textPillColor;
     
     if (statusText == 'WIN') {
        bgPillColor = context.colors.statusSuccess.withOpacity(0.1);
        textPillColor = context.colors.statusSuccess;
     } else if (statusText == 'LOSS') {
        bgPillColor = context.colors.statusError.withOpacity(0.1);
        textPillColor = context.colors.statusError;
     } else if (statusText == 'BREAK_EVEN' || statusText == 'BREAKEVEN') {
        bgPillColor = context.colors.statusWarning.withOpacity(0.1);
        textPillColor = context.colors.statusWarning;
        statusText = "BREAKEVEN"; 
     } else {
        bgPillColor = context.colors.statusNeutral.withOpacity(0.1);
        textPillColor = context.colors.statusNeutral;
     }

     final isDark = Theme.of(context).brightness == Brightness.dark;
     final symbolColors = [
        Colors.blue.withOpacity(0.1),
        Colors.purple.withOpacity(0.1),
        Colors.orange.withOpacity(0.1),
        Colors.teal.withOpacity(0.1)
     ];
     final symbolTextColors = [
        isDark ? Colors.blue.shade300 : Colors.blue.shade700,
        isDark ? Colors.purple.shade300 : Colors.purple.shade700,
        isDark ? Colors.orange.shade300 : Colors.orange.shade800,
        isDark ? Colors.teal.shade300 : Colors.teal.shade700
     ];
     final colorIndex = holding.displaySymbol.length % symbolColors.length;

     return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: context.cardColor,
           borderRadius: BorderRadius.circular(20),
           border: Border.all(color: context.colors.border),
           boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
           ]
        ),
        child: InkWell(
           onTap: () => onSelectTrade(holding),
           child: Row(
              children: [
                 // Radio Circle
                 Icon(Icons.radio_button_unchecked, size: 20, color: context.colors.border),
                 const SizedBox(width: 16),
                 
                 // Symbol Box
                 Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                       color: symbolColors[colorIndex],
                       borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                       holding.displaySymbol.substring(0, 2),
                       style: TextStyle(color: symbolTextColors[colorIndex], fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                 ),
                 const SizedBox(width: 12),
                 
                 // Symbol & Company
                 Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text(holding.displaySymbol, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary)),
                          const SizedBox(height: 2),
                          Text(holding.displayCompanyName, style: TextStyle(color: context.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                       ],
                    ),
                 ),
                 
                 // Status Pill
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                       color: bgPillColor,
                       borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(
                       statusText,
                       style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textPillColor),
                       textAlign: TextAlign.center,
                    ),
                 ),
                 const SizedBox(width: 12),
                 
                 // Price & Qty
                 Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Text(holding.displayCurrentValue, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary)),
                       const SizedBox(height: 2),
                       Text("Qty: ${_formatCompactQty(holding.quantity)}", style: TextStyle(color: context.textSecondary, fontSize: 11)),
                    ],
                 )
              ],
           ),
        ),
     ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
  
  String _formatCompactQty(int? qty) {
     if (qty == null) return "0";
     if (qty >= 1000) return "${(qty / 1000).toStringAsFixed(0)}k";
     return qty.toString();
  }
}
