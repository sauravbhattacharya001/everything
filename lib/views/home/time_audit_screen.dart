import 'package:flutter/material.dart';
import '../../core/services/time_audit_service.dart';

/// Smart Time Audit screen — cross-tracker time analysis that identifies
/// productivity windows and delivers proactive schedule optimization.
///
/// 4 tabs: Overview, Windows, Hotspots, Optimize.
class TimeAuditScreen extends StatefulWidget {
  const TimeAuditScreen({super.key});

  @override
  State<TimeAuditScreen> createState() => _TimeAuditScreenState();
}

class _TimeAuditScreenState extends State<TimeAuditScreen>
    with SingleTickerProviderStateMixin {
  final TimeAuditService _service = TimeAuditService();
  late TabController _tabController;
  late List<TimeBlock> _blocks;
  late List<ProductivityWindow> _windows;
  late List<TimeHotspot> _hotspots;
  late List<OptimizationTip> _tips;
  late List<CategoryBalance> _balances;
  late int _balanceScore;
  late int _streak;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _blocks = _service.generateWeeklyBlocks();
    _windows = _service.analyzeProductivityWindows(_blocks);
    _hotspots = _service.detectWastedTime(_blocks);
    _tips = _service.generateOptimizations(_blocks);
    _balances = _service.getTimeBalance(_blocks);
    _balanceScore = _service.calculateBalanceScore(_balances);
    _streak = _service.getBalanceStreak();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _categoryColor(TimeCategory cat) {
    return Color(cat.colorValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Audit'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'Overview'),
            Tab(icon: Icon(Icons.wb_sunny), text: 'Windows'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Hotspots'),
            Tab(icon: Icon(Icons.auto_fix_high), text: 'Optimize'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverview(),
          _buildWindows(),
          _buildHotspots(),
          _buildOptimize(),
        ],
      ),
    );
  }

  // ── Overview Tab ──

  Widget _buildOverview() {
    final totalHours =
        _blocks.fold<double>(0, (sum, b) => sum + b.duration);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance score
        Center(
          child: Column(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _balanceScore / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        _balanceScore > 70
                            ? Colors.green
                            : _balanceScore > 40
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    Center(
                      child: Text(
                        '$_balanceScore',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Balance Score',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text('🔥 $_streak day streak',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Total hours
        Text(
          '${totalHours.toStringAsFixed(1)} hours tracked this week',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 32,
            child: Row(
              children: _balances.map((b) {
                final fraction =
                    totalHours > 0 ? b.actualHours / totalHours : 0.0;
                if (fraction <= 0) return const SizedBox.shrink();
                return Expanded(
                  flex: (fraction * 1000).round(),
                  child: Container(color: _categoryColor(b.category)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _balances.map((b) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _categoryColor(b.category),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${b.category.label} ${b.actualHours.toStringAsFixed(1)}h',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Actual vs Ideal
        const Text('Actual vs Ideal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._balances.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(b.category.label,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (b.actualHours / (b.idealHours * 1.5))
                          .clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation(_categoryColor(b.category)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${b.actualHours.toStringAsFixed(0)}/${b.idealHours.toStringAsFixed(0)}h',
                    style: TextStyle(
                      fontSize: 12,
                      color: b.overAllocated
                          ? Colors.red
                          : b.underAllocated
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── Windows Tab ──

  Widget _buildWindows() {
    if (_windows.isEmpty) {
      return const Center(child: Text('No productivity windows detected.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _windows.length,
      itemBuilder: (context, index) {
        final w = _windows[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny,
                        color: _categoryColor(w.dominantCategory)),
                    const SizedBox(width: 8),
                    Text(w.hourRange,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${w.avgQuality.round()}% quality',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: w.avgQuality / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                      _categoryColor(w.dominantCategory)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${w.dominantCategory.label} dominant',
                  style: TextStyle(
                      fontSize: 13,
                      color: _categoryColor(w.dominantCategory)),
                ),
                const SizedBox(height: 4),
                Text(w.recommendation,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Hotspots Tab ──

  Widget _buildHotspots() {
    if (_hotspots.isEmpty) {
      return const Center(child: Text('No time hotspots detected. 🎉'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hotspots.length,
      itemBuilder: (context, index) {
        final h = _hotspots[index];
        final severity = h.isSevere ? Colors.red : Colors.orange;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: severity.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      h.isSevere ? Icons.error : Icons.warning_amber,
                      color: severity,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${h.dayLabel} ${ProductivityWindow._formatHour(h.startHour)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severity.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${h.quality}%',
                        style: TextStyle(fontSize: 12, color: severity),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(h.issue, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(h.suggestion,
                          style: const TextStyle(
                              fontSize: 13, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Optimize Tab ──

  Widget _buildOptimize() {
    final sorted = List<OptimizationTip>.from(_tips)
      ..sort((a, b) => b.impactScore.compareTo(a.impactScore));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final tip = sorted[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tip.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(tip.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Impact: ${tip.impactScore}/10',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(tip.description,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ActionChip(
                    label: const Text('Apply'),
                    avatar: const Icon(Icons.add, size: 16),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '✓ "${tip.title}" added to schedule suggestions'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
