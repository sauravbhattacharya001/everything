import 'package:flutter/material.dart';
import '../../core/services/context_switcher_service.dart';

/// Smart Context Switcher — autonomous life-context detection with
/// activity pattern analysis and proactive tool suggestions.
class ContextSwitcherScreen extends StatefulWidget {
  const ContextSwitcherScreen({super.key});

  @override
  State<ContextSwitcherScreen> createState() => _ContextSwitcherScreenState();
}

class _ContextSwitcherScreenState extends State<ContextSwitcherScreen> {
  final _service = ContextSwitcherService();
  LifeContext _selectedBias = LifeContext.work;
  late List<ActivitySignal> _activity;
  late ContextDetection _detection;
  bool _evidenceExpanded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _activity = _service.generateSampleActivity(_selectedBias);
    _detection = _service.detectContext(_activity);
  }

  Color _contextColor(LifeContext ctx) => Color(ctx.colorValue);

  IconData _iconForName(String name) {
    const map = <String, IconData>{
      'view_kanban': Icons.view_kanban,
      'grid_4x4': Icons.grid_4x4,
      'attach_money': Icons.attach_money,
      'timer': Icons.timer,
      'rocket_launch': Icons.rocket_launch,
      'schedule': Icons.schedule,
      'table_chart': Icons.table_chart,
      'favorite': Icons.favorite,
      'nights_stay': Icons.nights_stay,
      'checklist': Icons.checklist,
      'card_giftcard': Icons.card_giftcard,
      'people': Icons.people,
      'rate_review': Icons.rate_review,
      'fitness_center': Icons.fitness_center,
      'water_drop': Icons.water_drop,
      'restaurant': Icons.restaurant,
      'monitor_weight': Icons.monitor_weight,
      'local_fire_department': Icons.local_fire_department,
      'grid_on': Icons.grid_on,
      'brush': Icons.brush,
      'palette': Icons.palette,
      'text_fields': Icons.text_fields,
      'article': Icons.article,
      'short_text': Icons.short_text,
      'account_balance': Icons.account_balance,
      'receipt_long': Icons.receipt_long,
      'trending_down': Icons.trending_down,
      'notifications': Icons.notifications,
      'calculate': Icons.calculate,
      'monitor_heart': Icons.monitor_heart,
      'bloodtype': Icons.bloodtype,
      'straighten': Icons.straighten,
      'medication': Icons.medication,
      'bedtime': Icons.bedtime,
      'warning': Icons.warning,
    };
    return map[name] ?? Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctx = _detection.detectedContext;
    final color = _contextColor(ctx);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Context Switcher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-analyze',
            onPressed: () => setState(_refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Context Indicator ─────────────────────────────────
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Current Context', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _detection.confidence,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      Text(ctx.emoji, style: const TextStyle(fontSize: 40)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(ctx.label, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${(_detection.confidence * 100).toStringAsFixed(0)}% confidence',
                      style: theme.textTheme.bodyMedium?.copyWith(color: color)),
                  const SizedBox(height: 4),
                  Text(ctx.description, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Context Distribution Bar ──────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity Distribution', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        children: _detection.alternativeContexts.entries
                            .where((e) => e.value > 0.01)
                            .map((e) => Expanded(
                                  flex: (e.value * 1000).round().clamp(1, 1000),
                                  child: Tooltip(
                                    message: '${e.key.label}: ${(e.value * 100).toStringAsFixed(0)}%',
                                    child: Container(color: _contextColor(e.key)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: _detection.alternativeContexts.entries
                        .where((e) => e.value > 0.01)
                        .map((e) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 10, height: 10,
                                    decoration: BoxDecoration(color: _contextColor(e.key), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text('${e.key.emoji} ${(e.value * 100).toStringAsFixed(0)}%',
                                    style: theme.textTheme.bodySmall),
                              ],
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Evidence Panel ────────────────────────────────────
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.search, color: color),
              title: const Text('Detection Evidence'),
              initiallyExpanded: _evidenceExpanded,
              onExpansionChanged: (v) => _evidenceExpanded = v,
              children: [
                for (final signal in _detection.signals)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.arrow_right, size: 16),
                    title: Text(signal, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Suggested Tools Grid ──────────────────────────────
          Text('Suggested Tools', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: _detection.suggestedTools.length,
            itemBuilder: (_, i) {
              final tool = _detection.suggestedTools[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_iconForName(tool.iconName), size: 20, color: color),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tool.name, style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(tool.reason, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      LinearProgressIndicator(
                        value: tool.relevanceScore,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(color.withAlpha(180)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Transition Insight ────────────────────────────────
          Card(
            color: color.withAlpha(25),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Context Insight', style: theme.textTheme.titleSmall?.copyWith(color: color)),
                        const SizedBox(height: 4),
                        Text(_detection.transitionInsight, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Day Timeline ──────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Typical Day Flow', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: _service.getContextHistory().map((c) => Expanded(
                        child: Tooltip(
                          message: '${c.emoji} ${c.label}',
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: _contextColor(c),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(child: Text(c.emoji, style: const TextStyle(fontSize: 12))),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('6 AM', style: theme.textTheme.bodySmall),
                      Text('12 PM', style: theme.textTheme.bodySmall),
                      Text('9 PM', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Scenario Selector ─────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Simulation', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<LifeContext>(
                          value: _selectedBias,
                          decoration: const InputDecoration(
                            labelText: 'Activity bias',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: LifeContext.values.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.emoji} ${c.label}'),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() {
                              _selectedBias = v;
                              _refresh();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Run'),
                        onPressed: () => setState(_refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${_activity.length} activity signals generated',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
