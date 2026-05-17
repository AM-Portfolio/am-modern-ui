import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'document_processor/document_processor_view.dart';
import 'email_extractor/email_extractor_view.dart';
import '../../services/api_service.dart';

class DocIntelligenceScreen extends StatefulWidget {
  final String userId;
  const DocIntelligenceScreen({super.key, required this.userId});

  @override
  State<DocIntelligenceScreen> createState() => _DocIntelligenceScreenState();
}

class _DocIntelligenceScreenState extends State<DocIntelligenceScreen> {
  String _activeNavItem = 'Doc Processor';

  @override
  Widget build(BuildContext context) {
    return UnifiedSidebarScaffold(
      title: 'Doc Intelligence',
      icon: Icons.psychology_outlined,
      accentColor: Theme.of(context).colorScheme.primary,
      items: [
        SecondarySidebarItem(
          title: 'Doc Processor',
          icon: Icons.description_outlined,
          onTap: () => setState(() => _activeNavItem = 'Doc Processor'),
          isSelected: _activeNavItem == 'Doc Processor',
        ),
        SecondarySidebarItem(
          title: 'Email Extractor',
          icon: Icons.email_outlined,
          onTap: () => setState(() => _activeNavItem = 'Email Extractor'),
          isSelected: _activeNavItem == 'Email Extractor',
        ),
        const SidebarDivider(),
        SecondarySidebarItem(
          title: 'Environment: ${apiProvider.environment == AppEnvironment.local ? "Local" : "Preprod"}',
          icon: apiProvider.environment == AppEnvironment.local ? Icons.lan_outlined : Icons.cloud_outlined,
          onTap: () {
            setState(() {
              apiProvider.environment = apiProvider.environment == AppEnvironment.local 
                  ? AppEnvironment.preprod 
                  : AppEnvironment.local;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Switched to ${apiProvider.environment == AppEnvironment.local ? "Local" : "Preprod"} Backend'),
                behavior: SnackBarBehavior.floating,
                width: 400,
              ),
            );
          },
        ),
      ],
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('${_activeNavItem}_${apiProvider.environment}'),
          child: _activeNavItem == 'Doc Processor'
              ? const DocumentProcessorView()
              : const EmailExtractorView(),
        ),
      ),
    );
  }
}
