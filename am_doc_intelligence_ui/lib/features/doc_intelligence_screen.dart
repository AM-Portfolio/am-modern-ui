import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_doc_intelligence_ui/features/document_processor/document_processor_view.dart';
import 'package:am_doc_intelligence_ui/features/email_extractor/email_extractor_view.dart';
import 'package:am_doc_intelligence_ui/services/api_service.dart';

class DocIntelligenceScreen extends StatefulWidget {
  const DocIntelligenceScreen({
    required this.userId,
    this.initialTab = 'doc-processor',
    this.onTabChanged,
    super.key,
  });

  final String userId;
  final String initialTab;
  final ValueChanged<String>? onTabChanged;

  @override
  State<DocIntelligenceScreen> createState() => _DocIntelligenceScreenState();
}

class _DocIntelligenceScreenState extends State<DocIntelligenceScreen> {
  late String _activeSlug;

  static const _slugToTitle = {
    'doc-processor': 'Doc Processor',
    'email-extractor': 'Email Extractor',
  };

  @override
  void initState() {
    super.initState();
    _activeSlug = _slugToTitle.containsKey(widget.initialTab)
        ? widget.initialTab
        : 'doc-processor';
  }

  @override
  void didUpdateWidget(covariant DocIntelligenceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        _slugToTitle.containsKey(widget.initialTab) &&
        widget.initialTab != _activeSlug) {
      setState(() => _activeSlug = widget.initialTab);
    }
  }

  void _selectTab(String slug) {
    if (_activeSlug == slug) return;
    setState(() => _activeSlug = slug);
    widget.onTabChanged?.call(slug);
  }

  @override
  Widget build(BuildContext context) {
    final title = _slugToTitle[_activeSlug] ?? 'Doc Processor';

    return UnifiedSidebarScaffold(
      title: 'Doc Intelligence',
      icon: Icons.psychology_outlined,
      accentColor: Theme.of(context).colorScheme.primary,
      autoHideMobileTabsOnScroll: true,
      items: [
        SecondarySidebarItem(
          title: 'Doc Processor',
          icon: Icons.description_outlined,
          onTap: () => _selectTab('doc-processor'),
          isSelected: _activeSlug == 'doc-processor',
        ),
        SecondarySidebarItem(
          title: 'Email Extractor',
          icon: Icons.email_outlined,
          onTap: () => _selectTab('email-extractor'),
          isSelected: _activeSlug == 'email-extractor',
        ),
      ],
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('${title}_${apiProvider.environment}'),
          child: _activeSlug == 'doc-processor'
              ? const DocumentProcessorView()
              : const EmailExtractorView(),
        ),
      ),
    );
  }
}
