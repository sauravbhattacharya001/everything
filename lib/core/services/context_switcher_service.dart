/// Smart Context Switcher Service — autonomous life-context detection
/// with activity pattern analysis, recency weighting, time-of-day
/// heuristics, and proactive tool suggestions.

import 'dart:math';

/// Life context categories the user may be operating in.
enum LifeContext {
  work('Work', '💼', 0xFF1565C0, 'Professional tasks, meetings, project management'),
  personal('Personal', '🏠', 0xFF7B1FA2, 'Home life, relationships, personal growth'),
  fitness('Fitness', '💪', 0xFF2E7D32, 'Exercise, nutrition, physical wellness'),
  creative('Creative', '🎨', 0xFFE65100, 'Art, design, writing, creative expression'),
  finance('Finance', '💰', 0xFF00838F, 'Budgeting, investments, financial planning'),
  health('Health', '❤️', 0xFFC62828, 'Medical tracking, mental wellness, self-care');

  final String label;
  final String emoji;
  final int colorValue;
  final String description;
  const LifeContext(this.label, this.emoji, this.colorValue, this.description);
}

/// A single recorded activity signal.
class ActivitySignal {
  final String toolName;
  final String category;
  final DateTime timestamp;
  final int durationMinutes;

  const ActivitySignal({
    required this.toolName,
    required this.category,
    required this.timestamp,
    required this.durationMinutes,
  });
}

/// A tool suggestion with relevance scoring.
class ToolSuggestion {
  final String name;
  final String iconName;
  final String reason;
  final double relevanceScore;

  const ToolSuggestion({
    required this.name,
    required this.iconName,
    required this.reason,
    required this.relevanceScore,
  });
}

/// Result of context detection analysis.
class ContextDetection {
  final LifeContext detectedContext;
  final double confidence;
  final List<String> signals;
  final List<ToolSuggestion> suggestedTools;
  final Map<LifeContext, double> alternativeContexts;
  final String transitionInsight;

  const ContextDetection({
    required this.detectedContext,
    required this.confidence,
    required this.signals,
    required this.suggestedTools,
    required this.alternativeContexts,
    required this.transitionInsight,
  });
}

/// Autonomous context detection and tool suggestion engine.
class ContextSwitcherService {
  static final _rng = Random(42);

  // ── Tool-to-context mappings ──────────────────────────────────────

  static const _contextTools = <LifeContext, List<Map<String, String>>>{
    LifeContext.work: [
      {'name': 'Kanban Board', 'icon': 'view_kanban', 'reason': 'Organize tasks visually'},
      {'name': 'Eisenhower Matrix', 'icon': 'grid_4x4', 'reason': 'Prioritize by urgency & importance'},
      {'name': 'Meeting Cost', 'icon': 'attach_money', 'reason': 'Track meeting ROI'},
      {'name': 'Focus Time', 'icon': 'timer', 'reason': 'Deep work sessions'},
      {'name': 'Project Planner', 'icon': 'rocket_launch', 'reason': 'Plan project milestones'},
      {'name': 'Time Audit', 'icon': 'schedule', 'reason': 'Analyze time allocation'},
      {'name': 'Decision Matrix', 'icon': 'table_chart', 'reason': 'Weigh decisions systematically'},
    ],
    LifeContext.personal: [
      {'name': 'Gratitude Journal', 'icon': 'favorite', 'reason': 'Reflect on positives'},
      {'name': 'Dream Journal', 'icon': 'nights_stay', 'reason': 'Record & interpret dreams'},
      {'name': 'Bucket List', 'icon': 'checklist', 'reason': 'Track life goals'},
      {'name': 'Gift Tracker', 'icon': 'card_giftcard', 'reason': 'Remember gift ideas'},
      {'name': 'Contact Tracker', 'icon': 'people', 'reason': 'Nurture relationships'},
      {'name': 'Daily Review', 'icon': 'rate_review', 'reason': 'End-of-day reflection'},
    ],
    LifeContext.fitness: [
      {'name': 'Workout Tracker', 'icon': 'fitness_center', 'reason': 'Log exercises'},
      {'name': 'Water Tracker', 'icon': 'water_drop', 'reason': 'Stay hydrated'},
      {'name': 'Fasting Tracker', 'icon': 'restaurant', 'reason': 'Intermittent fasting windows'},
      {'name': 'Weight Tracker', 'icon': 'monitor_weight', 'reason': 'Track body composition'},
      {'name': 'Interval Timer', 'icon': 'timer', 'reason': 'HIIT & circuit training'},
      {'name': 'Calorie Counter', 'icon': 'local_fire_department', 'reason': 'Track nutrition intake'},
    ],
    LifeContext.creative: [
      {'name': 'Pixel Art', 'icon': 'grid_on', 'reason': 'Create pixel artwork'},
      {'name': 'Sketch Pad', 'icon': 'brush', 'reason': 'Freeform drawing'},
      {'name': 'Color Mixer', 'icon': 'palette', 'reason': 'Explore color combinations'},
      {'name': 'ASCII Art', 'icon': 'text_fields', 'reason': 'Text-based art'},
      {'name': 'Markdown Preview', 'icon': 'article', 'reason': 'Write & preview content'},
      {'name': 'Lorem Ipsum', 'icon': 'short_text', 'reason': 'Generate placeholder text'},
    ],
    LifeContext.finance: [
      {'name': 'Budget Planner', 'icon': 'account_balance', 'reason': 'Plan monthly budget'},
      {'name': 'Expense Tracker', 'icon': 'receipt_long', 'reason': 'Track daily spending'},
      {'name': 'Debt Payoff', 'icon': 'trending_down', 'reason': 'Debt elimination strategy'},
      {'name': 'Bill Reminder', 'icon': 'notifications', 'reason': 'Never miss a payment'},
      {'name': 'Tax Calculator', 'icon': 'calculate', 'reason': 'Estimate tax liability'},
      {'name': 'FIRE Calculator', 'icon': 'local_fire_department', 'reason': 'Financial independence planning'},
    ],
    LifeContext.health: [
      {'name': 'Blood Pressure', 'icon': 'monitor_heart', 'reason': 'Track BP readings'},
      {'name': 'Blood Sugar', 'icon': 'bloodtype', 'reason': 'Monitor glucose levels'},
      {'name': 'BMI Calculator', 'icon': 'straighten', 'reason': 'Check body mass index'},
      {'name': 'Medication Tracker', 'icon': 'medication', 'reason': 'Stay on schedule'},
      {'name': 'Sleep Tracker', 'icon': 'bedtime', 'reason': 'Optimize sleep quality'},
      {'name': 'Burnout Detector', 'icon': 'warning', 'reason': 'Monitor stress levels'},
    ],
  };

  // ── Category-to-context mapping for detection ─────────────────────

  static const _categoryContextWeights = <String, Map<LifeContext, double>>{
    'Planning & Views': {LifeContext.work: 0.6, LifeContext.personal: 0.3},
    'Productivity': {LifeContext.work: 0.7, LifeContext.personal: 0.2},
    'Health & Wellness': {LifeContext.health: 0.5, LifeContext.fitness: 0.4},
    'Finance': {LifeContext.finance: 0.9},
    'Lifestyle': {LifeContext.personal: 0.4, LifeContext.creative: 0.4},
    'Organization': {LifeContext.work: 0.5, LifeContext.personal: 0.4},
    'Tracking': {LifeContext.health: 0.3, LifeContext.fitness: 0.3, LifeContext.personal: 0.2},
  };

  static const _toolContextOverrides = <String, LifeContext>{
    'Kanban Board': LifeContext.work,
    'Eisenhower Matrix': LifeContext.work,
    'Meeting Cost': LifeContext.work,
    'Focus Time': LifeContext.work,
    'Project Planner': LifeContext.work,
    'Workout Tracker': LifeContext.fitness,
    'Water Tracker': LifeContext.fitness,
    'Weight Tracker': LifeContext.fitness,
    'Interval Timer': LifeContext.fitness,
    'Pixel Art': LifeContext.creative,
    'Sketch Pad': LifeContext.creative,
    'Color Mixer': LifeContext.creative,
    'ASCII Art': LifeContext.creative,
    'Budget Planner': LifeContext.finance,
    'Expense Tracker': LifeContext.finance,
    'Debt Payoff': LifeContext.finance,
    'Bill Reminder': LifeContext.finance,
    'Blood Pressure': LifeContext.health,
    'Blood Sugar': LifeContext.health,
    'Burnout Detector': LifeContext.health,
    'Sleep Tracker': LifeContext.health,
    'Gratitude Journal': LifeContext.personal,
    'Dream Journal': LifeContext.personal,
    'Bucket List': LifeContext.personal,
  };

  // ── Sample activity generation ────────────────────────────────────

  /// Generates 20-30 realistic activity signals biased toward [bias].
  List<ActivitySignal> generateSampleActivity(LifeContext bias) {
    final count = 20 + _rng.nextInt(11);
    final now = DateTime.now();
    final signals = <ActivitySignal>[];

    final biasTools = _contextTools[bias]!;
    final otherContexts = LifeContext.values.where((c) => c != bias).toList();

    for (var i = 0; i < count; i++) {
      final isBiased = _rng.nextDouble() < 0.65;
      final Map<String, String> tool;
      final LifeContext ctx;

      if (isBiased) {
        tool = biasTools[_rng.nextInt(biasTools.length)];
        ctx = bias;
      } else {
        ctx = otherContexts[_rng.nextInt(otherContexts.length)];
        final tools = _contextTools[ctx]!;
        tool = tools[_rng.nextInt(tools.length)];
      }

      signals.add(ActivitySignal(
        toolName: tool['name']!,
        category: _categoryForContext(ctx),
        timestamp: now.subtract(Duration(minutes: _rng.nextInt(480) + 5)),
        durationMinutes: 2 + _rng.nextInt(45),
      ));
    }

    signals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return signals;
  }

  String _categoryForContext(LifeContext ctx) {
    switch (ctx) {
      case LifeContext.work:
        return 'Productivity';
      case LifeContext.personal:
        return 'Lifestyle';
      case LifeContext.fitness:
        return 'Health & Wellness';
      case LifeContext.creative:
        return 'Lifestyle';
      case LifeContext.finance:
        return 'Finance';
      case LifeContext.health:
        return 'Health & Wellness';
    }
  }

  // ── Context detection ─────────────────────────────────────────────

  /// Analyzes activity signals to detect current life context.
  ContextDetection detectContext(List<ActivitySignal> recentActivity) {
    if (recentActivity.isEmpty) {
      return ContextDetection(
        detectedContext: _timeOfDayDefault(),
        confidence: 0.3,
        signals: ['No recent activity — using time-of-day heuristic'],
        suggestedTools: getSuggestionsForContext(_timeOfDayDefault()),
        alternativeContexts: {for (final c in LifeContext.values) c: 1.0 / LifeContext.values.length},
        transitionInsight: 'Start using tools to help me learn your patterns!',
      );
    }

    final scores = <LifeContext, double>{for (final c in LifeContext.values) c: 0.0};
    final evidence = <String>[];
    final now = DateTime.now();

    // Score each signal with recency weighting
    for (final signal in recentActivity) {
      final minutesAgo = now.difference(signal.timestamp).inMinutes.clamp(1, 9999);
      final recencyWeight = 1.0 / (1.0 + minutesAgo / 60.0); // decay over hours
      final durationWeight = signal.durationMinutes / 30.0; // normalize to ~30 min

      // Direct tool override
      final override = _toolContextOverrides[signal.toolName];
      if (override != null) {
        scores[override] = scores[override]! + recencyWeight * durationWeight * 2.0;
        continue;
      }

      // Category-based scoring
      final weights = _categoryContextWeights[signal.category];
      if (weights != null) {
        for (final entry in weights.entries) {
          scores[entry.key] = scores[entry.key]! + entry.value * recencyWeight * durationWeight;
        }
      }
    }

    // Time-of-day bonus
    final hour = now.hour;
    if (hour >= 9 && hour < 17) {
      scores[LifeContext.work] = scores[LifeContext.work]! + 0.5;
    } else if (hour >= 6 && hour < 9) {
      scores[LifeContext.fitness] = scores[LifeContext.fitness]! + 0.4;
      scores[LifeContext.health] = scores[LifeContext.health]! + 0.3;
    } else if (hour >= 19 && hour < 23) {
      scores[LifeContext.personal] = scores[LifeContext.personal]! + 0.4;
      scores[LifeContext.creative] = scores[LifeContext.creative]! + 0.3;
    }

    // Normalize to distribution
    final total = scores.values.fold(0.0, (a, b) => a + b);
    final distribution = <LifeContext, double>{};
    for (final entry in scores.entries) {
      distribution[entry.key] = total > 0 ? entry.value / total : 1.0 / LifeContext.values.length;
    }

    // Find winner
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final detected = sorted.first.key;
    final confidence = sorted.first.value;

    // Build evidence
    final toolCounts = <String, int>{};
    for (final s in recentActivity) {
      toolCounts[s.toolName] = (toolCounts[s.toolName] ?? 0) + 1;
    }
    final topTools = toolCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final t in topTools.take(3)) {
      evidence.add('Used ${t.key} ${t.value}x recently');
    }
    if (hour >= 9 && hour < 17) {
      evidence.add('Work hours detected (${hour}:00)');
    } else if (hour >= 6 && hour < 9) {
      evidence.add('Morning routine time (${hour}:00)');
    } else if (hour >= 19) {
      evidence.add('Evening wind-down time (${hour}:00)');
    }
    evidence.add('${recentActivity.length} activities analyzed');
    evidence.add('Top context: ${detected.emoji} ${detected.label} (${(confidence * 100).toStringAsFixed(0)}%)');

    return ContextDetection(
      detectedContext: detected,
      confidence: confidence,
      signals: evidence,
      suggestedTools: getSuggestionsForContext(detected),
      alternativeContexts: distribution,
      transitionInsight: _generateInsight(detected, sorted),
    );
  }

  LifeContext _timeOfDayDefault() {
    final hour = DateTime.now().hour;
    if (hour >= 9 && hour < 17) return LifeContext.work;
    if (hour >= 6 && hour < 9) return LifeContext.fitness;
    if (hour >= 19 && hour < 22) return LifeContext.personal;
    return LifeContext.health;
  }

  String _generateInsight(
    LifeContext detected,
    List<MapEntry<LifeContext, double>> sorted,
  ) {
    if (sorted.length < 2) return 'Keep using tools to build your pattern profile!';

    final second = sorted[1];
    final gap = sorted[0].value - second.value;

    if (gap < 0.1) {
      return 'You\'re splitting focus between ${detected.emoji} ${detected.label} '
          'and ${second.key.emoji} ${second.key.label}. Consider batching similar '
          'tasks to reduce context-switching overhead.';
    } else if (gap > 0.4) {
      return 'You\'re deeply focused on ${detected.emoji} ${detected.label}. '
          'Great flow state! Consider a short break before switching contexts.';
    } else {
      return 'Your ${detected.emoji} ${detected.label} session is dominant. '
          'When ready to transition to ${second.key.emoji} ${second.key.label}, '
          'try a 2-minute mindfulness reset.';
    }
  }

  // ── Tool suggestions ──────────────────────────────────────────────

  /// Returns 6-8 relevant tool suggestions for a given context.
  List<ToolSuggestion> getSuggestionsForContext(LifeContext context) {
    final tools = _contextTools[context] ?? [];
    return tools.asMap().entries.map((entry) {
      final t = entry.value;
      final score = 1.0 - (entry.key * 0.08); // decreasing relevance
      return ToolSuggestion(
        name: t['name']!,
        iconName: t['icon']!,
        reason: t['reason']!,
        relevanceScore: score.clamp(0.4, 1.0),
      );
    }).toList();
  }

  /// Returns a simulated history of context switches through a typical day.
  List<LifeContext> getContextHistory() {
    return const [
      LifeContext.health,    // 6 AM - wake up, check vitals
      LifeContext.fitness,   // 7 AM - morning workout
      LifeContext.personal,  // 8 AM - breakfast, family
      LifeContext.work,      // 9 AM - start work
      LifeContext.work,      // 10 AM - deep work
      LifeContext.work,      // 11 AM - meetings
      LifeContext.personal,  // 12 PM - lunch break
      LifeContext.work,      // 1 PM - afternoon work
      LifeContext.finance,   // 2 PM - review finances
      LifeContext.work,      // 3 PM - wrap up tasks
      LifeContext.creative,  // 5 PM - creative time
      LifeContext.fitness,   // 6 PM - evening exercise
      LifeContext.personal,  // 7 PM - dinner, family
      LifeContext.creative,  // 8 PM - hobby time
      LifeContext.health,    // 9 PM - wind down, sleep prep
    ];
  }

  /// Returns percentage breakdown of contexts in activity.
  Map<LifeContext, double> getContextDistribution(List<ActivitySignal> activity) {
    if (activity.isEmpty) {
      return {for (final c in LifeContext.values) c: 0.0};
    }

    final counts = <LifeContext, int>{for (final c in LifeContext.values) c: 0};
    for (final signal in activity) {
      final ctx = _toolContextOverrides[signal.toolName];
      if (ctx != null) {
        counts[ctx] = counts[ctx]! + 1;
      } else {
        // Fall back to category mapping
        final weights = _categoryContextWeights[signal.category];
        if (weights != null && weights.isNotEmpty) {
          final best = weights.entries.reduce((a, b) => a.value > b.value ? a : b);
          counts[best.key] = counts[best.key]! + 1;
        }
      }
    }

    final total = counts.values.fold(0, (a, b) => a + b);
    return {
      for (final entry in counts.entries)
        entry.key: total > 0 ? entry.value / total : 0.0,
    };
  }

  /// Generates a coaching message about transitioning between contexts.
  String getTransitionInsight(LifeContext from, LifeContext to) {
    if (from == to) return 'Staying in ${from.emoji} ${from.label} mode. Deep focus!';

    final insights = <String>[
      '${from.emoji} → ${to.emoji}: Try a 2-minute breathing exercise to reset your mental state.',
      'Switching from ${from.label} to ${to.label}? Write down your top 3 priorities for the new context.',
      'Context switch detected! Close ${from.label} tabs/apps to reduce residual attention.',
      'Pro tip: Leave a "re-entry note" for ${from.label} so you can resume easily later.',
    ];
    return insights[from.index % insights.length];
  }
}
