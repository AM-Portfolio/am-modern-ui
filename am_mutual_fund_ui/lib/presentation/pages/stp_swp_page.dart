import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/mf_providers.dart';
import '../widgets/mf_page_header.dart';

class MfStpSwpPage extends ConsumerStatefulWidget {
  const MfStpSwpPage({this.initialIsin, super.key});

  final String? initialIsin;

  @override
  ConsumerState<MfStpSwpPage> createState() => _MfStpSwpPageState();
}

class _MfStpSwpPageState extends ConsumerState<MfStpSwpPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _from;
  late final TextEditingController _to;
  late final TextEditingController _scheme;
  late final TextEditingController _amount;
  late final TextEditingController _dates;
  late final TextEditingController _folio;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _from = TextEditingController(text: widget.initialIsin ?? 'INF579M01AV5');
    _to = TextEditingController(text: 'INF579M01AW3');
    _scheme = TextEditingController(text: widget.initialIsin ?? 'INF579M01AV5');
    _amount = TextEditingController(text: '1000');
    _dates = TextEditingController(text: '15/12/2026');
    _folio = TextEditingController();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _from.dispose();
    _to.dispose();
    _scheme.dispose();
    _amount.dispose();
    _dates.dispose();
    _folio.dispose();
    super.dispose();
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
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const MfPageHeader(
          title: 'STP / SWP',
          subtitle:
              'Systematic transfer and withdrawal via NSE desk product APIs.',
        ),
        const SizedBox(height: AppSpacing.md),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'STP'),
            Tab(text: 'SWP'),
          ],
        ),
        SizedBox(
          height: 360,
          child: TabBarView(
            controller: _tabs,
            children: [
              _StpForm(
                from: _from,
                to: _to,
                amount: _amount,
                dates: _dates,
                busy: _busy,
                onSubmit: () => _run(() async {
                  final amt = double.tryParse(_amount.text.trim());
                  if (amt == null || amt <= 0) {
                    setState(() => _message = 'Enter a positive amount');
                    return;
                  }
                  final op = await ref.read(mfApiClientProvider).registerStp(
                        fromSchemeId: _from.text.trim(),
                        toSchemeId: _to.text.trim(),
                        amount: amt,
                        dates: _dates.text.trim(),
                      );
                  if (!mounted) return;
                  setState(() {
                    _message =
                        'STP ok=${op.ok} · ${op.message ?? op.ref ?? ''}';
                  });
                }),
              ),
              _SwpForm(
                scheme: _scheme,
                amount: _amount,
                dates: _dates,
                folio: _folio,
                busy: _busy,
                onSubmit: () => _run(() async {
                  final amt = double.tryParse(_amount.text.trim());
                  if (amt == null || amt <= 0) {
                    setState(() => _message = 'Enter a positive amount');
                    return;
                  }
                  final op = await ref.read(mfApiClientProvider).registerSwp(
                        schemeId: _scheme.text.trim(),
                        amount: amt,
                        dates: _dates.text.trim(),
                        folio: _folio.text.trim().isEmpty
                            ? null
                            : _folio.text.trim(),
                      );
                  if (!mounted) return;
                  setState(() {
                    _message =
                        'SWP ok=${op.ok} · ${op.message ?? op.ref ?? ''}';
                  });
                }),
              ),
            ],
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_message!, style: TextStyle(color: context.textPrimary)),
        ],
      ],
    );
  }
}

class _StpForm extends StatelessWidget {
  const _StpForm({
    required this.from,
    required this.to,
    required this.amount,
    required this.dates,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController from;
  final TextEditingController to;
  final TextEditingController amount;
  final TextEditingController dates;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        TextField(
          controller: from,
          decoration: const InputDecoration(labelText: 'From ISIN'),
        ),
        TextField(
          controller: to,
          decoration: const InputDecoration(labelText: 'To ISIN'),
        ),
        TextField(
          controller: amount,
          decoration: const InputDecoration(labelText: 'Amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: dates,
          decoration: const InputDecoration(labelText: 'Start date DD/MM/YYYY'),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: const Text('Register STP'),
        ),
      ],
    );
  }
}

class _SwpForm extends StatelessWidget {
  const _SwpForm({
    required this.scheme,
    required this.amount,
    required this.dates,
    required this.folio,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController scheme;
  final TextEditingController amount;
  final TextEditingController dates;
  final TextEditingController folio;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        TextField(
          controller: scheme,
          decoration: const InputDecoration(labelText: 'Scheme ISIN'),
        ),
        TextField(
          controller: amount,
          decoration: const InputDecoration(labelText: 'Amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: dates,
          decoration: const InputDecoration(labelText: 'Start date DD/MM/YYYY'),
        ),
        TextField(
          controller: folio,
          decoration: const InputDecoration(labelText: 'Folio (optional)'),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: const Text('Register SWP'),
        ),
      ],
    );
  }
}
