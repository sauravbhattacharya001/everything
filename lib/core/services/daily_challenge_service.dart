import 'dart:math';

/// Category for daily challenges.
enum ChallengeCategory {
  fitness(icon: '💪', label: 'Fitness', colorValue: 0xFFE53935),
  learning(icon: '📚', label: 'Learning', colorValue: 0xFF1E88E5),
  creativity(icon: '🎨', label: 'Creativity', colorValue: 0xFF8E24AA),
  social(icon: '🤝', label: 'Social', colorValue: 0xFF43A047),
  mindfulness(icon: '🧘', label: 'Mindfulness', colorValue: 0xFF00ACC1),
  productivity(icon: '⚡', label: 'Productivity', colorValue: 0xFFFB8C00);

  final String icon;
  final String label;
  final int colorValue;
  const ChallengeCategory(
      {required this.icon, required this.label, required this.colorValue});
}

/// Difficulty level for a challenge.
enum ChallengeDifficulty {
  easy(label: 'Easy', colorValue: 0xFF4CAF50),
  medium(label: 'Medium', colorValue: 0xFFFF9800),
  hard(label: 'Hard', colorValue: 0xFFF44336);

  final String label;
  final int colorValue;
  const ChallengeDifficulty({required this.label, required this.colorValue});
}

/// A single daily challenge definition.
class DailyChallenge {
  final int id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final int estimatedMinutes;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedMinutes,
  });
}

/// Record of a completed or skipped challenge.
class ChallengeRecord {
  final DailyChallenge challenge;
  final DateTime date;
  final bool completed;
  final String? notes;

  ChallengeRecord({
    required this.challenge,
    required this.date,
    required this.completed,
    this.notes,
  });
}

/// Service that manages daily challenges, history, and streaks.
class DailyChallengeService {
  final List<ChallengeRecord> _history = [];

  List<ChallengeRecord> get history => List.unmodifiable(_history);

  static const List<DailyChallenge> _challenges = [
    // Fitness
    DailyChallenge(id: 1, title: 'Walk 10,000 Steps', description: 'Get moving! Track your steps and hit 10K today.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 60),
    DailyChallenge(id: 2, title: '20 Push-ups', description: 'Drop and give me 20! Break them into sets if needed.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 5),
    DailyChallenge(id: 3, title: '5-Minute Plank', description: 'Hold a plank for 5 minutes total. Take breaks as needed.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.hard, estimatedMinutes: 10),
    DailyChallenge(id: 4, title: 'Stretch for 15 Minutes', description: 'Do a full-body stretching routine. Focus on tight areas.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 15),
    DailyChallenge(id: 5, title: '30-Minute Jog', description: 'Go for a steady jog around your neighborhood.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 30),
    DailyChallenge(id: 6, title: '50 Squats', description: 'Do 50 bodyweight squats throughout the day.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 15),
    DailyChallenge(id: 7, title: 'Take the Stairs All Day', description: 'Avoid elevators and escalators completely today.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 0),
    DailyChallenge(id: 8, title: '7-Minute HIIT Workout', description: 'Do a quick high-intensity interval training session.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 7),
    DailyChallenge(id: 9, title: 'Dance for 20 Minutes', description: 'Put on your favorite music and dance like nobody is watching.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 20),
    DailyChallenge(id: 10, title: 'Balance Challenge', description: 'Stand on one foot for 1 minute per side, 5 rounds.', category: ChallengeCategory.fitness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 10),

    // Learning
    DailyChallenge(id: 11, title: 'Learn 10 New Words', description: 'Pick a language or expand your vocabulary with 10 new words.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 20),
    DailyChallenge(id: 12, title: 'Read for 30 Minutes', description: 'Read a book, article, or paper on a topic you want to learn about.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 30),
    DailyChallenge(id: 13, title: 'Watch a TED Talk', description: 'Watch a TED talk on a topic outside your comfort zone.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 20),
    DailyChallenge(id: 14, title: 'Teach Someone Something', description: 'Explain a concept you know well to someone else.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 30),
    DailyChallenge(id: 15, title: 'Solve a Brain Teaser', description: 'Find and solve a logic puzzle, riddle, or math problem.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 15),
    DailyChallenge(id: 16, title: 'Learn a Keyboard Shortcut', description: 'Master 5 new keyboard shortcuts for your most-used app.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 10),
    DailyChallenge(id: 17, title: 'Write a Summary', description: 'Read an article and write a one-paragraph summary from memory.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 25),
    DailyChallenge(id: 18, title: 'Explore a Wikipedia Rabbit Hole', description: 'Start on a random Wikipedia page and follow links for 20 minutes.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 20),
    DailyChallenge(id: 19, title: 'Practice Mental Math', description: 'Do 20 mental math problems without a calculator.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 15),
    DailyChallenge(id: 20, title: 'Study a Historical Event', description: 'Pick a date in history and learn what happened that day.', category: ChallengeCategory.learning, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 20),

    // Creativity
    DailyChallenge(id: 21, title: 'Sketch Something', description: 'Draw anything — your coffee cup, a pet, an imaginary creature.', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 15),
    DailyChallenge(id: 22, title: 'Write a Haiku', description: 'Write 3 haikus about your day (5-7-5 syllable pattern).', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 10),
    DailyChallenge(id: 23, title: 'Cook Something New', description: 'Try a recipe you have never made before.', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 60),
    DailyChallenge(id: 24, title: 'Take 10 Creative Photos', description: 'Find interesting angles, lighting, or subjects around you.', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 20),
    DailyChallenge(id: 25, title: 'Write a Short Story', description: 'Write a 500-word story with a beginning, middle, and end.', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.hard, estimatedMinutes: 45),
    DailyChallenge(id: 26, title: 'Create a Playlist', description: 'Curate a themed playlist of 15+ songs for a specific mood.', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 20),
    DailyChallenge(id: 27, title: 'Rearrange a Space', description: 'Reorganize your desk, shelf, or a room corner for fresh energy.', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 30),
    DailyChallenge(id: 28, title: 'Doodle a Map', description: 'Draw a fantasy map of an imaginary world or neighborhood.', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 20),
    DailyChallenge(id: 29, title: 'Write a Letter', description: 'Write a handwritten letter to someone — mail it or keep it.', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 20),
    DailyChallenge(id: 30, title: 'Build Something', description: 'Use LEGO, cardboard, or code to build something from scratch.', category: ChallengeCategory.creativity, difficulty: ChallengeDifficulty.hard, estimatedMinutes: 60),

    // Social
    DailyChallenge(id: 31, title: 'Compliment 3 People', description: 'Give genuine, specific compliments to three different people.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 5),
    DailyChallenge(id: 32, title: 'Call an Old Friend', description: 'Reach out to someone you have not talked to in a while.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 30),
    DailyChallenge(id: 33, title: 'Have a Deep Conversation', description: 'Ask someone a meaningful question and really listen.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 30),
    DailyChallenge(id: 34, title: 'Write a Thank-You Note', description: 'Send a heartfelt thank-you message to someone who helped you.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 10),
    DailyChallenge(id: 35, title: 'Help a Stranger', description: 'Hold a door, give directions, or help someone carry something.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 5),
    DailyChallenge(id: 36, title: 'Share a Meal', description: 'Eat lunch or dinner with someone — no phones allowed.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 45),
    DailyChallenge(id: 37, title: 'Introduce Two People', description: 'Connect two people in your life who should know each other.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 10),
    DailyChallenge(id: 38, title: 'Listen Without Interrupting', description: 'In every conversation today, let others finish before responding.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 0),
    DailyChallenge(id: 39, title: 'Leave a Positive Review', description: 'Write a thoughtful positive review for a local business you like.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 10),
    DailyChallenge(id: 40, title: 'Volunteer Your Time', description: 'Spend an hour helping a cause or person who needs it.', category: ChallengeCategory.social, difficulty: ChallengeDifficulty.hard, estimatedMinutes: 60),

    // Mindfulness
    DailyChallenge(id: 41, title: 'Meditate for 10 Minutes', description: 'Sit quietly, focus on your breath, and let thoughts pass.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 10),
    DailyChallenge(id: 42, title: 'Digital Detox Hour', description: 'Put away all screens for one full hour.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 60),
    DailyChallenge(id: 43, title: 'Gratitude Journal', description: 'Write down 10 things you are grateful for today.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 10),
    DailyChallenge(id: 44, title: 'Mindful Walk', description: 'Go for a 15-minute walk and notice 5 things you see, hear, smell.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 15),
    DailyChallenge(id: 45, title: 'Body Scan', description: 'Do a full body scan meditation from head to toe.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 20),
    DailyChallenge(id: 46, title: 'Eat One Meal Mindfully', description: 'Eat slowly, savor each bite, no screens during the meal.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 30),
    DailyChallenge(id: 47, title: 'Journaling Session', description: 'Free-write for 15 minutes about whatever comes to mind.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 15),
    DailyChallenge(id: 48, title: 'Single-Task Day', description: 'No multitasking today. Do one thing at a time, fully present.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.hard, estimatedMinutes: 0),
    DailyChallenge(id: 49, title: 'Breathing Exercise', description: 'Do 4-7-8 breathing: inhale 4s, hold 7s, exhale 8s. 10 rounds.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 10),
    DailyChallenge(id: 50, title: 'Observe Nature', description: 'Spend 15 minutes outside just observing nature without your phone.', category: ChallengeCategory.mindfulness, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 15),

    // Productivity
    DailyChallenge(id: 51, title: 'Inbox Zero', description: 'Process every email in your inbox — reply, archive, or delete.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 30),
    DailyChallenge(id: 52, title: 'Declutter Your Desktop', description: 'Clean up your computer desktop and organize files into folders.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 15),
    DailyChallenge(id: 53, title: 'Plan Tomorrow Tonight', description: 'Write out your full schedule and top 3 priorities for tomorrow.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 10),
    DailyChallenge(id: 54, title: 'Two-Minute Rule', description: 'Do every task that takes under 2 minutes immediately today.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 0),
    DailyChallenge(id: 55, title: 'Deep Work Session', description: 'Block 90 minutes for uninterrupted focus on your most important task.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.hard, estimatedMinutes: 90),
    DailyChallenge(id: 56, title: 'Unsubscribe from 10 Emails', description: 'Go through recent emails and unsubscribe from newsletters you never read.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 15),
    DailyChallenge(id: 57, title: 'Time Audit', description: 'Track how you spend every hour today and review at night.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 10),
    DailyChallenge(id: 58, title: 'Automate One Thing', description: 'Set up an automation, shortcut, or template that saves future time.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.hard, estimatedMinutes: 30),
    DailyChallenge(id: 59, title: 'Review Your Goals', description: 'Look at your monthly/yearly goals and assess progress.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.easy, estimatedMinutes: 15),
    DailyChallenge(id: 60, title: 'Batch Similar Tasks', description: 'Group all similar tasks (calls, emails, errands) and do them together.', category: ChallengeCategory.productivity, difficulty: ChallengeDifficulty.medium, estimatedMinutes: 0),
  ];

  /// Get today's challenge (deterministic based on date).
  DailyChallenge getTodayChallenge() {
    return getChallengeForDate(DateTime.now());
  }

  /// Get challenge for a specific date.
  DailyChallenge getChallengeForDate(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final rng = Random(seed);
    return _challenges[rng.nextInt(_challenges.length)];
  }

  /// Mark today's challenge as completed.
  void completeChallenge({String? notes}) {
    final today = _todayKey();
    // Remove any existing record for today
    _history.removeWhere((r) => _dateKey(r.date) == today);
    _history.add(ChallengeRecord(
      challenge: getTodayChallenge(),
      date: DateTime.now(),
      completed: true,
      notes: notes,
    ));
  }

  /// Skip today's challenge.
  void skipChallenge() {
    final today = _todayKey();
    _history.removeWhere((r) => _dateKey(r.date) == today);
    _history.add(ChallengeRecord(
      challenge: getTodayChallenge(),
      date: DateTime.now(),
      completed: false,
    ));
  }

  /// Check if today's challenge is already completed.
  bool get isTodayCompleted {
    final today = _todayKey();
    return _history.any((r) => _dateKey(r.date) == today && r.completed);
  }

  /// Check if today's challenge is skipped.
  bool get isTodaySkipped {
    final today = _todayKey();
    return _history.any((r) => _dateKey(r.date) == today && !r.completed);
  }

  /// Get current streak of consecutive completed days.
  int getCurrentStreak() {
    if (_history.isEmpty) return 0;
    final completed = _history.where((r) => r.completed).toList();
    if (completed.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();

    // If today isn't completed yet, start checking from yesterday
    if (!isTodayCompleted) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = _dateKey(checkDate);
      if (completed.any((r) => _dateKey(r.date) == key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Get longest streak ever.
  int getLongestStreak() {
    if (_history.isEmpty) return 0;
    final completed = _history.where((r) => r.completed).toList();
    if (completed.isEmpty) return 0;

    final dates = completed.map((r) => _dateKey(r.date)).toSet().toList()..sort();
    int longest = 1;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {
      final prev = _parseKey(dates[i - 1]);
      final curr = _parseKey(dates[i]);
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  /// Get completions per category.
  Map<ChallengeCategory, int> getCategoryStats() {
    final stats = <ChallengeCategory, int>{};
    for (final cat in ChallengeCategory.values) {
      stats[cat] = _history
          .where((r) => r.completed && r.challenge.category == cat)
          .length;
    }
    return stats;
  }

  /// Get total completed count.
  int get totalCompleted => _history.where((r) => r.completed).length;

  /// Preview upcoming challenges for the next N days.
  List<DailyChallenge> getUpcoming(int days) {
    final list = <DailyChallenge>[];
    final now = DateTime.now();
    for (int i = 1; i <= days; i++) {
      list.add(getChallengeForDate(now.add(Duration(days: i))));
    }
    return list;
  }

  String _todayKey() => _dateKey(DateTime.now());
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  DateTime _parseKey(String key) {
    final parts = key.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}
