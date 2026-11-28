import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mf_dto.dart';
import '../../data/mf_error_message.dart';
import '../../providers/mf_providers.dart';
import '../widgets/mf_empty_state.dart';
import '../widgets/mf_page_header.dart';
import '../widgets/mf_status_chip.dart';

class MfHistoryPage extends ConsumerWidget {
  const MfHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(mfOrdersHistoryProvider);
    final sips = ref.watch(mfSipsHistoryProvider);
    final mandates = ref.watch(mfMandatesHistoryProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const MfPageHeader(
          title: 'History',
          subtitle: 'Orders, SIP registrations, and mandates for this account.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Orders',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MfErrorBanner(message: mfErrorMessage(e)),
          data: (list) {
            if (list.isEmpty) {
              return const MfEmptyState(
                title: 'No orders yet',
                body: 'Lump-sum purchases and redemptions appear here.',
                icon: Icons.receipt_long_outlined,
              );
            }
            return Column(
              children: [
                for (final o in list) _OrderTile(order: o),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'SIPs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            AppButton(
              text: 'Refresh',
              type: AppButtonType.text,
              icon: Icons.refresh,
              onPressed: () {
                ref.invalidate(mfSipsHistoryProvider);
                ref.invalidate(mfOrdersHistoryProvider);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        sips.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MfErrorBanner(message: mfErrorMessage(e)),
          data: (list) {
            if (list.isEmpty) {
              return const MfEmptyState(
                title: 'No SIPs yet',
                body: 'Register a SIP/XSIP from Systematic.',
                icon: Icons.autorenew,
              );
            }
            return Column(
              children: [
                for (final s in list) _SipTile(sip: s),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Mandates',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            AppButton(
              text: 'Refresh list',
              type: AppButtonType.text,
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(mfMandatesHistoryProvider),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        mandates.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => MfErrorBanner(message: mfErrorMessage(e)),
          data: (list) {
            if (list.isEmpty) {
              return const MfEmptyState(
                title: 'No mandates yet',
                body: 'Create a mandate from Systematic for XSIP auto-debit.',
                icon: Icons.account_balance_outlined,
              );
            }
            return Column(
              children: [
                for (final m in list) _MandateTile(mandate: m),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final MfOrder order;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${order.side} · ${order.isin}'),
      subtitle: Text(order.createdAt),
      trailing: MfStatusChip(status: order.status),
      onTap: () => context.go('/app/mutual-funds/orders/${order.id}'),
    );
  }
}

class _SipTile extends ConsumerStatefulWidget {
  const _SipTile({required this.sip});

  final MfSip sip;

  @override
  ConsumerState<_SipTile> createState() => _SipTileState();
}

class _SipTileState extends ConsumerState<_SipTile> {
  late MfSip _sip;
  bool _busy = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _sip = widget.sip;
  }

  @override
  void didUpdateWidget(covariant _SipTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sip.id != widget.sip.id ||
        oldWidget.sip.status != widget.sip.status) {
      _sip = widget.sip;
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() => _msg = mfErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refId = _sip.distributorSipRef;
    final canAct = refId != null && refId.isNotEmpty && !_busy;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadii.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_sip.xsip ? 'XSIP' : 'SIP'} · ${_sip.isin}',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  MfStatusChip(status: _sip.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '₹${_sip.installmentAmount.toStringAsFixed(0)} · ${_sip.frequency}'
              '${refId != null ? ' · $refId' : ''}',
              style: TextStyle(color: context.textSecondary),
            ),
            if (_msg != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(_msg!, style: TextStyle(color: context.textSecondary)),
            ],
            if (canAct) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (_sip.canPause)
                    AppButton(
                      text: 'Pause',
                      type: AppButtonType.secondary,
                      isOutlined: true,
                      onPressed: () => _act(() async {
                        final op = await ref
                            .read(mfApiClientProvider)
                            .pauseSip(refId);
                        if (!mounted) return;
                        setState(() {
                          _msg = op.message ?? 'Pause: ok=${op.ok}';
                          if (op.ok) {
                            _sip = _sip.copyWith(status: 'paused');
                            ref
                                .read(mfSessionIdsProvider.notifier)
                                .setSip(ref: refId, status: 'paused');
                          }
                        });
                        ref.invalidate(mfSipsHistoryProvider);
                      }),
                    ),
                  if (_sip.canResume)
                    AppButton(
                      text: 'Resume',
                      type: AppButtonType.secondary,
                      isOutlined: true,
                      onPressed: () => _act(() async {
                        final op = await ref
                            .read(mfApiClientProvider)
                            .resumeSip(refId);
                        if (!mounted) return;
                        setState(() {
                          _msg = op.message ?? 'Resume: ok=${op.ok}';
                          if (op.ok) {
                            _sip = _sip.copyWith(status: 'active');
                            ref
                                .read(mfSessionIdsProvider.notifier)
                                .setSip(ref: refId, status: 'active');
                          }
                        });
                        ref.invalidate(mfSipsHistoryProvider);
                      }),
                    ),
                  if (_sip.canCancel)
                    AppButton(
                      text: 'Cancel',
                      type: AppButtonType.secondary,
                      isOutlined: true,
                      onPressed: () => _act(() async {
                        final op = await ref
                            .read(mfApiClientProvider)
                            .cancelSip(refId);
                        if (!mounted) return;
                        setState(() {
                          _msg = op.message ?? 'Cancel: ok=${op.ok}';
                          if (op.ok) {
                            _sip = _sip.copyWith(status: 'cancelled');
                            ref
                                .read(mfSessionIdsProvider.notifier)
                                .setSip(ref: refId, status: 'cancelled');
                          }
                        });
                        ref.invalidate(mfSipsHistoryProvider);
                      }),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MandateTile extends ConsumerStatefulWidget {
  const _MandateTile({required this.mandate});

  final MfMandate mandate;

  @override
  ConsumerState<_MandateTile> createState() => _MandateTileState();
}

class _MandateTileState extends ConsumerState<_MandateTile> {
  late MfMandate _mandate;
  bool _busy = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _mandate = widget.mandate;
  }

  @override
  void didUpdateWidget(covariant _MandateTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mandate.id != widget.mandate.id ||
        oldWidget.mandate.status != widget.mandate.status) {
      _mandate = widget.mandate;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final client = ref.read(mfApiClientProvider);
      final m = await client.getMandate(_mandate.id);
      if (!mounted) return;
      setState(() {
        _mandate = m;
        _msg = 'Status refreshed';
      });
      ref.read(mfSessionIdsProvider.notifier).setMandate(
            id: m.id,
            status: m.status,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _msg = mfErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '₹${_mandate.amount.toStringAsFixed(0)}'
        '${_mandate.distributorMandateRef != null ? ' · ${_mandate.distributorMandateRef}' : ''}',
      ),
      subtitle: Text(
        '${_mandate.id}'
        '${_mandate.createdAt.isNotEmpty ? ' · ${_mandate.createdAt}' : ''}'
        '${_msg != null ? '\n$_msg' : ''}',
      ),
      isThreeLine: _msg != null,
      trailing: _busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : MfStatusChip(status: _mandate.status),
      onTap: _busy ? null : _refresh,
    );
  }
}
