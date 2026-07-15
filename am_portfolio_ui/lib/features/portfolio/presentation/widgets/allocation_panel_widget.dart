import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../internal/domain/entities/portfolio_analytics.dart';
import '../../internal/domain/entities/portfolio_holding.dart';

class AllocationPanelWidget extends StatefulWidget {
  const AllocationPanelWidget({
    super.key,
    this.sectorAllocation,
    this.marketCapAllocation,
    this.holdings,
    this.isLoading = false,
    this.error,
  });
  final SectorAllocation? sectorAllocation;
  final MarketCapAllocation? marketCapAllocation;
  final List<PortfolioHolding>? holdings;
  final bool isLoading;
  final String? error;

  @override
  State<AllocationPanelWidget> createState() => _AllocationPanelWidgetState();
}

class _AllocationPanelWidgetState extends State<AllocationPanelWidget>
    with TickerProviderStateMixin {
  late final AnimationController _donutController;
  late final Animation<double> _donutAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;
  
  int _selectedTab = 0; // 0 = Sector, 1 = Industry, 2 = Cap
  String? _expandedId;
  bool _showAllSectors = false;
  int? _hoveredIndex;
  int? _previousHoveredIndex;

  @override
  void initState() {
    super.initState();
    _donutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _donutAnimation = CurvedAnimation(
      parent: _donutController,
      curve: Curves.easeOutCubic,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    );
    if (widget.sectorAllocation != null) {
      _donutController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AllocationPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sectorAllocation != null &&
        oldWidget.sectorAllocation != widget.sectorAllocation) {
      _donutController.forward(from: 0);
      _hoveredIndex = null;
      _previousHoveredIndex = null;
      _hoverController.reset();
    }
  }

  @override
  void dispose() {
    _donutController.dispose();
    _pulseController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(Offset localPosition, List<SectorWeight> weights) {
    final center = const Offset(110, 110);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist < 68 || dist > 115) {
      _onHoverExit();
      return;
    }

    double totalWeight = weights.fold(0.0, (sum, item) => sum + item.weightPercentage);
    if (totalWeight <= 0) totalWeight = 100.0;

    double angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2 + 2 * math.pi) % (2 * math.pi);

    double cumulative = 0;
    for (int i = 0; i < weights.length; i++) {
      double normalizedWeight = (weights[i].weightPercentage / totalWeight) * 100;
      cumulative += (normalizedWeight / 100) * (2 * math.pi);
      
      if (angle <= cumulative) {
        if (_hoveredIndex != i) {
          setState(() {
            _previousHoveredIndex = _hoveredIndex;
            _hoveredIndex = i;
          });
          _hoverController.forward(from: 0);
        }
        return;
      }
    }
    _onHoverExit();
  }

  void _onHoverExit() {
    if (_hoveredIndex != null) {
      setState(() {
        _previousHoveredIndex = _hoveredIndex;
        _hoveredIndex = null;
      });
      _hoverController.forward(from: 0).then((_) {
        if (mounted && _hoveredIndex == null) {
          setState(() {
            _previousHoveredIndex = null;
          });
        }
      });
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDark
                  ? [
                      const Color(0xFF0D1B2A).withValues(alpha: 0.9),
                      const Color(0xFF0A1628).withValues(alpha: 0.75),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.45),
                      const Color(0xFFF5F7FF).withValues(alpha: 0.25),
                    ],
            ),
            border: Border.all(
              color: _isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.07),
              width: 1,
            ),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.donut_small_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Allocation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (widget.error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 8),
              Text('Failed to load allocation data',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Text(widget.error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (widget.sectorAllocation == null ||
        widget.sectorAllocation!.sectorWeights.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.data_usage_outlined, size: 48),
              SizedBox(height: 8),
              Text('No allocation data available',
                  style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      );
    }

    List<SectorWeight> weights = [];
    String sectionTitle = 'Distribution';
    String emptyText = 'No allocation data available';
    String centerTitle = 'Sectors';
    
    if (_selectedTab == 0 && widget.sectorAllocation != null) {
      weights = widget.sectorAllocation!.sectorWeights;
      sectionTitle = 'Sector Distribution';
      emptyText = 'No sector data available';
      centerTitle = 'Sectors';
    } else if (_selectedTab == 1 && widget.sectorAllocation != null) {
      weights = widget.sectorAllocation!.industryWeights.map((w) => SectorWeight(
        sectorName: w.industryName,
        weightPercentage: w.weightPercentage,
        marketCap: w.marketCap,
        topStocks: w.topStocks,
      )).toList();
      sectionTitle = 'Industry Distribution';
      emptyText = 'No industry data available';
      centerTitle = 'Industries';
    } else if (_selectedTab == 2 && widget.marketCapAllocation != null) {
      weights = widget.marketCapAllocation!.segments.map((w) => SectorWeight(
        sectorName: w.segmentName,
        weightPercentage: w.weightPercentage,
        marketCap: w.segmentValue,
        topStocks: w.topStocks,
      )).toList();
      sectionTitle = 'Market Cap Distribution';
      emptyText = 'No market cap data available';
      centerTitle = 'Market Cap';
    }

    if (weights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedTab == 0 || _selectedTab == 1) _buildTabs(),
            const SizedBox(height: 20),
            const Icon(Icons.data_usage_outlined, size: 48),
            const SizedBox(height: 8),
            Text(emptyText, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    final visibleWeights = weights;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SECTION 0: Tabs ──
        _buildTabs(),
        const SizedBox(height: 20),

        // ── SECTION 1: Sector Distribution – Donut View (TOP) ──
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: AnimatedBuilder(
              animation: Listenable.merge([_donutAnimation, _pulseAnimation, _hoverAnimation]),
              builder: (context, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    MouseRegion(
                      onHover: (event) => _onHover(event.localPosition, weights),
                      onExit: (_) => _onHoverExit(),
                      child: GestureDetector(
                        onTapDown: (d) => _onHover(d.localPosition, weights),
                        onTapUp: (d) => _onHover(d.localPosition, weights),
                        onPanUpdate: (d) => _onHover(d.localPosition, weights),
                        onPanEnd: (_) => _onHoverExit(),
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: CustomPaint(
                            painter: _GlowingDonutPainter(
                              weights,
                              progress: _donutAnimation.value,
                              pulse: _pulseAnimation.value,
                              hoveredIndex: _hoveredIndex,
                              previousHoveredIndex: _previousHoveredIndex,
                              hoverProgress: _hoverAnimation.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _hoverAnimation,
                      builder: (context, _) {
                        double hoverProgress = _hoverAnimation.value;
                        
                        double defaultOpacity;
                        if (_hoveredIndex != null && _previousHoveredIndex == null) {
                          defaultOpacity = 1.0 - hoverProgress;
                        } else if (_hoveredIndex == null && _previousHoveredIndex != null) {
                          defaultOpacity = hoverProgress;
                        } else if (_hoveredIndex == null && _previousHoveredIndex == null) {
                          defaultOpacity = 1.0;
                        } else {
                          defaultOpacity = 0.0;
                        }

                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: defaultOpacity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    centerTitle,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                  ),
                                  Text(
                                    'Tap to explore',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: _isDark
                                              ? Colors.white.withValues(alpha: 0.45)
                                              : Colors.black.withValues(alpha: 0.45),
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (_hoveredIndex != null)
                              Opacity(
                                opacity: hoverProgress,
                                child: _buildCenterText(_hoveredIndex!, weights),
                              ),
                            if (_previousHoveredIndex != null)
                              Opacity(
                                opacity: 1.0 - hoverProgress,
                                child: _buildCenterText(_previousHoveredIndex!, weights),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── SECTION 2: Sector Distribution label ──
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            sectionTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
          ),
        ),
        const SizedBox(height: 10),

        // ── SECTION 3: Sector bars – scrollable so content never overflows ──
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    children: List.generate(visibleWeights.length, (index) {
                      final weight = visibleWeights[index];
                      final colors = _getGradientColors(index);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_expandedId == weight.sectorName) {
                                _expandedId = null;
                              } else {
                                _expandedId = weight.sectorName;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: _expandedId == weight.sectorName ? colors.first.withValues(alpha: 0.05) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: _expandedId == weight.sectorName ? Border.all(color: colors.first.withValues(alpha: 0.2)) : Border.all(color: Colors.transparent),
                            ),
                            padding: _expandedId == weight.sectorName ? const EdgeInsets.all(12) : EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: colors.first,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              weight.sectorName,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${weight.weightPercentage.toStringAsFixed(1)}%',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: colors.first,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedRotation(
                                      turns: _expandedId == weight.sectorName ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 300),
                                      child: Icon(Icons.keyboard_arrow_down, size: 16, color: colors.first),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TweenAnimationBuilder<double>(
                                  key: ValueKey(weight.sectorName),
                                  tween: Tween<double>(begin: 0, end: weight.weightPercentage / 100),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOutQuart,
                                  builder: (context, value, _) {
                                    return LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Stack(
                                          children: [
                                            Container(
                                              height: 6,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: _isDark
                                                    ? Colors.white.withValues(alpha: 0.08)
                                                    : Colors.black.withValues(alpha: 0.07),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                            Container(
                                              height: 6,
                                              width: constraints.maxWidth * value,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(3),
                                                gradient: LinearGradient(
                                                  colors: colors,
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: colors.first.withValues(alpha: 0.45),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                if (_expandedId == weight.sectorName)
                                  _buildExpandedHoldings(weight, colors.first),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(int index) {
    final color = _kPalette[index % _kPalette.length];
    return [color, color.withValues(alpha: 0.8)];
  }

  Widget _buildCenterText(int index, List<SectorWeight> weights) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${weights[index].weightPercentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: _kPalette[index % _kPalette.length],
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            weights[index].sectorName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF132337) : const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabOption(0, 'Sector'),
          _buildTabOption(1, 'Industry'),
          _buildTabOption(2, 'Cap'),
        ],
      ),
    );
  }

  Widget _buildTabOption(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTab != index) {
          setState(() {
            _selectedTab = index;
            _expandedId = null;
            _hoveredIndex = null;
            _previousHoveredIndex = null;
            _showAllSectors = false;
            _donutController.forward(from: 0);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected 
                ? Colors.white 
                : (_isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedHoldings(SectorWeight weight, Color color) {
    if (widget.holdings == null || widget.holdings!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text("No holdings data"),
      );
    }

    Iterable<PortfolioHolding> filteredHoldings;
    if (_selectedTab == 0) {
      filteredHoldings = widget.holdings!.where((h) => h.sector == weight.sectorName);
    } else if (_selectedTab == 1) {
      filteredHoldings = widget.holdings!.where((h) => h.industry == weight.sectorName);
    } else {
      filteredHoldings = widget.holdings!.where((h) => weight.topStocks.contains(h.symbol));
    }

    final groupHoldings = filteredHoldings.toList()
      ..sort((a, b) => b.portfolioWeight.compareTo(a.portfolioWeight));

    final topHoldings = groupHoldings.take(7).toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        Divider(height: 1, color: color.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                "HOLDING",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "% GROUP",
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "% PORTFOLIO",
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...topHoldings.map((h) {
          final groupPercent = weight.weightPercentage > 0 
              ? (h.portfolioWeight / weight.weightPercentage) * 100 
              : 0.0;
              
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    h.symbol,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${groupPercent.toStringAsFixed(1)}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${h.portfolioWeight.toStringAsFixed(1)}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (groupHoldings.length > 7)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${groupHoldings.length - 7} more holdings',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

const List<Color> _kPalette = [
  Color(0xFF00B894),
  Color(0xFFFF7675),
  Color(0xFF60A5FA),
  Color(0xFFFBBF24),
  Color(0xFFF472B6),
  Color(0xFF34D399),
  Color(0xFFA78BFA),
  Color(0xFFFB923C),
];

class _GlowingDonutPainter extends CustomPainter {
  final List<SectorWeight> sectorWeights;
  final double progress;
  final double pulse;
  final int? hoveredIndex;
  final int? previousHoveredIndex;
  final double hoverProgress;

  _GlowingDonutPainter(
    this.sectorWeights, {
    this.progress = 1.0,
    this.pulse = 0.0,
    this.hoveredIndex,
    this.previousHoveredIndex,
    this.hoverProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sectorWeights.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.shortestSide / 2) - 14;

    const gapAngle = 0.045;
    double startAngle = -math.pi / 2;

    double totalWeight = sectorWeights.fold(0.0, (sum, item) => sum + item.weightPercentage);
    if (totalWeight <= 0) totalWeight = 100.0;

    for (int i = 0; i < sectorWeights.length; i++) {
      final weight = sectorWeights[i];
      final color = _kPalette[i % _kPalette.length];
      
      double getTargetColorAlpha(int? activeHover) {
        if (activeHover == null) return 1.0;
        if (i == activeHover) return 1.0;
        return 0.35;
      }
      
      double getTargetGlowAlpha(int? activeHover) {
        if (activeHover == null) return 0.3;
        if (i == activeHover) return 0.65;
        return 0.1;
      }
      
      double getTargetHoverProg(int? activeHover) {
        if (activeHover == null) return 0.0;
        if (i == activeHover) return 1.0;
        return 0.0;
      }

      double startColorAlpha = getTargetColorAlpha(previousHoveredIndex);
      double endColorAlpha = getTargetColorAlpha(hoveredIndex);
      double colorAlpha = startColorAlpha + (endColorAlpha - startColorAlpha) * hoverProgress;

      double startGlowAlpha = getTargetGlowAlpha(previousHoveredIndex);
      double endGlowAlpha = getTargetGlowAlpha(hoveredIndex);
      double glowAlpha = startGlowAlpha + (endGlowAlpha - startGlowAlpha) * hoverProgress;

      double startProg = getTargetHoverProg(previousHoveredIndex);
      double endProg = getTargetHoverProg(hoveredIndex);
      double currentHoverProg = startProg + (endProg - startProg) * hoverProgress;
      
      bool isIdle = hoveredIndex == null && (previousHoveredIndex == null || hoverProgress >= 0.99);
      final double currentPulse = (i == 0 && isIdle && progress > 0.98) ? pulse : 0.0;

      final double outerRadius = baseRadius + (8 * currentHoverProg) + (2 * currentPulse);
      final double strokeWidth = 24.0 + (4 * currentHoverProg) + (1 * currentPulse);
      
      final rect = Rect.fromCircle(center: center, radius: outerRadius);

      double normalizedWeight = (weight.weightPercentage / totalWeight) * 100;
      double fullSweep = (normalizedWeight / 100) * (2 * math.pi);
      if (fullSweep < gapAngle + 0.01) fullSweep = gapAngle + 0.01;

      final animatedSweep = fullSweep * progress;
      final actualSweep = (animatedSweep - gapAngle).clamp(0.0, animatedSweep);

      if (actualSweep > 0) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: glowAlpha * colorAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6 + (8 * currentHoverProg)
          ..strokeCap = StrokeCap.butt
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + (10 * currentHoverProg));
        canvas.drawArc(rect, startAngle, actualSweep, false, glowPaint);

        final paint = Paint()
          ..color = color.withValues(alpha: colorAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, startAngle, actualSweep, false, paint);
      }

      startAngle += fullSweep * progress;
    }
  }

  @override
  bool shouldRepaint(covariant _GlowingDonutPainter oldDelegate) =>
      oldDelegate.sectorWeights != sectorWeights ||
      oldDelegate.progress != progress ||
      oldDelegate.pulse != pulse ||
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.previousHoveredIndex != previousHoveredIndex ||
      oldDelegate.hoverProgress != hoverProgress;
}
