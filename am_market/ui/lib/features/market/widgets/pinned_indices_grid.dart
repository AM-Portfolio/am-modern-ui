import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:am_market_common/models/market_data.dart';
import 'index_card.dart';

class PinnedIndicesGrid extends StatelessWidget {
  final List<StockIndicesMarketData> indices;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;

  const PinnedIndicesGrid({
    required this.indices,
    required this.selectedIndexSymbol,
    required this.onIndexSelected,
    super.key,
  });

  static const double mobileCardWidth = 148;
  static const double mobileCardHeight = 68;
  static const double mobileSeparator = 8;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return _MobileIndicesStrip(
        indices: indices.take(12).toList(),
        selectedIndexSymbol: selectedIndexSymbol,
        onIndexSelected: onIndexSelected,
      );
    }

    final itemsToShow = indices.take(6).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        mainAxisExtent: 72.0,
      ),
      itemCount: itemsToShow.length,
      itemBuilder: (context, index) {
        final data = itemsToShow[index];
        final isSelected = data.indexSymbol == selectedIndexSymbol;
        return IndexCard(
          data: data,
          isSelected: isSelected,
          onTap: () => onIndexSelected(data),
        );
      },
    );
  }
}

/// Full-width horizontal indices with slow continuous LTR marquee.
class _MobileIndicesStrip extends StatefulWidget {
  const _MobileIndicesStrip({
    required this.indices,
    required this.selectedIndexSymbol,
    required this.onIndexSelected,
  });

  final List<StockIndicesMarketData> indices;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;

  @override
  State<_MobileIndicesStrip> createState() => _MobileIndicesStripState();
}

class _MobileIndicesStripState extends State<_MobileIndicesStrip>
    with SingleTickerProviderStateMixin {
  static const double _speedPxPerSec = 14;
  static const Duration _resumeIdle = Duration(seconds: 2);
  static const double _minExtentForAutoScroll = 8;

  final ScrollController _controller = ScrollController();
  Timer? _resumeTimer;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  bool _paused = false;
  bool _marqueeEnabled = false;

  int get _baseCount => widget.indices.length;

  double get _itemExtent =>
      PinnedIndicesGrid.mobileCardWidth + PinnedIndicesGrid.mobileSeparator;

  double get _halfExtent => _baseCount * _itemExtent;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluateMarquee());
  }

  @override
  void didUpdateWidget(covariant _MobileIndicesStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indices.length != widget.indices.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _evaluateMarquee());
    }
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _ticker?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _evaluateMarquee() {
    if (!mounted) return;
    if (_reduceMotion || _baseCount == 0 || !_controller.hasClients) {
      _stopTicker();
      if (_marqueeEnabled) {
        _marqueeEnabled = false;
        setState(() {});
      }
      return;
    }
    // Overflow means we should loop with a duplicated list.
    final max = _controller.position.maxScrollExtent;
    final shouldEnable = max > _minExtentForAutoScroll;
    if (shouldEnable == _marqueeEnabled) {
      if (_marqueeEnabled && !_paused) {
        _startTicker();
      }
      return;
    }
    _stopTicker();
    _marqueeEnabled = shouldEnable;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _paused || !_marqueeEnabled) return;
      _startTicker();
    });
  }

  void _startTicker() {
    if (_ticker == null || _ticker!.isActive) return;
    _lastElapsed = Duration.zero;
    _ticker!.start();
  }

  void _stopTicker() {
    if (_ticker == null || !_ticker!.isActive) return;
    _ticker!.stop();
    _lastElapsed = Duration.zero;
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _paused || !_marqueeEnabled) return;
    if (!_controller.hasClients) return;

    final dt = _lastElapsed == Duration.zero
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.1) return;

    final half = _halfExtent;
    if (half <= 0) return;

    var next = _controller.offset + _speedPxPerSec * dt;
    if (next >= half) {
      next -= half;
    }
    _controller.jumpTo(next.clamp(0.0, _controller.position.maxScrollExtent));
  }

  void _pauseInteraction() {
    _paused = true;
    _resumeTimer?.cancel();
    _stopTicker();
  }

  void _scheduleResume() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeIdle, () {
      if (!mounted) return;
      _paused = false;
      if (_marqueeEnabled) _startTicker();
    });
  }

  void _onIndexTap(StockIndicesMarketData data) {
    _pauseInteraction();
    _scheduleResume();
    widget.onIndexSelected(data);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _pauseInteraction();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.indices;
    if (base.isEmpty) {
      return const SizedBox(height: PinnedIndicesGrid.mobileCardHeight);
    }

    final useLoop = _marqueeEnabled && !_reduceMotion;
    final display = useLoop ? [...base, ...base] : base;

    return SizedBox(
      height: PinnedIndicesGrid.mobileCardHeight,
      child: Listener(
        onPointerDown: (_) => _pauseInteraction(),
        onPointerUp: (_) => _scheduleResume(),
        onPointerCancel: (_) => _scheduleResume(),
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: display.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: PinnedIndicesGrid.mobileSeparator),
            itemBuilder: (context, index) {
              final data = display[index];
              final isSelected = data.indexSymbol == widget.selectedIndexSymbol;
              return SizedBox(
                key: ValueKey('idx-$index-${data.indexSymbol}'),
                width: PinnedIndicesGrid.mobileCardWidth,
                height: PinnedIndicesGrid.mobileCardHeight,
                child: IndexCard(
                  data: data,
                  isSelected: isSelected,
                  onTap: () => _onIndexTap(data),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
