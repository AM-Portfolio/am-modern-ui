import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mf_api_client.dart';
import '../../data/mf_error_message.dart';
import '../../data/mf_scheme_view.dart';
import '../../providers/mf_providers.dart';
import '../widgets/mf_empty_state.dart';
import '../widgets/mf_page_header.dart';

class MfInvestPage extends ConsumerStatefulWidget {
  const MfInvestPage({required this.isin, super.key});

  final String isin;

  @override
  ConsumerState<MfInvestPage> createState() => _MfInvestPageState();
}

class _MfInvestPageState extends ConsumerState<MfInvestPage> {
  final _amountCtrl = TextEditingController(text: '5000');
  final _folioCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Stable for retries of the same amount/folio until success navigates away.
  String? _idempotencyKey;
  String? _keyFingerprint;

  Color get _accent =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _folioCtrl.dispose();
    super.dispose();
  }

  String _fingerprint(double amount, String folio) =>
      '${widget.isin.toUpperCase()}|$amount|$folio';

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a positive amount');
      return;
    }
    final folio = _folioCtrl.text.trim();
    final fp = _fingerprint(amount, folio);
    if (_idempotencyKey == null || _keyFingerprint != fp) {
      _idempotencyKey = MfApiClient.newIdempotencyKey();
      _keyFingerprint = fp;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(mfApiClientProvider);
      final order = await client.purchase(
        schemeId: widget.isin,
        amount: amount,
        folio: folio.isEmpty ? null : folio,
        idempotencyKey: _idempotencyKey,
      );
      ref.read(mfSessionIdsProvider.notifier).setOrderId(order.id);
      if (!mounted) return;
      context.go('/app/mutual-funds/orders/${order.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mfErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final schemeAsync = ref.watch(mfSchemeDetailProvider(widget.isin));
    final scheme = schemeAsync.asData?.value;
    final view = scheme != null ? MfSchemeView.fromSummary(scheme) : null;
    final canPurchase = view?.digPurchaseEnabled ??
        digInvestableIsins.contains(widget.isin.toUpperCase());

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MfPageHeader(
          title: 'Invest',
          subtitle: widget.isin.toUpperCase(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.go('/app/mutual-funds/schemes/${widget.isin}'),
          ),
        ),
        if (view != null && !canPurchase) ...[
          MfQuietNote(
            message: view.metricsIllustrative
                ? 'Purchase only for dig UAT-mapped ISINs '
                    '(INF579M01AV5 / INF579M01AW3) until SchemeIdMapper expands.'
                : 'Purchase not allowed for this scheme.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppRadii.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  helperText: 'Lump-sum purchase',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) {
                  _idempotencyKey = null;
                  _keyFingerprint = null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _folioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Folio (optional)',
                ),
                onChanged: (_) {
                  _idempotencyKey = null;
                  _keyFingerprint = null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: (_busy || !canPurchase) ? null : _submit,
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
                    : const Text('Place purchase'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                MfErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
