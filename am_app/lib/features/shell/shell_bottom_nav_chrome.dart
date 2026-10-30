part of 'app_shell.dart';

/// Floating bottom-nav show/hide, idle timer, and chrome pointer/scroll.
mixin ShellBottomNavChrome on State<AppShell>, TickerProvider {
  // Satisfied by [ShellNav] on the same State.
  String get _currentLocation;

  late final AnimationController _bottomNavController;
  late final Animation<double> _bottomNavFactor;
  late final ValueNotifier<bool> _mobileSearchOpen;
  bool _wantBottomNav = true;
  double _bottomNavScrollAccum = 0;
  static const double _bottomNavScrollThreshold = 12;
  static const Duration _bottomNavIdleHide = Duration(seconds: 3);
  static const double _bottomNavTapSlop = 18;
  int? _chromePointer;
  Offset? _chromePointerDown;
  bool _chromePointerMoved = false;
  bool _chromeScrollSessionActive = false;
  Timer? _bottomNavHideTimer;

  void _initBottomNavChrome() {
    _bottomNavController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    final bottomNavCurve = CurvedAnimation(
      parent: _bottomNavController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _bottomNavFactor =
        Tween<double>(begin: 0.0, end: 1.0).animate(bottomNavCurve);
    // Drive overlay consumers with the linear controller value so layout
    // lift stays in sync with show/hide (curved factor overshoots).
    _bottomNavController.addListener(() {
      GlobalBottomNavVisibility.setFactor(_bottomNavController.value);
    });
    GlobalBottomNavVisibility.setFactor(_bottomNavController.value);

    _mobileSearchOpen = ValueNotifier<bool>(false);
    _mobileSearchOpen.addListener(_onMobileSearchOpenChanged);
    GlobalBottomNavVisibility.hideRequests.addListener(_onHideRequest);
  }

  void _disposeBottomNavChrome() {
    _bottomNavHideTimer?.cancel();
    GlobalBottomNavVisibility.hideRequests.removeListener(_onHideRequest);
    _mobileSearchOpen.removeListener(_onMobileSearchOpenChanged);
    _mobileSearchOpen.dispose();
    _bottomNavController.dispose();
  }

  void _onHideRequest() {
    if (!mounted) return;
    _bottomNavHideTimer?.cancel();
    _setBottomNavVisible(false);
  }

  void _setBottomNavVisible(bool visible) {
    if (_wantBottomNav == visible) return;
    _wantBottomNav = visible;
    _bottomNavScrollAccum = 0;
    if (visible) {
      _bottomNavController.forward();
    } else {
      _bottomNavController.reverse();
    }
  }

  void _onMobileSearchOpenChanged() {
    if (!mounted) return;
    if (_mobileSearchOpen.value) {
      _bottomNavHideTimer?.cancel();
      _setBottomNavVisible(false);
    }
  }

  bool get _isAiChatRoute {
    try {
      return _currentLocation.startsWith(AppRoutes.aiChat);
    } catch (_) {
      return false;
    }
  }

  void _showBottomNavWithIdleHide() {
    if (_mobileSearchOpen.value) return;
    // Indices / other modal sheets hold a lock until dismissed.
    if (GlobalBottomNavVisibility.isModalLocked) return;
    // AI chat + keyboard: never flash the floating nav while typing.
    if (mounted &&
        _isAiChatRoute &&
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      return;
    }
    _bottomNavHideTimer?.cancel();
    _setBottomNavVisible(true);
    _bottomNavHideTimer = Timer(_bottomNavIdleHide, () {
      if (mounted) _setBottomNavVisible(false);
    });
  }

  void _onChromePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch &&
        event.kind != PointerDeviceKind.mouse &&
        event.kind != PointerDeviceKind.stylus) {
      return;
    }
    if (_chromePointer != null) return;
    _chromePointer = event.pointer;
    _chromePointerDown = event.position;
    _chromePointerMoved = false;
  }

  void _onChromePointerMove(PointerMoveEvent event) {
    if (event.pointer != _chromePointer || _chromePointerDown == null) return;
    if ((event.position - _chromePointerDown!).distance > _bottomNavTapSlop) {
      _chromePointerMoved = true;
    }
  }

  void _onChromePointerUp(PointerUpEvent event) {
    if (event.pointer != _chromePointer) return;
    final wasTap = !_chromePointerMoved && !_chromeScrollSessionActive;
    _chromePointer = null;
    _chromePointerDown = null;
    _chromePointerMoved = false;
    if (GlobalBottomNavVisibility.isModalLocked) {
      return;
    }
    if (GlobalBottomNavVisibility.suppressChromeTapReveal) {
      GlobalBottomNavVisibility.suppressChromeTapReveal = false;
      return;
    }
    if (wasTap) {
      _showBottomNavWithIdleHide();
    }
  }

  void _onChromePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _chromePointer) return;
    _chromePointer = null;
    _chromePointerDown = null;
    _chromePointerMoved = false;
    if (GlobalBottomNavVisibility.isModalLocked) {
      return;
    }
    if (GlobalBottomNavVisibility.suppressChromeTapReveal) {
      GlobalBottomNavVisibility.suppressChromeTapReveal = false;
    }
  }

  /// Scroll away → hide; at / toward top → show for [_bottomNavIdleHide] (3s).
  bool _handleBottomNavScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollStartNotification) {
      _chromeScrollSessionActive = true;
      return false;
    }
    if (notification is ScrollEndNotification) {
      _chromeScrollSessionActive = false;
      // Landed at top of any page → pop bottom nav for 3s.
      if (notification.metrics.pixels <= 0.5) {
        _showBottomNavWithIdleHide();
      }
      return false;
    }
    if (notification is! ScrollUpdateNotification) return false;

    // Already at (or above) the top — same as mobile section pills.
    if (notification.metrics.pixels <= 0.5) {
      if (!_wantBottomNav) {
        _showBottomNavWithIdleHide();
      }
      _bottomNavScrollAccum = 0;
      return false;
    }

    final delta = notification.scrollDelta ?? 0.0;
    if (delta == 0) return false;

    // Meaningful scroll invalidates an in-flight tap-to-reveal gesture.
    _chromePointerMoved = true;

    // Reset accum when direction flips (matches mobile section-tab chrome).
    if ((_bottomNavScrollAccum > 0 && delta < 0) ||
        (_bottomNavScrollAccum < 0 && delta > 0)) {
      _bottomNavScrollAccum = 0;
    }
    _bottomNavScrollAccum += delta;

    if (_bottomNavScrollAccum >= _bottomNavScrollThreshold && _wantBottomNav) {
      _bottomNavHideTimer?.cancel();
      _setBottomNavVisible(false);
      _bottomNavScrollAccum = 0;
    } else if (_bottomNavScrollAccum <= -_bottomNavScrollThreshold) {
      _showBottomNavWithIdleHide();
      _bottomNavScrollAccum = 0;
    }
    return false;
  }
}
