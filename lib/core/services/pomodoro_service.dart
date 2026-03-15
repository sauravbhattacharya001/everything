/// Pomodoro Timer Service — manages work/break intervals using the
/// Pomodoro Technique. Tracks completed pomodoros, total focus time,
/// and session history.
///
/// Default intervals:
///   - Work: 25 minutes
///   - Short break: 5 minutes
///   - Long break: 15 minutes (every 4 pomodoros)

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'phase': phase.index,
        'durationMinutes': durationMinutes,
        'completed': completed,
      };

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      phase: PomodoroPhase.values[json['phase'] as int],
      durationMinutes: json['durationMinutes'] as int,
      completed: json['completed'] as bool? ?? false,
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
  static const String _storageKey = 'pomodoro_sessions';
  final PomodoroSettings settings;
  final List<PomodoroSession> _sessions = [];
  bool _initialized = false;

  PomodoroService({this.settings = const PomodoroSettings()});

  List<PomodoroSession> get sessions => List.unmodifiable(_sessions);

  /// Initialize service by loading persisted sessions.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final list = jsonDecode(data) as List<dynamic>;
        _sessions.addAll(
          list.map((e) => PomodoroSession.fromJson(e as Map<String, dynamic>)),
        );
      }
    } catch (_) {}
    _initialized = true;
  }

  /// Persist sessions to SharedPreferences.
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_sessions.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}
  }

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
  Future<PomodoroSession> startSession(PomodoroPhase phase) async {
    await init();
    final session = PomodoroSession(
      startedAt: DateTime.now(),
      phase: phase,
      durationMinutes: phaseDuration(phase),
    );
    _sessions.add(session);
    await _save();
    return session;
  }

  /// Mark the current session as completed.
  Future<void> completeCurrentSession() async {
    await init();
    if (_sessions.isNotEmpty && !_sessions.last.completed) {
      _sessions[_sessions.length - 1] = _sessions.last.copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );
      await _save();
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
  Future<void> reset() async {
    _sessions.clear();
    await _save();
  }
}
