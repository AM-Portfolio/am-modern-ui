import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import '../../../internal/domain/entities/portfolio_list.dart';

class PortfolioFormModal extends StatefulWidget {
  const PortfolioFormModal({super.key, this.portfolio, required this.onSubmit});

  final PortfolioItem? portfolio;
  final Future<void> Function(String name, String? description) onSubmit;

  static Future<void> show({
    required BuildContext context,
    PortfolioItem? portfolio,
    required Future<void> Function(String name, String? description) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          PortfolioFormModal(portfolio: portfolio, onSubmit: onSubmit),
    );
  }

  @override
  State<PortfolioFormModal> createState() => _PortfolioFormModalState();
}

class _PortfolioFormModalState extends State<PortfolioFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.portfolio?.portfolioName ?? '',
    );
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Portfolio name is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(name, _descController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? errorText,
  }) {
    final accent = ModuleColors.portfolio;
    final radius = BorderRadius.circular(12);
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      floatingLabelStyle: TextStyle(color: accent),
      labelStyle: TextStyle(color: context.textSecondary),
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: context.statusError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: context.statusError, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.portfolio != null;
    final accent = ModuleColors.portfolio;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // Global bottom nav chrome (~70) sits above the home indicator.
    const navChrome = 70.0;

    return ValueListenableBuilder<double>(
      valueListenable: GlobalBottomNavVisibility.factor,
      builder: (context, navFactor, _) {
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        // When nav is visible, lift Save Changes above it; when hidden, sit on
        // the safe bottom inset only.
        final bottomPad =
            keyboard + safeBottom + (navChrome * navFactor.clamp(0.0, 1.0));

        return Container(
          padding: EdgeInsets.only(bottom: bottomPad),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Portfolio' : 'Create Portfolio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    cursorColor: accent,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _fieldDecoration(
                      label: 'Portfolio Name',
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    cursorColor: accent,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _fieldDecoration(
                      label: 'Description (Optional)',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: context.colors.actionPrimaryFg,
                        disabledBackgroundColor:
                            accent.withValues(alpha: 0.45),
                        overlayColor: accent.withValues(alpha: 0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: context.colors.actionPrimaryFg,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEdit ? 'Save Changes' : 'Create',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.colors.actionPrimaryFg,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
