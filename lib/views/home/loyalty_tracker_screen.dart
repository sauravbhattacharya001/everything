import 'package:flutter/material.dart';
import '../../models/loyalty_card.dart';
import '../../core/services/loyalty_tracker_service.dart';
import '../../core/services/persistent_state_mixin.dart';

/// Loyalty Card / Rewards Tracker Screen.
///
/// 4-tab UI:
///   - Cards: all loyalty programs with balance & value
///   - Alerts: expiring points warnings
///   - Analytics: portfolio summary, type breakdown, trends
///   - Search: filter by name, type, or tag
class LoyaltyTrackerScreen extends StatefulWidget {
  const LoyaltyTrackerScreen({super.key});

  @override
  State<LoyaltyTrackerScreen> createState() => _LoyaltyTrackerScreenState();
}

class _LoyaltyTrackerScreenState extends State<LoyaltyTrackerScreen>
    with TickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'loyalty_tracker_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  final LoyaltyTrackerService _service = LoyaltyTrackerService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<LoyaltyCard> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    initPersistence();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty & Rewards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.credit_card), text: 'Cards'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCardsTab(),
          _buildAlertsTab(),
          _buildAnalyticsTab(),
          _buildSearchTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCardsTab() {
    final cards = _service.sortedByValue();
    if (cards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.loyalty, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No loyalty cards yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap + to add your first rewards program.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(card.type.emoji, style: const TextStyle(fontSize: 20)),
            ),
            title: Text(card.programName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${card.currentBalance.toStringAsFixed(0)} ${card.unit.label}'
                ' • \$${card.dollarValue.toStringAsFixed(2)} value'
                '${card.tier != TierLevel.none ? " • ${card.tier.label}" : ""}'),
            trailing: card.isExpiringWithin(30)
                ? const Icon(Icons.warning, color: Colors.orange)
                : null,
            onTap: () => _showCardDetail(card),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    final alerts = _service.getExpiryAlerts(days: 90);
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No expiring points!',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final urgency = alert.daysUntil <= 7
            ? Colors.red
            : alert.daysUntil <= 30 ? Colors.orange : Colors.yellow.shade700;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.timer, color: urgency),
            title: Text(alert.card.programName),
            subtitle: Text(alert.message),
            trailing: Text('${alert.daysUntil}d',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: urgency, fontSize: 16)),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    final summary = _service.getSummary();
    final underUtilized = _service.getUnderUtilized();
    final topCategories = _service.getTopEarningCategories();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Portfolio Overview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _statRow('Total Programs', '${summary.totalPrograms}'),
                  _statRow('Total Value',
                      '\$${summary.totalDollarValue.toStringAsFixed(2)}'),
                  _statRow('Lifetime Earned',
                      '${summary.lifetimeEarned.toStringAsFixed(0)} pts'),
                  _statRow('Avg Redemption',
                      '${(summary.averageRedemptionRate * 100).toStringAsFixed(1)}%'),
                  if (summary.expiringWithin30Days > 0) ...[
                    const Divider(),
                    _statRow('⚠️ Expiring (30d)',
                        '${summary.expiringWithin30Days} cards '
                        '(\$${summary.expiringValue.toStringAsFixed(2)})'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (summary.typeBreakdown.isNotEmpty) ...[
            const Text('By Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...summary.typeBreakdown.map((tb) => Card(
              child: ListTile(
                leading: Text(tb.type.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(tb.type.label),
                subtitle: Text(
                    '${tb.count} programs • \$${tb.totalValue.toStringAsFixed(2)}'),
                trailing: Text('${tb.percentOfValue.toStringAsFixed(1)}%'),
              ),
            )),
          ],
          if (underUtilized.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('💡 Under-utilized',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...underUtilized.map((c) => Card(
              child: ListTile(
                leading: Text(c.type.emoji),
                title: Text(c.programName),
                subtitle: Text(
                    '${c.currentBalance.toStringAsFixed(0)} ${c.unit.label} '
                    '(\$${c.dollarValue.toStringAsFixed(2)}) unused'),
              ),
            )),
          ],
          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Top Earning Categories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...topCategories.take(5).map((cat) => ListTile(
              dense: true,
              title: Text(cat.category),
              trailing: Text('${cat.totalEarned.toStringAsFixed(0)} pts '
                  '(${cat.percentOfTotal.toStringAsFixed(1)}%)'),
            )),
          ],
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search programs...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      })
                  : null,
            ),
            onChanged: (q) =>
                setState(() => _searchResults = _service.search(q)),
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty && _searchController.text.isEmpty
              ? const Center(child: Text('Type to search your loyalty programs',
                  style: TextStyle(color: Colors.grey)))
              : _searchResults.isEmpty
                  ? const Center(child: Text('No results found'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) {
                        final c = _searchResults[i];
                        return ListTile(
                          leading: Text(c.type.emoji,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(c.programName),
                          subtitle: Text(
                              '${c.currentBalance.toStringAsFixed(0)} ${c.unit.label}'),
                          onTap: () => _showCardDetail(c),
                        );
                      }),
        ),
      ],
    );
  }

  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        var type = RewardsProgramType.other;
        var unit = PointsUnit.points;
        double balance = 0, pointValue = 0.01;

        return AlertDialog(
          title: const Text('Add Loyalty Card'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Program Name *'),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<RewardsProgramType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: RewardsProgramType.values.map((t) =>
                    DropdownMenuItem(value: t,
                        child: Text('${t.emoji} ${t.label}'))).toList(),
                onChanged: (v) => type = v ?? type,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<PointsUnit>(
                value: unit,
                decoration: const InputDecoration(labelText: 'Points Unit'),
                items: PointsUnit.values.map((u) =>
                    DropdownMenuItem(value: u, child: Text(u.label))).toList(),
                onChanged: (v) => unit = v ?? unit,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                    labelText: 'Current Balance', hintText: '0'),
                keyboardType: TextInputType.number,
                onChanged: (v) => balance = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                    labelText: 'Point Value (\$)', hintText: '0.01'),
                keyboardType: TextInputType.number,
                onChanged: (v) => pointValue = double.tryParse(v) ?? 0.01,
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (name.trim().isEmpty) return;
                setState(() {
                  _service.add(LoyaltyCard(
                    id: 'lc_${DateTime.now().millisecondsSinceEpoch}',
                    programName: name.trim(), type: type, unit: unit,
                    currentBalance: balance, lifetimeEarned: balance,
                    pointValue: pointValue, enrollDate: DateTime.now(),
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showCardDetail(LoyaltyCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3,
        expand: false,
        builder: (context, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Text(card.type.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.programName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (card.tier != TierLevel.none)
                      Text('${card.tier.label} Member',
                          style: const TextStyle(color: Colors.grey)),
                  ],
                )),
              ]),
              const Divider(height: 24),
              _statRow('Balance',
                  '${card.currentBalance.toStringAsFixed(0)} ${card.unit.label}'),
              _statRow('Dollar Value', '\$${card.dollarValue.toStringAsFixed(2)}'),
              _statRow('Lifetime Earned',
                  '${card.lifetimeEarned.toStringAsFixed(0)} ${card.unit.label}'),
              _statRow('Redemption Rate',
                  '${(card.redemptionRate * 100).toStringAsFixed(1)}%'),
              _statRow('Point Value', '\$${card.pointValue.toStringAsFixed(3)}'),
              if (card.pointsExpiryDate != null)
                _statRow('Points Expire',
                    card.daysUntilExpiry >= 0
                        ? 'in ${card.daysUntilExpiry} days' : 'expired'),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton.icon(icon: const Icon(Icons.add),
                    label: const Text('Earn'),
                    onPressed: () => _showTxDialog(card, true)),
                ElevatedButton.icon(icon: const Icon(Icons.remove),
                    label: const Text('Redeem'),
                    onPressed: () => _showTxDialog(card, false)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _service.remove(card.id));
                      Navigator.pop(context);
                    }),
              ]),
              if (card.transactions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Recent Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...card.transactions.reversed.take(10).map((tx) => ListTile(
                  dense: true,
                  leading: Icon(tx.isEarn ? Icons.arrow_downward : Icons.arrow_upward,
                      color: tx.isEarn ? Colors.green : Colors.red, size: 20),
                  title: Text(tx.description),
                  trailing: Text(
                      '${tx.isEarn ? "+" : "-"}${tx.amount.toStringAsFixed(0)}',
                      style: TextStyle(color: tx.isEarn ? Colors.green : Colors.red)),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTxDialog(LoyaltyCard card, bool isEarn) {
    double amount = 0;
    String desc = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${isEarn ? "Earn" : "Redeem"} ${card.unit.label}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            decoration: InputDecoration(
                labelText: isEarn ? 'Amount' : 'Amount (max: ${card.currentBalance.toStringAsFixed(0)})'),
            keyboardType: TextInputType.number,
            onChanged: (v) => amount = double.tryParse(v) ?? 0,
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (v) => desc = v,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (amount <= 0) return;
              if (!isEarn && amount > card.currentBalance) return;
              setState(() {
                if (isEarn) {
                  _service.earnPoints(card.id, amount, desc);
                } else {
                  _service.redeemPoints(card.id, amount, desc);
                }
              });
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(isEarn ? 'Earn' : 'Redeem'),
          ),
        ],
      ),
    );
  }
}
