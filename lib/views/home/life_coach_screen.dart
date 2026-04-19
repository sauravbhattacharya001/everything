import 'package:flutter/material.dart';
import '../../core/services/life_coach_service.dart';

/// Smart Life Coach screen — proactive cross-tracker intelligence that
/// analyzes patterns across habits, mood, energy, and goals to deliver
/// personalized nudges, insights, and recommendations.
///
/// 4 tabs:
/// - **Nudges**: Priority-ranked actionable recommendations
/// - **Patterns**: Detected cross-tracker correlations and trends
/// - **Focus Areas**: Life-area scorecards with trend and advice
/// - **Summary**: Weekly coaching report with wins and opportunities
class LifeCoachScreen extends StatefulWidget {
  const LifeCoachScreen({super.key});

  @override
  State<LifeCoachScreen> createState() => _LifeCoachScreenState();
}

class _LifeCoachScreenState extends State<LifeCoachScreen>
    with SingleTickerProviderStateMixin {
  final LifeCoachService _service = LifeCoachService();
  late TabController _tabController;
  late List<CoachNudge> _nudges;
  late List<DetectedPattern> _patterns;
  late List<FocusArea> _focusAreas;
  late CoachingSummary _summary;
  late String _motivation;

  // Filter state for nudges tab
  NudgeType? _selectedFilter;
  final Set<int> _dismissedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nudges = _service.generateNudges();
    _patterns = _service.detectPatterns();
    _focusAreas = _service.getFocusAreas();
    _summary = _service.generateWeeklySummary();
    _motivation = _service.getDailyMotivation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CoachNudge> get _filteredNudges {
    var list = _nudges.where((n) => !_dismissedIds.contains(n.id)).toList();
    if (_selectedFilter != null) {
      list = list.where((n) => n.type == _selectedFilter).toList();
    }
    list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return list;
  }

  Color _priorityColor(NudgePriority p) {
    switch (p) {
      case NudgePriority.urgent:
        return Colors.red;
      case NudgePriority.high:
        return Colors.orange;
      case NudgePriority.medium:
        return Colors.blue;
      case NudgePriority.low:
        return Colors.grey;
    }
  }

  String _typeEmoji(NudgeType t) {
    switch (t) {
      case NudgeType.streak:
        return '🔥';
      case NudgeType.warning:
        return '⚠️';
      case NudgeType.celebration:
        return '🎉';
      case NudgeType.suggestion:
        return '💡';
      case NudgeType.insight:
        return '🧠';
      case NudgeType.challenge:
        return '🏆';
    }
  }

  Color _patternColor(PatternType t) {
    switch (t) {
      case PatternType.correlation:
        return Colors.purple;
      case PatternType.trend:
        return Colors.teal;
      case PatternType.anomaly:
        return Colors.deepOrange;
      case PatternType.cycle:
        return Colors.indigo;
      case PatternType.milestone:
        return Colors.amber;
    }
  }

  String _trendArrow(String trend) {
    switch (trend) {
      case 'up':
        return '↑';
      case 'down':
        return '↓';
      default:
        return '→';
    }
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Coach'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_active), text: 'Nudges'),
            Tab(icon: Icon(Icons.pattern), text: 'Patterns'),
            Tab(icon: Icon(Icons.radar), text: 'Focus'),
            Tab(icon: Icon(Icons.summarize), text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNudgesTab(),
          _buildPatternsTab(),
          _buildFocusTab(),
          _buildSummaryTab(),
        ],
      ),
    );
  }

  // ── Nudges Tab ──

  Widget _buildNudgesTab() {
    final nudges = _filteredNudges;
    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedFilter == null,
                onSelected: (_) => setState(() => _selectedFilter = null),
              ),
              const SizedBox(width: 8),
              ...NudgeType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${_typeEmoji(t)} ${t.name}'),
                      selected: _selectedFilter == t,
                      onSelected: (_) => setState(() =>
                          _selectedFilter = _selectedFilter == t ? null : t),
                    ),
                  )),
            ],
          ),
        ),
        Expanded(
          child: nudges.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Your coach is analyzing patterns...',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: nudges.length,
                  itemBuilder: (ctx, i) => _buildNudgeCard(nudges[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildNudgeCard(CoachNudge nudge) {
    final color = _priorityColor(nudge.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_typeEmoji(nudge.type),
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(nudge.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        setState(() => _dismissedIds.add(nudge.id)),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(nudge.message,
                  style: TextStyle(color: Colors.grey[700], height: 1.4)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(nudge.source,
                        style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  if (nudge.actionLabel != null)
                    TextButton(
                      onPressed: () {},
                      child: Text(nudge.actionLabel!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Patterns Tab ──

  Widget _buildPatternsTab() {
    final sorted = List<DetectedPattern>.from(_patterns)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) => _buildPatternCard(sorted[i]),
    );
  }

  Widget _buildPatternCard(DetectedPattern pattern) {
    final color = _patternColor(pattern.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(pattern.type.name.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    const Spacer(),
                    Text('${(pattern.confidence * 100).round()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(pattern.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pattern.description, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 8),
                Text(pattern.evidence,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                // Confidence bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pattern.confidence,
                    backgroundColor: Colors.grey[200],
                    color: color,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                // Tracker chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: pattern.trackers
                      .map((t) => Chip(
                            label: Text(t,
                                style: const TextStyle(fontSize: 11)),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Focus Areas Tab ──

  Widget _buildFocusTab() {
    // Overall score
    final totalScore =
        (_focusAreas.fold<int>(0, (s, f) => s + f.score) / _focusAreas.length)
            .round();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall score arc
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: totalScore / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    color: totalScore >= 70
                        ? Colors.green
                        : totalScore >= 50
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$totalScore',
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold)),
                    const Text('Life Score',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Focus area grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _focusAreas.length,
            itemBuilder: (ctx, i) => _buildFocusCard(_focusAreas[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusCard(FocusArea area) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFocusDetail(area),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: area.score / 100,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey[200],
                      color: _trendColor(area.trend),
                    ),
                  ),
                  Icon(area.icon, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(area.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${area.score}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(_trendArrow(area.trend),
                      style: TextStyle(
                          color: _trendColor(area.trend),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFocusDetail(FocusArea area) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(area.icon, size: 32),
                const SizedBox(width: 12),
                Text(area.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${area.score}/100',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _trendColor(area.trend))),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Coach\'s Advice',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Text(area.advice,
                style: TextStyle(color: Colors.grey[700], height: 1.5)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Summary Tab ──

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline card
          Card(
            color: Colors.blue[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events,
                      size: 40, color: Colors.amber),
                  const SizedBox(height: 12),
                  Text(_summary.headline,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statBadge('Score', '${_summary.overallScore.round()}'),
                      const SizedBox(width: 16),
                      _statBadge('Nudges', '${_summary.totalNudges}'),
                      const SizedBox(width: 16),
                      _statBadge('Acted On', '${_summary.nudgesActedOn}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Wins
          const Text('✅ This Week\'s Wins',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._summary.wins.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          // Opportunities
          const Text('💡 Opportunities',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._summary.opportunities.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(o)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          // Focus recommendation
          Card(
            color: Colors.purple[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.center_focus_strong, color: Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Focus This Week',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(_summary.focusArea,
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Daily motivation
          Card(
            color: Colors.green[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_motivation,
                        style: TextStyle(
                            color: Colors.green[800],
                            fontStyle: FontStyle.italic,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
