import 'package:flutter/material.dart';
import '../../core/services/screen_persistence.dart';
import '../../core/services/subscription_tracker_service.dart';
import '../../models/subscription_entry.dart';

/// Subscription Tracker screen — manage recurring subscriptions, view upcoming
/// renewals, and get cost optimization insights.
class SubscriptionTrackerScreen extends StatefulWidget {
  const SubscriptionTrackerScreen({super.key});

  @override
  State<SubscriptionTrackerScreen> createState() =>
      _SubscriptionTrackerScreenState();
}

class _SubscriptionTrackerScreenState extends State<SubscriptionTrackerScreen>
    with SingleTickerProviderStateMixin {
  final SubscriptionTrackerService _service = SubscriptionTrackerService();
  final _persistence = ScreenPersistence<SubscriptionEntry>(
    storageKey: 'subscription_tracker_entries',
    toJson: (e) => e.toJson(),
    fromJson: SubscriptionEntry.fromJson,
  );
  late TabController _tabController;
  SubscriptionCategory? _filterCategory;
  SubscriptionStatus? _filterStatus;
  String _searchQuery = '';
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await _persistence.load();
    if (saved.isNotEmpty) {
      for (final entry in saved) {
        _service.add(entry);
      }
      _nextId = saved.length + 1;
      if (mounted) setState(() {});
    } else {
      _loadSampleData();
      _persistAll();
    }
  }

  Future<void> _persistAll() async {
    await _persistence.save(_service.subscriptions.toList());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    final samples = [
      SubscriptionEntry(
        id: 's1', name: 'Netflix', amount: 15.49,
        cycle: BillingCycle.monthly, category: SubscriptionCategory.streaming,
        startDate: now.subtract(const Duration(days: 365)),
        nextBillingDate: now.add(const Duration(days: 5)),
        tags: ['entertainment', 'family'],
      ),
      SubscriptionEntry(
        id: 's2', name: 'Spotify', amount: 10.99,
        cycle: BillingCycle.monthly, category: SubscriptionCategory.music,
        startDate: now.subtract(const Duration(days: 730)),
        nextBillingDate: now.add(const Duration(days: 12)),
        tags: ['music'],
      ),
      SubscriptionEntry(
        id: 's3', name: 'GitHub Copilot', amount: 100.00,
        cycle: BillingCycle.annual, category: SubscriptionCategory.software,
        startDate: now.subtract(const Duration(days: 200)),
        nextBillingDate: now.add(const Duration(days: 165)),
        tags: ['dev', 'tools'],
      ),
      SubscriptionEntry(
        id: 's4', name: 'iCloud+', amount: 2.99,
        cycle: BillingCycle.monthly, category: SubscriptionCategory.cloud,
        startDate: now.subtract(const Duration(days: 500)),
        nextBillingDate: now.add(const Duration(days: 3)),
        tags: ['storage'],
      ),
      SubscriptionEntry(
        id: 's5', name: 'Gym Membership', amount: 49.99,
        cycle: BillingCycle.monthly, category: SubscriptionCategory.fitness,
        status: SubscriptionStatus.paused,
        startDate: now.subtract(const Duration(days: 180)),
        nextBillingDate: now.add(const Duration(days: 20)),
        tags: ['health'],
      ),
      SubscriptionEntry(
        id: 's6', name: 'Notion', amount: 8.00,
        cycle: BillingCycle.monthly, category: SubscriptionCategory.productivity,
        status: SubscriptionStatus.trial,
        startDate: now.subtract(const Duration(days: 7)),
        nextBillingDate: now.add(const Duration(days: 7)),
        trialEndDate: now.add(const Duration(days: 7)),
        tags: ['productivity'],
      ),
    ];
    _nextId = 7;
    for (final s in samples) {
      _service.add(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Active'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Optimize'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubscriptionList(),
          _buildCalendarTab(),
          _buildInsightsTab(),
          _buildOptimizeTab(),
        ],
      ),
    );
  }

  // ─── Tab 1: Subscription List ─────────────────────────────────────

  Widget _buildSubscriptionList() {
    var subs = List<SubscriptionEntry>.from(_service.subscriptions);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      subs = subs.where((s) => s.name.toLowerCase().contains(q)).toList();
    }
    if (_filterCategory != null) {
      subs = subs.where((s) => s.category == _filterCategory).toList();
    }
    if (_filterStatus != null) {
      subs = subs.where((s) => s.status == _filterStatus).toList();
    }

    return Column(
      children: [
        // Summary strip
        _buildSummaryStrip(),
        // Search & filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search subscriptions...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<SubscriptionCategory?>(
                icon: Badge(
                  isLabelVisible: _filterCategory != null,
                  child: const Icon(Icons.category),
                ),
                tooltip: 'Filter by category',
                onSelected: (v) => setState(() => _filterCategory = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All categories')),
                  ...SubscriptionCategory.values.map((c) =>
                      PopupMenuItem(value: c, child: Text(c.label))),
                ],
              ),
              PopupMenuButton<SubscriptionStatus?>(
                icon: Badge(
                  isLabelVisible: _filterStatus != null,
                  child: const Icon(Icons.filter_alt),
                ),
                tooltip: 'Filter by status',
                onSelected: (v) => setState(() => _filterStatus = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All statuses')),
                  ...SubscriptionStatus.values.map((s) =>
                      PopupMenuItem(value: s, child: Text(s.label))),
                ],
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: subs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.subscriptions_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _service.subscriptions.isEmpty
                            ? 'No subscriptions yet'
                            : 'No matches',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: subs.length,
                  itemBuilder: (ctx, i) => _buildSubscriptionCard(subs[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip() {
    final summary = _service.getSummary();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Monthly', '\$${summary.monthlySpend.toStringAsFixed(2)}',
              Icons.calendar_today),
          _summaryItem('Annual', '\$${summary.annualSpend.toStringAsFixed(2)}',
              Icons.date_range),
          _summaryItem('Active', '${summary.totalActive}', Icons.check_circle),
          _summaryItem('Paused', '${summary.totalPaused}', Icons.pause_circle),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildSubscriptionCard(SubscriptionEntry sub) {
    final statusColor = switch (sub.status) {
      SubscriptionStatus.active => Colors.green,
      SubscriptionStatus.paused => Colors.orange,
      SubscriptionStatus.cancelled => Colors.red,
      SubscriptionStatus.trial => Colors.blue,
      SubscriptionStatus.expired => Colors.grey,
    };

    final categoryIcon = switch (sub.category) {
      SubscriptionCategory.streaming => Icons.movie,
      SubscriptionCategory.music => Icons.music_note,
      SubscriptionCategory.gaming => Icons.sports_esports,
      SubscriptionCategory.software => Icons.code,
      SubscriptionCategory.cloud => Icons.cloud,
      SubscriptionCategory.news => Icons.newspaper,
      SubscriptionCategory.fitness => Icons.fitness_center,
      SubscriptionCategory.food => Icons.restaurant,
      SubscriptionCategory.education => Icons.school,
      SubscriptionCategory.finance => Icons.account_balance,
      SubscriptionCategory.productivity => Icons.task_alt,
      SubscriptionCategory.social => Icons.people,
      SubscriptionCategory.other => Icons.more_horiz,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(categoryIcon, color: statusColor),
        ),
        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '\$${sub.amount.toStringAsFixed(2)} / ${sub.cycle.label.toLowerCase()}'
          '  •  ${sub.status.label}'
          '${sub.daysUntilNextBilling >= 0 ? "  •  ${sub.daysUntilNextBilling}d" : ""}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(action, sub),
          itemBuilder: (_) => [
            if (sub.status == SubscriptionStatus.active)
              const PopupMenuItem(value: 'pause', child: Text('Pause')),
            if (sub.status == SubscriptionStatus.paused)
              const PopupMenuItem(value: 'resume', child: Text('Resume')),
            if (sub.status != SubscriptionStatus.cancelled)
              const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showDetailSheet(sub),
      ),
    );
  }

  void _handleAction(String action, SubscriptionEntry sub) {
    setState(() {
      switch (action) {
        case 'pause':
          _service.pause(sub.id);
        case 'resume':
          _service.resume(sub.id);
        case 'cancel':
          _service.cancel(sub.id);
        case 'delete':
          _service.remove(sub.id);
        case 'edit':
          _showEditDialog(sub);
      }
    });
    if (action != 'edit') {
      _persistAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sub.name}: $action'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDetailSheet(SubscriptionEntry sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(sub.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _detailRow('Amount',
                '\$${sub.amount.toStringAsFixed(2)} / ${sub.cycle.label}'),
            _detailRow('Monthly cost',
                '\$${sub.monthlyCost.toStringAsFixed(2)}'),
            _detailRow('Annual cost',
                '\$${sub.annualCost.toStringAsFixed(2)}'),
            _detailRow('Category', sub.category.label),
            _detailRow('Status', sub.status.label),
            _detailRow('Start date',
                '${sub.startDate.month}/${sub.startDate.day}/${sub.startDate.year}'),
            _detailRow('Next billing',
                '${sub.nextBillingDate.month}/${sub.nextBillingDate.day}/${sub.nextBillingDate.year}'
                ' (${sub.daysUntilNextBilling} days)'),
            _detailRow('Auto-renew', sub.autoRenew ? 'Yes' : 'No'),
            _detailRow('Total spent',
                '\$${sub.totalSpent.toStringAsFixed(2)}'),
            if (sub.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: sub.tags
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            if (sub.priceHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Price History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...sub.priceHistory.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${p.date.month}/${p.date.day}/${p.date.year}: '
                      '\$${p.oldPrice.toStringAsFixed(2)} → \$${p.newPrice.toStringAsFixed(2)}'
                      ' (${p.changePercent >= 0 ? '+' : ''}${p.changePercent.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 13,
                        color: p.changeAmount > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  )),
            ],
            if (sub.notes != null && sub.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Notes: ${sub.notes}',
                  style: TextStyle(color: Colors.grey.shade700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Tab 2: Renewal Calendar ──────────────────────────────────────

  Widget _buildCalendarTab() {
    final calendar = _service.getRenewalCalendar(days: 60);
    final expiringTrials = _service.getExpiringTrials(withinDays: 14);

    if (calendar.isEmpty && expiringTrials.isEmpty) {
      return const Center(child: Text('No upcoming renewals'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (expiringTrials.isNotEmpty) ...[
          _sectionHeader('⚠️ Expiring Trials', Colors.orange),
          ...expiringTrials.map((alert) => Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.orange),
                  title: Text(alert.subscription.name),
                  subtitle: Text(alert.message),
                  trailing: Text(
                    '${alert.daysUntil}d',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],
        _sectionHeader('📅 Renewal Calendar (60 days)', null),
        ...calendar.map((entry) {
          final dateStr =
              '${_weekday(entry.date.weekday)}, ${entry.date.month}/${entry.date.day}';
          final daysAway = entry.date
              .difference(DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day))
              .inDays;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateStr,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: daysAway <= 3
                              ? Colors.red.shade100
                              : daysAway <= 7
                                  ? Colors.orange.shade100
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          daysAway == 0
                              ? 'Today'
                              : daysAway == 1
                                  ? 'Tomorrow'
                                  : 'In $daysAway days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: daysAway <= 3 ? Colors.red : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...entry.subscriptions.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6),
                            const SizedBox(width: 8),
                            Expanded(child: Text(s.name)),
                            Text('\$${s.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )),
                  if (entry.subscriptions.length > 1) ...[
                    const Divider(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: \$${entry.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Tab 3: Insights ──────────────────────────────────────────────

  Widget _buildInsightsTab() {
    final summary = _service.getSummary();
    final duplicates = _service.detectPotentialDuplicates();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cost breakdown
        _sectionHeader('💰 Cost Breakdown', null),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _insightRow('Daily spend',
                    '\$${summary.dailySpend.toStringAsFixed(2)}'),
                _insightRow('Monthly spend',
                    '\$${summary.monthlySpend.toStringAsFixed(2)}'),
                _insightRow('Annual spend',
                    '\$${summary.annualSpend.toStringAsFixed(2)}'),
                _insightRow('Avg per subscription',
                    '\$${summary.averagePerSubscription.toStringAsFixed(2)}/mo'),
                _insightRow('Lifetime spent',
                    '\$${summary.totalLifetimeSpent.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Category breakdown
        _sectionHeader('📊 By Category', null),
        ...summary.categoryBreakdown.map((cat) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                title: Text(cat.category.label),
                subtitle: LinearProgressIndicator(
                  value: cat.percentOfTotal / 100,
                  backgroundColor: Colors.grey.shade200,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${cat.monthlyTotal.toStringAsFixed(2)}/mo',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${cat.percentOfTotal.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )),

        if (summary.mostExpensive != null) ...[
          const SizedBox(height: 16),
          _sectionHeader('🏆 Extremes', null),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _insightRow('Most expensive',
                      '${summary.mostExpensive!.name} (\$${summary.mostExpensive!.monthlyCost.toStringAsFixed(2)}/mo)'),
                  if (summary.cheapest != null)
                    _insightRow('Cheapest',
                        '${summary.cheapest!.name} (\$${summary.cheapest!.monthlyCost.toStringAsFixed(2)}/mo)'),
                ],
              ),
            ),
          ),
        ],

        if (summary.totalPriceIncreases > 0) ...[
          const SizedBox(height: 16),
          _sectionHeader('📈 Price Increases', null),
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _insightRow('Total increases', '${summary.totalPriceIncreases}'),
                  _insightRow('Total increase amount',
                      '+\$${summary.totalPriceIncreaseAmount.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],

        if (duplicates.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionHeader('⚠️ Potential Duplicates', Colors.orange),
          ...duplicates.map((group) => Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading:
                      const Icon(Icons.content_copy, color: Colors.orange),
                  title: Text(group.map((s) => s.name).join(' & ')),
                  subtitle: Text(
                    'Same category (${group.first.category.label}), '
                    'similar cost — consider consolidating',
                  ),
                ),
              )),
        ],
      ],
    );
  }

  // ─── Tab 4: Optimize ──────────────────────────────────────────────

  Widget _buildOptimizeTab() {
    final suggestions = _service.getOptimizationSuggestions();

    if (suggestions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Your subscriptions look optimized!',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('💡 Optimization Suggestions', null),
        const SizedBox(height: 8),
        ...suggestions.asMap().entries.map((e) {
          final icon = e.value.contains('overlap')
              ? Icons.copy_all
              : e.value.contains('trial')
                  ? Icons.timer
                  : e.value.contains('annual')
                      ? Icons.savings
                      : e.value.contains('costs')
                          ? Icons.attach_money
                          : Icons.lightbulb_outline;
          final color = e.value.contains('trial')
              ? Colors.blue
              : e.value.contains('overlap')
                  ? Colors.orange
                  : Colors.amber.shade700;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(e.value, style: const TextStyle(fontSize: 14)),
            ),
          );
        }),
      ],
    );
  }

  // ─── Add / Edit Dialogs ───────────────────────────────────────────

  void _showAddDialog() {
    _showSubscriptionForm(null);
  }

  void _showEditDialog(SubscriptionEntry existing) {
    _showSubscriptionForm(existing);
  }

  void _showSubscriptionForm(SubscriptionEntry? existing) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(2) : '');
    final notesController =
        TextEditingController(text: existing?.notes ?? '');
    var cycle = existing?.cycle ?? BillingCycle.monthly;
    var category = existing?.category ?? SubscriptionCategory.other;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Subscription' : 'Add Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Name', hintText: 'e.g. Netflix'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Amount', prefixText: '\$ '),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BillingCycle>(
                  value: cycle,
                  decoration:
                      const InputDecoration(labelText: 'Billing cycle'),
                  items: BillingCycle.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => cycle = v ?? cycle),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SubscriptionCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: SubscriptionCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim());
                if (name.isEmpty || amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid name and amount'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final now = DateTime.now();
                final notes = notesController.text.trim();
                setState(() {
                  if (existing != null) {
                    _service.update(
                      existing.id,
                      existing.copyWith(
                        name: name,
                        amount: amount,
                        cycle: cycle,
                        category: category,
                        notes: notes.isNotEmpty ? notes : null,
                      ),
                    );
                  } else {
                    _service.add(SubscriptionEntry(
                      id: 's${_nextId++}',
                      name: name,
                      amount: amount,
                      cycle: cycle,
                      category: category,
                      startDate: now,
                      nextBillingDate:
                          now.add(Duration(days: cycle.daysBetween)),
                      notes: notes.isNotEmpty ? notes : null,
                    ));
                  }
                });
                _persistAll();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existing != null
                        ? '$name updated'
                        : '$name added'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(existing != null ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Widget _sectionHeader(String title, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _insightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _weekday(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }
}
