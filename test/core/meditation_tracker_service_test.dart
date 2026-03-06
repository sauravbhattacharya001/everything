import 'package:test/test.dart';
import 'package:everything/models/meditation_entry.dart';
import 'package:everything/core/services/meditation_tracker_service.dart';

void main() {
  group('MeditationEntry', () {
    test('toJson/fromJson round-trip', () {
      final entry = MeditationEntry(
        id: 'm1',
        dateTime: DateTime(2026, 3, 6, 8, 0),
        durationMinutes: 15,
        type: MeditationType.breathing,
        preMood: 4,
        postMood: 7,
        note: 'Morning session',
        guideName: 'Calm',
      );

      final json = entry.toJson();
      final restored = MeditationEntry.fromJson(json);

      expect(restored.id, 'm1');
      expect(restored.durationMinutes, 15);
      expect(restored.type, MeditationType.breathing);
      expect(restored.preMood, 4);
      expect(restored.postMood, 7);
      expect(restored.moodDelta, 3);
      expect(restored.note, 'Morning session');
      expect(restored.guideName, 'Calm');
      expect(restored.interrupted, false);
    });

    test('moodDelta returns null when moods missing', () {
      final entry = MeditationEntry(
        id: 'm2',
        dateTime: DateTime.now(),
        durationMinutes: 10,
      );
      expect(entry.moodDelta, isNull);
    });

    test('encodeList/decodeList round-trip', () {
      final entries = [
        MeditationEntry(id: 'a', dateTime: DateTime(2026, 1, 1), durationMinutes: 5),
        MeditationEntry(id: 'b', dateTime: DateTime(2026, 1, 2), durationMinutes: 10),
      ];
      final json = MeditationEntry.encodeList(entries);
      final decoded = MeditationEntry.decodeList(json);
      expect(decoded.length, 2);
      expect(decoded[0].id, 'a');
      expect(decoded[1].durationMinutes, 10);
    });

    test('copyWith preserves and overrides fields', () {
      final entry = MeditationEntry(
        id: 'c',
        dateTime: DateTime(2026, 3, 1),
        durationMinutes: 20,
        type: MeditationType.mantra,
        preMood: 5,
        postMood: 8,
      );
      final copy = entry.copyWith(durationMinutes: 30, type: MeditationType.walking);
      expect(copy.id, 'c');
      expect(copy.durationMinutes, 30);
      expect(copy.type, MeditationType.walking);
      expect(copy.preMood, 5);
    });
  });

  group('MeditationType', () {
    test('all types have labels and emojis', () {
      for (final t in MeditationType.values) {
        expect(t.label.isNotEmpty, true);
        expect(t.emoji.isNotEmpty, true);
      }
    });
  });

  group('MeditationTrackerService', () {
    late MeditationTrackerService service;

    setUp(() {
      service = MeditationTrackerService(
        config: const MeditationConfig(dailyGoalMinutes: 15, weeklySessionGoal: 5),
      );
    });

    MeditationEntry _makeEntry({
      required String id,
      required DateTime dateTime,
      int duration = 15,
      MeditationType type = MeditationType.mindfulness,
      int? preMood,
      int? postMood,
      bool interrupted = false,
    }) {
      return MeditationEntry(
        id: id,
        dateTime: dateTime,
        durationMinutes: duration,
        type: type,
        preMood: preMood,
        postMood: postMood,
        interrupted: interrupted,
      );
    }

    test('addSession sorts by date', () {
      service.addSession(_makeEntry(id: 'b', dateTime: DateTime(2026, 3, 2)));
      service.addSession(_makeEntry(id: 'a', dateTime: DateTime(2026, 3, 1)));
      expect(service.sessions[0].id, 'a');
      expect(service.sessions[1].id, 'b');
    });

    test('removeSession returns false for missing id', () {
      expect(service.removeSession('nope'), false);
    });

    test('removeSession removes and returns true', () {
      service.addSession(_makeEntry(id: 'x', dateTime: DateTime(2026, 3, 1)));
      expect(service.removeSession('x'), true);
      expect(service.sessions.isEmpty, true);
    });

    test('getSession finds by id', () {
      service.addSession(_makeEntry(id: 'find-me', dateTime: DateTime(2026, 3, 1)));
      expect(service.getSession('find-me')?.id, 'find-me');
      expect(service.getSession('nope'), isNull);
    });

    test('updateSession replaces and re-sorts', () {
      service.addSession(_makeEntry(id: 'u1', dateTime: DateTime(2026, 3, 5), duration: 10));
      service.updateSession(_makeEntry(id: 'u1', dateTime: DateTime(2026, 3, 5), duration: 25));
      expect(service.getSession('u1')!.durationMinutes, 25);
    });

    test('getSessionsForDate filters correctly', () {
      service.addSession(_makeEntry(id: 'd1', dateTime: DateTime(2026, 3, 1, 8)));
      service.addSession(_makeEntry(id: 'd2', dateTime: DateTime(2026, 3, 1, 20)));
      service.addSession(_makeEntry(id: 'd3', dateTime: DateTime(2026, 3, 2)));
      final march1 = service.getSessionsForDate(DateTime(2026, 3, 1));
      expect(march1.length, 2);
    });

    test('getSessionsByType filters correctly', () {
      service.addSession(_makeEntry(id: 't1', dateTime: DateTime(2026, 3, 1), type: MeditationType.breathing));
      service.addSession(_makeEntry(id: 't2', dateTime: DateTime(2026, 3, 2), type: MeditationType.mantra));
      service.addSession(_makeEntry(id: 't3', dateTime: DateTime(2026, 3, 3), type: MeditationType.breathing));
      expect(service.getSessionsByType(MeditationType.breathing).length, 2);
    });

    test('getDailySummary computes goal progress', () {
      service.addSession(_makeEntry(id: 'ds1', dateTime: DateTime(2026, 3, 1, 8), duration: 10, preMood: 3, postMood: 6));
      service.addSession(_makeEntry(id: 'ds2', dateTime: DateTime(2026, 3, 1, 20), duration: 8, preMood: 5, postMood: 7));
      final summary = service.getDailySummary(DateTime(2026, 3, 1));
      expect(summary.sessionCount, 2);
      expect(summary.totalMinutes, 18);
      expect(summary.goalMet, true); // 18 >= 15
      expect(summary.avgMoodDelta, closeTo(2.5, 0.01)); // (3+2)/2
    });

    test('getWeeklySummary includes type breakdown', () {
      final monday = DateTime(2026, 3, 2); // Monday
      service.addSession(_makeEntry(id: 'w1', dateTime: monday, type: MeditationType.breathing));
      service.addSession(_makeEntry(id: 'w2', dateTime: monday.add(const Duration(days: 1)), type: MeditationType.breathing));
      service.addSession(_makeEntry(id: 'w3', dateTime: monday.add(const Duration(days: 2)), type: MeditationType.visualization));

      final summary = service.getWeeklySummary(monday);
      expect(summary.sessionCount, 3);
      expect(summary.typeBreakdown[MeditationType.breathing], 2);
      expect(summary.typeBreakdown[MeditationType.visualization], 1);
    });

    test('getStreak computes consecutive days', () {
      // 3-day streak
      service.addSession(_makeEntry(id: 's1', dateTime: DateTime(2026, 3, 1)));
      service.addSession(_makeEntry(id: 's2', dateTime: DateTime(2026, 3, 2)));
      service.addSession(_makeEntry(id: 's3', dateTime: DateTime(2026, 3, 3)));
      // gap
      service.addSession(_makeEntry(id: 's4', dateTime: DateTime(2026, 3, 5)));
      service.addSession(_makeEntry(id: 's5', dateTime: DateTime(2026, 3, 6)));

      final streak = service.getStreak();
      expect(streak.longestDays, 3);
      expect(streak.currentDays, 2); // Mar 5-6
      expect(streak.totalSessions, 5);
    });

    test('empty streak returns zeros', () {
      final streak = service.getStreak();
      expect(streak.currentDays, 0);
      expect(streak.longestDays, 0);
      expect(streak.totalSessions, 0);
    });

    test('analyzeTechniqueMoodImpact ranks by mood delta', () {
      service.addSession(_makeEntry(id: 'mi1', dateTime: DateTime(2026, 3, 1), type: MeditationType.breathing, preMood: 3, postMood: 8));
      service.addSession(_makeEntry(id: 'mi2', dateTime: DateTime(2026, 3, 2), type: MeditationType.mantra, preMood: 5, postMood: 6));
      service.addSession(_makeEntry(id: 'mi3', dateTime: DateTime(2026, 3, 3), type: MeditationType.breathing, preMood: 4, postMood: 7));

      final impacts = service.analyzeTechniqueMoodImpact();
      expect(impacts.first.type, MeditationType.breathing); // higher delta
      expect(impacts.first.avgMoodDelta, closeTo(4.0, 0.01)); // (5+3)/2 = 4
    });

    test('generateInsights returns tips for empty service', () {
      final insights = service.generateInsights();
      expect(insights.length, 1);
      expect(insights.first.contains('Start'), true);
    });

    test('generateReport produces valid summary', () {
      service.addSession(_makeEntry(id: 'r1', dateTime: DateTime(2026, 3, 1), duration: 20, preMood: 3, postMood: 7));
      service.addSession(_makeEntry(id: 'r2', dateTime: DateTime(2026, 3, 2), duration: 10, preMood: 5, postMood: 6, interrupted: true));

      final report = service.generateReport();
      expect(report.totalSessions, 2);
      expect(report.totalMinutes, 30);
      expect(report.avgSessionMinutes, 15.0);
      expect(report.avgMoodDelta, closeTo(2.5, 0.01));
      expect(report.completionRate, 50.0); // 1 of 2 not interrupted
      expect(report.toTextSummary().contains('Meditation Report'), true);
    });

    test('toJson/fromJson round-trip', () {
      service.addSession(_makeEntry(id: 'j1', dateTime: DateTime(2026, 3, 1), duration: 12, type: MeditationType.visualization));
      final json = service.toJson();
      final restored = MeditationTrackerService.fromJson(json);
      expect(restored.sessions.length, 1);
      expect(restored.sessions.first.type, MeditationType.visualization);
      expect(restored.config.dailyGoalMinutes, 15);
    });

    test('getTypeFrequency counts correctly', () {
      service.addSession(_makeEntry(id: 'f1', dateTime: DateTime(2026, 3, 1), type: MeditationType.breathing));
      service.addSession(_makeEntry(id: 'f2', dateTime: DateTime(2026, 3, 2), type: MeditationType.breathing));
      service.addSession(_makeEntry(id: 'f3', dateTime: DateTime(2026, 3, 3), type: MeditationType.mantra));
      final freq = service.getTypeFrequency();
      expect(freq[MeditationType.breathing], 2);
      expect(freq[MeditationType.mantra], 1);
    });
  });

  group('MeditationConfig', () {
    test('toJson/fromJson round-trip', () {
      const config = MeditationConfig(
        dailyGoalMinutes: 20,
        weeklySessionGoal: 7,
        defaultType: MeditationType.walking,
      );
      final json = config.toJson();
      final restored = MeditationConfig.fromJson(json);
      expect(restored.dailyGoalMinutes, 20);
      expect(restored.weeklySessionGoal, 7);
      expect(restored.defaultType, MeditationType.walking);
    });

    test('defaults are sensible', () {
      const config = MeditationConfig();
      expect(config.dailyGoalMinutes, 15);
      expect(config.weeklySessionGoal, 5);
      expect(config.defaultType, MeditationType.mindfulness);
    });
  });
}
