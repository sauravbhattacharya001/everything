import 'package:flutter/material.dart';
import '../../core/services/net_worth_tracker_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/net_worth_account.dart';

/// Net Worth Tracker - manage accounts, record balances, view reports,
/// and track milestones. 4-tab UI: Accounts / Add / Report / Milestones.
class NetWorthTrackerScreen extends StatefulWidget {
  const NetWorthTrackerScreen({super.key});

  @override
  State<NetWorthTrackerScreen> createState() => _NetWorthTrackerScreenState();
}

class _NetWorthTrackerScreenState extends State<NetWorthTrackerScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'net_worth_tracker_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  final NetWorthTrackerService _service = NetWorthTrackerService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    initPersistence();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Accounts'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
            Tab(icon: Icon(Icons.assessment), text: 'Report'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Milestones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AccountsTab(
            service: _service,
            onChanged: () => setState(() {}),
          ),
          _AddAccountTab(
            service: _service,
            onAdded: () {
              setState(() {});
              _tabController.animateTo(0);
            },
          ),
          _ReportTab(service: _service),
          _MilestonesTab(service: _service),
        ],
      ),
    );
  }
}

// ─── ACCOUNTS TAB ───────────────────────────────────────────────────────────

class _AccountsTab extends StatelessWidget {
  final NetWorthTrackerService service;
  final VoidCallback onChanged;

  const _AccountsTab({required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Net Worth Summary Card ──
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('Net Worth',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(service.netWorth),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: service.netWorth >= 0
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryChip(
                      label: 'Assets',
                      value: _formatCurrency(service.totalAssets),
                      color: Colors.green,
                      icon: Icons.trending_up,
                    ),
                    _SummaryChip(
                      label: 'Liabilities',
                      value: _formatCurrency(service.totalLiabilities),
                      color: Colors.red,
                      icon: Icons.trending_down,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Assets Section ──
        if (service.assets.isNotEmpty) ...[
          _SectionHeader(
            title: 'Assets',
            count: service.assets.length,
            color: Colors.green,
          ),
          ...service.assets.map((a) => _AccountTile(
                account: a,
                service: service,
                onChanged: onChanged,
              )),
          const SizedBox(height: 16),
        ],

        // ── Liabilities Section ──
        if (service.liabilities.isNotEmpty) ...[
          _SectionHeader(
            title: 'Liabilities',
            count: service.liabilities.length,
            color: Colors.red,
          ),
          ...service.liabilities.map((a) => _AccountTile(
                account: a,
                service: service,
                onChanged: onChanged,
              )),
        ],

        // ── Empty State ──
        if (service.activeAccounts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No accounts yet',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Add your first account to start tracking',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[500])),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── ACCOUNT TILE ───────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final NetWorthAccount account;
  final NetWorthTrackerService service;
  final VoidCallback onChanged;

  const _AccountTile({
    required this.account,
    required this.service,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final change = account.lastChange;
    final changeColor =
        (change != null && change >= 0) ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: account.type == AccountType.asset
              ? Colors.green[50]
              : Colors.red[50],
          child: Text(account.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(account.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${account.category.label}'
          '${account.institution != null ? ' · ${account.institution}' : ''}'
          '${account.isStale ? ' · ⚠️ Stale' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(account.currentBalance),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (change != null)
              Text(
                '${change >= 0 ? '+' : ''}${_formatCurrency(change)}',
                style: TextStyle(fontSize: 11, color: changeColor),
              ),
          ],
        ),
        onTap: () => _showUpdateBalanceDialog(context),
        onLongPress: () => _showAccountActions(context),
      ),
    );
  }

  void _showUpdateBalanceDialog(BuildContext context) {
    final controller = TextEditingController(
        text: account.currentBalance.toStringAsFixed(2));
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${account.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'New Balance',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final balance = double.tryParse(controller.text);
              if (balance != null && balance >= 0) {
                service.recordBalance(
                  account.id,
                  balance,
                  note: noteController.text.isNotEmpty
                      ? noteController.text
                      : null,
                );
                onChanged();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAccountActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Update Balance'),
              onTap: () {
                Navigator.pop(ctx);
                _showUpdateBalanceDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive Account'),
              onTap: () {
                service.archiveAccount(account.id);
                onChanged();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Balance History'),
              onTap: () {
                Navigator.pop(ctx);
                _showBalanceHistory(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBalanceHistory(BuildContext context) {
    final snapshots = List<BalanceSnapshot>.from(account.snapshots)
      ..sort((a, b) => b.date.compareTo(a.date));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${account.emoji} ${account.name} History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: snapshots.isEmpty
              ? const Center(child: Text('No snapshots recorded'))
              : ListView.builder(
                  itemCount: snapshots.length,
                  itemBuilder: (_, i) {
                    final s = snapshots[i];
                    return ListTile(
                      dense: true,
                      title: Text(_formatCurrency(s.balance),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${_formatDate(s.date)}'
                        '${s.note != null ? ' - ${s.note}' : ''}',
                      ),
                      leading: Icon(
                        i < snapshots.length - 1
                            ? (s.balance >= snapshots[i + 1].balance
                                ? Icons.arrow_upward
                                : Icons.arrow_downward)
                            : Icons.circle,
                        size: 16,
                        color: i < snapshots.length - 1
                            ? (s.balance >= snapshots[i + 1].balance
                                ? Colors.green
                                : Colors.red)
                            : Colors.grey,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

// ─── ADD ACCOUNT TAB ────────────────────────────────────────────────────────

class _AddAccountTab extends StatefulWidget {
  final NetWorthTrackerService service;
  final VoidCallback onAdded;

  const _AddAccountTab({required this.service, required this.onAdded});

  @override
  State<_AddAccountTab> createState() => _AddAccountTabState();
}

class _AddAccountTabState extends State<_AddAccountTab> {
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _balanceController = TextEditingController();
  final _notesController = TextEditingController();
  AccountCategory _category = AccountCategory.checking;
  AccountType _type = AccountType.asset;

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Add Account',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),

        // Account Name
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Account Name *',
            hintText: 'e.g. Chase Checking',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
        ),
        const SizedBox(height: 12),

        // Type Toggle
        SegmentedButton<AccountType>(
          segments: const [
            ButtonSegment(
              value: AccountType.asset,
              label: Text('Asset'),
              icon: Icon(Icons.trending_up),
            ),
            ButtonSegment(
              value: AccountType.liability,
              label: Text('Liability'),
              icon: Icon(Icons.trending_down),
            ),
          ],
          selected: {_type},
          onSelectionChanged: (v) => setState(() => _type = v.first),
        ),
        const SizedBox(height: 12),

        // Category Dropdown
        DropdownButtonFormField<AccountCategory>(
          value: _category,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: AccountCategory.values
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.defaultEmoji} ${c.label}'),
                  ))
              .toList(),
          onChanged: (c) {
            if (c != null) {
              setState(() {
                _category = c;
                _type = c.defaultType;
              });
            }
          },
        ),
        const SizedBox(height: 12),

        // Institution
        TextField(
          controller: _institutionController,
          decoration: const InputDecoration(
            labelText: 'Institution (optional)',
            hintText: 'e.g. Chase, Vanguard, Coinbase',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 12),

        // Initial Balance
        TextField(
          controller: _balanceController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Current Balance',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 12),

        // Notes
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.notes),
          ),
        ),
        const SizedBox(height: 24),

        // Submit
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Add Account'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an account name')),
      );
      return;
    }

    final balance = double.tryParse(_balanceController.text);

    widget.service.addAccount(
      name: name,
      type: _type,
      category: _category,
      institution: _institutionController.text.trim().isNotEmpty
          ? _institutionController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      initialBalance: balance,
    );

    // Reset form
    _nameController.clear();
    _institutionController.clear();
    _balanceController.clear();
    _notesController.clear();
    setState(() {
      _category = AccountCategory.checking;
      _type = AccountType.asset;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name added!')),
    );
    widget.onAdded();
  }
}

// ─── REPORT TAB ─────────────────────────────────────────────────────────────

class _ReportTab extends StatelessWidget {
  final NetWorthTrackerService service;

  const _ReportTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final report = service.generateReport();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Overview Card ──
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Overview',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(),
                _ReportRow(
                    label: 'Total Assets',
                    value: _formatCurrency(report.totalAssets),
                    color: Colors.green),
                _ReportRow(
                    label: 'Total Liabilities',
                    value: _formatCurrency(report.totalLiabilities),
                    color: Colors.red),
                const Divider(),
                _ReportRow(
                    label: 'Net Worth',
                    value: _formatCurrency(report.netWorth),
                    color: report.netWorth >= 0 ? Colors.green : Colors.red,
                    bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Changes Card ──
        if (report.monthOverMonthChange != null ||
            report.yearOverYearChange != null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Changes',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (report.monthOverMonthChange != null)
                    _ReportRow(
                      label: 'Month over Month',
                      value:
                          '${report.monthOverMonthChange! >= 0 ? '+' : ''}${_formatCurrency(report.monthOverMonthChange!)}'
                          '${report.monthOverMonthPercent != null ? ' (${(report.monthOverMonthPercent! * 100).toStringAsFixed(1)}%)' : ''}',
                      color: report.monthOverMonthChange! >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  if (report.yearOverYearChange != null)
                    _ReportRow(
                      label: 'Year over Year',
                      value:
                          '${report.yearOverYearChange! >= 0 ? '+' : ''}${_formatCurrency(report.yearOverYearChange!)}',
                      color: report.yearOverYearChange! >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // ── Debt Analysis ──
        if (service.totalDebt > 0)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Debt Analysis',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(),
                  _ReportRow(
                      label: 'Total Debt',
                      value: _formatCurrency(service.totalDebt),
                      color: Colors.red),
                  if (service.debtToAssetRatio != null)
                    _ReportRow(
                      label: 'Debt-to-Asset Ratio',
                      value:
                          '${(service.debtToAssetRatio! * 100).toStringAsFixed(1)}%',
                      color: service.debtToAssetRatio! > 0.5
                          ? Colors.red
                          : Colors.green,
                    ),
                  if (service.monthsToDebtFree != null)
                    _ReportRow(
                      label: 'Est. Debt Free In',
                      value: '${service.monthsToDebtFree} months',
                      color: Colors.blue,
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // ── Asset Breakdown ──
        if (report.assetBreakdown.isNotEmpty)
          _BreakdownCard(
            title: 'Asset Breakdown',
            breakdowns: report.assetBreakdown,
            color: Colors.green,
          ),
        const SizedBox(height: 12),

        // ── Liability Breakdown ──
        if (report.liabilityBreakdown.isNotEmpty)
          _BreakdownCard(
            title: 'Liability Breakdown',
            breakdowns: report.liabilityBreakdown,
            color: Colors.red,
          ),
        const SizedBox(height: 12),

        // ── Monthly History ──
        if (report.history.isNotEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly History',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...report.history.reversed.take(12).map((m) => _ReportRow(
                        label: m.label,
                        value: _formatCurrency(m.netWorth),
                        color: m.netWorth >= 0 ? Colors.green : Colors.red,
                      )),
                ],
              ),
            ),
          ),

        // ── Stale Accounts Warning ──
        if (report.staleAccounts > 0) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.orange[50],
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${report.staleAccounts} account(s) haven\'t been updated in 30+ days',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── MILESTONES TAB ─────────────────────────────────────────────────────────

class _MilestonesTab extends StatelessWidget {
  final NetWorthTrackerService service;

  const _MilestonesTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final milestones = service.milestones;
    final next = service.nextMilestone;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Progress toward next milestone ──
        if (next != null)
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events,
                      size: 48, color: Colors.amber),
                  const SizedBox(height: 8),
                  Text('Next: ${next.label}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCurrency(next.target - service.netWorth)} to go',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: service.milestoneProgress,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(service.milestoneProgress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        Text('All Milestones',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // ── Milestone List ──
        ...milestones.map((m) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: m.reached ? Colors.green[50] : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      m.reached ? Colors.green : Colors.grey[300],
                  child: Icon(
                    m.reached ? Icons.check : Icons.lock_outline,
                    color: m.reached ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                title: Text(
                  m.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: m.reached ? Colors.green[800] : null,
                    decoration:
                        m.reached ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  m.reached
                      ? (m.reachedDate != null
                          ? 'Reached ${_formatDate(m.reachedDate!)}'
                          : 'Achieved! 🎉')
                      : 'Target: ${_formatCurrency(m.target)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: m.reached
                    ? const Text('🏆', style: TextStyle(fontSize: 24))
                    : Text(
                        _formatCurrency(m.target),
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 13),
                      ),
              ),
            )),
      ],
    );
  }
}

// ─── SHARED WIDGETS ─────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _ReportRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final List<CategoryBreakdown> breakdowns;
  final Color color;

  const _BreakdownCard({
    required this.title,
    required this.breakdowns,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            ...breakdowns.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${b.category.defaultEmoji} ${b.category.label} (${b.accountCount})'),
                          Text(_formatCurrency(b.total),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, color: color)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: b.percentOfType,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              AlwaysStoppedAnimation(color.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── HELPERS ────────────────────────────────────────────────────────────────

String _formatCurrency(double amount) {
  final negative = amount < 0;
  final abs = amount.abs();
  if (abs >= 1000000) {
    return '${negative ? '-' : ''}\$${(abs / 1000000).toStringAsFixed(1)}M';
  } else if (abs >= 1000) {
    return '${negative ? '-' : ''}\$${(abs / 1000).toStringAsFixed(1)}K';
  }
  return '${negative ? '-' : ''}\$${abs.toStringAsFixed(2)}';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
