import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mf_error_message.dart';
import '../../providers/mf_providers.dart';
import '../widgets/mf_empty_state.dart';
import '../widgets/mf_page_header.dart';
import '../widgets/mf_status_chip.dart';

class MfMandateSipPage extends ConsumerStatefulWidget {
  const MfMandateSipPage({this.initialIsin, super.key});

  final String? initialIsin;

  @override
  ConsumerState<MfMandateSipPage> createState() => _MfMandateSipPageState();
}

class _MfMandateSipPageState extends ConsumerState<MfMandateSipPage> {
  late final TextEditingController _mandateAmount;
  late final TextEditingController _isin;
  late final TextEditingController _sipAmount;
  late final TextEditingController _dates;
  bool _xsip = true;
  bool _busy = false;
  bool _hydrated = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _mandateAmount = TextEditingController(text: '5000');
    _isin = TextEditingController(text: widget.initialIsin ?? 'INF579M01AV5');
    _sipAmount = TextEditingController(text: '1000');
    _dates = TextEditingController(text: '15/12/2026');
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateSession());
  }

  @override
  void dispose() {
    _mandateAmount.dispose();
    _isin.dispose();
    _sipAmount.dispose();
    _dates.dispose();
    super.dispose();
  }

  Future<void> _hydrateSession() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final client = ref.read(mfApiClientProvider);
      final mandates = await client.listMandates();
      final sips = await client.listSips();
      if (!mounted) return;
      ref.read(mfSessionIdsProvider.notifier).hydrateFromLists(
            mandates: mandates,
            sips: sips,
          );
      ref.invalidate(mfMandatesHistoryProvider);
      ref.invalidate(mfSipsHistoryProvider);
      final session = ref.read(mfSessionIdsProvider);
      if (session.mandateId != null || session.distributorSipRef != null) {
        setState(() {
          _message =
              'Hydrated from History'
              '${session.mandateId != null ? ' · mandate ${session.mandateId} (${session.mandateStatus})' : ''}'
              '${session.distributorSipRef != null ? ' · SIP ${session.distributorSipRef} (${session.sipStatus})' : ''}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = mfErrorMessage(e));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = mfErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(mfSessionIdsProvider);
    final sipStatus = (session.sipStatus ?? 'pending').toLowerCase();

    final accent =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.mutualFund;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MfPageHeader(
          title: 'Systematic plans',
          subtitle:
              'Create mandate, wait until status is ACTIVE (bank eNACH), then XSIP. '
              'Pause/cancel only after desk auth (not AUTHPENDING). '
              'Resume works on stub distributor; NSE returns unsupported until desk confirms. '
              'Start date must be DD/MM/YYYY with day 1–28.',
          trailing: session.mandateId != null
              ? MfStatusChip(status: session.mandateStatus ?? sipStatus)
              : null,
        ),
        Text('Mandate', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _mandateAmount,
          decoration: const InputDecoration(labelText: 'Mandate amount (₹)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          text: 'Create mandate',
          backgroundColor: accent,
          isLoading: _busy,
          onPressed: _busy
              ? null
              : () => _run(() async {
                    final amount =
                        double.tryParse(_mandateAmount.text.trim());
                    if (amount == null || amount <= 0) {
                      if (!mounted) return;
                      setState(() =>
                          _message = 'Enter a positive mandate amount');
                      return;
                    }
                    final m = await ref
                        .read(mfApiClientProvider)
                        .createMandate(amount: amount);
                    final usable = m.status != 'rejected' &&
                        m.status != 'cancelled' &&
                        m.status != 'failed';
                    if (usable) {
                      ref.read(mfSessionIdsProvider.notifier).setMandate(
                            id: m.id,
                            status: m.status,
                          );
                    }
                    ref.invalidate(mfMandatesHistoryProvider);
                    if (!mounted) return;
                    setState(() {
                      _message = usable
                          ? 'Mandate ${m.id} · status ${m.status}'
                              '${m.distributorMandateRef != null ? ' · desk ${m.distributorMandateRef}' : ''}'
                          : 'Mandate not usable for XSIP (status ${m.status})'
                              '${m.failureMessage != null ? ': ${m.failureMessage}' : ''}';
                    });
                  }),
        ),
        if (session.mandateId != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('Local mandate id: ',
                  style: TextStyle(color: context.textSecondary)),
              Expanded(
                child: SelectableText(
                  session.mandateId!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (session.mandateStatus != null)
                MfStatusChip(status: session.mandateStatus!),
            ],
          ),
          AppButton(
            text: 'Refresh mandate status',
            type: AppButtonType.text,
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final m = await ref
                          .read(mfApiClientProvider)
                          .getMandate(session.mandateId!);
                      ref.read(mfSessionIdsProvider.notifier).setMandate(
                            id: m.id,
                            status: m.status,
                          );
                      if (!mounted) return;
                      setState(() {
                        _message =
                            'Mandate refresh · ${m.status}'
                            '${m.distributorMandateRef != null ? ' · desk ${m.distributorMandateRef}' : ''}';
                      });
                    }),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('SIP / XSIP', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _isin,
          decoration: const InputDecoration(labelText: 'Scheme ISIN'),
          textCapitalization: TextCapitalization.characters,
        ),
        TextFormField(
          controller: _sipAmount,
          decoration: const InputDecoration(labelText: 'Installment amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextFormField(
          controller: _dates,
          decoration: const InputDecoration(
            labelText: 'Start date',
            helperText: 'DD/MM/YYYY (day 1–28)',
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('XSIP (auto-debit via mandate)'),
          value: _xsip,
          onChanged: (v) => setState(() => _xsip = v),
        ),
        AppButton(
          text: 'Register SIP',
          backgroundColor: accent,
          isLoading: _busy,
          onPressed: _busy
              ? null
              : () => _run(() async {
                    if (_xsip && !session.mandateUsableForXsip) {
                      if (!mounted) return;
                      setState(() => _message =
                          'XSIP needs mandate ACTIVE (or dry_run). '
                          'Create mandate, complete bank auth, then Refresh.');
                      return;
                    }
                    final amount = double.tryParse(_sipAmount.text.trim());
                    if (amount == null || amount <= 0) {
                      if (!mounted) return;
                      setState(() =>
                          _message = 'Enter a positive SIP amount');
                      return;
                    }
                    if (_isin.text.trim().isEmpty) {
                      if (!mounted) return;
                      setState(() => _message = 'Enter scheme ISIN');
                      return;
                    }
                    final sip = await ref.read(mfApiClientProvider).createSip(
                          schemeId: _isin.text.trim(),
                          amount: amount,
                          dates: _dates.text.trim(),
                          mandateId: session.mandateId,
                          xsip: _xsip,
                        );
                    if (sip.distributorSipRef != null) {
                      ref.read(mfSessionIdsProvider.notifier).setSip(
                            ref: sip.distributorSipRef!,
                            status: sip.status,
                          );
                    } else {
                      ref
                          .read(mfSessionIdsProvider.notifier)
                          .setSipStatus(sip.status);
                    }
                    ref.invalidate(mfSipsHistoryProvider);
                    if (!mounted) return;
                    setState(() {
                      _message =
                          'SIP ${sip.id} · ${sip.status}'
                          '${sip.distributorSipRef != null ? ' · ref ${sip.distributorSipRef}' : ''}'
                          '${sip.failureMessage != null ? ' · ${sip.failureMessage}' : ''}';
                    });
                  }),
        ),
        if (session.distributorSipRef != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text('SIP ref: '),
              Expanded(child: SelectableText(session.distributorSipRef!)),
              MfStatusChip(status: sipStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                text: 'Pause',
                type: AppButtonType.secondary,
                isOutlined: true,
                onPressed: _busy ||
                        !(sipStatus == 'active' || sipStatus == 'dry_run')
                    ? null
                    : () => _run(() async {
                          final op = await ref
                              .read(mfApiClientProvider)
                              .pauseSip(session.distributorSipRef!);
                          if (op.ok) {
                            ref
                                .read(mfSessionIdsProvider.notifier)
                                .setSipStatus('paused');
                          }
                          ref.invalidate(mfSipsHistoryProvider);
                          if (!mounted) return;
                          setState(() =>
                              _message = op.message ?? 'Pause: ok=${op.ok}');
                        }),
              ),
              AppButton(
                text: 'Resume',
                type: AppButtonType.secondary,
                isOutlined: true,
                onPressed: _busy || sipStatus != 'paused'
                    ? null
                    : () => _run(() async {
                          final op = await ref
                              .read(mfApiClientProvider)
                              .resumeSip(session.distributorSipRef!);
                          if (op.ok) {
                            ref
                                .read(mfSessionIdsProvider.notifier)
                                .setSipStatus('active');
                          }
                          ref.invalidate(mfSipsHistoryProvider);
                          if (!mounted) return;
                          setState(() => _message =
                              op.message ?? 'Resume: ok=${op.ok}');
                        }),
              ),
              AppButton(
                text: 'Cancel SIP',
                type: AppButtonType.secondary,
                isOutlined: true,
                onPressed: _busy ||
                        sipStatus == 'cancelled' ||
                        sipStatus == 'failed'
                    ? null
                    : () => _run(() async {
                          final op = await ref
                              .read(mfApiClientProvider)
                              .cancelSip(session.distributorSipRef!);
                          if (op.ok) {
                            ref
                                .read(mfSessionIdsProvider.notifier)
                                .setSipStatus('cancelled');
                          }
                          ref.invalidate(mfSipsHistoryProvider);
                          if (!mounted) return;
                          setState(() =>
                              _message = op.message ?? 'Cancel: ok=${op.ok}');
                        }),
              ),
            ],
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: AppSpacing.lg),
          MfQuietNote(message: _message!),
        ],
      ],
    );
  }
}
