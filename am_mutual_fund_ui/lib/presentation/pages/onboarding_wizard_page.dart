import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/mf_providers.dart';
import '../widgets/mf_page_header.dart';
import '../widgets/mf_status_chip.dart';

class MfOnboardingWizardPage extends ConsumerStatefulWidget {
  const MfOnboardingWizardPage({super.key});

  @override
  ConsumerState<MfOnboardingWizardPage> createState() =>
      _MfOnboardingWizardPageState();
}

class _MfOnboardingWizardPageState
    extends ConsumerState<MfOnboardingWizardPage> {
  int _step = 0;
  bool _busy = false;
  bool _hydrating = true;
  String? _kycMessage;
  String? _ekycMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromServer());
  }

  Future<void> _hydrateFromServer() async {
    try {
      final status = await ref.read(mfApiClientProvider).getOnboardingStatus();
      if (!mounted) return;
      ref.read(mfOnboardingDraftProvider.notifier).hydrateFromStatus(status);
      // Jump stepper to first incomplete step (or Bank when done).
      var step = 0;
      if (status.uccOk) step = 2;
      if (status.fatcaOk) step = 3;
      if (status.complete) step = 3;
      setState(() {
        _step = step;
        _hydrating = false;
        if (status.uccOk) {
          _kycMessage = 'KYC/UCC already bound for this dig user';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hydrating = false);
      // Dig without status route yet → 404; keep wizard usable, no stack dump.
      final msg = e.toString();
      final soft = msg.contains('404')
          ? 'Onboarding status API not on dig yet (404). '
              'Finish UCC/FATCA/Bank once; after MF BFF deploy, reopen to see saved state.'
          : 'Could not load onboarding status: $e';
      ref.read(mfOnboardingDraftProvider.notifier).patch(
            (d) => d.copyWith(lastMessage: soft),
          );
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ref.read(mfOnboardingDraftProvider.notifier).patch(
            (d) => d.copyWith(lastMessage: e.toString()),
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitFatca({required bool advanceToBank}) async {
    final draft = ref.read(mfOnboardingDraftProvider);
    final client = ref.read(mfApiClientProvider);
    final op = await client.submitFatca({
      'pan': draft.pan.trim().toUpperCase(),
      if (draft.name.isNotEmpty) 'name': draft.name.trim(),
      if (draft.dob.isNotEmpty) 'dob': draft.dob.trim(),
      'country_of_birth': draft.countryOfBirth.trim().toUpperCase(),
      'citizenship': draft.citizenship.trim().toUpperCase(),
      'tax_status': draft.taxStatus.trim(),
    });
    ref.read(mfOnboardingDraftProvider.notifier).patch(
          (d) => d.copyWith(
            fatcaOk: op.ok,
            lastMessage: op.message ??
                (op.ok ? 'FATCA ok' : 'FATCA failed — retry before investing'),
          ),
        );
    if (op.ok && advanceToBank && mounted) setState(() => _step = 3);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(mfOnboardingDraftProvider);
    final metaAsync = ref.watch(mfMetaProvider);
    final strict = metaAsync.asData?.value.onboardingStrict ?? false;

    if (_hydrating) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MfPageHeader(
          title: 'Investor onboarding',
          subtitle: strict
              ? 'Strict mode: KYC must pass, eKYC required, FATCA+bank gate trading.'
              : 'Dig soft mode: KYC/eKYC can be soft. '
                  'UCC binds PAN. FATCA auto-runs after UCC; purchase needs fatca_ok+bank_ok.',
          trailing: draft.uccOk && draft.fatcaOk && draft.bankOk
              ? const MfStatusChip(status: 'ok')
              : null,
        ),
        if (draft.uccOk && draft.fatcaOk && draft.bankOk) ...[
          Card(
            child: ListTile(
              leading: Icon(Icons.verified, color: context.marketPositive),
              title: const Text('Onboarding complete for this dig user'),
              subtitle: Text(
                [
                  if (draft.pan.isNotEmpty) 'PAN ${draft.pan}',
                  if (draft.clientCode.isNotEmpty) 'UCC ${draft.clientCode}',
                  'FATCA ok · Bank ok',
                ].join(' · '),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Stepper(
          currentStep: _step,
          onStepTapped: (i) {
            // Bank is step 3; block until UCC ok.
            if (i > 2 && !draft.uccOk) return;
            setState(() => _step = i);
          },
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: [
            Step(
              title: const Text('KYC check'),
              isActive: _step == 0,
              state: draft.uccOk ? StepState.complete : StepState.indexed,
              content: _KycStep(
                draft: draft,
                busy: _busy,
                message: _kycMessage,
                onChanged: (d) =>
                    ref.read(mfOnboardingDraftProvider.notifier).patch((_) => d),
                onCheck: () => _run(() async {
                  final client = ref.read(mfApiClientProvider);
                  final op = await client.checkKyc(
                    pan: draft.pan,
                    mobile: draft.mobile.trim().isEmpty
                        ? null
                        : draft.mobile.trim(),
                  );
                  if (!mounted) return;
                  final msg = op.message ?? (op.ok ? 'KYC ok' : 'KYC checked');
                  final blocked = strict && !op.ok;
                  setState(() {
                    _kycMessage = blocked
                        ? '$msg — strict mode blocks UCC until KYC passes'
                        : msg;
                    if (!blocked) _step = 1;
                  });
                  ref.read(mfOnboardingDraftProvider.notifier).patch(
                        (d) => d.copyWith(lastMessage: _kycMessage),
                      );
                }),
              ),
            ),
            Step(
              title: const Text('eKYC'),
              isActive: _step == 1,
              state: draft.ekycOk ? StepState.complete : StepState.indexed,
              content: _EkycStep(
                draft: draft,
                busy: _busy,
                message: _ekycMessage,
                allowSkip: !strict,
                onStart: () => _run(() async {
                  final client = ref.read(mfApiClientProvider);
                  final op = await client.startEkyc(pan: draft.pan);
                  final msg = op.message ??
                      (op.ok
                          ? 'eKYC started'
                          : 'eKYC not available (common on dig UAT)');
                  if (!mounted) return;
                  final blocked = strict && !op.ok;
                  setState(() {
                    _ekycMessage = blocked
                        ? '$msg — strict mode requires eKYC success'
                        : msg;
                    if (!blocked) _step = 2;
                  });
                  ref.read(mfOnboardingDraftProvider.notifier).patch(
                        (d) => d.copyWith(
                          ekycOk: op.ok,
                          lastMessage: _ekycMessage,
                        ),
                      );
                }),
                onSkip: () {
                  setState(() {
                    _ekycMessage = 'Skipped eKYC — continue with UCC';
                    _step = 2;
                  });
                  ref.read(mfOnboardingDraftProvider.notifier).patch(
                        (d) => d.copyWith(lastMessage: _ekycMessage),
                      );
                },
              ),
            ),
            Step(
              title: const Text('UCC + FATCA'),
              isActive: _step == 2,
              state: draft.uccOk && draft.fatcaOk
                  ? StepState.complete
                  : draft.uccOk
                      ? StepState.indexed
                      : StepState.indexed,
              content: _UccFatcaStep(
                draft: draft,
                busy: _busy,
                hideClientCode: strict,
                onChanged: (d) =>
                    ref.read(mfOnboardingDraftProvider.notifier).patch((_) => d),
                onSubmit: () => _run(() async {
                  final d = ref.read(mfOnboardingDraftProvider);
                  if (!d.fatcaAttested) {
                    ref.read(mfOnboardingDraftProvider.notifier).patch(
                          (x) => x.copyWith(
                            lastMessage:
                                'Confirm tax residency attestation before Submit UCC',
                          ),
                        );
                    return;
                  }
                  bool isIndia(String v) {
                    final u = v.trim().toUpperCase();
                    return u == 'IN' || u == 'IND' || u == 'INDIA';
                  }
                  if (!isIndia(d.citizenship) ||
                      !isIndia(d.countryOfBirth)) {
                    ref.read(mfOnboardingDraftProvider.notifier).patch(
                          (x) => x.copyWith(
                            lastMessage:
                                'NRI / foreign tax residency not supported yet',
                          ),
                        );
                    return;
                  }
                  if (d.dob.trim().isEmpty) {
                    ref.read(mfOnboardingDraftProvider.notifier).patch(
                          (x) => x.copyWith(
                            lastMessage: 'DOB is required (DD/MM/YYYY)',
                          ),
                        );
                    return;
                  }
                  final client = ref.read(mfApiClientProvider);
                  final op = await client.submitUcc({
                    'pan': d.pan.trim().toUpperCase(),
                    if (!strict && d.clientCode.isNotEmpty)
                      'client_code': d.clientCode.trim(),
                    if (d.name.isNotEmpty) 'name': d.name.trim(),
                    'dob': d.dob.trim(),
                    if (d.email.isNotEmpty) 'email': d.email.trim(),
                    if (d.mobile.isNotEmpty) 'mobile': d.mobile.trim(),
                    if (d.bankAccountNo.isNotEmpty)
                      'bank_account_no': d.bankAccountNo.trim(),
                    if (d.bankIfsc.isNotEmpty)
                      'bank_ifsc': d.bankIfsc.trim().toUpperCase(),
                    if (d.accountType.isNotEmpty) 'account_type': d.accountType,
                    'country_of_birth': 'IN',
                    'citizenship': 'IN',
                    'tax_status': d.taxStatus.trim().isEmpty
                        ? '01'
                        : d.taxStatus.trim(),
                  });
                  final genCode =
                      op.details['client_code']?.toString() ?? d.clientCode;
                  ref.read(mfOnboardingDraftProvider.notifier).patch(
                        (x) => x.copyWith(
                          uccOk: op.ok,
                          clientCode: genCode,
                          lastMessage: op.message ??
                              (op.ok
                                  ? 'UCC ok — submitting FATCA…'
                                  : 'UCC failed — stop here'),
                        ),
                      );
                  if (!op.ok || !mounted) return;
                  await _submitFatca(advanceToBank: true);
                }),
              ),
            ),
            Step(
              title: const Text('Bank'),
              isActive: _step == 3,
              state: !draft.uccOk
                  ? StepState.disabled
                  : draft.bankOk
                      ? StepState.complete
                      : StepState.indexed,
              content: draft.uccOk
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!draft.fatcaOk) ...[
                          Text(
                            'FATCA incomplete — invest is blocked until Retry succeeds.',
                            style: TextStyle(color: context.marketNegative),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _run(
                                      () => _submitFatca(advanceToBank: false),
                                    ),
                            child: const Text('Retry FATCA'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _BankStep(
                          draft: draft,
                          busy: _busy,
                          onChanged: (d) => ref
                              .read(mfOnboardingDraftProvider.notifier)
                              .patch((_) => d),
                          onSubmit: () => _run(() async {
                            final client = ref.read(mfApiClientProvider);
                            final op = await client.submitBank({
                              'pan': draft.pan.trim().toUpperCase(),
                              'account_no': draft.bankAccountNo.trim(),
                              'ifsc': draft.bankIfsc.trim().toUpperCase(),
                              if (draft.accountType.isNotEmpty)
                                'account_type': draft.accountType,
                              if (draft.clientCode.isNotEmpty)
                                'client_code': draft.clientCode.trim(),
                            });
                            ref
                                .read(mfOnboardingDraftProvider.notifier)
                                .patch(
                                  (d) => d.copyWith(
                                    bankOk: op.ok,
                                    lastMessage: op.message ??
                                        (op.ok
                                            ? 'Bank registered (or already exists)'
                                            : 'Bank failed'),
                                  ),
                                );
                          }),
                        ),
                      ],
                    )
                  : const Text('Complete UCC with ok:true before bank.'),
            ),
          ],
        ),
        if (draft.lastMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            draft.lastMessage!,
            style: TextStyle(
              color: draft.uccOk ||
                      draft.bankOk ||
                      draft.fatcaOk ||
                      draft.ekycOk
                  ? context.marketPositive
                  : context.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _KycStep extends StatelessWidget {
  const _KycStep({
    required this.draft,
    required this.busy,
    required this.onChanged,
    required this.onCheck,
    this.message,
  });

  final MfOnboardingDraft draft;
  final bool busy;
  final String? message;
  final ValueChanged<MfOnboardingDraft> onChanged;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: draft.pan,
          decoration: const InputDecoration(labelText: 'PAN'),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => onChanged(draft.copyWith(pan: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          initialValue: draft.mobile,
          decoration: const InputDecoration(labelText: 'Mobile (optional)'),
          onChanged: (v) => onChanged(draft.copyWith(mobile: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: busy || draft.pan.trim().length < 10 ? null : onCheck,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Check KYC'),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(message!),
        ],
      ],
    );
  }
}

class _EkycStep extends StatelessWidget {
  const _EkycStep({
    required this.draft,
    required this.busy,
    required this.onStart,
    required this.onSkip,
    required this.allowSkip,
    this.message,
  });

  final MfOnboardingDraft draft;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onSkip;
  final bool allowSkip;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Starts NSE eKYC for PAN ${draft.pan.isEmpty ? '(enter on KYC step)' : draft.pan}.',
          style: TextStyle(color: context.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            FilledButton(
              onPressed:
                  busy || draft.pan.trim().length < 10 ? null : onStart,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start eKYC'),
            ),
            if (allowSkip) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: busy ? null : onSkip,
                child: const Text('Skip'),
              ),
            ],
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(message!),
        ],
      ],
    );
  }
}

class _UccFatcaStep extends StatelessWidget {
  const _UccFatcaStep({
    required this.draft,
    required this.busy,
    required this.onChanged,
    required this.onSubmit,
    required this.hideClientCode,
  });

  final MfOnboardingDraft draft;
  final bool busy;
  final bool hideClientCode;
  final ValueChanged<MfOnboardingDraft> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!hideClientCode)
          TextFormField(
            initialValue: draft.clientCode,
            decoration: const InputDecoration(
              labelText: 'Client code (optional dig fixture)',
              helperText: 'Leave blank to auto-generate; dig may use GYAAN*',
            ),
            onChanged: (v) => onChanged(draft.copyWith(clientCode: v)),
          ),
        TextFormField(
          initialValue: draft.name,
          decoration: const InputDecoration(labelText: 'Investor name'),
          onChanged: (v) => onChanged(draft.copyWith(name: v)),
        ),
        TextFormField(
          initialValue: draft.dob,
          decoration: const InputDecoration(
            labelText: 'DOB *',
            helperText: 'DD/MM/YYYY (required)',
          ),
          onChanged: (v) => onChanged(draft.copyWith(dob: v)),
        ),
        TextFormField(
          initialValue: draft.email,
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: (v) => onChanged(draft.copyWith(email: v)),
        ),
        TextFormField(
          initialValue: draft.bankAccountNo,
          decoration: const InputDecoration(labelText: 'Bank account'),
          onChanged: (v) => onChanged(draft.copyWith(bankAccountNo: v)),
        ),
        TextFormField(
          initialValue: draft.bankIfsc,
          decoration: const InputDecoration(labelText: 'IFSC'),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => onChanged(draft.copyWith(bankIfsc: v)),
        ),
        TextFormField(
          initialValue: draft.countryOfBirth,
          decoration: const InputDecoration(
            labelText: 'Country of birth',
            helperText: 'IN only for now',
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => onChanged(draft.copyWith(countryOfBirth: v)),
        ),
        TextFormField(
          initialValue: draft.citizenship,
          decoration: const InputDecoration(
            labelText: 'Tax residency / citizenship',
            helperText: 'IN only for now',
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => onChanged(draft.copyWith(citizenship: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.fatcaAttested,
          onChanged: busy
              ? null
              : (v) =>
                  onChanged(draft.copyWith(fatcaAttested: v ?? false)),
          title: const Text(
            'I confirm I am an India tax resident and agree that '
            'standard resident FATCA defaults may be submitted to the exchange.',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: busy ||
                  draft.pan.trim().length < 10 ||
                  !draft.fatcaAttested
              ? null
              : onSubmit,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit UCC (FATCA auto)'),
        ),
      ],
    );
  }
}

class _BankStep extends StatelessWidget {
  const _BankStep({
    required this.draft,
    required this.busy,
    required this.onChanged,
    required this.onSubmit,
  });

  final MfOnboardingDraft draft;
  final bool busy;
  final ValueChanged<MfOnboardingDraft> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: draft.bankAccountNo,
          decoration: const InputDecoration(labelText: 'Account number'),
          onChanged: (v) => onChanged(draft.copyWith(bankAccountNo: v)),
        ),
        TextFormField(
          initialValue: draft.bankIfsc,
          decoration: const InputDecoration(labelText: 'IFSC'),
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => onChanged(draft.copyWith(bankIfsc: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: busy ||
                  draft.bankAccountNo.trim().isEmpty ||
                  draft.bankIfsc.trim().isEmpty
              ? null
              : onSubmit,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Register bank'),
        ),
      ],
    );
  }
}
