import 'dart:async';

/// State of the typewriter animation cycle.
enum TypewriterPhase {
  typing,
  dwelling,
  erasing,
  pausing,
}

/// A lightweight, reusable controller that powers typewriter ghost hint animations
/// for text fields without polluting the underlying TextEditingController.
class TypewriterHintController {
  TypewriterHintController({
    required this.hints,
    required this.onHintChanged,
    this.typingSpeed = const Duration(milliseconds: 90),
    this.dwellDuration = const Duration(milliseconds: 1400),
    this.erasingSpeed = const Duration(milliseconds: 45),
    this.pauseDuration = const Duration(milliseconds: 300),
  });

  final List<String> hints;
  final void Function(String text, bool isAnimating) onHintChanged;
  final Duration typingSpeed;
  final Duration dwellDuration;
  final Duration erasingSpeed;
  final Duration pauseDuration;

  Timer? _timer;
  int _currentHintIndex = 0;
  int _currentCharIndex = 0;
  TypewriterPhase _phase = TypewriterPhase.typing;
  bool _isPaused = false;
  bool _isDisposed = false;

  /// Starts or resumes the typewriter loop.
  void start() {
    if (_isDisposed || hints.isEmpty) return;
    _isPaused = false;
    _scheduleNextTick();
  }

  /// Pauses the typewriter loop and resets the displayed text if requested.
  void pause({bool clearHint = true}) {
    _timer?.cancel();
    _isPaused = true;
    if (clearHint && !_isDisposed) {
      onHintChanged('', false);
    }
  }

  /// Resumes the loop if previously paused.
  void resume() {
    if (_isDisposed || !_isPaused || hints.isEmpty) return;
    _isPaused = false;
    _currentCharIndex = 0;
    _phase = TypewriterPhase.typing;
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    if (_isPaused || _isDisposed || hints.isEmpty) return;

    final currentTarget = hints[_currentHintIndex];

    switch (_phase) {
      case TypewriterPhase.typing:
        if (_currentCharIndex < currentTarget.length) {
          _currentCharIndex++;
          final text = currentTarget.substring(0, _currentCharIndex);
          onHintChanged(text, true);
          _timer = Timer(typingSpeed, _scheduleNextTick);
        } else {
          _phase = TypewriterPhase.dwelling;
          _timer = Timer(dwellDuration, _scheduleNextTick);
        }
        break;

      case TypewriterPhase.dwelling:
        _phase = TypewriterPhase.erasing;
        _scheduleNextTick();
        break;

      case TypewriterPhase.erasing:
        if (_currentCharIndex > 0) {
          _currentCharIndex--;
          final text = currentTarget.substring(0, _currentCharIndex);
          onHintChanged(text, true);
          _timer = Timer(erasingSpeed, _scheduleNextTick);
        } else {
          _phase = TypewriterPhase.pausing;
          _timer = Timer(pauseDuration, _scheduleNextTick);
        }
        break;

      case TypewriterPhase.pausing:
        _currentHintIndex = (_currentHintIndex + 1) % hints.length;
        _currentCharIndex = 0;
        _phase = TypewriterPhase.typing;
        _scheduleNextTick();
        break;
    }
  }

  /// Cancels all active timers.
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
