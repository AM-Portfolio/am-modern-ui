import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class PricingCard extends StatefulWidget {
  final String title;
  final String description;
  final int monthlyPrice;
  final int annualPrice;
  final bool isAnnual;
  final String ctaText;
  final VoidCallback? onCtaPressed;
  final List<String> features;
  final Color? primaryColor;
  final bool isPopular;
  final bool isCustom;
  final bool isCurrentPlan;

  const PricingCard({
    super.key,
    required this.title,
    required this.description,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.isAnnual,
    required this.ctaText,
    required this.onCtaPressed,
    required this.features,
    this.primaryColor,
    this.isPopular = false,
    this.isCustom = false,
    this.isCurrentPlan = false,
  });

  @override
  State<PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<PricingCard> {
  bool _isHovered = false;

  Color get _primary =>
      widget.primaryColor ?? context.premiumAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final currentPrice = widget.isAnnual ? (widget.annualPrice / 12).round() : widget.monthlyPrice;
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -8.0 : 0.0),
        width: 280,
        margin: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: isMobile ? 10 : 20,
        ),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isCurrentPlan
                ? context.statusSuccess // Green for active plan
                : (_isHovered 
                    ? _primary 
                    : (widget.isPopular ? _primary : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200))),
            width: (widget.isCurrentPlan || widget.isPopular || _isHovered) ? 2 : 1,
          ),
          boxShadow: [
            if (widget.isCurrentPlan)
              BoxShadow(
                color: context.statusSuccess.withOpacity(_isHovered ? 0.25 : 0.15),
                blurRadius: _isHovered ? 25 : 20,
                offset: Offset(0, _isHovered ? 12 : 10),
              )
            else if (_isHovered)
              BoxShadow(
                color: _primary.withOpacity(isDark ? 0.25 : 0.18),
                blurRadius: 25,
                offset: const Offset(0, 12),
              )
            else if (widget.isPopular)
              BoxShadow(
                color: _primary.withOpacity(isDark ? 0.15 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.all(isMobile ? 18.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  if (!widget.isCustom) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹$currentPrice',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/mo',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (widget.isAnnual && widget.annualPrice > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Billed annually (₹${widget.annualPrice}/yr)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                        ),
                      ),
                    ] else if (widget.annualPrice == 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Free forever',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 18), // Spacer to match height
                    ]
                  ] else ...[
                    Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact us for team pricing',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                  SizedBox(height: isMobile ? 16 : 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onCtaPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.onCtaPressed == null 
                            ? (widget.isCurrentPlan ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9)) : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200)) 
                            : _primary,
                        foregroundColor: widget.onCtaPressed == null 
                            ? (widget.isCurrentPlan ? (isDark ? const Color(0xFF34D399) : const Color(0xFF2E7D32)) : (isDark ? Colors.white38 : Colors.grey.shade500)) 
                            : (widget.title == 'Free' ? (isDark ? Colors.white : Colors.black87) : Colors.white),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: widget.title == 'Free' && widget.onCtaPressed != null
                              ? BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300) 
                              : BorderSide.none,
                        ),
                      ),
                      child: Text(
                        widget.ctaText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 32),
                  ...widget.features.map((feature) => Padding(
                    padding: EdgeInsets.only(bottom: isMobile ? 8.0 : 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check,
                          size: 18,
                          color: widget.isCurrentPlan 
                              ? context.statusSuccess 
                              : (widget.isCustom ? context.promotionalHighlight : (widget.title == 'Premium' ? AppColors.primary : _primary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            if (widget.isCurrentPlan)
              Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.statusSuccess,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE PLAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              )
            else if (widget.isPopular)
              Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
