import 'package:flutter/material.dart';
import '../../core/services/time_capsule_service.dart';
import '../../models/time_capsule_entry.dart';

class TimeCapsuleScreen extends StatefulWidget {
  const TimeCapsuleScreen({super.key});

  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen>
    with SingleTickerProviderStateMixin {
  final TimeCapsuleService _service = TimeCapsuleService();
  late TabController _tabController;
  bool _loading = true;

  static const _moods = ['😊', '😢', '🔥', '💪', '🌟', '❤️', '🤔', '😴'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _service.init();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createCapsule() async {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    DateTime unlockDate = DateTime.now().add(const Duration(days: 30));
    String selectedMood = '😊';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('✉️ New Time Capsule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'A note to future me...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Dear future me...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Current mood:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: _moods
                      .map((m) => GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedMood = m),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: m == selectedMood
                                    ? Theme.of(ctx)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.2)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: m == selectedMood
                                    ? Border.all(
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .primary)
                                    : null,
                              ),
                              child: Text(m, style: const TextStyle(fontSize: 24)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_clock),
                  title: const Text('Unlock date'),
                  subtitle: Text(
                    '${unlockDate.year}-${unlockDate.month.toString().padLeft(2, '0')}-${unlockDate.day.toString().padLeft(2, '0')}',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: unlockDate,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 10)),
                    );
                    if (picked != null) {
                      setDialogState(() => unlockDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Seal Capsule 🔒'),
            ),
          ],
        ),
      ),
    );

    if (result == true &&
        titleCtrl.text.isNotEmpty &&
        messageCtrl.text.isNotEmpty) {
      final capsule = TimeCapsuleEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleCtrl.text,
        message: messageCtrl.text,
        createdAt: DateTime.now(),
        unlockAt: unlockDate,
        mood: selectedMood,
      );
      await _service.addCapsule(capsule);
      setState(() {});
    }

    titleCtrl.dispose();
    messageCtrl.dispose();
  }

  Future<void> _openCapsule(TimeCapsuleEntry capsule) async {
    final opened = await _service.openCapsule(capsule.id);
    if (opened == null) return;
    setState(() {});

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(opened.mood ?? '✉️'),
            const SizedBox(width: 8),
            Expanded(child: Text(opened.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Written on ${_formatDate(opened.createdAt)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const Divider(height: 24),
              Text(
                opened.message,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCapsule(TimeCapsuleEntry capsule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Capsule?'),
        content: Text('Delete "${capsule.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteCapsule(capsule.id);
      setState(() {});
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _buildCapsuleCard(TimeCapsuleEntry capsule) {
    final isLocked = !capsule.isUnlocked;
    final canOpen = capsule.canOpen;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLocked
              ? Colors.grey[300]
              : canOpen
                  ? Colors.amber[100]
                  : Colors.green[100],
          child: Text(
            isLocked
                ? '🔒'
                : canOpen
                    ? '✨'
                    : '📖',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          isLocked ? '🔒 ${capsule.title}' : capsule.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isLocked ? Colors.grey[600] : null,
          ),
        ),
        subtitle: Text(
          isLocked
              ? capsule.timeRemainingLabel
              : capsule.isOpened
                  ? 'Opened ${_formatDate(capsule.openedAt!)}'
                  : 'Ready to open!',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'open') _openCapsule(capsule);
            if (v == 'delete') _deleteCapsule(capsule);
          },
          itemBuilder: (_) => [
            if (canOpen)
              const PopupMenuItem(
                  value: 'open', child: Text('✨ Open Capsule')),
            if (capsule.isOpened)
              const PopupMenuItem(value: 'open', child: Text('📖 Re-read')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('🗑️ Delete',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
        onTap: canOpen
            ? () => _openCapsule(capsule)
            : capsule.isOpened
                ? () => _openCapsule(capsule)
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('⏳ Time Capsules')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('⏳ Time Capsules'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '🔒 Locked (${_service.lockedCount})'),
            Tab(text: '✨ Ready (${_service.readyToOpenCount})'),
            Tab(text: '📖 Opened (${_service.openedCount})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_service.locked, 'No locked capsules.\nWrite a note to future you!'),
          _buildList(_service.readyToOpen, 'No capsules ready to open yet.\nPatience! 🕐'),
          _buildList(_service.opened, 'No opened capsules yet.'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCapsule,
        icon: const Icon(Icons.add),
        label: const Text('New Capsule'),
      ),
    );
  }

  Widget _buildList(List<TimeCapsuleEntry> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildCapsuleCard(items[i]),
    );
  }
}
