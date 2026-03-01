/// Simple timer utility for game events
class GameTimer {
  GameTimer(this.duration, {this.repeat = false});

  final double duration;
  final bool repeat;
  double _elapsed = 0;
  bool _isActive = true;

  bool get isFinished => _elapsed >= duration;
  bool get isActive => _isActive;
  double get progress => (_elapsed / duration).clamp(0, 1);
  double get remaining => (duration - _elapsed).clamp(0, duration);

  void update(double dt) {
    if (!_isActive) return;

    _elapsed += dt;

    if (_elapsed >= duration) {
      if (repeat) {
        _elapsed = 0;
      } else {
        _isActive = false;
      }
    }
  }

  void reset() {
    _elapsed = 0;
    _isActive = true;
  }

  void stop() {
    _isActive = false;
  }

  void start() {
    _isActive = true;
  }
}

/// Cooldown timer for abilities/actions
class Cooldown {
  Cooldown(this.duration);

  final double duration;
  double _remaining = 0;

  bool get isReady => _remaining <= 0;
  double get remaining => _remaining;
  double get progress => 1.0 - (_remaining / duration).clamp(0, 1);

  void update(double dt) {
    if (_remaining > 0) {
      _remaining -= dt;
    }
  }

  void trigger() {
    _remaining = duration;
  }

  void reset() {
    _remaining = 0;
  }
}
