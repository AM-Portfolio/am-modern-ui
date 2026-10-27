import 'package:flutter/material.dart';

import 'journal_themed_dropdown.dart';
import 'journal_workflow_field_theme.dart';

const String kJournalCustomPreset = '__custom__';

/// Dropdown of common presets with an optional free-text "Custom…" path.
/// Matches [JournalThemedDropdown] / filter-bar density for journal forms.
class JournalPresetOrCustomField extends StatefulWidget {
  const JournalPresetOrCustomField({
    super.key,
    required this.label,
    required this.presets,
    required this.value,
    required this.onChanged,
    this.hint,
    this.customHint = 'Type your own…',
    this.height = 48,
  });

  final String label;
  final List<String> presets;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final String customHint;
  final double height;

  @override
  State<JournalPresetOrCustomField> createState() =>
      _JournalPresetOrCustomFieldState();
}

class _JournalPresetOrCustomFieldState
    extends State<JournalPresetOrCustomField> {
  late final TextEditingController _custom;
  var _forceCustom = false;

  @override
  void initState() {
    super.initState();
    final v = widget.value?.trim() ?? '';
    _forceCustom = v.isNotEmpty && !_isPreset(v);
    _custom = TextEditingController(text: _forceCustom ? v : '');
  }

  @override
  void didUpdateWidget(covariant JournalPresetOrCustomField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final v = widget.value?.trim() ?? '';
    if ((_forceCustom || (v.isNotEmpty && !_isPreset(v))) &&
        _custom.text != v) {
      _custom.text = v;
    }
    if (v.isNotEmpty && !_isPreset(v)) {
      _forceCustom = true;
    } else if (_isPreset(v)) {
      _forceCustom = false;
    }
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  bool _isPreset(String v) =>
      widget.presets.any((p) => p.toLowerCase() == v.toLowerCase());

  String? get _dropdownValue {
    final v = widget.value?.trim() ?? '';
    if (_forceCustom) return kJournalCustomPreset;
    if (v.isEmpty) return null;
    for (final p in widget.presets) {
      if (p.toLowerCase() == v.toLowerCase()) return p;
    }
    return kJournalCustomPreset;
  }

  @override
  Widget build(BuildContext context) {
    final showCustom = _dropdownValue == kJournalCustomPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JournalThemedDropdown<String>(
          label: widget.label,
          value: _dropdownValue,
          hint: widget.hint ?? 'Select…',
          height: widget.height,
          fontSize: 15,
          items: [
            ...widget.presets.map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(p, overflow: TextOverflow.ellipsis),
              ),
            ),
            const DropdownMenuItem(
              value: kJournalCustomPreset,
              child: Text('Custom…'),
            ),
          ],
          onChanged: (v) {
            if (v == null) {
              setState(() => _forceCustom = false);
              _custom.clear();
              widget.onChanged(null);
              return;
            }
            if (v == kJournalCustomPreset) {
              setState(() => _forceCustom = true);
              final existing = widget.value?.trim() ?? '';
              if (existing.isNotEmpty && !_isPreset(existing)) {
                _custom.text = existing;
              }
              widget.onChanged(
                _custom.text.trim().isEmpty ? null : _custom.text.trim(),
              );
              return;
            }
            setState(() => _forceCustom = false);
            _custom.clear();
            widget.onChanged(v);
          },
        ),
        if (showCustom) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _custom,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: journalWorkflowDecoration(
              context,
              label: 'Custom ${widget.label.toLowerCase()}',
              hintText: widget.customHint,
            ),
            onChanged: (t) {
              final trimmed = t.trim();
              widget.onChanged(trimmed.isEmpty ? null : trimmed);
            },
          ),
        ],
      ],
    );
  }
}

/// Common Pre-Trade presets for the journal hub.
abstract final class JournalPreTradePresets {
  static const strategies = <String>[
    'Breakout',
    'Pullback',
    'Trend following',
    'Mean reversion',
    'Scalping',
    'Swing',
    'Momentum',
    'Range / sideways',
  ];

  static const setups = <String>[
    'S/R breakout',
    'Pullback to MA / VWAP',
    'Opening range breakout',
    'Gap fill',
    'Flag / consolidation',
    'Reversal at key level',
    'News / event',
    'Supply / demand zone',
  ];

  static const marketContexts = <String>[
    'Strong uptrend',
    'Strong downtrend',
    'Range-bound',
    'High volatility',
    'Quiet / low volume',
    'News / event day',
    'Pre-market / open',
    'Late session',
  ];

  static const brokers = <String>[
    'Zerodha',
    'Groww',
    'Angel One',
    'Upstox',
    'Dhan',
    'Fyers',
    'Paper / Simulator',
  ];

  static const orderTypes = <String>[
    'Market',
    'Limit',
    'SL',
    'SL-M',
    'Bracket / Cover',
  ];
}
