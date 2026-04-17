import 'dart:math';

/// Reusable client-side rate limiter for authentication flows.
///
/// Tracks consecutive failed attempts and enforces exponential-backoff
/// lockouts after a configurable threshold. Designed to be shared across
/// login, sign-up, and password-reset screens.
///
/// Usage:
/// ```dart
/// final limiter = AuthRateLimiter();
///
/// if (limiter.isLockedOut) {
///   showSnackBar('Try again in ${limiter.formatRemaining()}');
///   return;
/// }
///
/// try {
///   await authenticate();
///   limiter.reset();
/// } catch (_) {
///   limiter.recordFailure();
/// }
/// ```
class AuthRateLimiter {
  /// Maximum consecutive failures before lockout kicks in.
  final int maxAttempts;

  /// Base lockout duration (doubles after each lockout cycle).
  final Duration baseLockout;

  /// Maximum lockout duration cap.
  final Duration maxLockout;

  /// Number of consecutive failed attempts in the current cycle.
  int _failedAttempts = 0;

  /// How many times the lockout has been triggered (for exponential backoff).
  int _lockoutCycles = 0;

  /// When the current lockout expires, or null if not locked out.
  DateTime? _lockoutUntil;

  AuthRateLimiter({
    this.maxAttempts = 5,
    this.baseLockout = const Duration(seconds: 30),
    this.maxLockout = const Duration(minutes: 15),
  });

  /// Number of consecutive failed attempts so far.
  int get failedAttempts => _failedAttempts;

  /// Remaining lockout duration, or null if not locked out.
  Duration? get remaining {
    if (_lockoutUntil == null) return null;
    final r = _lockoutUntil!.difference(DateTime.now());
    return r.isNegative ? null : r;
  }

  /// Whether the user is currently locked out.
  bool get isLockedOut => remaining != null;

  /// How many attempts remain before the next lockout, or null if
  /// already locked out.
  int? get attemptsRemaining =>
      isLockedOut ? null : maxAttempts - _failedAttempts;

  /// Records a failed attempt; triggers lockout when threshold is hit.
  void recordFailure() {
    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      final multiplier = pow(2, _lockoutCycles).toInt();
      final lockoutDuration = Duration(
        seconds: min(
          baseLockout.inSeconds * multiplier,
          maxLockout.inSeconds,
        ),
      );
      _lockoutUntil = DateTime.now().add(lockoutDuration);
      _lockoutCycles++;
      _failedAttempts = 0;
    }
  }

  /// Resets all rate-limiting state (call after successful auth).
  void reset() {
    _failedAttempts = 0;
    _lockoutCycles = 0;
    _lockoutUntil = null;
  }

  /// Formats the remaining lockout duration as a human-readable string.
  ///
  /// Returns an empty string if not locked out.
  String formatRemaining() {
    final d = remaining;
    if (d == null) return '';
    if (d.inMinutes >= 1) {
      final mins = d.inMinutes;
      final secs = d.inSeconds % 60;
      return secs > 0 ? '$mins min $secs sec' : '$mins min';
    }
    return '${d.inSeconds} sec';
  }
}
