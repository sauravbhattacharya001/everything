import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Expense Splitter — create groups, add shared expenses, and see who owes whom.
///
/// All data is persisted locally via SharedPreferences.
class ExpenseSplitterScreen extends StatefulWidget {
  const ExpenseSplitterScreen({super.key});

  @override
  State<ExpenseSplitterScreen> createState() => _ExpenseSplitterScreenState();
}

class _ExpenseSplitterScreenState extends State<ExpenseSplitterScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'expense_splitter_groups';

  late TabController _tabController;
  List<SplitGroup> _groups = [];
  int? _selectedGroupIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Persistence ──

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _groups = list.map((e) => SplitGroup.fromJson(e)).toList();
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_groups.map((g) => g.toJson()).toList()));
  }

  // ── Group Management ──

  void _addGroup() {
    final nameController = TextEditingController();
    final membersController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. Road Trip 2026',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: membersController,
              decoration: const InputDecoration(
                labelText: 'Members (comma-separated)',
                hintText: 'Alice, Bob, Charlie',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final members = membersController.text
                  .split(',')
                  .map((m) => m.trim())
                  .where((m) => m.isNotEmpty)
                  .toList();
              if (name.isEmpty || members.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Need a name and at least 2 members')));
                return;
              }
              setState(() {
                _groups.add(SplitGroup(
                  name: name,
                  members: members,
                  expenses: [],
                  createdAt: DateTime.now(),
                ));
              });
              _save();
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(int index) {
    final group = _groups[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group?'),
        content: Text('Delete "${group.name}" and all its expenses?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _groups.removeAt(index);
                if (_selectedGroupIndex == index) {
                  _selectedGroupIndex = null;
                } else if (_selectedGroupIndex != null &&
                    _selectedGroupIndex! > index) {
                  _selectedGroupIndex = _selectedGroupIndex! - 1;
                }
              });
              _save();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Expense Management ──

  void _addExpense(SplitGroup group) {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String? paidBy = group.members.first;
    Set<String> splitAmong = group.members.toSet();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Dinner at Olive Garden',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paidBy,
                  decoration: const InputDecoration(labelText: 'Paid by'),
                  items: group.members
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => paidBy = v),
                ),
                const SizedBox(height: 12),
                const Text('Split among:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                ...group.members.map((m) => CheckboxListTile(
                      title: Text(m),
                      value: splitAmong.contains(m),
                      dense: true,
                      onChanged: (v) {
                        setDialogState(() {
                          if (v == true) {
                            splitAmong.add(m);
                          } else if (splitAmong.length > 1) {
                            splitAmong.remove(m);
                          }
                        });
                      },
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final desc = descController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (desc.isEmpty || amount <= 0 || paidBy == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Fill in all fields')));
                  return;
                }
                setState(() {
                  group.expenses.add(SplitExpense(
                    description: desc,
                    amount: amount,
                    paidBy: paidBy!,
                    splitAmong: splitAmong.toList(),
                    date: DateTime.now(),
                  ));
                });
                _save();
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Balance Calculation ──

  /// Computes net balances for a group. Positive = owed money, negative = owes money.
  Map<String, double> _computeBalances(SplitGroup group) {
    final balances = <String, double>{};
    for (final m in group.members) {
      balances[m] = 0;
    }
    for (final exp in group.expenses) {
      final share = exp.amount / exp.splitAmong.length;
      balances[exp.paidBy] = (balances[exp.paidBy] ?? 0) + exp.amount;
      for (final m in exp.splitAmong) {
        balances[m] = (balances[m] ?? 0) - share;
      }
    }
    return balances;
  }

  /// Simplifies debts into minimal transfers using greedy algorithm.
  List<_Transfer> _simplifyDebts(SplitGroup group) {
    final balances = _computeBalances(group);
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    for (final entry in balances.entries) {
      if (entry.value > 0.01) {
        creditors.add(entry);
      } else if (entry.value < -0.01) {
        debtors.add(entry);
      }
    }

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => a.value.compareTo(b.value));

    final transfers = <_Transfer>[];
    int ci = 0, di = 0;
    final cBal = creditors.map((e) => e.value).toList();
    final dBal = debtors.map((e) => e.value.abs()).toList();

    while (ci < creditors.length && di < debtors.length) {
      final amount =
          cBal[ci] < dBal[di] ? cBal[ci] : dBal[di];
      transfers.add(_Transfer(
        from: debtors[di].key,
        to: creditors[ci].key,
        amount: amount,
      ));
      cBal[ci] -= amount;
      dBal[di] -= amount;
      if (cBal[ci] < 0.01) ci++;
      if (dBal[di] < 0.01) di++;
    }

    return transfers;
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Splitter'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'Groups'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Details'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tabController.index == 0
            ? _addGroup
            : (_selectedGroupIndex != null
                ? () => _addExpense(_groups[_selectedGroupIndex!])
                : null),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No groups yet',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Tap + to create a group and start splitting expenses',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final total =
            group.expenses.fold<double>(0, (s, e) => s + e.amount);
        final transfers = _simplifyDebts(group);
        final isSelected = _selectedGroupIndex == index;

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _selectedGroupIndex = index);
              _tabController.animateTo(1);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(group.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        onPressed: () => _deleteGroup(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.members.length} members · ${group.expenses.length} expenses · \$${total.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (transfers.isNotEmpty) ...[
                    const Divider(height: 16),
                    const Text('Settlements:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    ...transfers.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_forward,
                                  size: 14, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Text(
                                '${t.from} → ${t.to}: \$${t.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsTab() {
    if (_selectedGroupIndex == null || _selectedGroupIndex! >= _groups.length) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Select a group from the Groups tab',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    final group = _groups[_selectedGroupIndex!];
    final balances = _computeBalances(group);
    final transfers = _simplifyDebts(group);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Group header
        Text(group.name,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
        Text('${group.members.join(', ')}',
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),

        // Balance cards
        const Text('Balances',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: group.members.map((m) {
            final bal = balances[m] ?? 0;
            final color = bal > 0.01
                ? Colors.green
                : bal < -0.01
                    ? Colors.red
                    : Colors.grey;
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Text(m[0].toUpperCase(),
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold)),
              ),
              label: Text(
                '$m: ${bal >= 0 ? '+' : ''}\$${bal.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Simplified settlements
        if (transfers.isNotEmpty) ...[
          const Text('Who Pays Whom',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...transfers.map((t) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: const Icon(Icons.swap_horiz,
                        color: Colors.orange),
                  ),
                  title: Text('${t.from} → ${t.to}'),
                  trailing: Text(
                    '\$${t.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Expense list
        Row(
          children: [
            const Expanded(
              child: Text('Expenses',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Text(
              'Total: \$${group.expenses.fold<double>(0, (s, e) => s + e.amount).toStringAsFixed(2)}',
              style: TextStyle(
                  color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (group.expenses.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('No expenses yet — tap + to add one',
                  style: TextStyle(color: Colors.grey[500])),
            ),
          )
        else
          ...group.expenses.reversed.toList().asMap().entries.map((entry) {
            final exp = entry.value;
            final realIndex = group.expenses.length - 1 - entry.key;
            return Dismissible(
              key: ValueKey('${group.name}_$realIndex'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                setState(() => group.expenses.removeAt(realIndex));
                _save();
              },
              child: Card(
                child: ListTile(
                  title: Text(exp.description),
                  subtitle: Text(
                    'Paid by ${exp.paidBy} · split ${exp.splitAmong.length} ways · ${exp.date.month}/${exp.date.day}',
                  ),
                  trailing: Text(
                    '\$${exp.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ── Data Models ──

class _Transfer {
  final String from;
  final String to;
  final double amount;
  const _Transfer({required this.from, required this.to, required this.amount});
}

class SplitExpense {
  String description;
  double amount;
  String paidBy;
  List<String> splitAmong;
  DateTime date;

  SplitExpense({
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitAmong,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'amount': amount,
        'paidBy': paidBy,
        'splitAmong': splitAmong,
        'date': date.toIso8601String(),
      };

  factory SplitExpense.fromJson(Map<String, dynamic> json) => SplitExpense(
        description: json['description'] ?? '',
        amount: (json['amount'] as num).toDouble(),
        paidBy: json['paidBy'] ?? '',
        splitAmong: List<String>.from(json['splitAmong'] ?? []),
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      );
}

class SplitGroup {
  String name;
  List<String> members;
  List<SplitExpense> expenses;
  DateTime createdAt;

  SplitGroup({
    required this.name,
    required this.members,
    required this.expenses,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'members': members,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SplitGroup.fromJson(Map<String, dynamic> json) => SplitGroup(
        name: json['name'] ?? '',
        members: List<String>.from(json['members'] ?? []),
        expenses: (json['expenses'] as List?)
                ?.map((e) => SplitExpense.fromJson(e))
                .toList() ??
            [],
        createdAt:
            DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
