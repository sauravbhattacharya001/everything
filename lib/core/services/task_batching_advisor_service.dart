/// Task Batching Advisor - agentic clustering advisor that groups pending tasks
/// by shared context, location, and tool so the user can crush them in batched
/// windows instead of paying the context-switch tax on every single one.
///
/// Sibling to:
///   * `daily_top_three_advisor_service.dart`     (today's shortlist)
///   * `goal_deadline_risk_advisor_service.dart`  (goal-level deadline risk)
///   * `habit_recovery_advisor_service.dart`      (lapsed habits)
///   * `subscription_rotation_advisor_service.dart` (recurring spend)
///   * `energy_budget_planner_service.dart`       (today's energy budget)
///
/// Where those advisors describe *what to commit to* and *which goals are at
/// risk*, this one answers a different operational question:
///
///   "Given everything still on my plate, which tasks should be done in the
///    same window because they share a context (errands at one mall, a stack
///    of phone calls, an afternoon of deep work, a shopping trip), how many
///    minutes of switching tax am I about to save, and which lone tasks
///    deserve their own slot anyway because they are urgent?"
///
/// Pipeline:
///   1. Classify each [TaskSnapshot] into a [TaskBatchingVerdict] based on
///      cluster membership, priority pressure, tool availability, and size.
///   2. Build clusters (context + location key) above the appetite-modulated
///      `minClusterSize` threshold.
///   3. Compute `fragmentationScore` 0..100 from unbatched isolates, lost
///      switching tax, tool blockers, and deep-work overload.
///   4. Modulate by [TaskBatchingRiskAppetite] (cautious 1.15x / balanced /
///      aggressive 0.85x score multiplier; cautious is more eager to batch
///      and appends an audit step; aggressive trims P3 fallbacks).
///   5. Aggregate portfolio: band + A-F grade + headline + insights.
///   6. Emit a deduped P0-first playbook of [BatchingAction] items
///      (priority, owner, blastRadius, reversibility, relatedIds).
///   7. Render via `toText` / `toMarkdown` / `toJson` (byte-stable).
///
/// Pure Dart, zero new dependencies. Deterministic - no `Random` usage. All
/// "now" reads go through `options.now ?? DateTime.now`. Stable sorts.
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum TaskBatchingRiskAppetite { cautious, balanced, aggressive }

enum TaskBatchingPriority { p0, p1, p2, p3 }

enum TaskBatchingVerdict {
  batchNow,
  batchSoon,
  standaloneUrgent,
  standaloneDefer,
  splitRecommended,
  blockedToolUnavailable,
  insufficientData,
}

enum TaskBatchingPortfolioBand { lean, healthy, bloated, severelyBloated }

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

class TaskSnapshot {
  final String id;
  final String title;

  /// Logical context tag, e.g. 'errand', 'computer', 'phone_call',
  /// 'deep_work', 'shopping', 'home', 'meeting'. Free-form lowercase.
  final String context;

  /// Optional location key for co-located batching (e.g. 'westgate_mall',
  /// 'home', 'office'). Two tasks need the same context AND location to form
  /// a co-located cluster.
  final String? location;

  /// Optional tool/dependency required ('car', 'laptop', 'phone', 'oven').
  /// If supplied and missing from [BatchingOptions.availableTools], the task
  /// becomes [TaskBatchingVerdict.blockedToolUnavailable].
  final String? requiredTool;

  final int estimatedMinutes;
  final DateTime? dueAt;

  /// 1..5; 5 is highest priority.
  final int priorityWeight;

  /// 'low' | 'medium' | 'high'.
  final String energyCost;

  const TaskSnapshot({
    required this.id,
    required this.title,
    required this.context,
    this.location,
    this.requiredTool,
    this.estimatedMinutes = 30,
    this.dueAt,
    this.priorityWeight = 3,
    this.energyCost = 'medium',
  });
}

class BatchingOptions {
  final TaskBatchingRiskAppetite riskAppetite;

  /// Tools/dependencies currently available to the user.
  final Set<String> availableTools;

  /// Minutes of overhead saved per avoided context switch (member-1 per
  /// cluster). Default 8 minutes per switch.
  final int contextSwitchTaxMinutes;

  /// Tasks at or above this size are classified as `SPLIT_RECOMMENDED`.
  final int splitThresholdMinutes;

  final DateTime Function()? now;

  const BatchingOptions({
    this.riskAppetite = TaskBatchingRiskAppetite.balanced,
    this.availableTools = const <String>{},
    this.contextSwitchTaxMinutes = 8,
    this.splitThresholdMinutes = 90,
    this.now,
  });
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

class TaskBatchingForecast {
  final String id;
  final String title;
  final String context;
  final String? location;
  final TaskBatchingVerdict verdict;
  final TaskBatchingPriority priority;
  final String? clusterId;
  final double batchabilityScore; // 0..100
  final List<String> reasons;
  final String suggestedAction;

  const TaskBatchingForecast({
    required this.id,
    required this.title,
    required this.context,
    required this.location,
    required this.verdict,
    required this.priority,
    required this.clusterId,
    required this.batchabilityScore,
    required this.reasons,
    required this.suggestedAction,
  });

  Map<String, dynamic> toJsonMap() => {
        'id': id,
        'title': title,
        'context': context,
        'location': location,
        'verdict': _verdictName(verdict),
        'priority': _priorityName(priority),
        'cluster_id': clusterId,
        'batchability_score':
            double.parse(batchabilityScore.toStringAsFixed(2)),
        'reasons': reasons,
        'suggested_action': suggestedAction,
      };
}

class TaskCluster {
  final String clusterId;
  final String context;
  final String? location;
  final List<String> memberIds;
  final int totalMinutes;
  final int savingsMinutesEstimate;
  final TaskBatchingPriority priority;

  const TaskCluster({
    required this.clusterId,
    required this.context,
    required this.location,
    required this.memberIds,
    required this.totalMinutes,
    required this.savingsMinutesEstimate,
    required this.priority,
  });

  Map<String, dynamic> toJsonMap() => {
        'cluster_id': clusterId,
        'context': context,
        'location': location,
        'member_ids': memberIds,
        'total_minutes': totalMinutes,
        'savings_minutes_estimate': savingsMinutesEstimate,
        'priority': _priorityName(priority),
      };
}

class BatchingAction {
  final String code;
  final TaskBatchingPriority priority;
  final String label;
  final String reason;
  final String owner;
  final int blastRadius; // 1..5
  final String reversibility; // 'low' | 'medium' | 'high'
  final List<String> relatedIds;

  const BatchingAction({
    required this.code,
    required this.priority,
    required this.label,
    required this.reason,
    this.owner = 'user',
    required this.blastRadius,
    required this.reversibility,
    this.relatedIds = const [],
  });

  Map<String, dynamic> toJsonMap() => {
        'code': code,
        'priority': _priorityName(priority),
        'label': label,
        'reason': reason,
        'owner': owner,
        'blast_radius': blastRadius,
        'reversibility': reversibility,
        'related_ids': relatedIds,
      };
}

class TaskBatchingReport {
  final DateTime generatedAt;
  final TaskBatchingRiskAppetite riskAppetite;
  final int totalTasks;
  final int batchedTaskCount;
  final int isolatedTaskCount;
  final int projectedSavedMinutes;
  final double fragmentationScore; // 0..100 (higher = worse)
  final TaskBatchingPortfolioBand band;
  final String grade;
  final String headline;
  final List<TaskBatchingForecast> forecasts;
  final List<TaskCluster> clusters;
  final List<BatchingAction> playbook;
  final List<String> insights;

  const TaskBatchingReport({
    required this.generatedAt,
    required this.riskAppetite,
    required this.totalTasks,
    required this.batchedTaskCount,
    required this.isolatedTaskCount,
    required this.projectedSavedMinutes,
    required this.fragmentationScore,
    required this.band,
    required this.grade,
    required this.headline,
    required this.forecasts,
    required this.clusters,
    required this.playbook,
    required this.insights,
  });

  Map<String, dynamic> toJsonMap() => {
        'generated_at': generatedAt.toUtc().toIso8601String(),
        'risk_appetite': _appetiteName(riskAppetite),
        'total_tasks': totalTasks,
        'batched_task_count': batchedTaskCount,
        'isolated_task_count': isolatedTaskCount,
        'projected_saved_minutes': projectedSavedMinutes,
        'fragmentation_score':
            double.parse(fragmentationScore.toStringAsFixed(2)),
        'band': _bandName(band),
        'grade': grade,
        'headline': headline,
        'insights': insights,
        'clusters': clusters.map((c) => c.toJsonMap()).toList(),
        'forecasts': forecasts.map((f) => f.toJsonMap()).toList(),
        'playbook': playbook.map((a) => a.toJsonMap()).toList(),
      };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class TaskBatchingAdvisorService {
  const TaskBatchingAdvisorService();

  TaskBatchingReport recommend(
    List<TaskSnapshot> tasks, {
    BatchingOptions options = const BatchingOptions(),
  }) {
    final now = (options.now ?? DateTime.now)();
    final appetite = options.riskAppetite;
    final tax = math.max(1, options.contextSwitchTaxMinutes);

    if (tasks.isEmpty) {
      return TaskBatchingReport(
        generatedAt: now,
        riskAppetite: appetite,
        totalTasks: 0,
        batchedTaskCount: 0,
        isolatedTaskCount: 0,
        projectedSavedMinutes: 0,
        fragmentationScore: 0,
        band: TaskBatchingPortfolioBand.lean,
        grade: 'A',
        headline: 'EMPTY_PORTFOLIO: nothing to batch',
        forecasts: const [],
        clusters: const [],
        playbook: const [],
        insights: const ['EMPTY_PORTFOLIO'],
      );
    }

    // -- 1. cluster by (context, location) key
    final minClusterSize = switch (appetite) {
      TaskBatchingRiskAppetite.cautious => 2,
      TaskBatchingRiskAppetite.balanced => 2,
      TaskBatchingRiskAppetite.aggressive => 3,
    };
    final batchNowThreshold = switch (appetite) {
      TaskBatchingRiskAppetite.cautious => 2,
      TaskBatchingRiskAppetite.balanced => 3,
      TaskBatchingRiskAppetite.aggressive => 3,
    };

    final byKey = <String, List<TaskSnapshot>>{};
    for (final t in tasks) {
      final key = '${t.context}__${t.location ?? "_"}';
      byKey.putIfAbsent(key, () => []).add(t);
    }
    // Stable cluster ids: sort keys lexicographically.
    final clusterKeys = byKey.keys.toList()..sort();
    final clusterIdForKey = <String, String>{};
    final clusters = <TaskCluster>[];
    var idx = 0;
    for (final k in clusterKeys) {
      final members = byKey[k]!;
      if (members.length < minClusterSize) continue;
      final cid = 'C${(idx + 1).toString().padLeft(2, '0')}';
      idx++;
      clusterIdForKey[k] = cid;
      final ids = members.map((m) => m.id).toList()..sort();
      final totalMin = members.fold<int>(0, (a, b) => a + b.estimatedMinutes);
      final savings = (members.length - 1) * tax;
      final clusterPriority = members.length >= batchNowThreshold
          ? TaskBatchingPriority.p0
          : TaskBatchingPriority.p1;
      clusters.add(TaskCluster(
        clusterId: cid,
        context: members.first.context,
        location: members.first.location,
        memberIds: ids,
        totalMinutes: totalMin,
        savingsMinutesEstimate: savings,
        priority: clusterPriority,
      ));
    }

    // -- 2. classify each task
    final forecasts = <TaskBatchingForecast>[];
    for (final t in tasks) {
      forecasts.add(_classify(
        t,
        now: now,
        availableTools: options.availableTools,
        splitMin: options.splitThresholdMinutes,
        clusterIdForKey: clusterIdForKey,
        clusterSizeForKey: {for (final k in byKey.keys) k: byKey[k]!.length},
        batchNowThreshold: batchNowThreshold,
      ));
    }

    forecasts.sort((a, b) {
      final p = a.priority.index.compareTo(b.priority.index);
      if (p != 0) return p;
      final s = b.batchabilityScore.compareTo(a.batchabilityScore);
      if (s != 0) return s;
      return a.id.compareTo(b.id);
    });

    // -- 3. portfolio aggregates
    final batchedCount = forecasts
        .where((f) =>
            f.verdict == TaskBatchingVerdict.batchNow ||
            f.verdict == TaskBatchingVerdict.batchSoon)
        .length;
    final isolatedCount = forecasts
        .where((f) =>
            f.verdict == TaskBatchingVerdict.standaloneUrgent ||
            f.verdict == TaskBatchingVerdict.standaloneDefer)
        .length;
    final blockedCount = forecasts
        .where((f) => f.verdict == TaskBatchingVerdict.blockedToolUnavailable)
        .length;
    final splitCount = forecasts
        .where((f) => f.verdict == TaskBatchingVerdict.splitRecommended)
        .length;
    final savedMinutes =
        clusters.fold<int>(0, (a, c) => a + c.savingsMinutesEstimate);

    final isolatedRatio =
        forecasts.isEmpty ? 0.0 : isolatedCount / forecasts.length;
    final lostTaxLoad = math.min(60.0, savedMinutes * 0.0); // placeholder
    final unrealisedTax = _unrealisedTax(byKey, minClusterSize, tax);
    final deepWorkCount =
        forecasts.where((f) => f.context == 'deep_work').length;
    final toolBlockPenalty = math.min(25.0, blockedCount * 8.0);

    final rawScore = math.min(
      100.0,
      isolatedRatio * 55.0 +
          math.min(30.0, unrealisedTax * 0.6) +
          toolBlockPenalty +
          (deepWorkCount >= 3 ? 8.0 : 0.0) +
          (splitCount > 0 ? math.min(10.0, splitCount * 3.0) : 0.0) +
          lostTaxLoad,
    );

    final mult = switch (appetite) {
      TaskBatchingRiskAppetite.cautious => 1.15,
      TaskBatchingRiskAppetite.balanced => 1.0,
      TaskBatchingRiskAppetite.aggressive => 0.85,
    };
    final fragmentation = math.min(100.0, rawScore * mult);

    final band = switch (fragmentation) {
      < 25 => TaskBatchingPortfolioBand.lean,
      < 50 => TaskBatchingPortfolioBand.healthy,
      < 75 => TaskBatchingPortfolioBand.bloated,
      _ => TaskBatchingPortfolioBand.severelyBloated,
    };
    final grade = switch (fragmentation) {
      <= 20 => 'A',
      <= 40 => 'B',
      <= 60 => 'C',
      <= 80 => 'D',
      _ => 'F',
    };

    // -- 4. playbook
    final playbook =
        _playbook(forecasts, clusters, appetite, grade, blockedCount);

    // -- 5. insights
    final insights = _insights(forecasts, clusters, savedMinutes, blockedCount);

    // -- 6. headline
    final headline = 'VERDICT: grade=$grade tasks=${tasks.length} '
        'batched=$batchedCount isolated=$isolatedCount '
        'blocked=$blockedCount clusters=${clusters.length} '
        'saved_min=$savedMinutes';

    return TaskBatchingReport(
      generatedAt: now,
      riskAppetite: appetite,
      totalTasks: tasks.length,
      batchedTaskCount: batchedCount,
      isolatedTaskCount: isolatedCount,
      projectedSavedMinutes: savedMinutes,
      fragmentationScore: fragmentation,
      band: band,
      grade: grade,
      headline: headline,
      forecasts: forecasts,
      clusters: clusters,
      playbook: playbook,
      insights: insights,
    );
  }

  // -------------------------------------------------------------------------
  // Internal classification
  // -------------------------------------------------------------------------

  TaskBatchingForecast _classify(
    TaskSnapshot t, {
    required DateTime now,
    required Set<String> availableTools,
    required int splitMin,
    required Map<String, String> clusterIdForKey,
    required Map<String, int> clusterSizeForKey,
    required int batchNowThreshold,
  }) {
    final reasons = <String>[];
    final key = '${t.context}__${t.location ?? "_"}';
    final clusterId = clusterIdForKey[key];
    final clusterSize = clusterSizeForKey[key] ?? 1;

    // 1) tool blocker (highest precedence -- can't work on it at all)
    final tool = t.requiredTool;
    if (tool != null && tool.isNotEmpty && !availableTools.contains(tool)) {
      reasons.add('REQUIRES_$tool'.toUpperCase());
      return TaskBatchingForecast(
        id: t.id,
        title: t.title,
        context: t.context,
        location: t.location,
        verdict: TaskBatchingVerdict.blockedToolUnavailable,
        priority: TaskBatchingPriority.p1,
        clusterId: clusterId,
        batchabilityScore: 0,
        reasons: reasons,
        suggestedAction: 'Acquire or schedule access to "$tool" first',
      );
    }

    // 2) split recommended
    if (t.estimatedMinutes >= splitMin) {
      reasons.add('OVER_${splitMin}_MIN');
      return TaskBatchingForecast(
        id: t.id,
        title: t.title,
        context: t.context,
        location: t.location,
        verdict: TaskBatchingVerdict.splitRecommended,
        priority: TaskBatchingPriority.p1,
        clusterId: clusterId,
        batchabilityScore: 30,
        reasons: reasons,
        suggestedAction:
            'Break "${t.title}" into <=${splitMin ~/ 2} min sub-tasks',
      );
    }

    final dueIn = t.dueAt?.difference(now);
    final isDueSoon = dueIn != null && dueIn.inHours <= 24;
    final isOverdue = dueIn != null && dueIn.isNegative;
    final highPriority = t.priorityWeight >= 4;

    // 3) cluster member?
    if (clusterId != null && clusterSize >= 2) {
      final batchNow = clusterSize >= batchNowThreshold ||
          isDueSoon ||
          isOverdue ||
          highPriority;
      final verdict = batchNow
          ? TaskBatchingVerdict.batchNow
          : TaskBatchingVerdict.batchSoon;
      reasons.add('CLUSTER_${clusterSize}_MEMBERS');
      if (isDueSoon) reasons.add('DUE_SOON');
      if (highPriority) reasons.add('HIGH_PRIORITY');
      final score = math.min(
          100.0, 40.0 + clusterSize * 10.0 + (isDueSoon ? 10.0 : 0.0));
      return TaskBatchingForecast(
        id: t.id,
        title: t.title,
        context: t.context,
        location: t.location,
        verdict: verdict,
        priority:
            batchNow ? TaskBatchingPriority.p0 : TaskBatchingPriority.p1,
        clusterId: clusterId,
        batchabilityScore: score,
        reasons: reasons,
        suggestedAction:
            'Run with cluster $clusterId (${clusterSize} sibling tasks)',
      );
    }

    // 4) standalone urgent vs defer
    if (isOverdue || isDueSoon || highPriority) {
      if (isOverdue) reasons.add('OVERDUE');
      if (isDueSoon) reasons.add('DUE_SOON');
      if (highPriority) reasons.add('HIGH_PRIORITY');
      return TaskBatchingForecast(
        id: t.id,
        title: t.title,
        context: t.context,
        location: t.location,
        verdict: TaskBatchingVerdict.standaloneUrgent,
        priority: TaskBatchingPriority.p1,
        clusterId: null,
        batchabilityScore: 15,
        reasons: reasons,
        suggestedAction: 'Slot solo - no batchable siblings, but time-pressured',
      );
    }

    if (t.priorityWeight <= 2) {
      reasons.add('LOW_PRIORITY_ISOLATED');
      return TaskBatchingForecast(
        id: t.id,
        title: t.title,
        context: t.context,
        location: t.location,
        verdict: TaskBatchingVerdict.standaloneDefer,
        priority: TaskBatchingPriority.p2,
        clusterId: null,
        batchabilityScore: 5,
        reasons: reasons,
        suggestedAction: 'Defer; reconsider when a sibling task appears',
      );
    }

    reasons.add('NO_CLUSTER_FIT');
    return TaskBatchingForecast(
      id: t.id,
      title: t.title,
      context: t.context,
      location: t.location,
      verdict: TaskBatchingVerdict.standaloneDefer,
      priority: TaskBatchingPriority.p2,
      clusterId: null,
      batchabilityScore: 10,
      reasons: reasons,
      suggestedAction: 'Pick up alone or wait for a sibling to surface',
    );
  }

  double _unrealisedTax(
    Map<String, List<TaskSnapshot>> byKey,
    int minClusterSize,
    int tax,
  ) {
    // For (context-only) groups with >=2 members that did NOT form a
    // co-located cluster, count the tax we are leaving on the table.
    final byContext = <String, int>{};
    for (final entry in byKey.entries) {
      final ctx = entry.key.split('__').first;
      byContext[ctx] = (byContext[ctx] ?? 0) + entry.value.length;
    }
    var lost = 0;
    byContext.forEach((_, count) {
      if (count >= 2) lost += (count - 1) * tax;
    });
    // Subtract what we already realised by clustering
    final realised = byKey.values
        .where((m) => m.length >= minClusterSize)
        .fold<int>(0, (a, m) => a + (m.length - 1) * tax);
    return math.max(0, lost - realised).toDouble();
  }

  // -------------------------------------------------------------------------
  // Playbook
  // -------------------------------------------------------------------------

  List<BatchingAction> _playbook(
    List<TaskBatchingForecast> forecasts,
    List<TaskCluster> clusters,
    TaskBatchingRiskAppetite appetite,
    String grade,
    int blockedCount,
  ) {
    final actions = <BatchingAction>[];
    final seen = <String>{};

    void add(BatchingAction a) {
      if (seen.add(a.code)) actions.add(a);
    }

    // P0: errand-style batch with due pressure
    final p0Clusters = clusters
        .where((c) =>
            c.priority == TaskBatchingPriority.p0 &&
            (c.context == 'errand' ||
                c.context == 'shopping' ||
                c.context == 'home') &&
            forecasts
                .where((f) => c.memberIds.contains(f.id))
                .any((f) => f.reasons.contains('DUE_SOON') ||
                    f.reasons.contains('OVERDUE')))
        .toList();
    if (p0Clusters.isNotEmpty) {
      add(BatchingAction(
        code: 'RUN_ERRAND_BATCH_NOW',
        priority: TaskBatchingPriority.p0,
        label: 'Run errand batch now',
        reason:
            '${p0Clusters.length} time-pressured co-located cluster(s) ready to batch',
        blastRadius: 2,
        reversibility: 'high',
        relatedIds:
            p0Clusters.expand((c) => c.memberIds).toList()..sort(),
      ));
    }

    // P0/P1: deep work block
    final deepWorkIds = forecasts
        .where((f) => f.context == 'deep_work')
        .map((f) => f.id)
        .toList()
      ..sort();
    if (deepWorkIds.length >= 2) {
      final p = deepWorkIds.length >= 3
          ? TaskBatchingPriority.p0
          : TaskBatchingPriority.p1;
      add(BatchingAction(
        code: 'BLOCK_DEEP_WORK_WINDOW',
        priority: p,
        label: 'Block a deep-work window',
        reason:
            '${deepWorkIds.length} deep_work tasks pending; protect a contiguous slot',
        blastRadius: 3,
        reversibility: 'medium',
        relatedIds: deepWorkIds,
      ));
    }

    // P1: phone call block
    final phoneIds = forecasts
        .where((f) => f.context == 'phone_call')
        .map((f) => f.id)
        .toList()
      ..sort();
    if (phoneIds.length >= 2) {
      add(BatchingAction(
        code: 'SCHEDULE_PHONE_CALL_BLOCK',
        priority: TaskBatchingPriority.p1,
        label: 'Schedule a phone call block',
        reason: '${phoneIds.length} phone_call tasks — knock them out back-to-back',
        blastRadius: 1,
        reversibility: 'high',
        relatedIds: phoneIds,
      ));
    }

    // P1: shopping trip
    final shoppingClusters = clusters
        .where((c) => c.context == 'shopping')
        .toList();
    if (shoppingClusters.isNotEmpty) {
      final ids = shoppingClusters
          .expand((c) => c.memberIds)
          .toSet()
          .toList()
        ..sort();
      add(BatchingAction(
        code: 'BATCH_SHOPPING_TRIP',
        priority: TaskBatchingPriority.p1,
        label: 'Batch shopping into one trip',
        reason:
            'Combine ${ids.length} shopping items into a single outing',
        blastRadius: 2,
        reversibility: 'high',
        relatedIds: ids,
      ));
    }

    // P1: break down large tasks
    final splitIds = forecasts
        .where((f) => f.verdict == TaskBatchingVerdict.splitRecommended)
        .map((f) => f.id)
        .toList()
      ..sort();
    if (splitIds.isNotEmpty) {
      add(BatchingAction(
        code: 'BREAK_DOWN_LARGE_TASKS',
        priority: TaskBatchingPriority.p1,
        label: 'Break down large tasks',
        reason: '${splitIds.length} task(s) too large to swallow in one sitting',
        blastRadius: 1,
        reversibility: 'high',
        relatedIds: splitIds,
      ));
    }

    // P1: unblock tool deps
    final blockedIds = forecasts
        .where(
            (f) => f.verdict == TaskBatchingVerdict.blockedToolUnavailable)
        .map((f) => f.id)
        .toList()
      ..sort();
    if (blockedIds.isNotEmpty) {
      add(BatchingAction(
        code: 'UNBLOCK_TOOL_DEPENDENCIES',
        priority: TaskBatchingPriority.p1,
        label: 'Unblock tool dependencies',
        reason: '$blockedCount task(s) waiting on missing tool(s)',
        blastRadius: 2,
        reversibility: 'high',
        relatedIds: blockedIds,
      ));
    }

    // P2: defer low priority isolates
    final deferIds = forecasts
        .where((f) =>
            f.verdict == TaskBatchingVerdict.standaloneDefer &&
            f.reasons.contains('LOW_PRIORITY_ISOLATED'))
        .map((f) => f.id)
        .toList()
      ..sort();
    if (deferIds.length >= 2) {
      add(BatchingAction(
        code: 'DEFER_LOW_PRIORITY_ISOLATES',
        priority: TaskBatchingPriority.p2,
        label: 'Defer low-priority isolated tasks',
        reason:
            '${deferIds.length} low-priority orphan task(s) — stash for next review',
        blastRadius: 1,
        reversibility: 'high',
        relatedIds: deferIds,
      ));
    }

    // P2: cautious audit step
    if (appetite == TaskBatchingRiskAppetite.cautious &&
        (grade == 'C' || grade == 'D' || grade == 'F')) {
      add(const BatchingAction(
        code: 'SCHEDULE_BATCHING_REVIEW',
        priority: TaskBatchingPriority.p2,
        label: 'Schedule a batching review',
        reason:
            'Cautious mode + portfolio grade is C or worse; revisit clusters tomorrow',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    // P3 fallback
    if (actions.isEmpty) {
      add(const BatchingAction(
        code: 'HEALTHY_TASK_FLOW',
        priority: TaskBatchingPriority.p3,
        label: 'Task flow looks healthy',
        reason: 'No batching pressure, no blockers, no oversized tasks',
        blastRadius: 1,
        reversibility: 'high',
      ));
    } else if (appetite == TaskBatchingRiskAppetite.aggressive) {
      // Aggressive: trim explicit P3 fallback if anything else is present.
      actions.removeWhere((a) => a.priority == TaskBatchingPriority.p3);
    }

    actions.sort((a, b) {
      final p = a.priority.index.compareTo(b.priority.index);
      if (p != 0) return p;
      return a.code.compareTo(b.code);
    });
    return actions;
  }

  // -------------------------------------------------------------------------
  // Insights
  // -------------------------------------------------------------------------

  List<String> _insights(
    List<TaskBatchingForecast> forecasts,
    List<TaskCluster> clusters,
    int savedMinutes,
    int blockedCount,
  ) {
    final out = <String>[];
    if (forecasts.isEmpty) {
      out.add('EMPTY_PORTFOLIO');
      return out;
    }
    if (clusters.any((c) => c.memberIds.length >= 4)) {
      out.add('LARGE_BATCH_OPPORTUNITY');
    }
    if (savedMinutes >= 30) {
      out.add('HIGH_CONTEXT_SWITCH_TAX');
    }
    if (blockedCount > 0) {
      out.add('TOOL_BOTTLENECK');
    }
    final deepWork =
        forecasts.where((f) => f.context == 'deep_work').length;
    if (deepWork >= 3) {
      out.add('OVERLOADED_DEEP_WORK_QUEUE');
    }
    final isolated = forecasts
        .where((f) =>
            f.verdict == TaskBatchingVerdict.standaloneUrgent ||
            f.verdict == TaskBatchingVerdict.standaloneDefer)
        .length;
    if (forecasts.length >= 4 && isolated / forecasts.length >= 0.7) {
      out.add('FRAGMENTED_TASK_PORTFOLIO');
    }
    if (out.isEmpty) {
      out.add('HEALTHY_TASK_FLOW');
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// Renderers
// ---------------------------------------------------------------------------

extension TaskBatchingReportRender on TaskBatchingReport {
  String toText() {
    final b = StringBuffer();
    b.writeln(headline);
    b.writeln('appetite=${_appetiteName(riskAppetite)} band=${_bandName(band)} '
        'frag=${fragmentationScore.toStringAsFixed(1)}');
    b.writeln('');
    b.writeln('Clusters (${clusters.length}):');
    for (final c in clusters) {
      b.writeln('  ${c.clusterId} ${c.context}@${c.location ?? "_"} '
          'n=${c.memberIds.length} save=${c.savingsMinutesEstimate}m '
          '[${_priorityName(c.priority)}]');
    }
    b.writeln('');
    b.writeln('Tasks (${forecasts.length}):');
    for (final f in forecasts) {
      b.writeln('  ${f.id} ${_verdictName(f.verdict)} '
          '[${_priorityName(f.priority)}] -> ${f.suggestedAction}');
    }
    b.writeln('');
    b.writeln('Playbook (${playbook.length}):');
    for (final a in playbook) {
      b.writeln('  [${_priorityName(a.priority)}] ${a.code}: ${a.label}');
    }
    b.writeln('');
    b.writeln('Insights: ${insights.join(", ")}');
    return b.toString();
  }

  String toMarkdown() {
    final b = StringBuffer();
    b.writeln('# Task Batching Advisor');
    b.writeln('');
    b.writeln('## Summary');
    b.writeln('');
    b.writeln('| metric | value |');
    b.writeln('|---|---|');
    b.writeln('| grade | $grade |');
    b.writeln('| band | ${_bandName(band)} |');
    b.writeln('| risk_appetite | ${_appetiteName(riskAppetite)} |');
    b.writeln('| total_tasks | $totalTasks |');
    b.writeln('| batched | $batchedTaskCount |');
    b.writeln('| isolated | $isolatedTaskCount |');
    b.writeln('| projected_saved_minutes | $projectedSavedMinutes |');
    b.writeln('| fragmentation_score | ${fragmentationScore.toStringAsFixed(2)} |');
    b.writeln('');
    b.writeln('## Tasks');
    b.writeln('');
    b.writeln('| id | context | verdict | priority | cluster | action |');
    b.writeln('|---|---|---|---|---|---|');
    for (final f in forecasts) {
      b.writeln('| ${_md(f.id)} | ${_md(f.context)} | '
          '${_verdictName(f.verdict)} | ${_priorityName(f.priority)} | '
          '${_md(f.clusterId ?? "-")} | ${_md(f.suggestedAction)} |');
    }
    b.writeln('');
    b.writeln('## Clusters');
    b.writeln('');
    if (clusters.isEmpty) {
      b.writeln('_no clusters formed_');
    } else {
      b.writeln('| cluster_id | context | location | members | total_min | save_min |');
      b.writeln('|---|---|---|---|---|---|');
      for (final c in clusters) {
        b.writeln('| ${c.clusterId} | ${_md(c.context)} | '
            '${_md(c.location ?? "-")} | ${c.memberIds.length} | '
            '${c.totalMinutes} | ${c.savingsMinutesEstimate} |');
      }
    }
    b.writeln('');
    b.writeln('## Playbook');
    b.writeln('');
    if (playbook.isEmpty) {
      b.writeln('_no actions_');
    } else {
      b.writeln('| priority | code | label | reason |');
      b.writeln('|---|---|---|---|');
      for (final a in playbook) {
        b.writeln('| ${_priorityName(a.priority)} | ${a.code} | '
            '${_md(a.label)} | ${_md(a.reason)} |');
      }
    }
    b.writeln('');
    b.writeln('## Insights');
    b.writeln('');
    for (final i in insights) {
      b.writeln('- $i');
    }
    return b.toString();
  }

  String toJson() {
    final sb = StringBuffer();
    _writeJson(sb, toJsonMap());
    return sb.toString();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _md(String s) => s.replaceAll('|', r'\|');

String _appetiteName(TaskBatchingRiskAppetite a) => switch (a) {
      TaskBatchingRiskAppetite.cautious => 'cautious',
      TaskBatchingRiskAppetite.balanced => 'balanced',
      TaskBatchingRiskAppetite.aggressive => 'aggressive',
    };

String _priorityName(TaskBatchingPriority p) => switch (p) {
      TaskBatchingPriority.p0 => 'P0',
      TaskBatchingPriority.p1 => 'P1',
      TaskBatchingPriority.p2 => 'P2',
      TaskBatchingPriority.p3 => 'P3',
    };

String _verdictName(TaskBatchingVerdict v) => switch (v) {
      TaskBatchingVerdict.batchNow => 'BATCH_NOW',
      TaskBatchingVerdict.batchSoon => 'BATCH_SOON',
      TaskBatchingVerdict.standaloneUrgent => 'STANDALONE_URGENT',
      TaskBatchingVerdict.standaloneDefer => 'STANDALONE_DEFER',
      TaskBatchingVerdict.splitRecommended => 'SPLIT_RECOMMENDED',
      TaskBatchingVerdict.blockedToolUnavailable => 'BLOCKED_TOOL_UNAVAILABLE',
      TaskBatchingVerdict.insufficientData => 'INSUFFICIENT_DATA',
    };

String _bandName(TaskBatchingPortfolioBand b) => switch (b) {
      TaskBatchingPortfolioBand.lean => 'lean',
      TaskBatchingPortfolioBand.healthy => 'healthy',
      TaskBatchingPortfolioBand.bloated => 'bloated',
      TaskBatchingPortfolioBand.severelyBloated => 'severely_bloated',
    };

void _writeJson(StringBuffer sb, dynamic v) {
  if (v == null) {
    sb.write('null');
  } else if (v is bool) {
    sb.write(v ? 'true' : 'false');
  } else if (v is num) {
    if (v is double && (v.isNaN || v.isInfinite)) {
      sb.write('null');
    } else {
      sb.write(v.toString());
    }
  } else if (v is String) {
    sb.write('"');
    for (final code in v.codeUnits) {
      switch (code) {
        case 0x22:
          sb.write(r'\"');
          break;
        case 0x5C:
          sb.write(r'\\');
          break;
        case 0x08:
          sb.write(r'\b');
          break;
        case 0x0C:
          sb.write(r'\f');
          break;
        case 0x0A:
          sb.write(r'\n');
          break;
        case 0x0D:
          sb.write(r'\r');
          break;
        case 0x09:
          sb.write(r'\t');
          break;
        default:
          if (code < 0x20) {
            sb.write('\\u${code.toRadixString(16).padLeft(4, '0')}');
          } else {
            sb.writeCharCode(code);
          }
      }
    }
    sb.write('"');
  } else if (v is List) {
    sb.write('[');
    for (var i = 0; i < v.length; i++) {
      if (i > 0) sb.write(',');
      _writeJson(sb, v[i]);
    }
    sb.write(']');
  } else if (v is Map) {
    sb.write('{');
    var first = true;
    v.forEach((key, value) {
      if (!first) sb.write(',');
      first = false;
      _writeJson(sb, key.toString());
      sb.write(':');
      _writeJson(sb, value);
    });
    sb.write('}');
  } else {
    _writeJson(sb, v.toString());
  }
}

