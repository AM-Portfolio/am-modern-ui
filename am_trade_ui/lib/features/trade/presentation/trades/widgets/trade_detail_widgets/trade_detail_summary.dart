import 'package:flutter/material.dart';

import '../../../models/trade_holding_view_model.dart';

class TradeDetailSummary extends StatelessWidget {
  const TradeDetailSummary({required this.trade, super.key});

  final TradeHoldingViewModel trade;

  @override
  Widget build(BuildContext context) {
    final isProfit = trade.isProfit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return isMobile ? _buildMobileLayout(context, isProfit) : _buildDesktopLayout(context, isProfit);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isProfit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trade Overview Card
        Expanded(
           child: _buildSpecificCard(
              context,
              title: 'Trade Overview',
              accentColor: const Color(0xFF311B92).withOpacity(0.3), // Dark Purple
              iconColor: const Color(0xFFB39DDB), // Light Purple
              icon: Icons.receipt_long,
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Expanded(child: _buildStatColumn('POSITION', trade.tradePositionType ?? 'N/A')),
                      Expanded(child: _buildStatColumn('QTY', trade.displayQuantity)),
                      Expanded(child: _buildStatColumn('EXECS', '${trade.executionCount}')),
                   ]
                 ),
                 const SizedBox(height: 16),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Expanded(child: _buildStatColumn('AVG. PRICE', trade.displayAvgPrice)),
                      Expanded(child: _buildStatColumn('HOLD', trade.displayHoldingPeriod)),
                      Expanded(child: _buildStatColumn('CURRENCY', trade.displayCurrency)),
                   ]
                 )
              ]
           )
        ),
        const SizedBox(width: 16),

        // Price & Value Card
        Expanded(
          child: _buildSpecificCard(
            context,
            title: 'Price & Value',
            accentColor: const Color(0xFF0D47A1).withOpacity(0.3), // Dark blue
            iconColor: const Color(0xFF90CAF9), // Light blue
            icon: Icons.attach_money,
            children: [
               _buildValueRow('Entry', trade.displayEntryPrice, 'Exit', trade.displayExitPrice),
               const SizedBox(height: 24),
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                     Text('Total Value', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                     Text(
                        trade.displayCurrentValue, 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                     ),
                  ],
               )
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Performance Card
        Expanded(
          child: _buildSpecificCard(
            context,
            title: 'Performance',
            accentColor: const Color(0xFF1B5E20).withOpacity(0.3), // Dark green
            iconColor: const Color(0xFFA5D6A7), // Light green
            icon: Icons.bar_chart,
            children: [
               _buildValueRow('Realized', trade.displayProfitLoss, 'ROE', trade.displayReturnOnEquity, value2Color: Colors.greenAccent),
               const SizedBox(height: 24),
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                     Text(
                        'Risk/Reward', 
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)
                     ),
                     Text(
                        trade.displayRiskRewardRatio, 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                     ),
                  ],
               )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewItem(BuildContext context, String label, String value, {bool isBold = false}) {
     return Expanded(
        child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
           decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.05)),
           ),
           child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                    label, 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), letterSpacing: 0.5)
                 ),
                 const SizedBox(height: 6),
                 Text(
                    value,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                 )
              ],
           ),
        ),
     );
  }

  Widget _buildSpecificCard(BuildContext context, {required String title, required Color accentColor, required Color iconColor, required IconData icon, required List<Widget> children}) {
      return Container(
         padding: const EdgeInsets.all(24),
         decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
         ),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                  children: [
                     Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                        child: Icon(icon, size: 16, color: iconColor),
                     ),
                     const SizedBox(width: 8),
                     Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))
                  ],
               ),
               const SizedBox(height: 24),
               ...children
            ],
         ),
      );
  }

  Widget _buildValueRow(String label1, String value1, String label2, String value2, {Color? value2Color}) {
     return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label1, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(value1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))
           ])),
           Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [ 
              Text(label2, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(value2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: value2Color ?? Colors.white))
           ])),
        ],
     );
  }

  Widget _buildStatColumn(String label, String value, {Color? valueColor}) {
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
           const SizedBox(height: 4),
           Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor ?? Colors.white)),
        ]
     );
  }

  Widget _buildAttachmentCard(BuildContext context, String name, String size, IconData icon, Color bgColor, Color iconColor) {
      return Expanded(
         child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1))
            ),
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                     child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(size, style: const TextStyle(fontSize: 11, color: Colors.grey)),
               ],
            ),
         ),
      );
  }

  Widget _buildMobileLayout(BuildContext context, bool isProfit) {
    return Column(
      children: [
        // Trade Overview Section (Mobile: Grid inside Card)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
             boxShadow: [
               BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
             ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                 children: [
                    Container(
                       padding: const EdgeInsets.all(6),
                       decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(8)),
                       child: const Icon(Icons.receipt_long, color: Color(0xFF7B1FA2), size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                       'Trade Overview',
                       style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                 ],
              ),
              const SizedBox(height: 16),
              // Mobile Grid for Overview Items
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildOverviewItem(context, 'POSITION', trade.tradePositionType ?? 'N/A', isBold: true),
                  _buildOverviewItem(context, 'QTY', trade.displayQuantity, isBold: true),
                  _buildOverviewItem(context, 'EXECS', '${trade.executionCount}', isBold: true),
                  _buildOverviewItem(context, 'AVG. PRICE', trade.displayAvgPrice),
                  _buildOverviewItem(context, 'HOLD', trade.displayHoldingPeriod),
                  _buildOverviewItem(context, 'CURRENCY', trade.displayCurrency, isBold: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Price & Value Card
        _buildSpecificCard(
           context,
           title: 'Price & Value',
           accentColor: const Color(0xFFE3F2FD),
           iconColor: const Color(0xFF1976D2),
           icon: Icons.attach_money,
           children: [
              _buildValueRow('Entry', trade.displayEntryPrice, 'Exit', trade.displayExitPrice),
              const SizedBox(height: 16),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                    Text('Total Value', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text(
                       trade.displayCurrentValue, 
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)
                    ),
                 ],
              )
           ],
        ),
        
        const SizedBox(height: 16),
        
        // Performance Card
        _buildSpecificCard(
           context,
           title: 'Performance',
           accentColor: const Color(0xFFE8F5E9),
           iconColor: const Color(0xFF388E3C),
           icon: Icons.bar_chart,
           children: [
              _buildValueRow('Realized', trade.displayProfitLoss, 'ROE', trade.displayReturnOnEquity),
              const SizedBox(height: 16),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                    Text('Risk/Reward', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text(
                       trade.displayRiskRewardRatio, 
                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                    ),
                 ],
              )
           ],
        ),
         
        const SizedBox(height: 16),
         
         // Attachments Section
         Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.surface,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
               boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
               ],
            ),
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Row(
                     children: [
                        Container(
                           padding: const EdgeInsets.all(6),
                           decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                           child: const Icon(Icons.attach_file, color: Color(0xFFEF6C00), size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                           'Attachments',
                           style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const Spacer(),
                        // Mobile simplified upload button
                        Icon(Icons.cloud_upload_outlined, color: const Color(0xFF7C4DFF), size: 20),
                     ],
                  ),
                  const SizedBox(height: 16),
                  Text('(3 files attached)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                  // Stacked attachments for mobile
                   Column(
                      children: [
                         _buildAttachmentCardMobile(context, 'Trading_Plan_V1.pdf', '2.4 MB', Icons.picture_as_pdf, Colors.red.shade100, Colors.red),
                         const SizedBox(height: 12),
                         _buildAttachmentCardMobile(context, 'Chart_Analysis.png', '1.8 MB', Icons.image, Colors.blue.shade100, Colors.blue),
                         const SizedBox(height: 12),
                         _buildAttachmentCardMobile(context, 'Notes.txt', '14 KB', Icons.description, Colors.green.shade100, Colors.green),
                      ],
                   )
               ],
            ),
         )
      ],
    );
  }

  Widget _buildAttachmentCardMobile(BuildContext context, String name, String size, IconData icon, Color bgColor, Color iconColor) {
      return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
             color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1))
          ),
          child: Row(
             children: [
                Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                   child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(size, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                     ],
                  ),
                ),
             ],
          ),
      );
  }

  Widget _buildMobileStatOne(BuildContext context, String label, String value, {bool isBold = false}) {
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(16),
           boxShadow: [
              BoxShadow(
                 color: Colors.grey.withOpacity(0.05),
                 blurRadius: 10,
                 offset: const Offset(0, 4)
              )
           ]
        ),
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(
                 fontSize: 15, 
                 fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                 color: Colors.black87
              ), maxLines: 1, overflow: TextOverflow.ellipsis)
           ],
        ),
     );
  }

  Widget _buildModernCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Card Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [iconColor.withOpacity(0.08), iconColor.withOpacity(0.03)],
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        // Card Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    ),
  );

  Widget _buildModernInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 14 : 13,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    ),
  );
}
