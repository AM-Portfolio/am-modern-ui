import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/features/broker_logo.dart';
import 'package:am_doc_intelligence_ui/features/import_holdings_info_rail.dart';
import 'package:am_doc_intelligence_ui/features/nps_password_suggest.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';

/// Canonical source keys for Import holdings (brokers + CDSL + NPS).
const List<ImportBrokerOption> kImportBrokerOptions = [
  ImportBrokerOption(key: 'groww', label: 'Groww'),
  ImportBrokerOption(key: 'zerodha', label: 'Zerodha'),
  ImportBrokerOption(key: 'angelone', label: 'Angel One'),
  ImportBrokerOption(key: 'dhan', label: 'Dhan'),
  ImportBrokerOption(key: 'mstock', label: 'mStock'),
  ImportBrokerOption(key: 'upstox', label: 'Upstox'),
  ImportBrokerOption(key: 'kotak', label: 'Kotak'),
  ImportBrokerOption(key: 'cdsl', label: 'CDSL CAS'),
  ImportBrokerOption(key: 'nps', label: 'NPS'),
];

/// Stable extract order: brokers first, then CDSL, then NPS.
List<String> orderedImportSources(Iterable<String> keys) {
  const tail = ['cdsl', 'nps'];
  final set = keys.map((k) => k.toLowerCase()).toSet();
  final brokers = kImportBrokerOptions
      .map((o) => o.key)
      .where((k) => !tail.contains(k) && set.contains(k))
      .toList();
  final out = <String>[...brokers];
  for (final t in tail) {
    if (set.contains(t)) out.add(t);
  }
  return out;
}

class ImportBrokerOption {
  const ImportBrokerOption({required this.key, required this.label});
  final String key;
  final String label;
}

/// Email-extractor API id for a shared broker key.
String? brokerKeyToEmailId(String? key) {
  if (key == null || key.isEmpty) return null;
  switch (key.toLowerCase()) {
    case 'angelone':
    case 'angel_one':
    case 'angleone':
      return 'angleone';
    case 'groww':
    case 'zerodha':
    case 'dhan':
    case 'mstock':
    case 'upstox':
    case 'kotak':
    case 'cdsl':
    case 'nps':
      return key.toLowerCase();
    default:
      return key.toLowerCase();
  }
}

/// Document-processor broker code for a shared broker key.
String? brokerKeyToDocCode(String? key) {
  if (key == null || key.isEmpty) return null;
  switch (key.toLowerCase()) {
    case 'angelone':
    case 'angel_one':
    case 'angleone':
      return 'ANGEL_ONE';
    case 'groww':
      return 'GROWW';
    case 'zerodha':
      return 'ZERODHA';
    case 'dhan':
      return 'DHAN';
    case 'mstock':
      return 'MSTOCK';
    case 'upstox':
      return 'UPSTOX';
    case 'kotak':
      return 'KOTAK';
    case 'cdsl':
      return 'CDSL';
    case 'nps':
      return 'NPS';
    default:
      return key.toUpperCase();
  }
}

/// Normalize any broker id/code back to a shared key.
String? normalizeBrokerKey(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  switch (raw.toLowerCase().replaceAll('-', '_')) {
    case 'groww':
      return 'groww';
    case 'zerodha':
      return 'zerodha';
    case 'angelone':
    case 'angel_one':
    case 'angleone':
      return 'angelone';
    case 'dhan':
      return 'dhan';
    case 'mstock':
      return 'mstock';
    case 'upstox':
      return 'upstox';
    case 'kotak':
      return 'kotak';
    case 'cdsl':
      return 'cdsl';
    case 'nps':
      return 'nps';
    default:
      final upper = raw.toUpperCase();
      switch (upper) {
        case 'GROWW':
        case 'GROW':
          return 'groww';
        case 'ZERODHA':
          return 'zerodha';
        case 'ANGEL_ONE':
          return 'angelone';
        case 'DHAN':
          return 'dhan';
        case 'MSTOCK':
          return 'mstock';
        case 'UPSTOX':
          return 'upstox';
        case 'KOTAK':
          return 'kotak';
        case 'CDSL':
          return 'cdsl';
        case 'NPS':
          return 'nps';
        default:
          return null;
      }
  }
}

String brokerKeyDisplayName(String? key) {
  final k = normalizeBrokerKey(key);
  if (k == null) return key ?? '';
  for (final o in kImportBrokerOptions) {
    if (o.key == k) return o.label;
  }
  return brokerDisplayName(brokerKeyToDocCode(k) ?? k);
}

/// Default document type when a shared source is selected (upload auto-select).
String? defaultDocTypeForSourceKeys(Iterable<String> keys) {
  final ordered = orderedImportSources(keys);
  if (ordered.isEmpty) return null;
  switch (ordered.first) {
    case 'cdsl':
      return 'MUTUAL_FUND';
    case 'nps':
      return 'NPS_STATEMENT';
    default:
      return null;
  }
}

/// Default document type for a document-processor broker code (CDSL / NPS / …).
String? defaultDocTypeForBrokerCode(String? brokerCode) {
  switch ((brokerCode ?? '').toUpperCase()) {
    case 'CDSL':
      return 'MUTUAL_FUND';
    case 'NPS':
      return 'NPS_STATEMENT';
    default:
      return null;
  }
}

/// Sentinel for optional Auto document type in the shared dropdown.
const String kImportDocTypeAuto = '__AUTO__';

/// Document types supported on Import holdings upload today.
const Set<String> kSupportedImportDocTypes = {
  'STOCK_PORTFOLIO',
  'PORTFOLIO_EQUITY',
  'PORTFOLIO_ETF',
  'MUTUAL_FUND',
  'TRADE_EQ',
  'TRADE_FNO',
  'NPS_STATEMENT',
};

const Set<String> kUnsupportedImportDocTypes = {
  'COMBINE_PORTFOLIO',
  'COMPANY_FINANCIAL_REPORT',
  'NSE_INDICES',
  'TRADE_MF',
  kImportDocTypeAuto,
};

/// Shared multi-select sources + portfolio name + passwords + document type.
class ImportHoldingsSharedControls extends StatefulWidget {
  const ImportHoldingsSharedControls({
    super.key,
    required this.selectedSourceKeys,
    required this.onSourcesChanged,
    required this.portfolioNameController,
    required this.passwordController,
    required this.documentType,
    required this.onDocumentTypeChanged,
    this.npsPasswordController,
    this.passwordRequiredHint = true,
    this.portfolioNameHint = 'Optional — defaults to broker name',
    this.documentTypeOptional = true,
    this.showPassword = true,
    this.showDocumentType = true,
    this.useSimpleDocTypePicker = false,
    this.showNpsPassword,
  });

  final Set<String> selectedSourceKeys;
  final ValueChanged<Set<String>> onSourcesChanged;
  final TextEditingController portfolioNameController;
  final TextEditingController passwordController;
  /// Shown when NPS is among selected sources (DOB / statement password).
  final TextEditingController? npsPasswordController;
  final String? documentType;
  final ValueChanged<String?> onDocumentTypeChanged;
  final bool passwordRequiredHint;
  final String portfolioNameHint;
  final bool documentTypeOptional;
  final bool showPassword;
  final bool showDocumentType;
  final bool useSimpleDocTypePicker;
  /// When non-null, overrides `selectedSourceKeys.contains('nps')` for NPS field.
  final bool? showNpsPassword;

  @override
  State<ImportHoldingsSharedControls> createState() =>
      _ImportHoldingsSharedControlsState();
}

class _ImportHoldingsSharedControlsState
    extends State<ImportHoldingsSharedControls> {
  List<String> _docTypes = const [];
  bool _loadingTypes = true;
  bool _passwordVisible = false;
  bool _npsPasswordVisible = false;
  final TextEditingController _npsFirstNameController = TextEditingController();
  final TextEditingController _npsDobController = TextEditingController();

  bool get _npsSelected =>
      widget.showNpsPassword ?? widget.selectedSourceKeys.contains('nps');

  @override
  void dispose() {
    _npsFirstNameController.dispose();
    _npsDobController.dispose();
    super.dispose();
  }

  void _applyNpsSuggest() {
    final dob = parseNpsDobInput(_npsDobController.text);
    final name = _npsFirstNameController.text.trim();
    if (name.isEmpty || dob == null || widget.npsPasswordController == null) {
      return;
    }
    widget.npsPasswordController!.text = buildNpsStatementPassword(name, dob);
  }

  String? get _primaryKey {
    final ordered = orderedImportSources(widget.selectedSourceKeys);
    return ordered.isEmpty ? null : ordered.first;
  }

  @override
  void initState() {
    super.initState();
    _loadDocTypes();
  }

  Future<void> _loadDocTypes() async {
    try {
      final types = await apiProvider.getSupportedDocumentTypes();
      if (!mounted) return;
      setState(() {
        _docTypes = types;
        _loadingTypes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _docTypes = const [
          'STOCK_PORTFOLIO',
          'MUTUAL_FUND',
          'NPS_STATEMENT',
          'TRADE_EQ',
          'TRADE_FNO',
        ];
        _loadingTypes = false;
      });
    }
  }

  void _toggleSource(String key) {
    final next = Set<String>.from(widget.selectedSourceKeys);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    widget.onSourcesChanged(next);
  }

  List<String> _supportedOnly(Iterable<String> types) => types
      .where((t) =>
          kSupportedImportDocTypes.contains(t) &&
          !kUnsupportedImportDocTypes.contains(t))
      .toList();

  List<String> _filteredDocTypes() {
    final broker = brokerKeyToDocCode(_primaryKey);
    List<String> raw;
    if (broker == null) {
      raw = _docTypes;
    } else {
      switch (broker) {
        case 'ZERODHA':
          raw = _docTypes
              .where((t) =>
                  t == 'STOCK_PORTFOLIO' || t == 'TRADE_EQ' || t == 'TRADE_FNO')
              .toList();
          break;
        case 'GROWW':
          raw = _docTypes
              .where((t) =>
                  t == 'STOCK_PORTFOLIO' ||
                  t == 'MUTUAL_FUND' ||
                  t == 'TRADE_EQ')
              .toList();
          break;
        case 'DHAN':
          final dhan = _docTypes
              .where((t) => t == 'PORTFOLIO_EQUITY' || t == 'PORTFOLIO_ETF')
              .toList();
          raw = dhan.isNotEmpty
              ? dhan
              : const ['PORTFOLIO_EQUITY', 'PORTFOLIO_ETF'];
          break;
        case 'ANGEL_ONE':
          raw = _docTypes
              .where((t) => t == 'STOCK_PORTFOLIO' || t == 'TRADE_EQ')
              .toList();
          if (raw.isEmpty) {
            raw = const ['STOCK_PORTFOLIO', 'TRADE_EQ'];
          }
          break;
        case 'MSTOCK':
          raw = _docTypes
              .where((t) => t == 'STOCK_PORTFOLIO' || t == 'TRADE_EQ')
              .toList();
          break;
        case 'CDSL':
          raw = _docTypes
              .where((t) => t == 'MUTUAL_FUND' || t == 'STOCK_PORTFOLIO')
              .toList();
          if (raw.isEmpty) raw = const ['MUTUAL_FUND', 'STOCK_PORTFOLIO'];
          break;
        case 'NPS':
          raw = _docTypes.where((t) => t == 'NPS_STATEMENT').toList();
          if (raw.isEmpty) raw = const ['NPS_STATEMENT'];
          break;
        default:
          raw = _docTypes;
      }
    }
    final supported = _supportedOnly(raw);
    return supported.isNotEmpty
        ? supported
        : _supportedOnly(kSupportedImportDocTypes);
  }

  String _docTypeLabel(String type) {
    switch (type) {
      case 'COMBINE_PORTFOLIO':
        return 'Combined Portfolio';
      case 'MUTUAL_FUND':
        return 'Mutual Funds / CAS';
      case 'NPS_STATEMENT':
        return 'NPS statement';
      case 'STOCK_PORTFOLIO':
        return 'Equity portfolio';
      case 'PORTFOLIO_EQUITY':
        return 'Equity portfolio';
      case 'PORTFOLIO_ETF':
        return 'ETF portfolio';
      case 'TRADE_EQ':
        return 'Equity trades';
      case 'TRADE_FNO':
        return 'F&O tradebook';
      default:
        return type.split('_').map((w) {
          if (w.isEmpty) return '';
          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
        }).join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final filtered = _filteredDocTypes();
    final currentDoc = widget.documentType != null &&
            filtered.contains(widget.documentType)
        ? widget.documentType
        : null;
    final selectedLabels = orderedImportSources(widget.selectedSourceKeys)
        .map(brokerKeyDisplayName)
        .join(', ');

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sources · tap to multi-select',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: muted,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final brokerCount = kImportBrokerOptions.length;
                final cols = constraints.maxWidth < 360 ? 3 : 4;
                final aspect = constraints.maxWidth < 360 ? 1.3 : 1.45;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: brokerCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: aspect,
                  ),
                  itemBuilder: (context, i) {
                    final opt = kImportBrokerOptions[i];
                    final selected =
                        widget.selectedSourceKeys.contains(opt.key);
                    final logoPath = brokerLogoAsset(opt.key);
                    return Tooltip(
                      message: opt.label,
                      child: Material(
                        color: Colors.white,
                        elevation: selected ? 3 : 0,
                        shadowColor: accent.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => _toggleSource(opt.key),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? accent
                                    : const Color(0xFFE4E7EC),
                                width: selected ? 3 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: logoPath != null
                                ? Image.asset(
                                    logoPath,
                                    package: 'am_doc_intelligence_ui',
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, __, ___) =>
                                        brokerLetterAvatar(
                                      opt.key,
                                      size: 24,
                                      color: accent,
                                    ),
                                  )
                                : brokerLetterAvatar(
                                    opt.key,
                                    size: 24,
                                    color: accent,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: widget.portfolioNameController,
              labelText: 'Portfolio name (optional)',
              hintText: widget.portfolioNameHint,
              focusedBorderColor: accent,
            ),
            if (widget.showPassword) ...[
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: ImportPrivacyInline(),
              ),
              const SizedBox(height: 6),
              AppTextField(
                controller: widget.passwordController,
                labelText: widget.passwordRequiredHint
                    ? 'PAN (Groww · Zerodha · Dhan · CDSL · …)'
                    : 'PAN / PDF password (optional)',
                hintText: '10-character PAN card number',
                obscureText: !_passwordVisible,
                focusedBorderColor: accent,
                suffix: IconButton(
                  tooltip: _passwordVisible ? 'Hide' : 'Show',
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(
                    () => _passwordVisible = !_passwordVisible,
                  ),
                ),
              ),
              if (_npsSelected && widget.npsPasswordController != null) ...[
                const SizedBox(height: 10),
                Text(
                  'NPS unlock = first 4 letters of first name (lowercase; '
                  'pad with 9s) + DOB as DDMM. Example: Om + 01/11/1975 → 99om0111',
                  style: TextStyle(fontSize: 11, color: muted, height: 1.35),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _npsFirstNameController,
                        labelText: 'First name',
                        hintText: 'As on CRA',
                        focusedBorderColor: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _npsDobController,
                        labelText: 'DOB',
                        hintText: 'DD/MM/YYYY',
                        focusedBorderColor: accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Suggest NPS password',
                      onPressed: _applyNpsSuggest,
                      icon: Icon(Icons.auto_awesome, color: accent),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: widget.npsPasswordController!,
                  labelText: 'NPS password (required)',
                  hintText: 'e.g. 99om0111',
                  obscureText: !_npsPasswordVisible,
                  focusedBorderColor: accent,
                  suffix: IconButton(
                    tooltip: _npsPasswordVisible ? 'Hide' : 'Show',
                    icon: Icon(
                      _npsPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () => setState(
                      () => _npsPasswordVisible = !_npsPasswordVisible,
                    ),
                  ),
                ),
              ],
            ],
            if (widget.showDocumentType) ...[
              const SizedBox(height: 10),
              Text(
                widget.documentTypeOptional
                    ? 'Document type · Optional'
                    : 'Document type · Required',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: muted,
                ),
              ),
              const SizedBox(height: 6),
              if (_loadingTypes)
                const ShimmerLoading(
                  child: SkeletonBox(height: 40, width: double.infinity),
                )
              else if (widget.useSimpleDocTypePicker)
                _buildDocTypeChips(
                  accent: accent,
                  filtered: filtered,
                  currentDoc: currentDoc,
                )
              else
                CustomDropdown<String>(
                  height: 40,
                  primaryColor: accent,
                  value: currentDoc,
                  items: filtered
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            _docTypeLabel(e),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  hint: widget.documentTypeOptional
                      ? 'Select type (optional)'
                      : 'Select document type',
                  onChanged: (v) => widget.onDocumentTypeChanged(v),
                ),
            ],
            if (widget.selectedSourceKeys.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Selected · $selectedLabels',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocTypeChips({
    required Color accent,
    required List<String> filtered,
    required String? currentDoc,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in filtered)
          ChoiceChip(
            label: Text(_docTypeLabel(e)),
            selected: currentDoc == e,
            selectedColor: accent.withValues(alpha: 0.28),
            checkmarkColor: accent,
            labelStyle: TextStyle(
              color: currentDoc == e ? accent : null,
              fontWeight: currentDoc == e ? FontWeight.w700 : FontWeight.w500,
            ),
            side: BorderSide(
              color: currentDoc == e
                  ? accent
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            onSelected: (on) {
              if (on) {
                widget.onDocumentTypeChanged(e);
              } else if (widget.documentTypeOptional) {
                widget.onDocumentTypeChanged(null);
              }
            },
          ),
      ],
    );
  }
}
