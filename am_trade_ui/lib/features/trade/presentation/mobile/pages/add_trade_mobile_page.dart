import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../internal/domain/entities/trade_controller_entities.dart';
import '../../add_trade/components/add_trade_form.dart';
import '../../cubit/trade_controller_cubit.dart';
import '../../cubit/trade_controller_state.dart';

/// Mobile page for adding new trades
/// Optimized for small screens with a vertical layout
class AddTradeMobilePage extends StatefulWidget {
  const AddTradeMobilePage({
    required this.portfolioId,
    super.key,
    this.portfolioName,
    this.onTradeAdded,
    this.onCancel,
    this.existingTrade,
  });

  final String portfolioId;
  final String? portfolioName;
  final VoidCallback? onTradeAdded;
  final VoidCallback? onCancel;
  final TradeDetails? existingTrade;

  @override
  State<AddTradeMobilePage> createState() => _AddTradeMobilePageState();
}

class _AddTradeMobilePageState extends State<AddTradeMobilePage> {
  bool _isLoading = false;

  void _handleSave(TradeDetails tradeDetails) {
    AppLogger.methodEntry('_handleSave', tag: 'AddTradeMobilePage');
    AppLogger.info(
      '💾 Starting trade save process - portfolioId: ${widget.portfolioId}, symbol: ${tradeDetails.instrumentInfo.symbol}',
      tag: 'AddTradeMobilePage',
    );

    setState(() => _isLoading = true);

    // CRITICAL: Set userId since it's not included in the form
    final tradeToSave = tradeDetails.copyWith();

    AppLogger.debug('📋 Trade Details (without explicit userId, handled by token): ${tradeToSave.toString()}', tag: 'AddTradeMobilePage');
    
    if (widget.existingTrade != null) {
      AppLogger.info('🚀 Calling TradeControllerCubit.updateExistingTrade()', tag: 'AddTradeMobilePage');
      final tradeToUpdate = tradeToSave.copyWith(tradeId: widget.existingTrade!.tradeId);
      context.read<TradeControllerCubit>().updateExistingTrade(tradeId: tradeToUpdate.tradeId, tradeDetails: tradeToUpdate);
    } else {
      AppLogger.info('🚀 Calling TradeControllerCubit.addNewTrade()', tag: 'AddTradeMobilePage');
      context.read<TradeControllerCubit>().addNewTrade(tradeToSave);
    }
  }

  void _handleCancel() {
    AppLogger.info('❌ Trade creation cancelled', tag: 'AddTradeMobilePage');
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surfaceTint,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Add New Trade',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.close_rounded), tooltip: 'Cancel', onPressed: _handleCancel),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.colorScheme.outlineVariant.withOpacity(0.5), height: 1),
        ),
      ),
      body: BlocListener<TradeControllerCubit, TradeControllerState>(
        listener: (context, state) {
          state.maybeWhen(
            error: (message, error) {
              AppLogger.error('❌ Trade save error: $message', tag: 'AddTradeMobilePage');
              setState(() => _isLoading = false);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $message'), backgroundColor: theme.colorScheme.error));
            },
            updateSuccess: (trade) {
              AppLogger.info('✅ Trade updated successfully!', tag: 'AddTradeMobilePage');
              setState(() => _isLoading = false);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Trade updated successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // Call callback and navigate back
              if (widget.onTradeAdded != null) {
                widget.onTradeAdded!();
              } else {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                } else {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              }
            },
            addSuccess: (trade) {
              AppLogger.info('✅ Trade saved successfully!', tag: 'AddTradeMobilePage');
              setState(() => _isLoading = false);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Trade saved successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // Call callback and navigate back
              if (widget.onTradeAdded != null) {
                widget.onTradeAdded!();
              } else {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                } else {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              }
            },
            orElse: () {},
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Main form with portfolioId passed via initialData
              AddTradeForm(
                onSave: _handleSave,
                onCancel: _handleCancel,
                isLoading: _isLoading,
                initialData: widget.existingTrade ?? TradeDetails.empty().copyWith(portfolioId: widget.portfolioId),
              ),

              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: theme.colorScheme.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Saving trade...',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

