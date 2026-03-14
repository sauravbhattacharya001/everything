import 'package:flutter/material.dart';
import '../../core/services/debt_payoff_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/debt_entry.dart';

/// Debt Payoff Planner — track debts, compare snowball vs avalanche,
/// see payoff timeline and interest savings.
class DebtPayoffScreen extends StatefulWidget {
  const DebtPayoffScreen({super.key});

  @override
  State<DebtPayoffScreen> createState() => _DebtPayoffScreenState();
}

class _DebtPayoffScreenState extends State<DebtPayoffScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'debt_payoff_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  final DebtPayoffService _service = DebtPayoffService();
  late TabController _tabController;
  double _extraPayment = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('💸 Debt Payoff Planner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Debts'),
            Tab(icon: Icon(Icons.compare_arrows), text: 'Compare'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDebtsTab(),
          _buildCompareTab(),
          _buildTimelineTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDebtDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Debts Tab ─────────────────────────────────────────────────

  Widget _buildDebtsTab() {
    final active = _service.activeDebts;
    final paidOff = _service.paidOffDebts;

    if (active.isEmpty && paidOff.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.money_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No debts tracked yet',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap + to add a debt',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Total Debt',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '\$${_service.totalDebt.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statChip('${active.length} active', Icons.trending_down),
                    _statChip(
                        '${_service.weightedAverageRate.toStringAsFixed(1)}% avg rate',
                        Icons.percent),
                    _statChip(
                        '\$${_service.totalMinimumPayments.toStringAsFixed(0)}/mo min',
                        Icons.payment),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...active.map((d) => _debtCard(d)),
        if (paidOff.isNotEmpty) ...[
          const Divider(),
          Text('Paid Off 🎉',
              style: Theme.of(context).textTheme.titleMedium),
          ...paidOff.map((d) => _debtCard(d, isPaidOff: true)),
        ],
      ],
    );
  }

  Widget _statChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _debtCard(DebtEntry debt, {bool isPaidOff = false}) {
    return Card(
      child: ListTile(
        leading: Text(debt.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(debt.name,
            style: TextStyle(
              decoration: isPaidOff ? TextDecoration.lineThrough : null,
            )),
        subtitle: Text(
          '${debt.category.label} · ${debt.interestRate}% APR\n'
          'Balance: \$${debt.currentBalance.toStringAsFixed(2)} · '
          'Min: \$${debt.minimumPayment.toStringAsFixed(2)}/mo',
        ),
        isThreeLine: true,
        trailing: isPaidOff
            ? const Icon(Icons.check_circle, color: Colors.green)
            : PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'pay') _showPaymentDialog(debt);
                  if (v == 'paidoff') {
                    setState(() => _service.markPaidOff(debt.id));
                  }
                  if (v == 'delete') {
                    setState(() => _service.removeDebt(debt.id));
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'pay', child: Text('Record Payment')),
                  const PopupMenuItem(
                      value: 'paidoff', child: Text('Mark Paid Off')),
                  const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
      ),
    );
  }

  // ── Compare Tab ───────────────────────────────────────────────

  Widget _buildCompareTab() {
    if (_service.activeDebts.isEmpty) {
      return const Center(child: Text('Add debts to compare strategies'));
    }

    final plans = _service.compareStrategies(extraPayment: _extraPayment);
    final snowball = plans['snowball']!;
    final avalanche = plans['avalanche']!;
    final savings = _service.interestSavings(extraPayment: _extraPayment);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Extra Monthly Payment',
                    style: Theme.of(context).textTheme.titleMedium),
                Slider(
                  value: _extraPayment,
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  label: '\$${_extraPayment.toStringAsFixed(0)}',
                  onChanged: (v) => setState(() => _extraPayment = v),
                ),
                Center(
                  child: Text(
                    '\$${_extraPayment.toStringAsFixed(0)} / month extra',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _strategyCard('❄️ Snowball', snowball,
                'Pay smallest balance first')),
            const SizedBox(width: 8),
            Expanded(child: _strategyCard('🏔️ Avalanche', avalanche,
                'Pay highest rate first')),
          ],
        ),
        const SizedBox(height: 16),
        if (savings > 0)
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.savings, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Avalanche saves \$${savings.toStringAsFixed(2)} in interest '
                      'and ${snowball.totalMonths - avalanche.totalMonths} months!',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text('Payoff Order', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _payoffOrderList('Snowball', snowball),
        const SizedBox(height: 8),
        _payoffOrderList('Avalanche', avalanche),
      ],
    );
  }

  Widget _strategyCard(String title, PayoffPlan plan, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const Divider(),
            _metricRow('Months', '${plan.totalMonths}'),
            _metricRow('Interest',
                '\$${plan.totalInterest.toStringAsFixed(0)}'),
            _metricRow(
                'Total Paid', '\$${plan.totalPaid.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _payoffOrderList(String strategy, PayoffPlan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strategy,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ...plan.payoffOrder.asMap().entries.map((e) {
              final debtName = _service.debts
                  .firstWhere((d) => d.id == e.value,
                      orElse: () => _service.debts.first)
                  .name;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${e.key + 1}. $debtName'),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Timeline Tab ──────────────────────────────────────────────

  Widget _buildTimelineTab() {
    if (_service.activeDebts.isEmpty) {
      return const Center(child: Text('Add debts to see your timeline'));
    }

    final plan = _service.computePlan(PayoffStrategy.avalanche,
        extraPayment: _extraPayment);

    final debtBalancesByMonth = <int, Map<String, double>>{};
    for (final m in plan.schedule) {
      debtBalancesByMonth.putIfAbsent(m.month, () => {});
      debtBalancesByMonth[m.month]![m.debtId] = m.endBalance;
    }
    final sortedMonths = debtBalancesByMonth.keys.toList()..sort();
    final totalByMonth = <int, double>{};
    for (final month in sortedMonths) {
      totalByMonth[month] = debtBalancesByMonth[month]!.values
          .fold(0.0, (s, v) => s + v);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('📅 Debt-Free Date',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _formatDate(plan.estimatedPayoffDate),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text('${plan.totalMonths} months from now'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Balance Over Time',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...List.generate(
          (sortedMonths.length / 3).ceil().clamp(0, 20),
          (i) {
            final month = sortedMonths[
                (i * 3).clamp(0, sortedMonths.length - 1)];
            final total = totalByMonth[month]!;
            final maxTotal = totalByMonth[sortedMonths.first]!;
            final pct = maxTotal > 0 ? total / maxTotal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text('Mo $month',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey.shade200,
                      color: pct > 0.5 ? Colors.red : Colors.green,
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${_monthName(d.month)} ${d.year}';

  String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  // ── Dialogs ───────────────────────────────────────────────────

  void _showAddDebtDialog() {
    final nameCtl = TextEditingController();
    final balanceCtl = TextEditingController();
    final rateCtl = TextEditingController();
    final minCtl = TextEditingController();
    var category = DebtCategory.creditCard;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Debt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: balanceCtl,
                  decoration:
                      const InputDecoration(labelText: 'Balance (\$)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: rateCtl,
                  decoration:
                      const InputDecoration(labelText: 'Interest Rate (%)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: minCtl,
                  decoration: const InputDecoration(
                      labelText: 'Minimum Payment (\$/mo)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<DebtCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: DebtCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.emoji} ${c.label}')))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? category),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final balance =
                    double.tryParse(balanceCtl.text) ?? 0;
                final rate = double.tryParse(rateCtl.text) ?? 0;
                final minPay = double.tryParse(minCtl.text) ?? 0;
                if (nameCtl.text.isNotEmpty && balance > 0 && minPay > 0) {
                  setState(() {
                    _service.addDebt(
                      name: nameCtl.text,
                      balance: balance,
                      interestRate: rate,
                      minimumPayment: minPay,
                      emoji: category.emoji,
                      category: category,
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(DebtEntry debt) {
    final amountCtl = TextEditingController();
    final noteCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment to ${debt.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtl,
              decoration: const InputDecoration(labelText: 'Amount (\$)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteCtl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountCtl.text) ?? 0;
              if (amount > 0) {
                setState(() {
                  _service.addPayment(debt.id, amount,
                      note: noteCtl.text.isEmpty ? null : noteCtl.text);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }
}
