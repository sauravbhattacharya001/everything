import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/productivity_score_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/habit.dart';
import 'package:everything/models/goal.dart';
import 'package:everything/models/sleep_entry.dart';
import 'package:everything/models/mood_entry.dart';
import 'package:everything/models/event_checklist.dart';

void main() {
  final today = DateTime(2026, 3, 3);
  final yesterday = DateTime(2026, 3, 2);

  EventModel _makeEvent({
    DateTime? date,
    EventPriority priority = EventPriority.medium,
    EventChecklist? checklist,
  }) {
    return EventModel(
      id: 'e-${date?.day ?? today.day}-${priority.name}',
      title: 'Test Event',
      date: date ?? today,
      priority: priority,
      checklist: checklist,
    );
  }

  Habit _makeHabit({
    String id = 'h1',
    HabitFrequency frequency = HabitFrequency.daily,
    List<int> customDays = const [],
    bool isActive = true,
  }) {
    return Habit(
      id: id,
      name: 'Test Habit',
      frequency: frequency,
      customDays: customDays,
      isActive: isActive,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Goal _makeGoal({
    double progress = 0.5,
    bool isCompleted = false,
    DateTime? deadline,
    DateTime? createdAt,
  }) {
    return Goal(
      id: 'g1',
      title: 'Test Goal',
      progress: progress,
      isCompleted: isCompleted,
      deadline: deadline ?? DateTime(2026, 4, 1),
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      category: GoalCategory.personal,
    );
  }

  SleepEntry _makeSleep({
    SleepQuality quality = SleepQuality.good,
    int durationMinutes = 480,
    DateTime? wakeTime,
  }) {
    final wake = wakeTime ?? DateTime(today.year, today.month, today.day, 7, 0);
    return SleepEntry(
      id: 's1',
      bedtime: wake.subtract(Duration(minutes: durationMinutes)),
      wakeTime: wake,
      quality: quality,
    );
  }

  MoodEntry _makeMood({
    MoodLevel mood = MoodLevel.good,
    DateTime? timestamp,
  }) {
    return MoodEntry(
      id: 'm1',
      mood: mood,
      timestamp: timestamp ?? today,
    );
  }

  // ── ProductivityWeights ────────────────────────────────────

  group('ProductivityWeights', () {
    test('default weights sum to 1.0', () {
      const w = ProductivityWeights();
      expect(w.isValid, isTrue);
      expect(w.total, closeTo(1.0, 0.001));
    });

    test('taskFocused preset is valid', () {
      expect(ProductivityWeights.taskFocused.isValid, isTrue);
    });

    test('wellnessFocused preset is valid', () {
      expect(ProductivityWeights.wellnessFocused.isValid, isTrue);
    });

    test('invalid weights detected', () {
      const w = ProductivityWeights(events: 0.5, habits: 0.5, goals: 0.5);
      expect(w.isValid, isFalse);
    });

    test('negative weights are invalid', () {
      const w = ProductivityWeights(events: -0.1);
      expect(w.isValid, isFalse);
    });

    test('toMap contains all dimensions', () {
      final map = const ProductivityWeights().toMap();
      expect(map.keys, containsAll(['events', 'habits', 'goals', 'sleep', 'mood', 'focus']));
    });

    test('fromMap round-trips', () {
      final original = const ProductivityWeights();
      final restored = ProductivityWeights.fromMap(original.toMap());
      expect(restored.events, original.events);
      expect(restored.habits, original.habits);
      expect(restored.goals, original.goals);
      expect(restored.sleep, original.sleep);
      expect(restored.mood, original.mood);
      expect(restored.focus, original.focus);
    });
  });

  // ── Constructor Validation ─────────────────────────────────

  group('constructor validation', () {
    test('rejects invalid weights', () {
      expect(
        () => ProductivityScoreService(
          weights: const ProductivityWeights(events: 0.9),
        ),
        throwsArgumentError,
      );
    });

    test('rejects zero targetEventsPerDay', () {
      expect(
        () => ProductivityScoreService(targetEventsPerDay: 0),
        throwsArgumentError,
      );
    });

    test('rejects zero targetFocusMinutes', () {
      expect(
        () => ProductivityScoreService(targetFocusMinutes: 0),
        throwsArgumentError,
      );
    });
  });

  // ── Event Scoring ──────────────────────────────────────────

  group('scoreEvents', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService());

    test('empty events returns 0', () {
      expect(service.scoreEvents([], today), 0);
    });

    test('events on different day not counted', () {
      final events = [_makeEvent(date: yesterday)];
      expect(service.scoreEvents(events, today), 0);
    });

    test('events without checklists give partial credit', () {
      final events = [_makeEvent(), _makeEvent()];
      final score = service.scoreEvents(events, today);
      expect(score, greaterThan(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('completed checklists boost score', () {
      final checklist = EventChecklist(items: [
        ChecklistItem(id: '1', title: 'A', completed: true),
        ChecklistItem(id: '2', title: 'B', completed: true),
      ]);
      final events = [_makeEvent(checklist: checklist)];
      final score = service.scoreEvents(events, today);
      expect(score, greaterThan(50));
    });

    test('incomplete checklists lower score', () {
      final complete = EventChecklist(items: [
        ChecklistItem(id: '1', title: 'A', completed: true),
        ChecklistItem(id: '2', title: 'B', completed: true),
      ]);
      final incomplete = EventChecklist(items: [
        ChecklistItem(id: '1', title: 'A', completed: false),
        ChecklistItem(id: '2', title: 'B', completed: false),
      ]);
      final highScore =
          service.scoreEvents([_makeEvent(checklist: complete)], today);
      final lowScore =
          service.scoreEvents([_makeEvent(checklist: incomplete)], today);
      expect(highScore, greaterThan(lowScore));
    });

    test('high-priority events with completed checklist give bonus', () {
      final checklist = EventChecklist(items: [
        ChecklistItem(id: '1', title: 'A', completed: true),
      ]);
      final highPri = [
        _makeEvent(priority: EventPriority.urgent, checklist: checklist),
      ];
      final lowPri = [
        _makeEvent(priority: EventPriority.low, checklist: checklist),
      ];
      final highScore = service.scoreEvents(highPri, today);
      final lowScore = service.scoreEvents(lowPri, today);
      expect(highScore, greaterThanOrEqualTo(lowScore));
    });

    test('score capped at 100', () {
      final events = List.generate(
        20,
        (i) => _makeEvent(
          checklist: EventChecklist(items: [
            ChecklistItem(id: '$i', title: 'Done', completed: true),
          ]),
          priority: EventPriority.urgent,
        ),
      );
      expect(service.scoreEvents(events, today), lessThanOrEqualTo(100));
    });
  });

  // ── Habit Scoring ──────────────────────────────────────────

  group('scoreHabits', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService());

    test('no habits returns 0', () {
      expect(service.scoreHabits([], {}, today), 0);
    });

    test('no habits due today returns 100', () {
      // Weekend habit on a weekday (March 3, 2026 is Tuesday)
      final habits = [_makeHabit(frequency: HabitFrequency.weekends)];
      expect(service.scoreHabits(habits, {}, today), 100);
    });

    test('all habits completed returns 100', () {
      final habits = [_makeHabit(id: 'h1'), _makeHabit(id: 'h2')];
      final completions = {
        'h1': [today],
        'h2': [today],
      };
      expect(service.scoreHabits(habits, completions, today), 100);
    });

    test('half habits completed returns 50', () {
      final habits = [_makeHabit(id: 'h1'), _makeHabit(id: 'h2')];
      final completions = {
        'h1': [today],
      };
      expect(service.scoreHabits(habits, completions, today), 50);
    });

    test('inactive habits excluded', () {
      final habits = [
        _makeHabit(id: 'h1', isActive: true),
        _makeHabit(id: 'h2', isActive: false),
      ];
      final completions = {'h1': [today]};
      expect(service.scoreHabits(habits, completions, today), 100);
    });

    test('weekday habits not due on weekend', () {
      final saturday = DateTime(2026, 3, 7); // Saturday
      final habits = [_makeHabit(frequency: HabitFrequency.weekdays)];
      expect(service.scoreHabits(habits, {}, saturday), 100);
    });

    test('custom day habits checked correctly', () {
      // Tuesday = weekday 2
      final habits = [
        _makeHabit(
          frequency: HabitFrequency.custom,
          customDays: [2], // Tuesday
        ),
      ];
      expect(service.scoreHabits(habits, {}, today), 0); // Not completed
      expect(
        service.scoreHabits(habits, {'h1': [today]}, today),
        100,
      );
    });
  });

  // ── Goal Scoring ───────────────────────────────────────────

  group('scoreGoals', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService());

    test('no goals returns 0', () {
      expect(service.scoreGoals([], today), 0);
    });

    test('all completed goals returns 100', () {
      final goals = [_makeGoal(isCompleted: true)];
      expect(service.scoreGoals(goals, today), 100);
    });

    test('higher progress gives higher score', () {
      final high = [_makeGoal(progress: 80)];
      final low = [_makeGoal(progress: 20)];
      expect(
        service.scoreGoals(high, today),
        greaterThan(service.scoreGoals(low, today)),
      );
    });

    test('past-deadline goals excluded from active', () {
      final pastDeadline = [
        _makeGoal(deadline: DateTime(2026, 2, 1)),
      ];
      // Completed goal exists to avoid 0
      final goals = [
        _makeGoal(isCompleted: true),
        ...pastDeadline,
      ];
      expect(service.scoreGoals(goals, today), 100);
    });

    test('score capped at 100', () {
      final goals = [_makeGoal(progress: 100)];
      expect(service.scoreGoals(goals, today), lessThanOrEqualTo(100));
    });
  });

  // ── Sleep Scoring ──────────────────────────────────────────

  group('scoreSleep', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService());

    test('no sleep data returns 0', () {
      expect(service.scoreSleep([], today), 0);
    });

    test('excellent quality + 8h gives high score', () {
      final entries = [
        _makeSleep(quality: SleepQuality.excellent, durationMinutes: 480),
      ];
      expect(service.scoreSleep(entries, today), 100);
    });

    test('terrible quality gives low score', () {
      final entries = [
        _makeSleep(quality: SleepQuality.terrible, durationMinutes: 480),
      ];
      final score = service.scoreSleep(entries, today);
      expect(score, lessThan(60));
    });

    test('short sleep reduces score', () {
      final good = [
        _makeSleep(quality: SleepQuality.good, durationMinutes: 480),
      ];
      final short = [
        _makeSleep(quality: SleepQuality.good, durationMinutes: 240),
      ];
      expect(
        service.scoreSleep(good, today),
        greaterThan(service.scoreSleep(short, today)),
      );
    });

    test('6 hours gives moderate duration score', () {
      final entries = [
        _makeSleep(quality: SleepQuality.excellent, durationMinutes: 360),
      ];
      final score = service.scoreSleep(entries, today);
      expect(score, greaterThan(70));
      expect(score, lessThan(100));
    });

    test('oversleep slightly penalized', () {
      final optimal = [
        _makeSleep(quality: SleepQuality.good, durationMinutes: 480),
      ];
      final over = [
        _makeSleep(quality: SleepQuality.good, durationMinutes: 600),
      ];
      expect(
        service.scoreSleep(optimal, today),
        greaterThanOrEqualTo(service.scoreSleep(over, today)),
      );
    });
  });

  // ── Mood Scoring ───────────────────────────────────────────

  group('scoreMood', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService());

    test('no mood entries returns 0', () {
      expect(service.scoreMood([], today), 0);
    });

    test('great mood returns 100', () {
      expect(
        service.scoreMood([_makeMood(mood: MoodLevel.great)], today),
        100,
      );
    });

    test('veryBad mood returns 20', () {
      expect(
        service.scoreMood([_makeMood(mood: MoodLevel.veryBad)], today),
        20,
      );
    });

    test('multiple entries averaged', () {
      final entries = [
        _makeMood(mood: MoodLevel.great),
        _makeMood(mood: MoodLevel.bad),
      ];
      final score = service.scoreMood(entries, today);
      // great=5, bad=2, avg=3.5, score=70
      expect(score, closeTo(70, 1));
    });

    test('entries on different day ignored', () {
      expect(
        service.scoreMood([_makeMood(timestamp: yesterday)], today),
        0,
      );
    });
  });

  // ── Focus Scoring ──────────────────────────────────────────

  group('scoreFocus', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService(targetFocusMinutes: 120));

    test('zero minutes returns 0', () {
      expect(service.scoreFocus(0), 0);
    });

    test('negative minutes returns 0', () {
      expect(service.scoreFocus(-10), 0);
    });

    test('target minutes returns 100', () {
      expect(service.scoreFocus(120), 100);
    });

    test('half target returns ~50', () {
      expect(service.scoreFocus(60), closeTo(50, 1));
    });

    test('above target capped at 100', () {
      expect(service.scoreFocus(200), lessThanOrEqualTo(100));
    });
  });

  // ── Daily Composite Score ──────────────────────────────────

  group('computeDailyScore', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService());

    test('all zeros gives needs-work grade', () {
      final score = service.computeDailyScore(
        date: today,
        events: [],
        habits: [],
        habitCompletions: {},
        goals: [],
        sleepEntries: [],
        moodEntries: [],
        focusMinutes: 0,
      );
      expect(score.overallScore, 0);
      expect(score.grade, ProductivityGrade.needsWork);
      expect(score.dimensions, hasLength(6));
    });

    test('perfect day gives excellent grade', () {
      final checklist = EventChecklist(items: [
        ChecklistItem(id: '1', title: 'A', completed: true),
      ]);
      final score = service.computeDailyScore(
        date: today,
        events: List.generate(5, (_) => _makeEvent(
          priority: EventPriority.urgent,
          checklist: checklist,
        )),
        habits: [_makeHabit()],
        habitCompletions: {'h1': [today]},
        goals: [_makeGoal(progress: 90)],
        sleepEntries: [
          _makeSleep(quality: SleepQuality.excellent, durationMinutes: 480),
        ],
        moodEntries: [_makeMood(mood: MoodLevel.great)],
        focusMinutes: 120,
      );
      expect(score.overallScore, greaterThan(80));
      expect(score.grade, ProductivityGrade.excellent);
    });

    test('dimensions have correct names', () {
      final score = service.computeDailyScore(
        date: today,
        events: [],
        habits: [],
        habitCompletions: {},
        goals: [],
        sleepEntries: [],
        moodEntries: [],
        focusMinutes: 0,
      );
      final names = score.dimensions.map((d) => d.name).toList();
      expect(names, ['Events', 'Habits', 'Goals', 'Sleep', 'Mood', 'Focus']);
    });

    test('strengths populated for high-scoring dimensions', () {
      final score = service.computeDailyScore(
        date: today,
        events: [],
        habits: [_makeHabit()],
        habitCompletions: {'h1': [today]},
        goals: [],
        sleepEntries: [
          _makeSleep(quality: SleepQuality.excellent, durationMinutes: 480),
        ],
        moodEntries: [_makeMood(mood: MoodLevel.great)],
        focusMinutes: 120,
      );
      expect(score.strengths, isNotEmpty);
    });

    test('improvements populated for low-scoring dimensions', () {
      final score = service.computeDailyScore(
        date: today,
        events: [],
        habits: [_makeHabit()],
        habitCompletions: {},
        goals: [_makeGoal(progress: 10)],
        sleepEntries: [],
        moodEntries: [],
        focusMinutes: 0,
      );
      expect(score.improvements, isNotEmpty);
    });

    test('toMap includes all fields', () {
      final score = service.computeDailyScore(
        date: today,
        events: [],
        habits: [],
        habitCompletions: {},
        goals: [],
        sleepEntries: [],
        moodEntries: [],
        focusMinutes: 0,
      );
      final map = score.toMap();
      expect(map.containsKey('date'), isTrue);
      expect(map.containsKey('overallScore'), isTrue);
      expect(map.containsKey('grade'), isTrue);
      expect(map.containsKey('dimensions'), isTrue);
      expect(map.containsKey('strengths'), isTrue);
      expect(map.containsKey('improvements'), isTrue);
    });

    test('custom weights affect scoring', () {
      final eventHeavy = ProductivityScoreService(
        weights: ProductivityWeights.taskFocused,
      );
      final wellnessHeavy = ProductivityScoreService(
        weights: ProductivityWeights.wellnessFocused,
      );

      // High events, low sleep
      final checklist = EventChecklist(items: [
        ChecklistItem(id: '1', title: 'A', completed: true),
      ]);
      final args = {
        'date': today,
        'events': List.generate(5, (_) => _makeEvent(checklist: checklist)),
        'habits': <Habit>[],
        'habitCompletions': <String, List<DateTime>>{},
        'goals': <Goal>[],
        'sleepEntries': <SleepEntry>[],
        'moodEntries': <MoodEntry>[],
        'focusMinutes': 0,
      };

      final eventScore = eventHeavy.computeDailyScore(
        date: args['date'] as DateTime,
        events: args['events'] as List<EventModel>,
        habits: args['habits'] as List<Habit>,
        habitCompletions: args['habitCompletions'] as Map<String, List<DateTime>>,
        goals: args['goals'] as List<Goal>,
        sleepEntries: args['sleepEntries'] as List<SleepEntry>,
        moodEntries: args['moodEntries'] as List<MoodEntry>,
        focusMinutes: args['focusMinutes'] as int,
      );
      final wellnessScore = wellnessHeavy.computeDailyScore(
        date: args['date'] as DateTime,
        events: args['events'] as List<EventModel>,
        habits: args['habits'] as List<Habit>,
        habitCompletions: args['habitCompletions'] as Map<String, List<DateTime>>,
        goals: args['goals'] as List<Goal>,
        sleepEntries: args['sleepEntries'] as List<SleepEntry>,
        moodEntries: args['moodEntries'] as List<MoodEntry>,
        focusMinutes: args['focusMinutes'] as int,
      );

      // Event-heavy should score higher when events are strong
      expect(eventScore.overallScore, greaterThan(wellnessScore.overallScore));
    });
  });

  // ── Trend Analysis ─────────────────────────────────────────

  group('analyzeTrend', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService());

    DailyProductivityScore _fakeScore(DateTime date, double score) {
      return DailyProductivityScore(
        date: date,
        overallScore: score,
        grade: ProductivityGrade.good,
        dimensions: [
          DimensionScore(
            name: 'Events', score: score, weight: 0.25,
            contribution: score * 0.25, insight: '',
          ),
          DimensionScore(
            name: 'Habits', score: score, weight: 0.20,
            contribution: score * 0.20, insight: '',
          ),
          DimensionScore(
            name: 'Goals', score: score, weight: 0.20,
            contribution: score * 0.20, insight: '',
          ),
          DimensionScore(
            name: 'Sleep', score: score, weight: 0.15,
            contribution: score * 0.15, insight: '',
          ),
          DimensionScore(
            name: 'Mood', score: score, weight: 0.10,
            contribution: score * 0.10, insight: '',
          ),
          DimensionScore(
            name: 'Focus', score: score, weight: 0.10,
            contribution: score * 0.10, insight: '',
          ),
        ],
        strengths: [],
        improvements: [],
      );
    }

    test('empty scores returns zeroed trend', () {
      final trend = service.analyzeTrend([]);
      expect(trend.averageScore, 0);
      expect(trend.bestScore, 0);
      expect(trend.worstScore, 0);
      expect(trend.direction, TrendDirection.stable);
      expect(trend.streak, 0);
    });

    test('single score returns that score', () {
      final trend = service.analyzeTrend([_fakeScore(today, 75)]);
      expect(trend.averageScore, 75);
      expect(trend.bestScore, 75);
      expect(trend.worstScore, 75);
    });

    test('rising scores detected', () {
      final scores = List.generate(
        7,
        (i) => _fakeScore(
          today.subtract(Duration(days: 6 - i)),
          40.0 + i * 10.0,
        ),
      );
      final trend = service.analyzeTrend(scores);
      expect(trend.direction, TrendDirection.rising);
      expect(trend.trendSlope, greaterThan(0));
    });

    test('declining scores detected', () {
      final scores = List.generate(
        7,
        (i) => _fakeScore(
          today.subtract(Duration(days: 6 - i)),
          90.0 - i * 10.0,
        ),
      );
      final trend = service.analyzeTrend(scores);
      expect(trend.direction, TrendDirection.declining);
      expect(trend.trendSlope, lessThan(0));
    });

    test('stable scores detected', () {
      final scores = List.generate(
        7,
        (i) => _fakeScore(
          today.subtract(Duration(days: 6 - i)),
          70.0 + (i.isEven ? 0.5 : -0.5),
        ),
      );
      final trend = service.analyzeTrend(scores);
      expect(trend.direction, TrendDirection.stable);
    });

    test('best and worst days identified', () {
      final scores = [
        _fakeScore(DateTime(2026, 3, 1), 50),
        _fakeScore(DateTime(2026, 3, 2), 90),
        _fakeScore(DateTime(2026, 3, 3), 30),
      ];
      final trend = service.analyzeTrend(scores);
      expect(trend.bestScore, 90);
      expect(trend.worstScore, 30);
      expect(trend.bestDay, DateTime(2026, 3, 2));
      expect(trend.worstDay, DateTime(2026, 3, 3));
    });

    test('streak counts consecutive days >= 60', () {
      final scores = [
        _fakeScore(DateTime(2026, 3, 1), 40),
        _fakeScore(DateTime(2026, 3, 2), 70),
        _fakeScore(DateTime(2026, 3, 3), 80),
        _fakeScore(DateTime(2026, 3, 4), 65),
      ];
      final trend = service.analyzeTrend(scores);
      expect(trend.streak, 3); // Last 3 are >= 60
    });

    test('streak breaks on score below 60', () {
      final scores = [
        _fakeScore(DateTime(2026, 3, 1), 70),
        _fakeScore(DateTime(2026, 3, 2), 50), // break
        _fakeScore(DateTime(2026, 3, 3), 80),
      ];
      final trend = service.analyzeTrend(scores);
      expect(trend.streak, 1); // Only the last day
    });

    test('dimension averages computed', () {
      final scores = [
        _fakeScore(DateTime(2026, 3, 1), 60),
        _fakeScore(DateTime(2026, 3, 2), 80),
      ];
      final trend = service.analyzeTrend(scores);
      expect(trend.dimensionAverages['Events'], closeTo(70, 1));
    });

    test('top strength and weakness identified', () {
      final score1 = DailyProductivityScore(
        date: today,
        overallScore: 65,
        grade: ProductivityGrade.good,
        dimensions: [
          DimensionScore(name: 'Events', score: 90, weight: 0.25, contribution: 22.5, insight: ''),
          DimensionScore(name: 'Habits', score: 30, weight: 0.20, contribution: 6, insight: ''),
          DimensionScore(name: 'Goals', score: 60, weight: 0.20, contribution: 12, insight: ''),
          DimensionScore(name: 'Sleep', score: 70, weight: 0.15, contribution: 10.5, insight: ''),
          DimensionScore(name: 'Mood', score: 80, weight: 0.10, contribution: 8, insight: ''),
          DimensionScore(name: 'Focus', score: 50, weight: 0.10, contribution: 5, insight: ''),
        ],
        strengths: [],
        improvements: [],
      );
      final trend = service.analyzeTrend([score1]);
      expect(trend.topStrength, 'Events');
      expect(trend.topWeakness, 'Habits');
    });

    test('toMap includes all fields', () {
      final trend = service.analyzeTrend([_fakeScore(today, 70)]);
      final map = trend.toMap();
      expect(map.containsKey('averageScore'), isTrue);
      expect(map.containsKey('direction'), isTrue);
      expect(map.containsKey('streak'), isTrue);
      expect(map.containsKey('dimensionAverages'), isTrue);
    });
  });

  // ── Weekly Summary ─────────────────────────────────────────

  group('weeklySummary', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService());

    DailyProductivityScore _fakeScore(DateTime date, double score) {
      return DailyProductivityScore(
        date: date,
        overallScore: score,
        grade: ProductivityGrade.good,
        dimensions: [
          DimensionScore(name: 'Events', score: score, weight: 0.25, contribution: score * 0.25, insight: ''),
          DimensionScore(name: 'Habits', score: score, weight: 0.20, contribution: score * 0.20, insight: ''),
          DimensionScore(name: 'Goals', score: score, weight: 0.20, contribution: score * 0.20, insight: ''),
          DimensionScore(name: 'Sleep', score: score, weight: 0.15, contribution: score * 0.15, insight: ''),
          DimensionScore(name: 'Mood', score: score, weight: 0.10, contribution: score * 0.10, insight: ''),
          DimensionScore(name: 'Focus', score: score, weight: 0.10, contribution: score * 0.10, insight: ''),
        ],
        strengths: [],
        improvements: [],
      );
    }

    test('improvement detected when this week higher', () {
      final thisWeek = [_fakeScore(today, 80)];
      final lastWeek = [_fakeScore(yesterday, 60)];
      final summary = service.weeklySummary(thisWeek, lastWeek);
      expect(summary['improving'], isTrue);
      expect(summary['change'], greaterThan(0));
    });

    test('decline detected when this week lower', () {
      final thisWeek = [_fakeScore(today, 50)];
      final lastWeek = [_fakeScore(yesterday, 80)];
      final summary = service.weeklySummary(thisWeek, lastWeek);
      expect(summary['improving'], isFalse);
      expect(summary['change'], lessThan(0));
    });

    test('dimension changes computed', () {
      final thisWeek = [_fakeScore(today, 80)];
      final lastWeek = [_fakeScore(yesterday, 60)];
      final summary = service.weeklySummary(thisWeek, lastWeek);
      final dimChanges = summary['dimensionChanges'] as Map<String, double>;
      expect(dimChanges['Events'], 20);
    });

    test('summary contains all expected keys', () {
      final thisWeek = [_fakeScore(today, 70)];
      final lastWeek = [_fakeScore(yesterday, 70)];
      final summary = service.weeklySummary(thisWeek, lastWeek);
      expect(summary.containsKey('thisWeek'), isTrue);
      expect(summary.containsKey('lastWeek'), isTrue);
      expect(summary.containsKey('change'), isTrue);
      expect(summary.containsKey('improving'), isTrue);
      expect(summary.containsKey('dimensionChanges'), isTrue);
    });
  });

  // ── Grade Labels ───────────────────────────────────────────

  group('ProductivityGrade', () {
    test('all grades have labels', () {
      for (final grade in ProductivityGrade.values) {
        expect(grade.label, isNotEmpty);
        expect(grade.emoji, isNotEmpty);
      }
    });
  });

  // ── Edge Cases ─────────────────────────────────────────────

  group('edge cases', () {
    late ProductivityScoreService service;
    setUp(() => service = ProductivityScoreService());

    test('dimension contribution equals score times weight', () {
      final result = service.computeDailyScore(
        date: today,
        events: [_makeEvent()],
        habits: [],
        habitCompletions: {},
        goals: [],
        sleepEntries: [],
        moodEntries: [],
        focusMinutes: 60,
      );
      for (final dim in result.dimensions) {
        final expected = (dim.score * dim.weight * 100).roundToDouble() / 100;
        expect(dim.contribution, closeTo(expected, 0.02));
      }
    });

    test('overall score is sum of contributions', () {
      final result = service.computeDailyScore(
        date: today,
        events: [_makeEvent()],
        habits: [_makeHabit()],
        habitCompletions: {'h1': [today]},
        goals: [_makeGoal()],
        sleepEntries: [_makeSleep()],
        moodEntries: [_makeMood()],
        focusMinutes: 60,
      );
      final sumContributions =
          result.dimensions.fold<double>(0, (s, d) => s + d.contribution);
      expect(result.overallScore, closeTo(sumContributions, 0.1));
    });
  });
}
