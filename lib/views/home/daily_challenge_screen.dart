import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/services/daily_challenge_service.dart';

/// A daily challenge screen with today's challenge, streaks, stats, and history.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with SingleTickerProviderStateMixin {
  final _service = DailyChallengeService();
  bool _showConfetti = false;
  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );
    _confettiController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showConfetti = false);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _complete() {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 Challenge Complete!'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'How did it go? (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _service.completeChallenge(
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );
                _showConfetti = true;
              });
              _confettiController.forward(from: 0);
              Navigator.pop(ctx);
            },
            child: const Text('Done!'),
          ),
        ],
      ),
    );
  }

  void _skip() {
    setState(() => _service.skipChallenge());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Challenge skipped. There\'s always tomorrow! 💪'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final challenge = _service.getTodayChallenge();
    final streak = _service.getCurrentStreak();
    final longest = _service.getLongestStreak();
    final catStats = _service.getCategoryStats();
    final upcoming = _service.getUpcoming(3);
    final isDone = _service.isTodayCompleted;
    final isSkipped = _service.isTodaySkipped;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Streak banner
              _buildStreakBanner(streak, longest, theme),
              const SizedBox(height: 16),
              // Today's challenge card
              _buildChallengeCard(challenge, isDone, isSkipped, theme),
              const SizedBox(height: 16),
              // Action buttons
              if (!isDone && !isSkipped)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _complete,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Complete'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _skip,
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Skip'),
                      ),
                    ),
                  ],
                ),
              if (isDone)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Completed! Great job! 🎉',
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              if (isSkipped)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.skip_next, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Skipped today',
                          style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Category stats
              _buildCategoryStats(catStats, theme),
              const SizedBox(height: 24),
              // Upcoming preview
              _buildUpcomingSection(upcoming, theme),
              const SizedBox(height: 24),
              // History
              _buildHistorySection(theme),
            ],
          ),
          // Confetti overlay
          if (_showConfetti) _buildConfetti(),
        ],
      ),
    );
  }

  Widget _buildStreakBanner(int streak, int longest, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text('🔥', style: TextStyle(fontSize: streak > 0 ? 32 : 24)),
                const SizedBox(height: 4),
                Text('$streak',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Current Streak',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
            Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.3)),
            Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text('$longest',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Best Streak',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
            Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.3)),
            Column(
              children: [
                const Text('✅', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text('${_service.totalCompleted}',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Total Done',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
      DailyChallenge challenge, bool isDone, bool isSkipped, ThemeData theme) {
    final catColor = Color(challenge.category.colorValue);
    final diffColor = Color(challenge.difficulty.colorValue);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: catColor.withOpacity(0.15),
            child: Row(
              children: [
                Text(challenge.category.icon,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(challenge.category.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: catColor, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(challenge.difficulty.label,
                      style: TextStyle(
                          color: diffColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Challenge",
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(challenge.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(challenge.description,
                    style: theme.textTheme.bodyMedium),
                if (challenge.estimatedMinutes > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('~${challenge.estimatedMinutes} min',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(
      Map<ChallengeCategory, int> stats, ThemeData theme) {
    final maxVal =
        stats.values.fold(0, (a, b) => a > b ? a : b).clamp(1, 9999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Breakdown',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...stats.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(e.key.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 90,
                      child: Text(e.key.label,
                          style: const TextStyle(fontSize: 13))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value / maxVal,
                        backgroundColor:
                            Color(e.key.colorValue).withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(
                            Color(e.key.colorValue)),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 24,
                      child: Text('${e.value}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildUpcomingSection(List<DailyChallenge> upcoming, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Coming Up',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...upcoming.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final dayLabel = i == 0
              ? 'Tomorrow'
              : i == 1
                  ? 'In 2 days'
                  : 'In 3 days';
          return ListTile(
            leading: Text(c.category.icon,
                style: const TextStyle(fontSize: 24)),
            title: Text(c.title),
            subtitle: Text(dayLabel),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(c.difficulty.colorValue).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(c.difficulty.label,
                  style: TextStyle(
                      color: Color(c.difficulty.colorValue), fontSize: 11)),
            ),
            dense: true,
          );
        }),
      ],
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    final history = _service.history.reversed.toList();
    if (history.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('History',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Center(
            child: Text('No challenges completed yet. Start today!',
                style: TextStyle(color: Colors.grey[500])),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...history.map((r) => ListTile(
              leading: Icon(
                r.completed ? Icons.check_circle : Icons.skip_next,
                color: r.completed ? Colors.green : Colors.orange,
              ),
              title: Text(r.challenge.title),
              subtitle: Text(
                  '${r.challenge.category.icon} ${r.challenge.category.label} • ${_formatDate(r.date)}${r.notes != null ? '\n${r.notes}' : ''}'),
              dense: true,
            )),
      ],
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(_confettiAnimation.value),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _rng = Random(42);

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];

    for (int i = 0; i < 60; i++) {
      final x = _rng.nextDouble() * size.width;
      final startY = -20.0;
      final endY = size.height + 20;
      final y = startY + (endY - startY) * progress +
          _rng.nextDouble() * 50 * sin(progress * 3.14 + i);
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      final w = 4.0 + _rng.nextDouble() * 6;
      final h = 3.0 + _rng.nextDouble() * 5;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(_rng.nextDouble() * 6.28 * progress);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
