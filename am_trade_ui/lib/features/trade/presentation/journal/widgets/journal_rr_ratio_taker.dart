import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/journal_calc_helper.dart';

/// Editable R:R in the old chip style: `R:R: 2 : 1`
///
/// Stored value remains reward÷risk (e.g. `3:2` → `1.5`).
class JournalRrRatioTaker extends StatefulWidget {
  const JournalRrRatioTaker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final double? value;
  final ValueChanged<double> onChanged;

  @override
  State<JournalRrRatioTaker> createState() => _JournalRrRatioTakerState();
}

class _JournalRrRatioTakerState extends State<JournalRrRatioTaker> {
  static const _min = 0.5;
  static const _max = 20.0;

  late final TextEditingController _rewardCtrl;
  late final TextEditingController _riskCtrl;
  late double _reward;
  late double _risk;

  @override
  void initState() {
    super.initState();
    _hydrateFrom(widget.value, syncControllers: false);
    _rewardCtrl =
        TextEditingController(text: JournalCalcHelper.trimRrNumber(_reward));
    _riskCtrl =
        TextEditingController(text: JournalCalcHelper.trimRrNumber(_risk));
  }

  @override
  void didUpdateWidget(covariant JournalRrRatioTaker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final current = _stored;
      final incoming = widget.value;
      if (incoming == null ||
          current == null ||
          (incoming - current).abs() > 0.0001) {
        _hydrateFrom(incoming, syncControllers: true);
      }
    }
  }

  @override
  void dispose() {
    _rewardCtrl.dispose();
    _riskCtrl.dispose();
    super.dispose();
  }

  double? get _stored =>
      _risk == 0 ? null : double.parse((_reward / _risk).toStringAsFixed(6));

  void _hydrateFrom(double? value, {required bool syncControllers}) {
    if (value == null || value <= 0 || value.isNaN || value.isInfinite) {
      _reward = 1.0;
      _risk = 1.0;
    } else {
      _reward = value;
      _risk = 1.0;
    }
    if (syncControllers) {
      _rewardCtrl.text = JournalCalcHelper.trimRrNumber(_reward);
      _riskCtrl.text = JournalCalcHelper.trimRrNumber(_risk);
    }
  }

  void _emit() {
    final stored = _stored;
    if (stored == null || stored <= 0) return;
    widget.onChanged(stored);
  }

  void _commitReward(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) {
      _rewardCtrl.text = JournalCalcHelper.trimRrNumber(_reward);
      return;
    }
    setState(() {
      _reward = parsed.clamp(_min, _max);
      _rewardCtrl.text = JournalCalcHelper.trimRrNumber(_reward);
    });
    _emit();
  }

  void _commitRisk(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) {
      _riskCtrl.text = JournalCalcHelper.trimRrNumber(_risk);
      return;
    }
    setState(() {
      _risk = parsed.clamp(_min, _max);
      _riskCtrl.text = JournalCalcHelper.trimRrNumber(_risk);
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Material(
      color: colors.cardSurface,
      shape: StadiumBorder(
        side: BorderSide(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'R:R:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            _SideField(
              controller: _rewardCtrl,
              onCommit: _commitReward,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                ':',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ),
            _SideField(
              controller: _riskCtrl,
              onCommit: _commitRisk,
            ),
          ],
        ),
      ),
    );
  }
}

class _SideField extends StatelessWidget {
  const _SideField({
    required this.controller,
    required this.onCommit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCommit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 44,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
        ),
        onSubmitted: onCommit,
        onEditingComplete: () => onCommit(controller.text),
        onTapOutside: (_) => onCommit(controller.text),
      ),
    );
  }
}
