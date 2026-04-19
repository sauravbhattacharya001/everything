import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/services/morning_briefing_service.dart';

/// Morning Briefing — a proactive daily dashboard that correlates signals
/// from habits, mood, sleep, water, energy, and focus to surface insights
/// and actionable recommendations.
///
/// This is an "inter-system awareness" feature: it detects patterns that
/// no single tracker could find on its own (e.g., sleep→energy correlation,
/// habit→mood feedback loops).
class MorningBriefingScreen extends StatefulWidget {
  const MorningBriefingScreen({super.key});

  @override
  State<MorningBriefingScreen> createState() => _MorningBriefingScreenState();
}

class _MorningBriefingScreenState extends State<MorningBriefingScreen>
    with SingleTickerProviderStateMixin {
  final _service = MorningBriefingService();
  late MorningBriefing _briefing;
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _briefing = _service.generate();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = Tween<double>(begin: 0, end: _briefing.overallScore)
        .animate(CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.easeOutCubic,
    ));
    _scoreAnimController.forward();
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    super.dispose();
  }

  Color _scoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _sentimentColor(InsightSentiment s) {
    switch (s) {
      case InsightSentiment.positive:
        return Colors.green.shade50;
      case InsightSentiment.warning:
        return Colors.orange.shade50;
      case InsightSentiment.correlation:
        return Colors.blue.shade50;
      case InsightSentiment.neutral:
        return Colors.grey.shade100;
    }
  }

  Color _sentimentBorder(InsightSentiment s) {
    switch (s) {
      case InsightSentiment.positive:
        return Colors.green.shade200;
      case InsightSentiment.warning:
        return Colors.orange.shade200;
      case InsightSentiment.correlation:
        return Colors.blue.shade200;
      case InsightSentiment.neutral:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Morning Briefing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh briefing',
            onPressed: () {
              setState(() {
                _briefing = _service.generate();
                _scoreAnim = Tween<double>(begin: 0, end: _briefing.overallScore)
                    .animate(CurvedAnimation(
                  parent: _scoreAnimController,
                  curve: Curves.easeOutCubic,
                ));
                _scoreAnimController
                  ..reset()
                  ..forward();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting & Score ──
            _buildHeader(),
            const SizedBox(height: 24),

            // ── Quick Stats Row ──
            _buildQuickStats(),
            const SizedBox(height: 24),

            // ── Insights ──
            if (_briefing.insights.isNotEmpty) ...[
              const Text(
                'Insights',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._briefing.insights.map(_buildInsightCard),
              const SizedBox(height: 24),
            ],

            // ── Recommendations ──
            if (_briefing.recommendations.isNotEmpty) ...[
              const Text(
                'Recommendations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._briefing.recommendations.asMap().entries.map(
                    (e) => _buildRecommendationTile(e.key + 1, e.value),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Animated score ring
            AnimatedBuilder(
              animation: _scoreAnim,
              builder: (context, child) {
                final value = _scoreAnim.value;
                return SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                    painter: _ScoreRingPainter(
                      score: value,
                      color: _scoreColor(value),
                    ),
                    child: Center(
                      child: Text(
                        '${value.round()}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _scoreColor(value),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_briefing.greeting}! ☀️',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _briefing.dayName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scoreLabel(_briefing.overallScore),
                    style: TextStyle(
                      fontSize: 14,
                      color: _scoreColor(_briefing.overallScore),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _scoreLabel(double score) {
    if (score >= 80) return 'You\'re doing amazing! 🚀';
    if (score >= 60) return 'Solid day ahead 💪';
    if (score >= 40) return 'Room for improvement 📈';
    return 'Take it easy today 🌿';
  }

  Widget _buildQuickStats() {
    final s = _briefing.snapshot;
    return Row(
      children: [
        _statChip('😴', '${s.sleepHours.toStringAsFixed(1)}h'),
        _statChip('💧', '${s.waterGlasses} glasses'),
        _statChip('🔋', '${s.energyLevel.toStringAsFixed(0)}/10'),
        _statChip('✅', '${s.habitsCompleted}/${s.habitsTotal}'),
      ],
    );
  }

  Widget _statChip(String emoji, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(BriefingInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _sentimentColor(insight.sentiment),
        border: Border.all(color: _sentimentBorder(insight.sentiment)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(insight.icon, style: const TextStyle(fontSize: 28)),
        title: Text(
          insight.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(insight.detail),
      ),
    );
  }

  Widget _buildRecommendationTile(int index, String rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            '$index',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        title: Text(rec),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}

/// Paints an animated circular score ring.
class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Color color;

  _ScoreRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = Colors.grey.shade200,
    );

    // Score arc
    final sweepAngle = (score / 100) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.score != score || old.color != color;
}


