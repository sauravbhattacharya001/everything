/// Pomodoro Timer Service — manages work/break intervals using the
/// Pomodoro Technique. Tracks completed pomodoros, total focus time,
/// and session history.
///
/// Default intervals:
///   - Work: 25 minutes
///   - Short break: 5 minutes
///   - Long break: 15 minutes (every 4 pomodoros)

class PomodoroSettings {
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakInterval;

  const PomodoroSettings({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.longBreakInterval = 4,
  });

  PomodoroSettings copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakInterval,
  }) {
    return PomodoroSettings(
      workMinutes: workMinutes ?? this.workMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
    );
  }
}

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroSession {
  final DateTime startedAt;
  final DateTime? completedAt;
  final PomodoroPhase phase;
  final int durationMinutes;
  final bool completed;

  const PomodoroSession({
    required this.startedAt,
    this.completedAt,
    required this.phase,
    required this.durationMinutes,
    this.completed = false,
  });

  PomodoroSession copyWith({
    DateTime? completedAt,
    bool? completed,
  }) {
    return PomodoroSession(
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      phase: phase,
      durationMinutes: durationMinutes,
      completed: completed ?? this.completed,
    );
  }
}

class PomodoroStats {
  final int completedPomodoros;
  final int totalFocusMinutes;
  final int totalBreakMinutes;
  final int currentStreak;
  final List<PomodoroSession> todaySessions;

  const PomodoroStats({
    this.completedPomodoros = 0,
    this.totalFocusMinutes = 0,
    this.totalBreakMinutes = 0,
    this.currentStreak = 0,
    this.todaySessions = const [],
  });
}

class PomodoroService {
  final PomodoroSettings settings;
  final List<PomodoroSession> _sessions = [];

  PomodoroService({this.settings = const PomodoroSettings()});

  List<PomodoroSession> get sessions => List.unmodifiable(_sessions);

  /// Determine which phase comes next based on completed work sessions.
  PomodoroPhase nextPhase() {
    final workCount =
        _sessions.where((s) => s.phase == PomodoroPhase.work && s.completed).length;
    if (workCount > 0 && workCount % settings.longBreakInterval == 0) {
      // Check if last completed was work (time for break)
      final lastCompleted = _sessions.lastWhere(
        (s) => s.completed,
        orElse: () => const PomodoroSession(
          startedAt: null ?? DateTime(2000),
          phase: PomodoroPhase.shortBreak,
          durationMinutes: 0,
        ),
      );
      if (lastCompleted.phase == PomodoroPhase.work) {
        return PomodoroPhase.longBreak;
      }
    }

    // After a break → work, after work → short break
    if (_sessions.isEmpty) return PomodoroPhase.work;
    final last = _sessions.last;
    if (!last.completed) return last.phase;
    if (last.phase == PomodoroPhase.work) {
      final completedWork =
          _sessions.where((s) => s.phase == PomodoroPhase.work && s.completed).length;
      if (completedWork % settings.longBreakInterval == 0) {
        return PomodoroPhase.longBreak;
      }
      return PomodoroPhase.shortBreak;
    }
    return PomodoroPhase.work;
  }

  /// Duration in minutes for a given phase.
  int phaseDuration(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return settings.workMinutes;
      case PomodoroPhase.shortBreak:
        return settings.shortBreakMinutes;
      case PomodoroPhase.longBreak:
        return settings.longBreakMinutes;
    }
  }

  /// Start a new session.
  PomodoroSession startSession(PomodoroPhase phase) {
    final session = PomodoroSession(
      startedAt: DateTime.now(),
      phase: phase,
      durationMinutes: phaseDuration(phase),
    );
    _sessions.add(session);
    return session;
  }

  /// Mark the current session as completed.
  void completeCurrentSession() {
    if (_sessions.isNotEmpty && !_sessions.last.completed) {
      _sessions[_sessions.length - 1] = _sessions.last.copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );
    }
  }

  /// Get today's statistics.
  PomodoroStats todayStats() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todaySessions =
        _sessions.where((s) => s.startedAt.isAfter(todayStart)).toList();

    final completedWork = todaySessions
        .where((s) => s.phase == PomodoroPhase.work && s.completed)
        .toList();
    final completedBreaks = todaySessions
        .where((s) => s.phase != PomodoroPhase.work && s.completed)
        .toList();

    // Calculate streak (consecutive completed pomodoros)
    int streak = 0;
    for (int i = todaySessions.length - 1; i >= 0; i--) {
      if (todaySessions[i].phase == PomodoroPhase.work &&
          todaySessions[i].completed) {
        streak++;
      } else if (todaySessions[i].phase == PomodoroPhase.work) {
        break;
      }
    }

    return PomodoroStats(
      completedPomodoros: completedWork.length,
      totalFocusMinutes:
          completedWork.fold(0, (sum, s) => sum + s.durationMinutes),
      totalBreakMinutes:
          completedBreaks.fold(0, (sum, s) => sum + s.durationMinutes),
      currentStreak: streak,
      todaySessions: todaySessions,
    );
  }

  /// Reset all sessions.
  void reset() {
    _sessions.clear();
  }
}
