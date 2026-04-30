import 'package:flutter/material.dart';
import '../../core/services/regret_minimization_service.dart';

/// Regret Minimization Engine screen — autonomous decision outcome tracker.
/// Analyzes past decisions for regret patterns, identifies cognitive biases,
/// generates wisdom principles, and runs Future Self tests for pending decisions.
class RegretMinimizationScreen extends StatefulWidget {
  const RegretMinimizationScreen({super.key});

  @override
  State<RegretMinimizationScreen> createState() =>
      _RegretMinimizationScreenState();
}

class _RegretMinimizationScreenState extends State<RegretMinimizationScreen>
    with SingleTickerProviderStateMixin {
  final RegretMinimizationService _service = RegretMinimizationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _service.loadSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _service.getDashboard();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regret Minimization Engine'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.history), text: 'Decisions'),
            Tab(icon: Icon(Icons.psychology), text: 'Biases'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Wisdom'),
            Tab(icon: Icon(Icons.elderly), text: 'Future Self'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(dashboard, theme),
          _buildDecisionsTab(theme),
          _buildBiasesTab(dashboard, theme),
          _buildWisdomTab(dashboard, theme),
          _buildFutureSelfTab(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard Tab
  // ---------------------------------------------------------------------------

  Widget _buildDashboardTab(RegretDashboard dashboard, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Verdict
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Decision Health',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(dashboard.healthVerdict,
                      style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Score Cards
          Row(
            children: [
              Expanded(
                child: _buildScoreCard(
                  'Regret Score',
                  dashboard.regretScore,
                  Colors.red,
                  '${dashboard.regretScore.toInt()}/100',
                  inverted: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreCard(
                  'Wisdom Score',
                  dashboard.wisdomScore,
                  Colors.amber,
                  '${dashboard.wisdomScore.toInt()}/100',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                  '${dashboard.totalDecisions}', 'Decisions', Icons.note_alt),
              _buildStatChip('${dashboard.outcomeRecorded}', 'Reviewed',
                  Icons.check_circle),
              _buildStatChip('${dashboard.pendingReview}', 'Pending',
                  Icons.schedule),
            ],
          ),
          const SizedBox(height: 24),

          // Domain Satisfaction
          if (dashboard.domainSatisfaction.isNotEmpty) ...[
            Text('Satisfaction by Domain',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...dashboard.domainSatisfaction.entries.map((e) {
              final normalized = (e.value + 1) / 2; // -1..1 → 0..1
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                        width: 30,
                        child:
                            Text(e.key.emoji, textAlign: TextAlign.center)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 90,
                        child: Text(e.key.label,
                            style: theme.textTheme.bodySmall)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: normalized.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        color: normalized > 0.6
                            ? Colors.green
                            : normalized > 0.4
                                ? Colors.amber
                                : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(e.value * 100).toInt()}%',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 24),

          // Top Regret Patterns
          if (dashboard.topPatterns.isNotEmpty) ...[
            Text('Top Regret Patterns',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...dashboard.topPatterns.map((p) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Text('${p.occurrences}x'),
                    ),
                    title: Text('${p.type.label} in ${p.domain.label}'),
                    subtitle: Text(p.insight),
                    trailing: Text(
                      '${(p.averageIntensity * 100).toInt()}%',
                      style: TextStyle(
                        color: p.averageIntensity > 0.6
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )),
          ],

          // Pending Reviews
          if (dashboard.upcomingReviews.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('⏰ Decisions Awaiting Review',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...dashboard.upcomingReviews.map((d) => Card(
                  child: ListTile(
                    leading: Text(d.domain.emoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(d.title),
                    subtitle: Text(
                        '${d.stakes.label} stakes • ${_daysAgo(d.timestamp)} days ago'),
                    trailing: const Icon(Icons.rate_review),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Decisions Tab
  // ---------------------------------------------------------------------------

  Widget _buildDecisionsTab(ThemeData theme) {
    final decisions = _service.decisions;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: decisions.length,
      itemBuilder: (context, index) {
        final d = decisions[index];
        final hasOutcome = d.outcome != null;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d.domain.emoji, style: const TextStyle(fontSize: 20)),
                if (hasOutcome)
                  Text(d.outcome!.satisfaction.emoji,
                      style: const TextStyle(fontSize: 14)),
              ],
            ),
            title: Text(d.title),
            subtitle: Text(
              '${d.stakes.label} • ${_daysAgo(d.timestamp)}d ago • '
              'Confidence: ${(d.confidenceLevel * 100).toInt()}%',
              style: theme.textTheme.bodySmall,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description:', style: theme.textTheme.labelLarge),
                    Text(d.description),
                    const SizedBox(height: 8),
                    Text('Chose: ${d.chosenOption}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Reasoning: ${d.reasoning}'),
                    const SizedBox(height: 8),
                    Text('Alternatives: ${d.alternatives.join(", ")}'),
                    Text(
                        'Emotions: ${d.emotionsAtTime.join(", ")}'),
                    Text(
                        'Reversible: ${d.wasReversible ? "Yes" : "No"}'),
                    if (d.externalPressure != null)
                      Text('External pressure: ${d.externalPressure}'),
                    if (hasOutcome) ...[
                      const Divider(height: 24),
                      Text('Outcome',
                          style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary)),
                      Text(
                          '${d.outcome!.satisfaction.emoji} ${d.outcome!.satisfaction.label}'),
                      Text('What happened: ${d.outcome!.whatHappened}'),
                      Text('Surprised by: ${d.outcome!.whatSurprised}'),
                      if (d.outcome!.regretType != null)
                        Text(
                          'Regret: ${d.outcome!.regretType!.label} '
                          '(${(d.outcome!.regretIntensity * 100).toInt()}%)',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      if (d.outcome!.lessonLearned != null)
                        Text(
                          '💡 Lesson: ${d.outcome!.lessonLearned}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      Text(
                        d.outcome!.wouldChooseSameAgain
                            ? '✅ Would choose same again'
                            : '❌ Would NOT choose same again',
                      ),
                    ] else
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: const Text('Awaiting outcome review'),
                        backgroundColor: Colors.amber.shade100,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Biases Tab
  // ---------------------------------------------------------------------------

  Widget _buildBiasesTab(RegretDashboard dashboard, ThemeData theme) {
    final biasProfile = _service.getBiasProfile();
    final allBiases = _service.getBiasDetections();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Bias Profile', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Cognitive biases detected in your decision history',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),

          if (biasProfile.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                      'Record more decisions with outcomes to detect biases'),
                ),
              ),
            )
          else ...[
            // Bias frequency chart
            ...biasProfile.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value))
              ..forEach((_) {}), // force evaluation
            ...biasProfile.entries
                .toList()
                .map((e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(e.key.label,
                                      style: theme.textTheme.titleSmall),
                                ),
                                Chip(
                                  label: Text('${e.value}x'),
                                  backgroundColor: e.value >= 3
                                      ? Colors.red.shade100
                                      : Colors.orange.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(e.key.description,
                                style: theme.textTheme.bodySmall),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.healing,
                                      size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Antidote: ${e.key.antidote}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.green.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),

            const SizedBox(height: 24),
            Text('Recent Bias Detections',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...allBiases.take(8).map((b) {
              final decision =
                  _service.decisions.where((d) => d.id == b.decisionId).first;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: Text('${(b.confidence * 100).toInt()}%',
                        style: const TextStyle(fontSize: 11)),
                  ),
                  title: Text(b.bias.label),
                  subtitle: Text('In: ${decision.title}\n${b.evidence}'),
                  isThreeLine: true,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Wisdom Tab
  // ---------------------------------------------------------------------------

  Widget _buildWisdomTab(RegretDashboard dashboard, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Earned Wisdom', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Principles distilled from your decision history',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),

          if (dashboard.wisdomPrinciples.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                      'Wisdom emerges with more reviewed decisions'),
                ),
              ),
            )
          else
            ...dashboard.wisdomPrinciples.map((w) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(w.principle,
                                  style: theme.textTheme.titleSmall),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(w.evidence,
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStrengthIndicator(w.strength),
                            const SizedBox(width: 12),
                            Text(
                              'Based on ${w.supportingDecisions} decisions',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (w.applicableDomains.length <
                            DecisionDomain.values.length) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children: w.applicableDomains
                                .map((d) => Chip(
                                      label: Text(
                                          '${d.emoji} ${d.label}',
                                          style: const TextStyle(
                                              fontSize: 11)),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                )),

          // Lessons from decisions
          const SizedBox(height: 24),
          Text('Lessons Learned', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._service.decisions
              .where((d) =>
                  d.outcome != null && d.outcome!.lessonLearned != null)
              .map((d) => Card(
                    child: ListTile(
                      leading: Text(d.domain.emoji,
                          style: const TextStyle(fontSize: 20)),
                      title: Text(
                        '💡 ${d.outcome!.lessonLearned}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      subtitle: Text('From: ${d.title}'),
                    ),
                  )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Future Self Tab
  // ---------------------------------------------------------------------------

  Widget _buildFutureSelfTab(ThemeData theme) {
    // Run sample tests for demonstration
    final tests = [
      _service.runFutureSelfTest(
        title: 'Quit job to start a company',
        domain: DecisionDomain.career,
        stakes: StakesLevel.lifeChanging,
        isAction: true,
      ),
      _service.runFutureSelfTest(
        title: 'Move to a new city for fresh start',
        domain: DecisionDomain.lifestyle,
        stakes: StakesLevel.high,
        isAction: true,
      ),
      _service.runFutureSelfTest(
        title: 'Have a difficult conversation with friend',
        domain: DecisionDomain.relationships,
        stakes: StakesLevel.moderate,
        isAction: true,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Future Self Test', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '"Will 80-year-old me regret NOT doing this?"',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Text(
            'Based on your decision history, here\'s how similar choices '
            'have played out:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          ...tests.map((test) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(test.decisionTitle,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),

                      // Regret comparison bars
                      Row(
                        children: [
                          const SizedBox(width: 80, child: Text('If you act:')),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: test.regretIfAct,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(test.regretIfAct * 100).toInt()}%'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                              width: 80, child: Text('If you skip:')),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: test.regretIfSkip,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(test.regretIfSkip * 100).toInt()}%'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Perspectives
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔮 10-Year View:',
                                style: theme.textTheme.labelMedium),
                            Text(test.tenYearPerspective,
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🪦 Deathbed View:',
                                style: theme.textTheme.labelMedium),
                            Text(test.deathbedPerspective,
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Recommendation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(test.recommendation,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildScoreCard(
      String title, double value, Color color, String display,
      {bool inverted = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: value / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: inverted
                        ? (value < 30
                            ? Colors.green
                            : value < 60
                                ? Colors.amber
                                : Colors.red)
                        : (value > 70
                            ? Colors.green
                            : value > 40
                                ? Colors.amber
                                : Colors.red),
                    strokeWidth: 6,
                  ),
                ),
                Text(display,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStrengthIndicator(double strength) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final threshold = (i + 1) / 5;
        return Icon(
          strength >= threshold ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: strength >= threshold ? Colors.amber : Colors.grey.shade300,
        );
      }),
    );
  }

  int _daysAgo(DateTime date) {
    return DateTime.now().difference(date).inDays;
  }
}
