import 'package:flutter/material.dart';
import '../../core/services/bill_reminder_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/bill_entry.dart';

/// Bill Reminder screen - track recurring bills, due dates, payment status,
/// and view monthly spending summaries.
class BillReminderScreen extends StatefulWidget {
  const BillReminderScreen({super.key});

  @override
  State<BillReminderScreen> createState() => _BillReminderScreenState();
}

class _BillReminderScreenState extends State<BillReminderScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'bill_reminder_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  final BillReminderService _service = BillReminderService();
  late TabController _tabController;
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    await initPersistence();
    if (_service.bills.isEmpty) _loadSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    final samples = [
      BillEntry(
        id: 'b1',
        name: 'Rent',
        amount: 1800.00,
        category: BillCategory.housing,
        frequency: BillFrequency.monthly,
        dueDate: DateTime(now.year, now.month, 1).add(const Duration(days: 31)),
        payee: 'Landlord',
      ),
      BillEntry(
        id: 'b2',
        name: 'Electric',
        amount: 95.00,
        category: BillCategory.utilities,
        frequency: BillFrequency.monthly,
        dueDate: now.add(const Duration(days: 5)),
        payee: 'City Power',
      ),
      BillEntry(
        id: 'b3',
        name: 'Car Insurance',
        amount: 420.00,
        category: BillCategory.insurance,
        frequency: BillFrequency.quarterly,
        dueDate: now.add(const Duration(days: 15)),
        autoPay: true,
        payee: 'GEICO',
      ),
      BillEntry(
        id: 'b4',
        name: 'Netflix',
        amount: 15.49,
        category: BillCategory.subscriptions,
        frequency: BillFrequency.monthly,
        dueDate: now.subtract(const Duration(days: 2)),
        autoPay: true,
        payee: 'Netflix',
      ),
      BillEntry(
        id: 'b5',
        name: 'Student Loan',
        amount: 350.00,
        category: BillCategory.loans,
        frequency: BillFrequency.monthly,
        dueDate: now.add(const Duration(days: 10)),
        payee: 'Navient',
      ),
    ];
    for (final s in samples) {
      _service.addBill(s);
    }
    _nextId = 6;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _service.getSummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Reminder'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Paid'),
            Tab(text: 'Summary'),
          ],
        ),
        actions: [
          if (canExport) buildExportButton(context),
        ],
      ),
      body: Column(
        children: [
          // Alert banner for overdue bills
          if (summary.overdueCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${summary.overdueCount} overdue bill${summary.overdueCount > 1 ? 's' : ''} '
                    '(\$${summary.totalUnpaid.toStringAsFixed(2)} unpaid)',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Monthly estimate
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Text(
              'Est. monthly: \$${summary.totalMonthly.toStringAsFixed(2)}',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBillList(false),
                _buildBillList(true),
                _buildSummaryTab(summary),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBillDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBillList(bool showPaid) {
    final bills = _service.getSorted(paidFilter: showPaid);
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showPaid ? Icons.check_circle_outline : Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              showPaid ? 'No paid bills yet' : 'No upcoming bills',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return _buildBillCard(bill);
      },
    );
  }

  Widget _buildBillCard(BillEntry bill) {
    final isOverdue = bill.isOverdue;
    final isDueSoon = bill.isDueSoon();
    Color statusColor;
    String statusText;

    if (bill.isPaid) {
      statusColor = Colors.green;
      statusText = 'Paid';
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusText = '${-bill.daysUntilDue}d overdue';
    } else if (isDueSoon) {
      statusColor = Colors.orange;
      statusText = bill.daysUntilDue == 0
          ? 'Due today'
          : '${bill.daysUntilDue}d left';
    } else {
      statusColor = Colors.grey;
      statusText = '${bill.daysUntilDue}d left';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(color: Colors.red.shade200, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Text(
            bill.category.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          bill.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: bill.isPaid ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${bill.frequency.label} · ${bill.payee ?? ""}'
          '${bill.autoPay ? ' · Auto-pay' : ''}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${bill.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        onTap: () => _showBillDialog(bill: bill),
        onLongPress: () {
          if (!bill.isPaid) {
            _service.markPaid(bill.id);
          } else {
            _service.markUnpaid(bill.id);
          }
          persistState();
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSummaryTab(BillSummary summary) {
    final entries = summary.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Key metrics
        Row(
          children: [
            _summaryCard('Monthly Est.', '\$${summary.totalMonthly.toStringAsFixed(0)}', Icons.calendar_month, Colors.blue),
            const SizedBox(width: 12),
            _summaryCard('Overdue', '${summary.overdueCount}', Icons.warning_amber, Colors.red),
            const SizedBox(width: 12),
            _summaryCard('Due Soon', '${summary.dueSoonCount}', Icons.schedule, Colors.orange),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Spending by Category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...entries.map((e) {
          final pct = summary.totalMonthly > 0
              ? (e.value / (summary.totalPaid + summary.totalUnpaid) * 100)
              : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(e.key.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${e.value.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  void _showBillDialog({BillEntry? bill}) {
    final isEdit = bill != null;
    final nameCtrl = TextEditingController(text: bill?.name ?? '');
    final amountCtrl = TextEditingController(
        text: bill != null ? bill.amount.toStringAsFixed(2) : '');
    final payeeCtrl = TextEditingController(text: bill?.payee ?? '');
    final notesCtrl = TextEditingController(text: bill?.notes ?? '');
    var category = bill?.category ?? BillCategory.other;
    var frequency = bill?.frequency ?? BillFrequency.monthly;
    var dueDate = bill?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    var autoPay = bill?.autoPay ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Bill' : 'Add Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bill Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: payeeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Payee (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BillCategory>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: BillCategory.values.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.emoji} ${c.label}'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BillFrequency>(
                  value: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: BillFrequency.values.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.label),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => frequency = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    'Due: ${dueDate.month}/${dueDate.day}/${dueDate.year}',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-pay'),
                  value: autoPay,
                  onChanged: (v) => setDialogState(() => autoPay = v),
                ),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () {
                  _service.removeBill(bill.id);
                  persistState();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text.trim());
                if (name.isEmpty || amount == null || amount <= 0) return;

                final entry = BillEntry(
                  id: isEdit ? bill.id : 'bill_${_nextId++}',
                  name: name,
                  amount: amount,
                  category: category,
                  frequency: frequency,
                  dueDate: dueDate,
                  isPaid: isEdit ? bill.isPaid : false,
                  paidDate: isEdit ? bill.paidDate : null,
                  autoPay: autoPay,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  payee: payeeCtrl.text.trim().isEmpty ? null : payeeCtrl.text.trim(),
                );

                if (isEdit) {
                  _service.updateBill(entry);
                } else {
                  _service.addBill(entry);
                }
                persistState();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
