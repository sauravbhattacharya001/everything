import 'dart:math';

/// Friction Journal Engine — autonomous micro-frustration tracker that detects,
/// categorizes, and patterns recurring friction points in daily life. It surfaces
/// elimination strategies, tracks friction debt accumulation over time, and
/// autonomously identifies systemic root causes from individual complaints.
///
/// Core concepts:
/// - **Friction Entry**: a logged micro-frustration with context (time, location, activity)
/// - **Friction Category**: domain classification (commute, tech, social, health, work, home, finance, bureaucracy)
/// - **Pattern Detection**: recurring friction signatures (same time, same trigger, same outcome)
/// - **Friction Score**: composite daily/weekly burden score (0-100, lower is better)
/// - **Root Cause Analysis**: autonomous clustering of entries to find systemic issues
/// - **Elimination Strategy**: actionable plan to remove or reduce a friction pattern
/// - **Friction Velocity**: rate of new friction accumulation vs. resolution
/// - **Tolerance Decay**: how repeated exposure to the same friction erodes patience over time

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Category of friction.
enum FrictionCategory {
  commute,
  technology,
  social,
  health,
  work,
  home,
  finance,
  bureaucracy;

  String get label {
    switch (this) {
      case FrictionCategory.commute:
        return 'Commute';
      case FrictionCategory.technology:
        return 'Technology';
      case FrictionCategory.social:
        return 'Social';
      case FrictionCategory.health:
        return 'Health';
      case FrictionCategory.work:
        return 'Work';
      case FrictionCategory.home:
        return 'Home';
      case FrictionCategory.finance:
        return 'Finance';
      case FrictionCategory.bureaucracy:
        return 'Bureaucracy';
    }
  }

  String get emoji {
    switch (this) {
      case FrictionCategory.commute:
        return '🚗';
      case FrictionCategory.technology:
        return '💻';
      case FrictionCategory.social:
        return '👥';
      case FrictionCategory.health:
        return '🏥';
      case FrictionCategory.work:
        return '💼';
      case FrictionCategory.home:
        return '🏠';
      case FrictionCategory.finance:
        return '💰';
      case FrictionCategory.bureaucracy:
        return '📋';
    }
  }

  /// Typical resolution effort (1-10 scale).
  int get typicalEffort {
    switch (this) {
      case FrictionCategory.commute:
        return 6;
      case FrictionCategory.technology:
        return 4;
      case FrictionCategory.social:
        return 7;
      case FrictionCategory.health:
        return 5;
      case FrictionCategory.work:
        return 6;
      case FrictionCategory.home:
        return 3;
      case FrictionCategory.finance:
        return 5;
      case FrictionCategory.bureaucracy:
        return 8;
    }
  }

  /// How quickly tolerance decays for this category (multiplier per occurrence).
  double get toleranceDecayRate {
    switch (this) {
      case FrictionCategory.commute:
        return 0.85; // daily repetition erodes fast
      case FrictionCategory.technology:
        return 0.80; // tech frustration compounds quickly
      case FrictionCategory.social:
        return 0.90; // social friction is more tolerable
      case FrictionCategory.health:
        return 0.75; // health issues become intolerable fast
      case FrictionCategory.work:
        return 0.82;
      case FrictionCategory.home:
        return 0.88;
      case FrictionCategory.finance:
        return 0.78;
      case FrictionCategory.bureaucracy:
        return 0.70; // bureaucracy is maximally annoying
    }
  }
}

/// Severity of a friction entry.
enum FrictionSeverity {
  minor, // annoying but brief
  moderate, // disrupts flow
  major, // ruins a significant chunk of time/energy
  critical; // cascading impact on the rest of the day

  String get label {
    switch (this) {
      case FrictionSeverity.minor:
        return 'Minor';
      case FrictionSeverity.moderate:
        return 'Moderate';
      case FrictionSeverity.major:
        return 'Major';
      case FrictionSeverity.critical:
        return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case FrictionSeverity.minor:
        return '😤';
      case FrictionSeverity.moderate:
        return '😠';
      case FrictionSeverity.major:
        return '🤬';
      case FrictionSeverity.critical:
        return '💥';
    }
  }

  /// Impact weight (used in scoring).
  double get weight {
    switch (this) {
      case FrictionSeverity.minor:
        return 1.0;
      case FrictionSeverity.moderate:
        return 2.5;
      case FrictionSeverity.major:
        return 5.0;
      case FrictionSeverity.critical:
        return 10.0;
    }
  }
}

/// Time of day when friction occurred.
enum FrictionTimeSlot {
  earlyMorning, // 5-8 AM
  morning, // 8-12 PM
  afternoon, // 12-5 PM
  evening, // 5-9 PM
  night; // 9 PM - 5 AM

  String get label {
    switch (this) {
      case FrictionTimeSlot.earlyMorning:
        return 'Early Morning';
      case FrictionTimeSlot.morning:
        return 'Morning';
      case FrictionTimeSlot.afternoon:
        return 'Afternoon';
      case FrictionTimeSlot.evening:
        return 'Evening';
      case FrictionTimeSlot.night:
        return 'Night';
    }
  }

  String get timeRange {
    switch (this) {
      case FrictionTimeSlot.earlyMorning:
        return '5:00–8:00';
      case FrictionTimeSlot.morning:
        return '8:00–12:00';
      case FrictionTimeSlot.afternoon:
        return '12:00–17:00';
      case FrictionTimeSlot.evening:
        return '17:00–21:00';
      case FrictionTimeSlot.night:
        return '21:00–5:00';
    }
  }
}

/// Strategy type for elimination.
enum EliminationStrategy {
  automate, // set up automation to remove the friction
  delegate, // have someone else handle it
  eliminate, // remove the activity entirely
  redesign, // restructure the workflow
  batch, // consolidate into fewer occurrences
  timebox, // limit exposure time
  reframe, // change perception/attitude
  substitute; // replace with less friction alternative

  String get label {
    switch (this) {
      case EliminationStrategy.automate:
        return 'Automate';
      case EliminationStrategy.delegate:
        return 'Delegate';
      case EliminationStrategy.eliminate:
        return 'Eliminate';
      case EliminationStrategy.redesign:
        return 'Redesign';
      case EliminationStrategy.batch:
        return 'Batch';
      case EliminationStrategy.timebox:
        return 'Timebox';
      case EliminationStrategy.reframe:
        return 'Reframe';
      case EliminationStrategy.substitute:
        return 'Substitute';
    }
  }

  String get emoji {
    switch (this) {
      case EliminationStrategy.automate:
        return '🤖';
      case EliminationStrategy.delegate:
        return '🤝';
      case EliminationStrategy.eliminate:
        return '✂️';
      case EliminationStrategy.redesign:
        return '🔧';
      case EliminationStrategy.batch:
        return '📦';
      case EliminationStrategy.timebox:
        return '⏱️';
      case EliminationStrategy.reframe:
        return '🧠';
      case EliminationStrategy.substitute:
        return '🔄';
    }
  }

  String get description {
    switch (this) {
      case EliminationStrategy.automate:
        return 'Set up systems to handle this automatically';
      case EliminationStrategy.delegate:
        return 'Find someone/something else to handle this';
      case EliminationStrategy.eliminate:
        return 'Stop doing this activity entirely';
      case EliminationStrategy.redesign:
        return 'Restructure the workflow to avoid the friction point';
      case EliminationStrategy.batch:
        return 'Consolidate into fewer, planned occurrences';
      case EliminationStrategy.timebox:
        return 'Limit exposure to a strict time window';
      case EliminationStrategy.reframe:
        return 'Change your relationship with this friction';
      case EliminationStrategy.substitute:
        return 'Replace with a lower-friction alternative';
    }
  }
}

/// Pattern confidence level.
enum PatternConfidence {
  emerging, // 2-3 occurrences
  probable, // 4-6 occurrences
  confirmed, // 7-10 occurrences
  chronic; // 11+ occurrences

  String get label {
    switch (this) {
      case PatternConfidence.emerging:
        return 'Emerging';
      case PatternConfidence.probable:
        return 'Probable';
      case PatternConfidence.confirmed:
        return 'Confirmed';
      case PatternConfidence.chronic:
        return 'Chronic';
    }
  }

  String get emoji {
    switch (this) {
      case PatternConfidence.emerging:
        return '🌱';
      case PatternConfidence.probable:
        return '📊';
      case PatternConfidence.confirmed:
        return '✅';
      case PatternConfidence.chronic:
        return '🔁';
    }
  }
}

/// Friction velocity phase.
enum FrictionVelocityPhase {
  improving, // friction accumulation slowing
  stable, // steady state
  worsening, // friction accumulating faster
  spiraling; // friction feeding on itself

  String get label {
    switch (this) {
      case FrictionVelocityPhase.improving:
        return 'Improving';
      case FrictionVelocityPhase.stable:
        return 'Stable';
      case FrictionVelocityPhase.worsening:
        return 'Worsening';
      case FrictionVelocityPhase.spiraling:
        return 'Spiraling';
    }
  }

  String get emoji {
    switch (this) {
      case FrictionVelocityPhase.improving:
        return '📉';
      case FrictionVelocityPhase.stable:
        return '➡️';
      case FrictionVelocityPhase.worsening:
        return '📈';
      case FrictionVelocityPhase.spiraling:
        return '🌀';
    }
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A single friction entry logged by the user.
class FrictionEntry {
  final String id;
  final DateTime timestamp;
  final FrictionCategory category;
  final FrictionSeverity severity;
  final FrictionTimeSlot timeSlot;
  final String description;
  final String? trigger; // what caused it
  final String? location;
  final String? activity; // what you were doing
  final Duration? durationLost; // time wasted
  final bool resolved;
  final String? resolution;

  FrictionEntry({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.severity,
    required this.timeSlot,
    required this.description,
    this.trigger,
    this.location,
    this.activity,
    this.durationLost,
    this.resolved = false,
    this.resolution,
  });

  /// Compute the effective impact score factoring in tolerance decay.
  double impactScore(int priorOccurrences) {
    final toleranceMultiplier =
        1.0 / pow(category.toleranceDecayRate, priorOccurrences);
    return severity.weight * toleranceMultiplier;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'category': category.name,
        'severity': severity.name,
        'timeSlot': timeSlot.name,
        'description': description,
        'trigger': trigger,
        'location': location,
        'activity': activity,
        'durationLostMinutes': durationLost?.inMinutes,
        'resolved': resolved,
        'resolution': resolution,
      };
}

/// A detected pattern of recurring friction.
class FrictionPattern {
  final String id;
  final String name;
  final FrictionCategory category;
  final PatternConfidence confidence;
  final List<String> entryIds;
  final String commonTrigger;
  final FrictionTimeSlot? peakTimeSlot;
  final double averageSeverity;
  final double toleranceRemaining; // 0-1, how much patience is left
  final List<EliminationStrategy> suggestedStrategies;
  final String rootCauseHypothesis;

  FrictionPattern({
    required this.id,
    required this.name,
    required this.category,
    required this.confidence,
    required this.entryIds,
    required this.commonTrigger,
    this.peakTimeSlot,
    required this.averageSeverity,
    required this.toleranceRemaining,
    required this.suggestedStrategies,
    required this.rootCauseHypothesis,
  });

  int get occurrenceCount => entryIds.length;

  /// Urgency score: higher when tolerance is low and pattern is confirmed.
  double get urgencyScore {
    final tolerancePenalty = 1.0 - toleranceRemaining;
    final confidenceBoost = confidence == PatternConfidence.chronic
        ? 2.0
        : confidence == PatternConfidence.confirmed
            ? 1.5
            : 1.0;
    return averageSeverity * tolerancePenalty * confidenceBoost;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'confidence': confidence.name,
        'occurrenceCount': occurrenceCount,
        'commonTrigger': commonTrigger,
        'peakTimeSlot': peakTimeSlot?.name,
        'averageSeverity': averageSeverity,
        'toleranceRemaining': toleranceRemaining,
        'urgencyScore': urgencyScore,
        'suggestedStrategies': suggestedStrategies.map((s) => s.name).toList(),
        'rootCauseHypothesis': rootCauseHypothesis,
      };
}

/// An elimination plan for a friction pattern.
class EliminationPlan {
  final String id;
  final String patternId;
  final EliminationStrategy strategy;
  final String actionDescription;
  final int estimatedEffortHours;
  final double expectedReduction; // 0-1, how much friction should drop
  final List<String> steps;
  final bool implemented;
  final double? actualReduction;

  EliminationPlan({
    required this.id,
    required this.patternId,
    required this.strategy,
    required this.actionDescription,
    required this.estimatedEffortHours,
    required this.expectedReduction,
    required this.steps,
    this.implemented = false,
    this.actualReduction,
  });

  /// ROI: expected reduction per hour of effort.
  double get roi =>
      estimatedEffortHours > 0 ? expectedReduction / estimatedEffortHours : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'patternId': patternId,
        'strategy': strategy.name,
        'actionDescription': actionDescription,
        'estimatedEffortHours': estimatedEffortHours,
        'expectedReduction': expectedReduction,
        'steps': steps,
        'implemented': implemented,
        'actualReduction': actualReduction,
        'roi': roi,
      };
}

/// Daily friction summary.
class DailyFrictionReport {
  final DateTime date;
  final List<FrictionEntry> entries;
  final double frictionScore; // 0-100
  final FrictionCategory? worstCategory;
  final FrictionTimeSlot? worstTimeSlot;
  final Duration totalTimeLost;
  final List<String> insights;

  DailyFrictionReport({
    required this.date,
    required this.entries,
    required this.frictionScore,
    this.worstCategory,
    this.worstTimeSlot,
    required this.totalTimeLost,
    required this.insights,
  });
}

/// Friction velocity analysis.
class FrictionVelocity {
  final FrictionVelocityPhase phase;
  final double weeklyRate; // entries per week
  final double weeklyRateChange; // change from prior week
  final double resolutionRate; // fraction of friction resolved
  final double netAccumulation; // new - resolved per week
  final String forecast;

  FrictionVelocity({
    required this.phase,
    required this.weeklyRate,
    required this.weeklyRateChange,
    required this.resolutionRate,
    required this.netAccumulation,
    required this.forecast,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Friction Journal Engine — tracks, patterns, and eliminates daily friction.
class FrictionJournalService {
  final List<FrictionEntry> _entries = [];
  final List<FrictionPattern> _patterns = [];
  final List<EliminationPlan> _plans = [];

  List<FrictionEntry> get entries => List.unmodifiable(_entries);
  List<FrictionPattern> get patterns => List.unmodifiable(_patterns);
  List<EliminationPlan> get plans => List.unmodifiable(_plans);

  // -------------------------------------------------------------------------
  // Entry Management
  // -------------------------------------------------------------------------

  /// Log a new friction entry.
  FrictionEntry logFriction({
    required FrictionCategory category,
    required FrictionSeverity severity,
    required FrictionTimeSlot timeSlot,
    required String description,
    String? trigger,
    String? location,
    String? activity,
    Duration? durationLost,
    DateTime? timestamp,
  }) {
    final entry = FrictionEntry(
      id: 'friction_${DateTime.now().millisecondsSinceEpoch}_${_entries.length}',
      timestamp: timestamp ?? DateTime.now(),
      category: category,
      severity: severity,
      timeSlot: timeSlot,
      description: description,
      trigger: trigger,
      location: location,
      activity: activity,
      durationLost: durationLost,
    );
    _entries.add(entry);
    _autoDetectPatterns();
    return entry;
  }

  /// Mark a friction entry as resolved.
  void resolveEntry(String entryId, String resolution) {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index == -1) return;
    final old = _entries[index];
    _entries[index] = FrictionEntry(
      id: old.id,
      timestamp: old.timestamp,
      category: old.category,
      severity: old.severity,
      timeSlot: old.timeSlot,
      description: old.description,
      trigger: old.trigger,
      location: old.location,
      activity: old.activity,
      durationLost: old.durationLost,
      resolved: true,
      resolution: resolution,
    );
  }

  // -------------------------------------------------------------------------
  // Pattern Detection
  // -------------------------------------------------------------------------

  /// Autonomous pattern detection — clusters entries by trigger/category/time.
  void _autoDetectPatterns() {
    _patterns.clear();

    // Group by category + trigger similarity
    final groups = <String, List<FrictionEntry>>{};
    for (final entry in _entries) {
      final key =
          '${entry.category.name}_${(entry.trigger ?? 'unknown').toLowerCase().trim()}';
      groups.putIfAbsent(key, () => []).add(entry);
    }

    for (final group in groups.entries) {
      if (group.value.length < 2) continue;

      final entries = group.value;
      final category = entries.first.category;
      final trigger = entries.first.trigger ?? 'Unknown';

      // Determine confidence
      final count = entries.length;
      final confidence = count >= 11
          ? PatternConfidence.chronic
          : count >= 7
              ? PatternConfidence.confirmed
              : count >= 4
                  ? PatternConfidence.probable
                  : PatternConfidence.emerging;

      // Find peak time slot
      final timeSlotCounts = <FrictionTimeSlot, int>{};
      for (final e in entries) {
        timeSlotCounts[e.timeSlot] = (timeSlotCounts[e.timeSlot] ?? 0) + 1;
      }
      final peakTimeSlot = timeSlotCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      // Average severity
      final avgSeverity =
          entries.map((e) => e.severity.weight).reduce((a, b) => a + b) /
              entries.length;

      // Tolerance remaining (decays with each occurrence)
      final toleranceRemaining =
          pow(category.toleranceDecayRate, count).toDouble();

      // Suggest strategies based on category and severity
      final strategies = _suggestStrategies(category, avgSeverity, count);

      // Root cause hypothesis
      final rootCause = _hypothesizeRootCause(category, trigger, entries);

      _patterns.add(FrictionPattern(
        id: 'pattern_${group.key}',
        name: '${category.label}: $trigger',
        category: category,
        confidence: confidence,
        entryIds: entries.map((e) => e.id).toList(),
        commonTrigger: trigger,
        peakTimeSlot: peakTimeSlot,
        averageSeverity: avgSeverity,
        toleranceRemaining: toleranceRemaining,
        suggestedStrategies: strategies,
        rootCauseHypothesis: rootCause,
      ));
    }

    // Sort by urgency
    _patterns.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
  }

  /// Suggest elimination strategies based on friction characteristics.
  List<EliminationStrategy> _suggestStrategies(
      FrictionCategory category, double avgSeverity, int count) {
    final strategies = <EliminationStrategy>[];

    // Technology friction → automate first
    if (category == FrictionCategory.technology) {
      strategies.add(EliminationStrategy.automate);
      strategies.add(EliminationStrategy.substitute);
    }

    // Bureaucracy → batch and timebox
    if (category == FrictionCategory.bureaucracy) {
      strategies.add(EliminationStrategy.batch);
      strategies.add(EliminationStrategy.timebox);
      strategies.add(EliminationStrategy.delegate);
    }

    // Commute → redesign or eliminate
    if (category == FrictionCategory.commute) {
      strategies.add(EliminationStrategy.redesign);
      strategies.add(EliminationStrategy.eliminate);
      strategies.add(EliminationStrategy.substitute);
    }

    // Social → reframe or redesign
    if (category == FrictionCategory.social) {
      strategies.add(EliminationStrategy.reframe);
      strategies.add(EliminationStrategy.redesign);
    }

    // High severity → prioritize elimination
    if (avgSeverity >= 5.0 && !strategies.contains(EliminationStrategy.eliminate)) {
      strategies.insert(0, EliminationStrategy.eliminate);
    }

    // Chronic patterns → any strategy is better than nothing
    if (count >= 11 && strategies.isEmpty) {
      strategies.addAll([EliminationStrategy.redesign, EliminationStrategy.automate]);
    }

    // Default fallbacks
    if (strategies.isEmpty) {
      strategies.addAll([EliminationStrategy.redesign, EliminationStrategy.reframe]);
    }

    return strategies.take(3).toList();
  }

  /// Generate a root cause hypothesis from pattern data.
  String _hypothesizeRootCause(
      FrictionCategory category, String trigger, List<FrictionEntry> entries) {
    final timeSlots = entries.map((e) => e.timeSlot).toSet();
    final locations = entries.map((e) => e.location).whereType<String>().toSet();

    if (timeSlots.length == 1) {
      return 'Consistently occurs during ${timeSlots.first.label} — likely tied to ${timeSlots.first.label.toLowerCase()} routine or environment';
    }

    if (locations.length == 1 && locations.first.isNotEmpty) {
      return 'Location-specific (${locations.first}) — environmental factor likely contributing';
    }

    switch (category) {
      case FrictionCategory.technology:
        return 'Recurring tech friction with "$trigger" suggests tooling gap or workflow inefficiency';
      case FrictionCategory.commute:
        return 'Commute friction with "$trigger" suggests route/timing optimization opportunity';
      case FrictionCategory.social:
        return 'Social friction with "$trigger" suggests boundary or communication pattern issue';
      case FrictionCategory.work:
        return 'Work friction with "$trigger" suggests process or prioritization issue';
      case FrictionCategory.health:
        return 'Health friction with "$trigger" suggests habit or environment adjustment needed';
      case FrictionCategory.home:
        return 'Home friction with "$trigger" suggests organization or maintenance gap';
      case FrictionCategory.finance:
        return 'Finance friction with "$trigger" suggests automation or simplification opportunity';
      case FrictionCategory.bureaucracy:
        return 'Bureaucratic friction with "$trigger" suggests batching or delegation opportunity';
    }
  }

  // -------------------------------------------------------------------------
  // Elimination Planning
  // -------------------------------------------------------------------------

  /// Generate an elimination plan for a pattern.
  EliminationPlan generatePlan(String patternId) {
    final pattern = _patterns.firstWhere((p) => p.id == patternId);
    final strategy = pattern.suggestedStrategies.first;

    final steps = _generateSteps(strategy, pattern);
    final effort = _estimateEffort(strategy, pattern);
    final expectedReduction = _estimateReduction(strategy, pattern);

    final plan = EliminationPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      patternId: patternId,
      strategy: strategy,
      actionDescription:
          '${strategy.label} the "${pattern.commonTrigger}" friction in ${pattern.category.label}',
      estimatedEffortHours: effort,
      expectedReduction: expectedReduction,
      steps: steps,
    );
    _plans.add(plan);
    return plan;
  }

  List<String> _generateSteps(EliminationStrategy strategy, FrictionPattern pattern) {
    switch (strategy) {
      case EliminationStrategy.automate:
        return [
          'Identify the repetitive manual steps in "${pattern.commonTrigger}"',
          'Research automation tools/scripts for this task',
          'Set up the automation with error handling',
          'Test with a dry run for 3 days',
          'Monitor for edge cases and adjust',
        ];
      case EliminationStrategy.delegate:
        return [
          'Document the task clearly: what, when, acceptance criteria',
          'Identify who/what can handle this (person, service, tool)',
          'Create handoff with clear instructions',
          'Set up feedback loop to catch issues',
          'Review weekly until stable',
        ];
      case EliminationStrategy.eliminate:
        return [
          'Question whether "${pattern.commonTrigger}" is truly necessary',
          'Identify what would break if you stopped doing this',
          'Test skipping it for 1 week and observe consequences',
          'If no real impact, permanently remove from routine',
          'Redirect freed energy to high-value activities',
        ];
      case EliminationStrategy.redesign:
        return [
          'Map the current workflow around "${pattern.commonTrigger}"',
          'Identify the exact point where friction occurs',
          'Brainstorm 3 alternative approaches',
          'Prototype the most promising alternative for 1 week',
          'Measure friction reduction and iterate',
        ];
      case EliminationStrategy.batch:
        return [
          'Identify all instances of "${pattern.commonTrigger}" in your week',
          'Consolidate into 1-2 dedicated time blocks',
          'Set up a collection inbox for items between batches',
          'Process the batch during designated time only',
          'Adjust batch frequency based on volume',
        ];
      case EliminationStrategy.timebox:
        return [
          'Set a hard time limit for "${pattern.commonTrigger}" (suggest 25min)',
          'Use a visible timer — stop when it rings regardless of completion',
          'Accept "good enough" within the timebox',
          'Track what happens to unfinished items (often: nothing)',
          'Gradually reduce the timebox as efficiency improves',
        ];
      case EliminationStrategy.reframe:
        return [
          'Identify the specific thought pattern triggered by "${pattern.commonTrigger}"',
          'Challenge: is this friction objectively bad or just uncomfortable?',
          'Find one positive aspect or growth opportunity in it',
          'Create a reframe phrase to use when it occurs',
          'Track whether the emotional impact decreases over 2 weeks',
        ];
      case EliminationStrategy.substitute:
        return [
          'List alternatives to "${pattern.commonTrigger}" that achieve the same goal',
          'Score each alternative on friction level (1-10)',
          'Trial the lowest-friction alternative for 1 week',
          'Compare outcomes — did you lose anything important?',
          'Switch permanently if comparable results with less friction',
        ];
    }
  }

  int _estimateEffort(EliminationStrategy strategy, FrictionPattern pattern) {
    final baseEffort = pattern.category.typicalEffort;
    switch (strategy) {
      case EliminationStrategy.automate:
        return baseEffort + 4; // automation takes setup
      case EliminationStrategy.delegate:
        return baseEffort + 2;
      case EliminationStrategy.eliminate:
        return max(1, baseEffort - 3); // elimination is usually quick
      case EliminationStrategy.redesign:
        return baseEffort + 3;
      case EliminationStrategy.batch:
        return max(1, baseEffort - 1);
      case EliminationStrategy.timebox:
        return 1; // minimal effort
      case EliminationStrategy.reframe:
        return 2; // mental work only
      case EliminationStrategy.substitute:
        return baseEffort;
    }
  }

  double _estimateReduction(EliminationStrategy strategy, FrictionPattern pattern) {
    switch (strategy) {
      case EliminationStrategy.automate:
        return 0.90; // near-complete removal
      case EliminationStrategy.delegate:
        return 0.80;
      case EliminationStrategy.eliminate:
        return 1.00; // total removal
      case EliminationStrategy.redesign:
        return 0.70;
      case EliminationStrategy.batch:
        return 0.50; // reduces frequency, not elimination
      case EliminationStrategy.timebox:
        return 0.40; // limits exposure
      case EliminationStrategy.reframe:
        return 0.30; // changes perception, not reality
      case EliminationStrategy.substitute:
        return 0.75;
    }
  }

  // -------------------------------------------------------------------------
  // Analysis & Scoring
  // -------------------------------------------------------------------------

  /// Calculate daily friction score (0-100, lower is better).
  double calculateDailyScore(DateTime date) {
    final dayEntries = _entries.where((e) =>
        e.timestamp.year == date.year &&
        e.timestamp.month == date.month &&
        e.timestamp.day == date.day);

    if (dayEntries.isEmpty) return 0.0;

    double rawScore = 0;
    for (final entry in dayEntries) {
      final priorOccurrences = _entries
          .where((e) =>
              e.category == entry.category &&
              e.trigger == entry.trigger &&
              e.timestamp.isBefore(entry.timestamp))
          .length;
      rawScore += entry.impactScore(priorOccurrences);
    }

    // Normalize to 0-100 (cap at 50 raw points = 100 score)
    return min(100.0, (rawScore / 50.0) * 100.0);
  }

  /// Generate a daily friction report.
  DailyFrictionReport generateDailyReport(DateTime date) {
    final dayEntries = _entries
        .where((e) =>
            e.timestamp.year == date.year &&
            e.timestamp.month == date.month &&
            e.timestamp.day == date.day)
        .toList();

    final score = calculateDailyScore(date);

    // Find worst category
    final catCounts = <FrictionCategory, int>{};
    for (final e in dayEntries) {
      catCounts[e.category] = (catCounts[e.category] ?? 0) + 1;
    }
    final worstCategory = catCounts.isEmpty
        ? null
        : catCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // Find worst time slot
    final timeCounts = <FrictionTimeSlot, int>{};
    for (final e in dayEntries) {
      timeCounts[e.timeSlot] = (timeCounts[e.timeSlot] ?? 0) + 1;
    }
    final worstTime = timeCounts.isEmpty
        ? null
        : timeCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // Total time lost
    final totalMinutes = dayEntries
        .map((e) => e.durationLost?.inMinutes ?? 0)
        .fold(0, (a, b) => a + b);

    // Generate insights
    final insights = _generateInsights(dayEntries, score);

    return DailyFrictionReport(
      date: date,
      entries: dayEntries,
      frictionScore: score,
      worstCategory: worstCategory,
      worstTimeSlot: worstTime,
      totalTimeLost: Duration(minutes: totalMinutes),
      insights: insights,
    );
  }

  List<String> _generateInsights(List<FrictionEntry> entries, double score) {
    final insights = <String>[];

    if (entries.isEmpty) {
      insights.add('🎉 Friction-free day! Whatever you did, keep doing it.');
      return insights;
    }

    if (score > 75) {
      insights.add(
          '⚠️ High-friction day (score: ${score.toStringAsFixed(0)}). Consider reviewing your patterns.');
    }

    // Check for critical entries
    final criticals =
        entries.where((e) => e.severity == FrictionSeverity.critical);
    if (criticals.isNotEmpty) {
      insights.add(
          '💥 ${criticals.length} critical friction event(s) — these need immediate attention.');
    }

    // Check for time concentration
    final timeSlots = entries.map((e) => e.timeSlot).toList();
    final modeCounts = <FrictionTimeSlot, int>{};
    for (final t in timeSlots) {
      modeCounts[t] = (modeCounts[t] ?? 0) + 1;
    }
    final maxSlot = modeCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (maxSlot.value >= 3) {
      insights.add(
          '🕐 ${maxSlot.value} friction events during ${maxSlot.key.label} — this time slot needs restructuring.');
    }

    // Check for repeated triggers
    final triggers = entries.map((e) => e.trigger).whereType<String>().toList();
    final triggerCounts = <String, int>{};
    for (final t in triggers) {
      triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
    }
    for (final tc in triggerCounts.entries) {
      if (tc.value >= 2) {
        insights.add(
            '🔁 "${tc.key}" triggered friction ${tc.value} times today — emerging pattern.');
      }
    }

    return insights;
  }

  /// Calculate friction velocity (rate of change).
  FrictionVelocity calculateVelocity() {
    if (_entries.length < 7) {
      return FrictionVelocity(
        phase: FrictionVelocityPhase.stable,
        weeklyRate: _entries.length.toDouble(),
        weeklyRateChange: 0,
        resolutionRate: 0,
        netAccumulation: _entries.length.toDouble(),
        forecast: 'Insufficient data — log more entries for velocity analysis',
      );
    }

    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    final thisWeek =
        _entries.where((e) => e.timestamp.isAfter(oneWeekAgo)).length;
    final lastWeek = _entries
        .where((e) =>
            e.timestamp.isAfter(twoWeeksAgo) &&
            e.timestamp.isBefore(oneWeekAgo))
        .length;

    final weeklyRate = thisWeek.toDouble();
    final change =
        lastWeek > 0 ? (thisWeek - lastWeek) / lastWeek : 0.0;

    final resolved = _entries.where((e) => e.resolved).length;
    final resolutionRate =
        _entries.isNotEmpty ? resolved / _entries.length : 0.0;

    final netAccumulation = thisWeek - (resolved > 0 ? thisWeek * resolutionRate : 0);

    // Determine phase
    FrictionVelocityPhase phase;
    if (change < -0.2) {
      phase = FrictionVelocityPhase.improving;
    } else if (change > 0.5) {
      phase = FrictionVelocityPhase.spiraling;
    } else if (change > 0.2) {
      phase = FrictionVelocityPhase.worsening;
    } else {
      phase = FrictionVelocityPhase.stable;
    }

    // Forecast
    String forecast;
    switch (phase) {
      case FrictionVelocityPhase.improving:
        forecast =
            'Friction decreasing ${(change.abs() * 100).toStringAsFixed(0)}% week-over-week. Keep up current elimination efforts.';
        break;
      case FrictionVelocityPhase.stable:
        forecast =
            'Friction stable at ~$thisWeek entries/week. Target your top pattern for improvement.';
        break;
      case FrictionVelocityPhase.worsening:
        forecast =
            'Friction increasing ${(change * 100).toStringAsFixed(0)}% week-over-week. Address top patterns before they become chronic.';
        break;
      case FrictionVelocityPhase.spiraling:
        forecast =
            '⚠️ Friction spiraling — ${(change * 100).toStringAsFixed(0)}% increase. Multiple patterns compounding. Immediate triage recommended.';
        break;
    }

    return FrictionVelocity(
      phase: phase,
      weeklyRate: weeklyRate,
      weeklyRateChange: change,
      resolutionRate: resolutionRate,
      netAccumulation: netAccumulation,
      forecast: forecast,
    );
  }

  // -------------------------------------------------------------------------
  // Category Analysis
  // -------------------------------------------------------------------------

  /// Get friction breakdown by category.
  Map<FrictionCategory, CategoryAnalysis> analyzeCategoriesBreakdown() {
    final result = <FrictionCategory, CategoryAnalysis>{};

    for (final category in FrictionCategory.values) {
      final categoryEntries =
          _entries.where((e) => e.category == category).toList();
      if (categoryEntries.isEmpty) continue;

      final totalImpact = categoryEntries.map((e) => e.severity.weight).fold(0.0, (a, b) => a + b);
      final avgSeverity = totalImpact / categoryEntries.length;
      final resolvedCount = categoryEntries.where((e) => e.resolved).length;
      final patterns = _patterns.where((p) => p.category == category).toList();

      result[category] = CategoryAnalysis(
        category: category,
        entryCount: categoryEntries.length,
        totalImpact: totalImpact,
        averageSeverity: avgSeverity,
        resolutionRate: resolvedCount / categoryEntries.length,
        patternCount: patterns.length,
        topPattern: patterns.isNotEmpty ? patterns.first : null,
      );
    }

    return result;
  }

  // -------------------------------------------------------------------------
  // Top Friction Sources (Prioritized)
  // -------------------------------------------------------------------------

  /// Get top N friction sources ranked by urgency (for elimination priority).
  List<FrictionPattern> getTopPriorities({int count = 5}) {
    if (_patterns.isEmpty) return [];
    return _patterns.take(min(count, _patterns.length)).toList();
  }

  /// Get entries for a specific date range.
  List<FrictionEntry> getEntriesInRange(DateTime start, DateTime end) {
    return _entries
        .where(
            (e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  /// Get unresolved entries.
  List<FrictionEntry> getUnresolved() {
    return _entries.where((e) => !e.resolved).toList();
  }

  // -------------------------------------------------------------------------
  // Autonomous Insights
  // -------------------------------------------------------------------------

  /// Generate autonomous insights across all data.
  List<String> generateAutonomousInsights() {
    final insights = <String>[];

    if (_entries.isEmpty) {
      insights.add('📝 Start logging friction to build your pattern library.');
      return insights;
    }

    // Chronic patterns
    final chronicPatterns =
        _patterns.where((p) => p.confidence == PatternConfidence.chronic);
    for (final p in chronicPatterns) {
      insights.add(
          '🔁 CHRONIC: "${p.commonTrigger}" (${p.category.label}) has occurred ${p.occurrenceCount} times. '
          'Tolerance at ${(p.toleranceRemaining * 100).toStringAsFixed(0)}%. '
          'Top strategy: ${p.suggestedStrategies.first.label}.');
    }

    // Tolerance warnings
    final lowTolerance = _patterns.where((p) => p.toleranceRemaining < 0.3);
    for (final p in lowTolerance) {
      if (p.confidence != PatternConfidence.chronic) {
        insights.add(
            '⚠️ Tolerance critically low for "${p.commonTrigger}" — '
            '${(p.toleranceRemaining * 100).toStringAsFixed(0)}% remaining. Address before burnout.');
      }
    }

    // Time-slot clustering
    final slotCounts = <FrictionTimeSlot, int>{};
    for (final e in _entries) {
      slotCounts[e.timeSlot] = (slotCounts[e.timeSlot] ?? 0) + 1;
    }
    if (slotCounts.isNotEmpty) {
      final worst =
          slotCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (worst.value > _entries.length * 0.4) {
        insights.add(
            '🕐 ${(worst.value / _entries.length * 100).toStringAsFixed(0)}% of all friction occurs during ${worst.key.label}. '
            'Consider restructuring this time period.');
      }
    }

    // Velocity insight
    final velocity = calculateVelocity();
    insights.add('${velocity.phase.emoji} Velocity: ${velocity.forecast}');

    // ROI opportunity
    if (_plans.isNotEmpty) {
      final bestRoi = _plans
          .where((p) => !p.implemented)
          .toList()
        ..sort((a, b) => b.roi.compareTo(a.roi));
      if (bestRoi.isNotEmpty) {
        insights.add(
            '💡 Best ROI opportunity: "${bestRoi.first.actionDescription}" '
            '(${bestRoi.first.estimatedEffortHours}h effort → ${(bestRoi.first.expectedReduction * 100).toStringAsFixed(0)}% reduction)');
      }
    }

    return insights;
  }
}

// ---------------------------------------------------------------------------
// Supporting Models
// ---------------------------------------------------------------------------

/// Analysis summary for a single category.
class CategoryAnalysis {
  final FrictionCategory category;
  final int entryCount;
  final double totalImpact;
  final double averageSeverity;
  final double resolutionRate;
  final int patternCount;
  final FrictionPattern? topPattern;

  CategoryAnalysis({
    required this.category,
    required this.entryCount,
    required this.totalImpact,
    required this.averageSeverity,
    required this.resolutionRate,
    required this.patternCount,
    this.topPattern,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'entryCount': entryCount,
        'totalImpact': totalImpact,
        'averageSeverity': averageSeverity,
        'resolutionRate': resolutionRate,
        'patternCount': patternCount,
        'topPattern': topPattern?.name,
      };
}
