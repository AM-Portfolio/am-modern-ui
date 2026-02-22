
import 'package:am_dashboard_ui/domain/models/top_movers_response.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/shared/widgets/tables/adaptive_data_table.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardRankingWidget extends StatelessWidget {
  final List<MoverItem> gainers;
  final List<MoverItem> losers;

  const DashboardRankingWidget({
    super.key,
    required this.gainers,
    required this.losers,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Top Movers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
             TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondaryLight,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Gainers'),
                Tab(text: 'Losers'),
              ],
            ),
            SizedBox(
              height: 400, // Fixed height for the list
              child: TabBarView(
                children: [
                  _buildTable(context, gainers),
                  _buildTable(context, losers),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<MoverItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 2);

    return SingleChildScrollView(
      child: Column(
        children: items.map((item) {
          final isPositive = item.changePercentage >= 0;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isPositive ? AppColors.profit.withOpacity(0.1) : AppColors.loss.withOpacity(0.1),
              child: Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? AppColors.profit : AppColors.loss,
                size: 20,
              ),
            ),
            title: Text(item.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(item.price),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  percentFormat.format(item.changePercentage / 100),
                  style: TextStyle(
                    color: isPositive ? AppColors.profit : AppColors.loss,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
