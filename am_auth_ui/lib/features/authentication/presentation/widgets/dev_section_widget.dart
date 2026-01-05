import 'package:flutter/material.dart';
import 'demo_login_button_widget.dart';
import 'feature_flag_panel_widget.dart';

/// Collapsible developer section containing Demo Login and Developer Controls
/// Hidden by default to keep production UI clean
class DevSectionWidget extends StatefulWidget {
  final bool isCompact;
  
  const DevSectionWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  State<DevSectionWidget> createState() => _DevSectionWidgetState();
}

class _DevSectionWidgetState extends State<DevSectionWidget> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle button
        TextButton.icon(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 16,
            color: Colors.grey,
          ),
          label: Text(
            'Developer Options',
            style: TextStyle(
              fontSize: widget.isCompact ? 11 : 12,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        
        // Collapsible content with animation
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Column(
                  children: [
                    SizedBox(height: widget.isCompact ? 12 : 16),
                    
                    // Demo Login Button
                    const DemoLoginButtonWidget(),
                    
                    SizedBox(height: widget.isCompact ? 12 : 16),
                    
                    // Developer Controls Panel
                    const FeatureFlagPanelWidget(),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
