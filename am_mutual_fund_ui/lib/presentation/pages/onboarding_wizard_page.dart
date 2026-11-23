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
  String? _kycMessage;
  String? _ekycMessage;

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

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(mfOnboardingDraftProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MfPageHeader(
          title: 'Investor onboarding',
          subtitle:
              'Asrax login ≠ NSE client. UCC binds PAN to your user. '
              'Stop unless UCC returns ok:true. Dig UAT may block eKYC — that is a business outcome.',
          trailing: draft.uccOk
              ? const MfStatusChip(status: 'ok')
              : null,
        ),
        Stepper(
          currentStep: _step,
          onStepTapped: (i) {
            // UCC is step 2; block FATCA/Bank until UCC ok.
            if (i > 2 && !draft.uccOk) return;
            setState(() => _step = i);
          },
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: [
            Step(
              title: const Text('KYC check'),
              isActive: _step == 0,
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
                  // UAT often returns NOT AVAILABLE and still allows UCC — advance either way.
                  if (!mounted) return;
                  setState(() {
                    _kycMessage =
                        op.message ?? (op.ok ? 'KYC ok' : 'KYC checked');
                    _step = 1;
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
                onStart: () => _run(() async {
                  final client = ref.read(mfApiClientProvider);
                  final op = await client.startEkyc(pan: draft.pan);
                  final msg = op.message ??
                      (op.ok
                          ? 'eKYC started'
                          : 'eKYC not available (common on dig UAT)');
                  if (!mounted) return;
                  setState(() {
                    _ekycMessage = msg;
                    _step = 2;
                  });
                  ref.read(mfOnboardingDraftProvider.notifier).patch(
                        (d) => d.copyWith(
                          ekycOk: op.ok,
                          lastMessage: msg,
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
              title: const Text('UCC'),
              isActive: _step == 2,
              state: draft.uccOk ? StepState.complete : StepState.indexed,
              content: _UccStep(
                draft: draft,
                busy: _busy,
                onChanged: (d) =>
                    ref.read(mfOnboardingDraftProvider.notifier).patch((_) => d),
                onSubmit: () => _run(() async {
                  final client = ref.read(mfApiClientProvider);
                  final op = await client.submitUcc({
                    'pan': draft.pan.trim().toUpperCase(),
                    if (draft.clientCode.isNotEmpty)
                      'client_code': draft.clientCode.trim(),
                    if (draft.name.isNotEmpty) 'name': draft.name.trim(),
                    if (draft.dob.isNotEmpty) 'dob': draft.dob.trim(),
                    if (draft.email.isNotEmpty) 'email': draft.email.trim(),
                    if (draft.mobile.isNotEmpty) 'mobile': draft.mobile.trim(),
                    if (draft.bankAccountNo.isNotEmpty)
                      'bank_account_no': draft.bankAccountNo.trim(),
                    if (draft.bankIfsc.isNotEmpty)
                      'bank_ifsc': draft.bankIfsc.trim().toUpperCase(),
                    if (draft.accountType.isNotEmpty)
                      'account_type': draft.accountType,
                  });
                  ref.read(mfOnboardingDraftProvider.notifier).patch(
                        (d) => d.copyWith(
                          uccOk: op.ok,
                          lastMessage: op.message ??
                              (op.ok ? 'UCC ok' : 'UCC failed — stop here'),
                        ),
                      );
                  if (op.ok && mounted) setState(() => _step = 3);
                }),
              ),
            ),
            Step(
              title: const Text('FATCA'),
              isActive: _step == 3,
              state: !draft.uccOk
                  ? StepState.disabled
                  : draft.fatcaOk
                      ? StepState.complete
                      : StepState.indexed,
              content: draft.uccOk
                  ? _SimpleActionStep(
                      busy: _busy,
                      label: 'Submit FATCA',
                      hint: 'Uses the PAN bound in UCC.',
                      onSubmit: () => _run(() async {
                        final client = ref.read(mfApiClientProvider);
                        final op = await client.submitFatca({
                          'pan': draft.pan.trim().toUpperCase(),
                          if (draft.name.isNotEmpty) 'name': draft.name.trim(),
                        });
                        ref.read(mfOnboardingDraftProvider.notifier).patch(
                              (d) => d.copyWith(
                                fatcaOk: op.ok,
                                lastMessage: op.message,
                              ),
                            );
                        if (op.ok && mounted) setState(() => _step = 4);
                      }),
                    )
                  : const Text('Complete UCC with ok:true before FATCA.'),
            ),
            Step(
              title: const Text('Bank'),
              isActive: _step == 4,
              state: !draft.uccOk
                  ? StepState.disabled
                  : draft.bankOk
                      ? StepState.complete
                      : StepState.indexed,
              content: draft.uccOk
                  ? _BankStep(
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
                        ref.read(mfOnboardingDraftProvider.notifier).patch(
                              (d) => d.copyWith(
                                bankOk: op.ok,
                                lastMessage: op.message ??
                                    (op.ok
                                        ? 'Bank registered (or already exists)'
                                        : 'Bank failed'),
                              ),
                            );
                      }),
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
    this.message,
  });

  final MfOnboardingDraft draft;
  final bool busy;
  final String? message;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Starts NSE eKYC for PAN ${draft.pan.isEmpty ? '(enter on KYC step)' : draft.pan}. '
          'UAT often returns a business fail — surface the message and continue.',
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
            const SizedBox(width: 8),
            TextButton(
              onPressed: busy ? null : onSkip,
              child: const Text('Skip'),
            ),
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

class _UccStep extends StatelessWidget {
  const _UccStep({
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
          initialValue: draft.clientCode,
          decoration: const InputDecoration(
            labelText: 'Client code (NSE UCC)',
            helperText: 'Desk fixture e.g. GYAAN001 — not your Keycloak user',
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
            labelText: 'DOB',
            helperText: 'DD/MM/YYYY',
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
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: busy || draft.pan.trim().length < 10 ? null : onSubmit,
          child: const Text('Submit UCC'),
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
          onChanged: (v) => onChanged(draft.copyWith(bankIfsc: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: busy ||
                  draft.bankAccountNo.isEmpty ||
                  draft.bankIfsc.isEmpty
              ? null
              : onSubmit,
          child: const Text('Register bank'),
        ),
      ],
    );
  }
}

class _SimpleActionStep extends StatelessWidget {
  const _SimpleActionStep({
    required this.busy,
    required this.label,
    required this.hint,
    required this.onSubmit,
  });

  final bool busy;
  final String label;
  final String hint;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: TextStyle(color: context.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: busy ? null : onSubmit, child: Text(label)),
      ],
    );
  }
}
