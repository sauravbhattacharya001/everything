import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/pomodoro_service.dart';

void main() {
  group('PomodoroSettings', () {
    test('has correct defaults', () {
      const s = PomodoroSettings();
      expect(s.workMinutes, 25);
      expect(s.shortBreakMinutes, 5);
      expect(s.longBreakMinutes, 15);
      expect(s.longBreakInterval, 4);
    });

    test('copyWith overrides specific fields', () {
      const s = PomodoroSettings();
      final s2 = s.copyWith(workMinutes: 50, shortBreakMinutes: 10);
      expect(s2.workMinutes, 50);
      expect(s2.shortBreakMinutes, 10);
      expect(s2.longBreakMinutes, 15); // unchanged
      expect(s2.longBreakInterval, 4); // unchanged
    });

    test('copyWith preserves all fields when nothing passed', () {
      const s = PomodoroSettings(workMinutes: 30, shortBreakMinutes: 7,
          longBreakMinutes: 20, longBreakInterval: 3);
      final s2 = s.copyWith();
      expect(s2.workMinutes, 30);
      expect(s2.shortBreakMinutes, 7);
      expect(s2.longBreakMinutes, 20);
      expect(s2.longBreakInterval, 3);
    });
  });

  group('PomodoroService', () {
    late PomodoroService service;

    setUp(() {
      service = PomodoroService();
    });

    test('starts with no sessions', () {
      expect(service.sessions, isEmpty);
    });

    test('nextPhase returns work initially', () {
      expect(service.nextPhase(), PomodoroPhase.work);
    });

    test('phaseDuration returns correct durations', () {
      expect(service.phaseDuration(PomodoroPhase.work), 25);
      expect(service.phaseDuration(PomodoroPhase.shortBreak), 5);
      expect(service.phaseDuration(PomodoroPhase.longBreak), 15);
    });

    test('phaseDuration uses custom settings', () {
      final custom = PomodoroService(
        settings: const PomodoroSettings(
          workMinutes: 50,
          shortBreakMinutes: 10,
          longBreakMinutes: 30,
        ),
      );
      expect(custom.phaseDuration(PomodoroPhase.work), 50);
      expect(custom.phaseDuration(PomodoroPhase.shortBreak), 10);
      expect(custom.phaseDuration(PomodoroPhase.longBreak), 30);
    });

    test('startSession creates a new session', () {
      final session = service.startSession(PomodoroPhase.work);
      expect(session.phase, PomodoroPhase.work);
      expect(session.durationMinutes, 25);
      expect(session.completed, false);
      expect(session.completedAt, isNull);
      expect(service.sessions, hasLength(1));
    });

    test('completeCurrentSession marks session as done', () {
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();
      expect(service.sessions.last.completed, true);
      expect(service.sessions.last.completedAt, isNotNull);
    });

    test('completeCurrentSession is no-op when no sessions', () {
      service.completeCurrentSession(); // should not throw
      expect(service.sessions, isEmpty);
    });

    test('completeCurrentSession is no-op when already completed', () {
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();
      final first = service.sessions.last.completedAt;
      service.completeCurrentSession();
      // Session should not be modified again
      expect(service.sessions, hasLength(1));
      expect(service.sessions.last.completedAt, first);
    });

    test('nextPhase returns shortBreak after 1 work', () {
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();
      expect(service.nextPhase(), PomodoroPhase.shortBreak);
    });

    test('nextPhase returns work after short break', () {
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();
      service.startSession(PomodoroPhase.shortBreak);
      service.completeCurrentSession();
      expect(service.nextPhase(), PomodoroPhase.work);
    });

    test('nextPhase returns longBreak after 4 work sessions', () {
      for (var i = 0; i < 4; i++) {
        service.startSession(PomodoroPhase.work);
        service.completeCurrentSession();
        if (i < 3) {
          service.startSession(PomodoroPhase.shortBreak);
          service.completeCurrentSession();
        }
      }
      expect(service.nextPhase(), PomodoroPhase.longBreak);
    });

    test('reset clears all sessions', () {
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();
      service.startSession(PomodoroPhase.shortBreak);
      service.reset();
      expect(service.sessions, isEmpty);
      expect(service.nextPhase(), PomodoroPhase.work);
    });

    test('sessions list is unmodifiable', () {
      service.startSession(PomodoroPhase.work);
      expect(() => service.sessions.add(PomodoroSession(
        startedAt: DateTime.now(),
        phase: PomodoroPhase.work,
        durationMinutes: 25,
      )), throwsA(isA<UnsupportedError>()));
    });
  });

  group('PomodoroService.todayStats', () {
    late PomodoroService service;

    setUp(() {
      service = PomodoroService();
    });

    test('returns zeros when no sessions', () {
      final stats = service.todayStats();
      expect(stats.completedPomodoros, 0);
      expect(stats.totalFocusMinutes, 0);
      expect(stats.totalBreakMinutes, 0);
      expect(stats.currentStreak, 0);
      expect(stats.todaySessions, isEmpty);
    });

    test('counts completed work sessions', () {
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();
      service.startSession(PomodoroPhase.shortBreak);
      service.completeCurrentSession();
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();

      final stats = service.todayStats();
      expect(stats.completedPomodoros, 2);
      expect(stats.totalFocusMinutes, 50); // 2 × 25
      expect(stats.totalBreakMinutes, 5);  // 1 × 5
    });

    test('streak counts consecutive completed work at end', () {
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();
      service.startSession(PomodoroPhase.shortBreak);
      service.completeCurrentSession();
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();

      // Streak should be 1 (only last contiguous work block)
      final stats = service.todayStats();
      expect(stats.currentStreak, 1);
    });

    test('incomplete work session breaks streak', () {
      service.startSession(PomodoroPhase.work);
      service.completeCurrentSession();
      service.startSession(PomodoroPhase.work);
      // Not completed — breaks streak

      final stats = service.todayStats();
      expect(stats.currentStreak, 0);
    });
  });

  group('PomodoroSession', () {
    test('copyWith overrides fields', () {
      final session = PomodoroSession(
        startedAt: DateTime(2026, 3, 8, 10, 0),
        phase: PomodoroPhase.work,
        durationMinutes: 25,
      );
      final completed = session.copyWith(
        completed: true,
        completedAt: DateTime(2026, 3, 8, 10, 25),
      );
      expect(completed.completed, true);
      expect(completed.completedAt, DateTime(2026, 3, 8, 10, 25));
      expect(completed.phase, PomodoroPhase.work); // unchanged
      expect(completed.durationMinutes, 25); // unchanged
    });
  });
}
