import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/features/broker_logo.dart';
import 'package:am_doc_intelligence_ui/features/import_holdings_info_rail.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';

/// Canonical broker keys for the shared Import holdings icon row.
const List<ImportBrokerOption> kImportBrokerOptions = [
  ImportBrokerOption(key: 'groww', label: 'Groww'),
  ImportBrokerOption(key: 'zerodha', label: 'Zerodha'),
  ImportBrokerOption(key: 'angelone', label: 'Angel One'),
  ImportBrokerOption(key: 'dhan', label: 'Dhan'),
  ImportBrokerOption(key: 'mstock', label: 'mStock'),
];

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
        default:
          return null;
      }
  }
}

String brokerKeyDisplayName(String? key) {
  final k = normalizeBrokerKey(key);
  if (k == null) return key ?? '';
  return brokerDisplayName(brokerKeyToDocCode(k) ?? k);
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
};

const Set<String> kUnsupportedImportDocTypes = {
  'COMBINE_PORTFOLIO',
  'NPS_STATEMENT',
  'COMPANY_FINANCIAL_REPORT',
  'NSE_INDICES',
  'TRADE_MF',
  kImportDocTypeAuto,
};

/// Shared broker icons + portfolio name + password + document type.
class ImportHoldingsSharedControls extends StatefulWidget {
  const ImportHoldingsSharedControls({
    super.key,
    required this.selectedBrokerKey,
    required this.onBrokerSelected,
    required this.portfolioNameController,
    required this.passwordController,
    required this.documentType,
    required this.onDocumentTypeChanged,
    this.passwordRequiredHint = true,
    this.portfolioNameHint = 'Optional — defaults to broker name',
    this.documentTypeOptional = true,
    this.showPassword = true,
    this.showDocumentType = true,
    this.useSimpleDocTypePicker = false,
  });

  final String? selectedBrokerKey;
  final ValueChanged<String> onBrokerSelected;
  final TextEditingController portfolioNameController;
  final TextEditingController passwordController;
  final String? documentType;
  final ValueChanged<String?> onDocumentTypeChanged;
  final bool passwordRequiredHint;
  final String portfolioNameHint;
  final bool documentTypeOptional;
  final bool showPassword;
  final bool showDocumentType;
  /// Chip / wrap picker — avoids overlay width crashes on wide fields.
  final bool useSimpleDocTypePicker;

  @override
  State<ImportHoldingsSharedControls> createState() =>
      _ImportHoldingsSharedControlsState();
}

class _ImportHoldingsSharedControlsState
    extends State<ImportHoldingsSharedControls> {
  List<String> _docTypes = const [];
  bool _loadingTypes = true;
  bool _passwordVisible = false;

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
          'COMBINE_PORTFOLIO',
          'TRADE_EQ',
          'TRADE_FNO',
        ];
        _loadingTypes = false;
      });
    }
  }

  List<String> _supportedOnly(Iterable<String> types) => types
      .where((t) =>
          kSupportedImportDocTypes.contains(t) &&
          !kUnsupportedImportDocTypes.contains(t))
      .toList();

  List<String> _filteredDocTypes() {
    final broker = brokerKeyToDocCode(widget.selectedBrokerKey);
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

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Broker',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: muted,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth < 360
                    ? 3
                    : (constraints.maxWidth < 520 ? 4 : 5);
                // Narrow widths: slightly wider-than-tall tiles to avoid tall
                // empty row gaps when the 5th broker wraps.
                final aspect = constraints.maxWidth < 520 ? 1.35 : 1.15;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kImportBrokerOptions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: aspect,
                  ),
                  itemBuilder: (context, i) {
                    final opt = kImportBrokerOptions[i];
                    final selected = widget.selectedBrokerKey == opt.key;
                    final logoPath = brokerLogoAsset(opt.key);
                    return Tooltip(
                      message: opt.label,
                      child: Material(
                        color: Colors.white,
                        elevation: selected ? 3 : 0,
                        shadowColor: accent.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => widget.onBrokerSelected(opt.key),
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
                            padding: const EdgeInsets.all(8),
                            child: logoPath != null
                                ? Image.asset(
                                    logoPath,
                                    package: 'am_doc_intelligence_ui',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        brokerLetterAvatar(
                                      opt.key,
                                      size: 28,
                                      color: accent,
                                    ),
                                  )
                                : brokerLetterAvatar(
                                    opt.key,
                                    size: 28,
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
                    ? 'PDF / file password (required)'
                    : 'PDF / file password (optional)',
                hintText: 'PAN / PDF password',
                obscureText: !_passwordVisible,
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
            if (widget.selectedBrokerKey != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected · ${brokerKeyDisplayName(widget.selectedBrokerKey)}',
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
              // Required mode: keep selection (no deselect to empty).
            },
          ),
      ],
    );
  }
}
