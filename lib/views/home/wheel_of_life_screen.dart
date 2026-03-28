import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin, max, atan2;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Wheel of Life — a self-assessment tool where users rate 8 life areas
/// on a 1-10 scale and visualise the balance as a radar chart. Tap any
/// segment to adjust scores. Previous assessments are tracked so users
/// can compare progress over time.
class WheelOfLifeScreen extends StatefulWidget {
  const WheelOfLifeScreen({super.key});

  @override
  State<WheelOfLifeScreen> createState() => _WheelOfLifeScreenState();
}

class _WheelOfLifeScreenState extends State<WheelOfLifeScreen>
    with SingleTickerProviderStateMixin {
  static const _prefsKey = 'wheel_of_life_history';

  static const List<_LifeArea> _areas = [
    _LifeArea('Career', Icons.work, Color(0xFF4CAF50)),
    _LifeArea('Finance', Icons.attach_money, Color(0xFF2196F3)),
    _LifeArea('Health', Icons.favorite, Color(0xFFF44336)),
    _LifeArea('Relationships', Icons.people, Color(0xFFFF9800)),
    _LifeArea('Fun & Recreation', Icons.sports_esports, Color(0xFF9C27B0)),
    _LifeArea('Personal Growth', Icons.school, Color(0xFF009688)),
    _LifeArea('Physical Environment', Icons.home, Color(0xFF795548)),
    _LifeArea('Family & Friends', Icons.group, Color(0xFFE91E63)),
  ];

  late List<double> _scores;
  List<List<double>>? _previousScores;
  List<String>? _previousDates;
  late AnimationController _animController;
  late Animation<double> _animation;
  int? _selectedArea;
  bool _showHistory = false;
  int _historyIndex = -1; // -1 = current

  @override
  void initState() {
    super.initState();
    _scores = List.filled(_areas.length, 5.0);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _loadHistory();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final entries = (data['entries'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _previousScores = entries.map((e) => (e['scores'] as List).cast<double>().toList()).toList();
        _previousDates = entries.map((e) => e['date'] as String).toList();
      });
    }
  }

  Future<void> _saveAssessment() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _previousScores ??= [];
    _previousDates ??= [];
    _previousScores!.add(List.from(_scores));
    _previousDates!.add(dateStr);

    // Keep last 20 assessments
    while (_previousScores!.length > 20) {
      _previousScores!.removeAt(0);
      _previousDates!.removeAt(0);
    }

    final entries = <Map<String, dynamic>>[];
    for (var i = 0; i < _previousScores!.length; i++) {
      entries.add({'date': _previousDates![i], 'scores': _previousScores![i]});
    }
    await prefs.setString(_prefsKey, jsonEncode({'entries': entries}));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assessment saved! Average: ${(_scores.reduce((a, b) => a + b) / _scores.length).toStringAsFixed(1)}/10'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double get _averageScore => _scores.reduce((a, b) => a + b) / _scores.length;

  String get _balanceLabel {
    final avg = _averageScore;
    final variance = _scores.map((s) => (s - avg) * (s - avg)).reduce((a, b) => a + b) / _scores.length;
    if (variance < 1.5) return 'Well Balanced';
    if (variance < 4.0) return 'Slightly Uneven';
    return 'Needs Attention';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wheel of Life'),
        actions: [
          if (_previousScores != null && _previousScores!.isNotEmpty)
            IconButton(
              icon: Icon(_showHistory ? Icons.radar : Icons.history),
              tooltip: _showHistory ? 'Current' : 'History',
              onPressed: () => setState(() {
                _showHistory = !_showHistory;
                _historyIndex = _showHistory ? _previousScores!.length - 1 : -1;
              }),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset all to 5',
            onPressed: () {
              setState(() {
                _scores = List.filled(_areas.length, 5.0);
                _selectedArea = null;
              });
              _animController.forward(from: 0);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryChip('Average', _averageScore.toStringAsFixed(1), theme.colorScheme.primary),
                  _summaryChip('Balance', _balanceLabel, _balanceLabel == 'Well Balanced' ? Colors.green : Colors.orange),
                  _summaryChip('Lowest', _areas[_scores.indexOf(_scores.reduce((a, b) => a < b ? a : b))].name,
                      Colors.red.shade300),
                ],
              ),
            ),
          ),

          // Radar chart
          Expanded(
            flex: 3,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final displayScores = _showHistory && _historyIndex >= 0
                    ? _previousScores![_historyIndex]
                    : _scores;
                return GestureDetector(
                  onTapUp: _showHistory ? null : (details) => _handleTap(details, context),
                  child: CustomPaint(
                    painter: _WheelPainter(
                      scores: displayScores,
                      areas: _areas,
                      animValue: _animation.value,
                      selectedIndex: _selectedArea,
                      isDark: isDark,
                      previousScores: _showHistory && _historyIndex > 0
                          ? _previousScores![_historyIndex - 1]
                          : null,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),

          if (_showHistory && _previousDates != null && _previousDates!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _historyIndex > 0
                        ? () => setState(() => _historyIndex--)
                        : null,
                  ),
                  Text(
                    '${_previousDates![_historyIndex]}  (${_historyIndex + 1}/${_previousDates!.length})',
                    style: theme.textTheme.titleSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _historyIndex < _previousDates!.length - 1
                        ? () => setState(() => _historyIndex++)
                        : null,
                  ),
                ],
              ),
            ),
          ],

          // Score sliders
          if (!_showHistory)
            Expanded(
              flex: 2,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _areas.length,
                itemBuilder: (context, i) {
                  final area = _areas[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(area.icon, color: area.color, size: 20),
                    title: Text(area.name, style: const TextStyle(fontSize: 13)),
                    trailing: SizedBox(
                      width: 48,
                      child: Text(
                        _scores[i].toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: area.color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    subtitle: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: area.color,
                        thumbColor: area.color,
                        inactiveTrackColor: area.color.withOpacity(0.2),
                        overlayColor: area.color.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: _scores[i],
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (v) => setState(() => _scores[i] = v),
                      ),
                    ),
                    onTap: () => setState(() => _selectedArea = _selectedArea == i ? null : i),
                    selected: _selectedArea == i,
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _showHistory
          ? null
          : FloatingActionButton.extended(
              onPressed: _saveAssessment,
              icon: const Icon(Icons.save),
              label: const Text('Save Assessment'),
            ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ],
    );
  }

  void _handleTap(TapUpDetails details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final tap = details.localPosition;
    final dx = tap.dx - center.dx;
    final dy = tap.dy - center.dy;
    if (dx == 0 && dy == 0) return;
    // Angle from top (12 o'clock), clockwise
    final a = (atan2(dx, -dy) + 2 * pi) % (2 * pi);
    final segmentAngle = 2 * pi / _areas.length;
    final index = (a / segmentAngle).floor() % _areas.length;
    setState(() => _selectedArea = _selectedArea == index ? null : index);
  }
}

class _LifeArea {
  final String name;
  final IconData icon;
  final Color color;
  const _LifeArea(this.name, this.icon, this.color);
}

class _WheelPainter extends CustomPainter {
  final List<double> scores;
  final List<_LifeArea> areas;
  final double animValue;
  final int? selectedIndex;
  final bool isDark;
  final List<double>? previousScores;

  _WheelPainter({
    required this.scores,
    required this.areas,
    required this.animValue,
    this.selectedIndex,
    required this.isDark,
    this.previousScores,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 * 0.75;
    final n = areas.length;
    final angleStep = 2 * pi / n;

    // Draw concentric rings (scale 2, 4, 6, 8, 10)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isDark ? Colors.white24 : Colors.black12;

    for (var ring = 2; ring <= 10; ring += 2) {
      final r = radius * ring / 10;
      canvas.drawCircle(center, r, ringPaint);
    }

    // Draw axis lines and labels
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isDark ? Colors.white30 : Colors.black26;

    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + i * angleStep;
      final end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, end, axisPaint);

      // Label
      final labelOffset = Offset(
        center.dx + (radius + 18) * cos(angle),
        center.dy + (radius + 18) * sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: areas[i].name,
          style: TextStyle(
            fontSize: 10,
            color: selectedIndex == i ? areas[i].color : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: selectedIndex == i ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(labelOffset.dx - tp.width / 2, labelOffset.dy - tp.height / 2));
    }

    // Draw previous scores (ghost overlay)
    if (previousScores != null) {
      final ghostPath = Path();
      for (var i = 0; i < n; i++) {
        final angle = -pi / 2 + i * angleStep;
        final r = radius * previousScores![i] / 10;
        final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
        if (i == 0) {
          ghostPath.moveTo(p.dx, p.dy);
        } else {
          ghostPath.lineTo(p.dx, p.dy);
        }
      }
      ghostPath.close();
      canvas.drawPath(
        ghostPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.grey.withOpacity(0.4),
      );
    }

    // Draw current scores polygon
    final path = Path();
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + i * angleStep;
      final r = radius * scores[i] / 10 * animValue;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    // Gradient-like fill using primary color
    fillPaint.color = Colors.blue.withOpacity(0.15);
    strokePaint.color = Colors.blue.withOpacity(0.8);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Draw score dots
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + i * angleStep;
      final r = radius * scores[i] / 10 * animValue;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      canvas.drawCircle(
        p,
        selectedIndex == i ? 6 : 4,
        Paint()..color = areas[i].color,
      );
      // Score text near dot
      final tp = TextPainter(
        text: TextSpan(
          text: scores[i].toStringAsFixed(0),
          style: TextStyle(fontSize: 10, color: areas[i].color, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => true;
}
