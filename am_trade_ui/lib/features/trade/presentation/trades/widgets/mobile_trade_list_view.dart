import 'package:flutter/material.dart';
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
      color: const Color(0xFFF8F9FC), // Light grey/purple background
      child: Column(
        children: [
          _buildMobileHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 16),
                _buildFilterSection(),
                const SizedBox(height: 24),
                _buildColumnHeaders(),
                const SizedBox(height: 12),
                ...holdings.map((holding) => _buildMobileTradeItem(holding)),
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
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
               if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Expanded(
            child: Text(
              'Trade Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 24), // Balance back button space
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
       height: 70, // Container for the whole filter block
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)
       ),
       child: Row(
          children: [
             // Filter Icon
             Container(
                height: 48, width: 48,
                decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.tune, color: Color(0xFF7C4DFF)),
             ),
             const SizedBox(width: 12),
             Expanded(
                child: ListView(
                   scrollDirection: Axis.horizontal,
                   children: [
                      // "Filters" Label
                      const Center(child: Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Text("Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                      )),
                      const Icon(Icons.bookmark, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      
                      // Add Button
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(8)),
                         child: Row(
                            children: const [
                               Icon(Icons.add, size: 16, color: Color(0xFF7C4DFF)),
                               SizedBox(width: 4),
                               Text("+ Add", style: TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold))
                            ],
                         ),
                      ),
                       const SizedBox(width: 12),
                      _buildFilterPill("All", true),
                      const SizedBox(width: 12),
                      _buildFilterPill("Profit", false),
                      const SizedBox(width: 12),
                      _buildFilterPill("Loss", false),
                   ],
                )
             )
          ],
       ),
    );
  }

  Widget _buildFilterPill(String label, bool isSelected) {
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Container(
           decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF536DFE) : Colors.transparent, 
              borderRadius: BorderRadius.circular(18),
              border: isSelected ? null : Border.all(color: Colors.grey.shade200)
           ),
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           child: Text(
              label,
              style: TextStyle(
                 color: isSelected ? Colors.white : Colors.grey.shade600,
                 fontWeight: FontWeight.bold
              ),
           ),
        )
     );
  }

  Widget _buildColumnHeaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
           const SizedBox(width: 48), // Space for Radio/SymbolBox
           Expanded(flex: 3, child: Text("SYMBOL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
           Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500), textAlign: TextAlign.center)),
           Expanded(flex: 2, child: Text("PRICE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildMobileTradeItem(TradeHoldingViewModel holding) {
     String statusText = holding.displayStatus.toUpperCase();
     Color bgPillColor;
     Color textPillColor;
     
     if (statusText == 'WIN') {
        bgPillColor = const Color(0xFFE8F5E9);
        textPillColor = const Color(0xFF2E7D32);
     } else if (statusText == 'LOSS') {
        bgPillColor = const Color(0xFFFFEBEE);
        textPillColor = const Color(0xFFC62828);
     } else if (statusText == 'BREAK_EVEN' || statusText == 'BREAKEVEN') {
        bgPillColor = const Color(0xFFFFF9C4);
        textPillColor = const Color(0xFFF9A825);
        statusText = "BREAKEVEN"; 
     } else {
        bgPillColor = Colors.grey.shade100;
        textPillColor = Colors.grey.shade700;
     }

     // Dynamic Symbol Color (Pseudo-random or hash based)
     final symbolColors = [
        Colors.blue.shade50,
        Colors.purple.shade50,
        Colors.orange.shade50,
        Colors.teal.shade50
     ];
     final symbolTextColors = [
        Colors.blue.shade700,
        Colors.purple.shade700,
        Colors.orange.shade800,
        Colors.teal.shade700
     ];
     final colorIndex = holding.displaySymbol.length % symbolColors.length;

     return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(20),
           boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
           ]
        ),
        child: InkWell(
           onTap: () => onSelectTrade(holding),
           child: Row(
              children: [
                 // Radio Circle
                 Icon(Icons.radio_button_unchecked, size: 20, color: Colors.grey.shade500),
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
                          Text(holding.displaySymbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                          const SizedBox(height: 2),
                          Text(holding.displayCompanyName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                       Text(holding.displayCurrentValue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                       const SizedBox(height: 2),
                       Text("Qty: ${_formatCompactQty(holding.quantity)}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
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
