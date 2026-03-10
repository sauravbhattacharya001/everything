import 'package:flutter/material.dart';
import '../../models/capture_item.dart';
import '../../core/services/quick_capture_service.dart';

/// Quick Capture Inbox screen — GTD-style rapid thought capture with
/// processing workflow, aging alerts, and inbox statistics.
class QuickCaptureScreen extends StatefulWidget {
  const QuickCaptureScreen({super.key});
  @override
  State<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends State<QuickCaptureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = QuickCaptureService();
  final _captureController = TextEditingController();
  CaptureCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _captureController.dispose();
    super.dispose();
  }

  void _quickCapture() {
    final text = _captureController.text;
    if (text.trim().isEmpty) return;
    setState(() {
      _service.quickCapture(text);
      _captureController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Captured!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\u{1F4E5} Quick Capture'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Capture'),
            Tab(icon: Icon(Icons.inbox), text: 'Inbox'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Processed'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCaptureTab(),
          _buildInboxTab(),
          _buildProcessedTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // ── Capture Tab ─────────────────────────────────────────────────

  Widget _buildCaptureTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Capture',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Type anything — tasks, ideas, questions, links. '
                    'Auto-detects category from keywords.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _captureController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _quickCapture(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _quickCapture,
                    icon: const Icon(Icons.bolt),
                    label: const Text('Capture'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auto-Detection Keywords',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _keywordRow('\u2705 Task', '"todo:", "need to", "should"'),
                  _keywordRow('\u{1F4A1} Idea', '"idea:", "what if", "maybe"'),
                  _keywordRow('\u2753 Question', 'starts/ends with "?"'),
                  _keywordRow('\u{1F517} Link', '"http://", ".com", ".org"'),
                  _keywordRow('\u{1F4AC} Quote', 'starts with \u201c or "'),
                  _keywordRow('\u23F0 Reminder', '"remind", "don\'t forget"'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keywordRow(String category, String keywords) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(category)),
          Expanded(
            child: Text(keywords, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // ── Inbox Tab ───────────────────────────────────────────────────

  Widget _buildInboxTab() {
    final inbox = _filterCategory != null
        ? _service.filterByCategory(_filterCategory!)
        : _service.getInbox();
    final staleCount = _service.getStaleItems().length;

    return Column(
      children: [
        if (staleCount > 0)
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '$staleCount stale items need attention (>3 days old)',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${inbox.length} items',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              DropdownButton<CaptureCategory?>(
                value: _filterCategory,
                hint: const Text('All categories'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...CaptureCategory.values.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.emoji} ${c.label}'),
                      )),
                ],
                onChanged: (v) => setState(() => _filterCategory = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: inbox.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Inbox zero!',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: inbox.length,
                  itemBuilder: (ctx, i) => _buildInboxTile(inbox[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildInboxTile(CaptureItem item) {
    Color? tileColor;
    if (item.isStale) {
      tileColor = Colors.red.shade50;
    } else if (item.isAging) {
      tileColor = Colors.orange.shade50;
    }

    return Card(
      color: tileColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.category.emoji, style: const TextStyle(fontSize: 20)),
            Text(item.priority.emoji, style: const TextStyle(fontSize: 12)),
          ],
        ),
        title: Text(
          item.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: item.isPinned ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(item.ageLabel),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleInboxAction(action, item),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'pin',
              child: Text(item.isPinned ? 'Unpin' : 'Pin'),
            ),
            const PopupMenuItem(value: 'process', child: Text('Process...')),
            const PopupMenuItem(value: 'archive', child: Text('Archive')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _handleInboxAction(String action, CaptureItem item) {
    setState(() {
      switch (action) {
        case 'pin':
          _service.togglePin(item.id);
          break;
        case 'process':
          _showProcessDialog(item);
          break;
        case 'archive':
          _service.archive(item.id);
          break;
        case 'delete':
          _service.delete(item.id);
          break;
      }
    });
  }

  void _showProcessDialog(CaptureItem item) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Process to...'),
        children: ProcessedDestination.values
            .where((d) => d != ProcessedDestination.discarded)
            .map((dest) => SimpleDialogOption(
                  onPressed: () {
                    setState(() {
                      _service.process(item.id, dest);
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(dest.label),
                ))
            .toList(),
      ),
    );
  }

  // ── Processed Tab ───────────────────────────────────────────────

  Widget _buildProcessedTab() {
    final processed = _service.getProcessed();
    final archived = _service.getArchived();
    final all = [...processed, ...archived];
    all.sort((a, b) =>
        (b.processedAt ?? b.capturedAt).compareTo(
            a.processedAt ?? a.capturedAt));

    return all.isEmpty
        ? const Center(
            child: Text('No processed items yet',
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            itemCount: all.length,
            itemBuilder: (ctx, i) {
              final item = all[i];
              return ListTile(
                leading: Text(item.category.emoji,
                    style: const TextStyle(fontSize: 20)),
                title: Text(item.text, maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  item.status == CaptureStatus.processed
                      ? 'Sent to ${item.destination?.label ?? "unknown"}'
                      : 'Archived',
                ),
                trailing: Icon(
                  item.status == CaptureStatus.processed
                      ? Icons.check_circle
                      : Icons.archive,
                  color: item.status == CaptureStatus.processed
                      ? Colors.green
                      : Colors.grey,
                ),
              );
            },
          );
  }

  // ── Stats Tab ───────────────────────────────────────────────────

  Widget _buildStatsTab() {
    final stats = _service.getStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overview cards
          Row(
            children: [
              _statCard('Inbox', '${stats.currentInbox}', Colors.blue),
              const SizedBox(width: 8),
              _statCard('Processed', '${stats.processedCount}', Colors.green),
              const SizedBox(width: 8),
              _statCard('Archived', '${stats.archivedCount}', Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Stale', '${stats.staleCount}',
                  stats.staleCount > 0 ? Colors.red : Colors.grey),
              const SizedBox(width: 8),
              _statCard('Aging', '${stats.agingCount}',
                  stats.agingCount > 0 ? Colors.orange : Colors.grey),
              const SizedBox(width: 8),
              _statCard('Pinned', '${stats.pinnedCount}', Colors.amber),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Productivity',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _metricRow('Captures/day', '${stats.capturesPerDay}'),
                  _metricRow('Processing rate',
                      '${(stats.processingRate * 100).toStringAsFixed(0)}%'),
                  _metricRow('Avg processing time',
                      '${stats.avgProcessingHours}h'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (stats.categoryBreakdown.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Inbox by Category',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...stats.categoryBreakdown.entries
                        .toList()
                      ..sort((a, b) => b.value.compareTo(a.value))
                      ..map((e) => _metricRow(
                            '${e.key.emoji} ${e.key.label}',
                            '${e.value}',
                          )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
