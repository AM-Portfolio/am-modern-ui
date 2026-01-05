import 'package:flutter/material.dart';
import '../display/interactive_background.dart';

class ThemeSelector extends StatelessWidget {
  final BackgroundTheme currentTheme;
  final Function(BackgroundTheme) onThemeChanged;

  const ThemeSelector({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(context, BackgroundTheme.nebula, Icons.bubble_chart, 'Nebula'),
          Container(width: 1, height: 20, color: Colors.white24),
          _buildOption(context, BackgroundTheme.market, Icons.candlestick_chart, 'Market'),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, BackgroundTheme theme, IconData icon, String label) {
    final isSelected = currentTheme == theme;
    return _HoverableOption(
      isSelected: isSelected,
      icon: icon,
      label: label,
      onTap: () => onThemeChanged(theme),
    );
  }
}

class _HoverableOption extends StatefulWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HoverableOption({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_HoverableOption> createState() => _HoverableOptionState();
}

class _HoverableOptionState extends State<_HoverableOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered || widget.isSelected ? 1.1 : 1.0),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             decoration: BoxDecoration(
               color: _isHovered ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
               borderRadius: BorderRadius.circular(30),
             ),
             child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isSelected ? Theme.of(context).primaryColor : Colors.white70,
                ),
                if (widget.isSelected) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

}
