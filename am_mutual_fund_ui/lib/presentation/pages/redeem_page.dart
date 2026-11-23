import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mf_api_client.dart';
import '../../providers/mf_providers.dart';
import '../widgets/mf_empty_state.dart';
import '../widgets/mf_page_header.dart';

class MfRedeemPage extends ConsumerStatefulWidget {
  const MfRedeemPage({
    required this.isin,
    this.initialUnits,
    this.initialFolio,
    super.key,
  });

  final String isin;
  final double? initialUnits;
  final String? initialFolio;

  @override
  ConsumerState<MfRedeemPage> createState() => _MfRedeemPageState();
}

class _MfRedeemPageState extends ConsumerState<MfRedeemPage> {
  late final TextEditingController _units;
  late final TextEditingController _folio;
  bool _busy = false;
  String? _error;

  Color get _accent =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;

  @override
  void initState() {
    super.initState();
    _units = TextEditingController(
      text: widget.initialUnits != null ? widget.initialUnits.toString() : '',
    );
    _folio = TextEditingController(text: widget.initialFolio ?? '');
  }

  @override
  void dispose() {
    _units.dispose();
    _folio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final units = double.tryParse(_units.text.trim());
    if (units == null || units <= 0) {
      setState(() => _error = 'Enter positive units');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await ref.read(mfApiClientProvider).redeem(
            schemeId: widget.isin,
            units: units,
            folio: _folio.text.trim().isEmpty ? null : _folio.text.trim(),
            idempotencyKey: MfApiClient.newIdempotencyKey(),
          );
      ref.read(mfSessionIdsProvider.notifier).setOrderId(order.id);
      if (!mounted) return;
      context.go('/app/mutual-funds/orders/${order.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MfPageHeader(
          title: 'Redeem',
          subtitle: widget.isin.toUpperCase(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/app/mutual-funds/holdings'),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppRadii.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _units,
                decoration: const InputDecoration(labelText: 'Units'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _folio,
                decoration:
                    const InputDecoration(labelText: 'Folio (optional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                MfErrorBanner(message: _error!),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit redeem'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
