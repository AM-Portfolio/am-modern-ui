import 'package:flutter/material.dart';

class PricingCard extends StatefulWidget {
  final String title;
  final String description;
  final int monthlyPrice;
  final int annualPrice;
  final bool isAnnual;
  final String ctaText;
  final VoidCallback? onCtaPressed;
  final List<String> features;
  final Color primaryColor;
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
    this.primaryColor = const Color(0xFF1B64F2), // Default blue
    this.isPopular = false,
    this.isCustom = false,
    this.isCurrentPlan = false,
  });

  @override
  State<PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<PricingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currentPrice = widget.isAnnual ? (widget.annualPrice / 12).round() : widget.monthlyPrice;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -8.0 : 0.0),
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isCurrentPlan
                ? const Color(0xFF10B981) // Green for active plan
                : (_isHovered 
                    ? widget.primaryColor 
                    : (widget.isPopular ? widget.primaryColor : Colors.grey.shade200)),
            width: (widget.isCurrentPlan || widget.isPopular || _isHovered) ? 2 : 1,
          ),
          boxShadow: [
            if (widget.isCurrentPlan)
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(_isHovered ? 0.25 : 0.15),
                blurRadius: _isHovered ? 25 : 20,
                offset: Offset(0, _isHovered ? 12 : 10),
              )
            else if (_isHovered)
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.18),
                blurRadius: 25,
                offset: const Offset(0, 12),
              )
            else if (widget.isPopular)
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!widget.isCustom) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹$currentPrice',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/mo',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
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
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ] else if (widget.annualPrice == 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Free forever',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 18), // Spacer to match height
                    ]
                  ] else ...[
                    const Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact us for team pricing',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onCtaPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.onCtaPressed == null 
                            ? (widget.isCurrentPlan ? const Color(0xFFE8F5E9) : Colors.grey.shade200) 
                            : widget.primaryColor,
                        foregroundColor: widget.onCtaPressed == null 
                            ? (widget.isCurrentPlan ? const Color(0xFF2E7D32) : Colors.grey.shade500) 
                            : (widget.title == 'Free' ? Colors.black87 : Colors.white),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: widget.title == 'Free' && widget.onCtaPressed != null
                              ? BorderSide(color: Colors.grey.shade300) 
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
                  const SizedBox(height: 32),
                  ...widget.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check,
                          size: 18,
                          color: widget.isCurrentPlan 
                              ? const Color(0xFF10B981) 
                              : (widget.isCustom ? const Color(0xFFE87C00) : (widget.title == 'Premium' ? const Color(0xFFA824EE) : widget.primaryColor)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
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
                      color: const Color(0xFF10B981),
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
                      color: widget.primaryColor,
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
