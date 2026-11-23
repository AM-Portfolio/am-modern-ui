import 'dart:async';

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/mf_error_message.dart';
import '../../providers/mf_providers.dart';
import '../widgets/mf_empty_state.dart';
import '../widgets/mf_page_header.dart';
import '../widgets/mf_status_chip.dart';

const _paymentModes = <String>[
  'upi',
  'netbanking',
  'neft',
  'mandate',
  'cheque',
];

class MfOrderDetailPage extends ConsumerStatefulWidget {
  const MfOrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<MfOrderDetailPage> createState() => _MfOrderDetailPageState();
}

class _MfOrderDetailPageState extends ConsumerState<MfOrderDetailPage> {
  Timer? _poll;
  bool _actionBusy = false;
  String? _actionError;
  String _paymentMode = 'upi';

  Color get _accent =>
      ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      final async = ref.read(mfOrderProvider(widget.orderId));
      final order = async.asData?.value;
      if (order == null || !order.isTerminal) {
        ref.invalidate(mfOrderProvider(widget.orderId));
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() {
      _actionBusy = true;
      _actionError = null;
    });
    try {
      await ref.read(mfApiClientProvider).payOrder(
            widget.orderId,
            paymentMode: _paymentMode,
          );
      ref.invalidate(mfOrderProvider(widget.orderId));
    } catch (e) {
      setState(() => _actionError = mfErrorMessage(e));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _cancel() async {
    setState(() {
      _actionBusy = true;
      _actionError = null;
    });
    try {
      await ref.read(mfApiClientProvider).cancelOrder(widget.orderId);
      ref.invalidate(mfOrderProvider(widget.orderId));
    } catch (e) {
      setState(() => _actionError = mfErrorMessage(e));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      setState(() => _actionError = 'Could not open payment link');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mfOrderProvider(widget.orderId));
    final accent = _accent;

    return async.when(
      loading: () => const MfLoadingBlock(),
      error: (e, _) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          MfPageHeader(
            title: 'Order',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/app/mutual-funds'),
            ),
          ),
          MfErrorBanner(message: mfErrorMessage(e)),
        ],
      ),
      data: (order) {
        final link = order.paymentLink;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            MfPageHeader(
              title: 'Order',
              subtitle: order.id,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/app/mutual-funds/history'),
              ),
              trailing: MfStatusChip(status: order.status),
            ),
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: AppRadii.md,
              child: Column(
                children: [
                  _kv(context, 'Order ID', order.id),
                  _kv(context, 'ISIN', order.isin),
                  if (order.toIsin != null && order.toIsin!.isNotEmpty)
                    _kv(context, 'To ISIN', order.toIsin!),
                  _kv(context, 'Side', order.side),
                  if (order.amount != null)
                    _kv(context, 'Amount',
                        '₹${order.amount!.toStringAsFixed(2)}'),
                  if (order.units != null)
                    _kv(context, 'Units', order.units!.toString()),
                  if (order.distributorOrderRef != null)
                    _kv(context, 'Distributor ref', order.distributorOrderRef!),
                  if (order.createdAt.isNotEmpty)
                    _kv(context, 'Created', order.createdAt),
                  if (order.updatedAt.isNotEmpty)
                    _kv(context, 'Updated', order.updatedAt),
                  if (order.dryRun) _kv(context, 'Mode', 'dry_run'),
                ],
              ),
            ),
            if (order.canPay) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Payment mode',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final mode in _paymentModes)
                    AmToggleChip(
                      label: mode.toUpperCase(),
                      selected: _paymentMode == mode,
                      filled: true,
                      compact: true,
                      accentColor: accent,
                      onTap: _actionBusy
                          ? null
                          : () => setState(() => _paymentMode = mode),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const MfQuietNote(
                message:
                    'Dig UAT may reject API pay for non-trusted members — '
                    'a payment link appears below when the BFF returns one.',
              ),
            ],
            if (order.failureCode != null || order.failureMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              MfErrorBanner(
                message: [
                  if (order.failureCode != null) order.failureCode!,
                  if (order.failureMessage != null) order.failureMessage!,
                  if (order.isNonTrustedPayFailure)
                    'Expected on dig UAT until NSE marks the member trusted for API payment.',
                ].join('\n'),
              ),
            ],
            if (link != null) ...[
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                borderRadius: AppRadii.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Payment link',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(
                      link,
                      style: TextStyle(color: context.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        AppButton(
                          text: 'Open link',
                          backgroundColor: accent,
                          onPressed: _actionBusy ? null : () => _openLink(link),
                        ),
                        AppButton(
                          text: 'Copy',
                          type: AppButtonType.secondary,
                          isOutlined: true,
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await Clipboard.setData(ClipboardData(text: link));
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Link copied')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (order.canPay)
                  AppButton(
                    text: 'Pay',
                    backgroundColor: accent,
                    isLoading: _actionBusy,
                    onPressed: _actionBusy ? null : _pay,
                  ),
                if (order.canCancel)
                  AppButton(
                    text: 'Cancel',
                    type: AppButtonType.secondary,
                    isOutlined: true,
                    onPressed: _actionBusy ? null : _cancel,
                  ),
                AppButton(
                  text: 'Refresh',
                  type: AppButtonType.secondary,
                  isOutlined: true,
                  onPressed: () =>
                      ref.invalidate(mfOrderProvider(widget.orderId)),
                ),
              ],
            ),
            if (_actionError != null) ...[
              const SizedBox(height: AppSpacing.md),
              MfErrorBanner(message: _actionError!),
            ],
          ],
        );
      },
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(k, style: TextStyle(color: context.textSecondary)),
          ),
          Expanded(
            child: SelectableText(
              v,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
