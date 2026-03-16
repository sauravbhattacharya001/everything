import 'package:flutter/material.dart';
import '../../core/services/document_expiry_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/document_entry.dart';

/// Document Expiry Tracker screen — track passports, licenses, insurance,
/// visas, certifications with color-coded urgency and renewal management.
class DocumentExpiryScreen extends StatefulWidget {
  const DocumentExpiryScreen({super.key});

  @override
  State<DocumentExpiryScreen> createState() => _DocumentExpiryScreenState();
}

class _DocumentExpiryScreenState extends State<DocumentExpiryScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'document_expiry_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  final DocumentExpiryService _service = DocumentExpiryService();
  late TabController _tabController;
  DocumentCategory? _filterCategory;
  String _searchQuery = '';
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    await initPersistence();
    if (_service.documents.isEmpty) {
      _loadSampleData();
    } else {
      _nextId = _service.documents.length + 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    final samples = [
      DocumentEntry(
        id: 'd1',
        name: 'US Passport',
        category: DocumentCategory.travel,
        issueDate: now.subtract(const Duration(days: 3285)),
        expiryDate: now.add(const Duration(days: 365)),
        issuer: 'US Department of State',
        documentNumber: 'C12345678',
        reminderDaysBefore: 180,
      ),
      DocumentEntry(
        id: 'd2',
        name: "Driver's License",
        category: DocumentCategory.identification,
        issueDate: now.subtract(const Duration(days: 1200)),
        expiryDate: now.add(const Duration(days: 60)),
        issuer: 'WA DOL',
        documentNumber: 'WDL7890123',
        reminderDaysBefore: 90,
      ),
      DocumentEntry(
        id: 'd3',
        name: 'Health Insurance',
        category: DocumentCategory.insurance,
        issueDate: now.subtract(const Duration(days: 200)),
        expiryDate: now.add(const Duration(days: 165)),
        issuer: 'Blue Cross',
        documentNumber: 'BC-456-789',
        reminderDaysBefore: 60,
      ),
      DocumentEntry(
        id: 'd4',
        name: 'Auto Insurance',
        category: DocumentCategory.vehicle,
        issueDate: now.subtract(const Duration(days: 150)),
        expiryDate: now.add(const Duration(days: 30)),
        issuer: 'GEICO',
        documentNumber: 'GK-11223',
        reminderDaysBefore: 30,
      ),
      DocumentEntry(
        id: 'd5',
        name: 'AWS Solutions Architect',
        category: DocumentCategory.professional,
        issueDate: now.subtract(const Duration(days: 900)),
        expiryDate: now.subtract(const Duration(days: 10)),
        issuer: 'Amazon Web Services',
        documentNumber: 'AWS-SA-9988',
        reminderDaysBefore: 90,
      ),
      DocumentEntry(
        id: 'd6',
        name: 'Apartment Lease',
        category: DocumentCategory.property,
        issueDate: now.subtract(const Duration(days: 300)),
        expiryDate: now.add(const Duration(days: 65)),
        issuer: 'Avalon Communities',
        documentNumber: 'LEASE-2025-42',
        reminderDaysBefore: 60,
      ),
    ];
    for (final s in samples) {
      _service.addDocument(s);
    }
    _nextId = samples.length + 1;
    savePersistence();
  }

  Color _urgencyColor(DocumentUrgency urgency) {
    switch (urgency) {
      case DocumentUrgency.expired: return Colors.red;
      case DocumentUrgency.critical: return Colors.deepOrange;
      case DocumentUrgency.warning: return Colors.amber.shade700;
      case DocumentUrgency.upcoming: return Colors.blue;
      case DocumentUrgency.safe: return Colors.green;
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var category = DocumentCategory.identification;
    var issueDate = DateTime.now();
    var expiryDate = DateTime.now().add(const Duration(days: 365));
    var reminderDays = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('Add Document'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Document Name *',
                    hintText: 'e.g. US Passport',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DocumentCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: DocumentCategory.values.map((c) =>
                    DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.label}'))
                  ).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: issuerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Issuer',
                    hintText: 'e.g. US Department of State',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Document Number',
                    hintText: 'e.g. C12345678',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Issue Date'),
                  subtitle: Text('${issueDate.month}/${issueDate.day}/${issueDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: issueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setDialogState(() => issueDate = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiry Date'),
                  subtitle: Text('${expiryDate.month}/${expiryDate.day}/${expiryDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: expiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2040),
                    );
                    if (d != null) setDialogState(() => expiryDate = d);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: reminderDays,
                  decoration: const InputDecoration(labelText: 'Remind before (days)'),
                  items: [14, 30, 60, 90, 180].map((d) =>
                    DropdownMenuItem(value: d, child: Text('$d days'))
                  ).toList(),
                  onChanged: (v) => setDialogState(() => reminderDays = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
                if (nameCtrl.text.trim().isEmpty) return;
                final doc = DocumentEntry(
                  id: 'd${_nextId++}',
                  name: nameCtrl.text.trim(),
                  category: category,
                  issueDate: issueDate,
                  expiryDate: expiryDate,
                  issuer: issuerCtrl.text.trim().isEmpty ? null : issuerCtrl.text.trim(),
                  documentNumber: numberCtrl.text.trim().isEmpty ? null : numberCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  reminderDaysBefore: reminderDays,
                );
                setState(() {
                  _service.addDocument(doc);
                  savePersistence();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      }),
    );
  }

  void _showRenewDialog(DocumentEntry doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Renew ${doc.name}?'),
        content: Text(
          'This will mark "${doc.name}" as renewed. '
          'You can add the new document separately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _service.markRenewed(doc.id);
                savePersistence();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Mark Renewed'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(DocumentEntry doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Remove "${doc.name}" from tracking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _service.removeDocument(doc.id);
                savePersistence();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Document Expiry Tracker'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '⏰ Active'),
            Tab(text: '🔔 Alerts'),
            Tab(text: '✅ Renewed'),
            Tab(text: '📊 Overview'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: _DocumentSearchDelegate(_service));
            },
            tooltip: 'Search documents',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildAlertsTab(),
          _buildRenewedTab(),
          _buildOverviewTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActiveTab() {
    final docs = _filterCategory != null
        ? _service.activeDocuments.where((d) => d.category == _filterCategory).toList()
        : _service.activeDocuments;

    return Column(
      children: [
        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterCategory == null,
                onSelected: (_) => setState(() => _filterCategory = null),
              ),
              const SizedBox(width: 6),
              ...DocumentCategory.values.map((c) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text('${c.emoji} ${c.label}'),
                  selected: _filterCategory == c,
                  onSelected: (_) => setState(() =>
                    _filterCategory = _filterCategory == c ? null : c),
                ),
              )),
            ],
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? const Center(child: Text('No documents tracked yet.\nTap + to add one.', textAlign: TextAlign.center))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _buildDocumentCard(docs[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    final alerts = _service.alertDocuments;
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('All clear! No documents need attention.',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: alerts.length,
      itemBuilder: (_, i) => _buildDocumentCard(alerts[i], showAlert: true),
    );
  }

  Widget _buildRenewedTab() {
    final renewed = _service.renewedDocuments;
    if (renewed.isEmpty) {
      return const Center(child: Text('No renewed documents yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: renewed.length,
      itemBuilder: (_, i) {
        final doc = renewed[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(doc.category.emoji),
            ),
            title: Text(doc.name),
            subtitle: Text('Renewed ${_formatDate(doc.renewedDate ?? DateTime.now())}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteDocument(doc),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    final urgencyCounts = _service.urgencyCounts;
    final categoryCounts = _service.categoryCounts;
    final nextExpiry = _service.nextToExpire;
    final avgDays = _service.averageDaysToExpiry;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _summaryCard('Total', '${_service.documents.length}', Icons.folder, Colors.blue),
              const SizedBox(width: 8),
              _summaryCard('Active', '${_service.activeDocuments.length}', Icons.pending, Colors.orange),
              const SizedBox(width: 8),
              _summaryCard('Alerts', '${_service.alertDocuments.length}', Icons.warning, Colors.red),
            ],
          ),
          const SizedBox(height: 16),

          // Next expiry
          if (nextExpiry != null) ...[
            Card(
              color: _urgencyColor(nextExpiry.urgency).withOpacity(0.1),
              child: ListTile(
                leading: Icon(Icons.timer, color: _urgencyColor(nextExpiry.urgency)),
                title: Text('Next to expire: ${nextExpiry.name}'),
                subtitle: Text(nextExpiry.daysUntilExpiry < 0
                    ? 'Expired ${-nextExpiry.daysUntilExpiry} days ago'
                    : '${nextExpiry.daysUntilExpiry} days remaining'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Avg days
          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Average days to expiry'),
              trailing: Text('${avgDays.round()} days',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),

          // Urgency breakdown
          const Text('By Urgency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...DocumentUrgency.values.map((u) {
            final count = urgencyCounts[u] ?? 0;
            if (count == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: _urgencyColor(u),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${u.emoji} ${u.label}'),
                  const Spacer(),
                  Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Category breakdown
          const Text('By Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...categoryCounts.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(e.key.emoji),
                const SizedBox(width: 8),
                Text(e.key.label),
                const Spacer(),
                Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(DocumentEntry doc, {bool showAlert = false}) {
    final urgency = doc.urgency;
    final color = _urgencyColor(urgency);
    final days = doc.daysUntilExpiry;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Text(doc.category.emoji),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (doc.issuer != null)
                        Text(doc.issuer!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    days < 0 ? 'Expired ${-days}d ago' : '${days}d left',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: doc.validityUsedPercent,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${urgency.emoji} ${urgency.label}',
                    style: TextStyle(fontSize: 12, color: color)),
                const Spacer(),
                if (doc.documentNumber != null)
                  Text(doc.documentNumber!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(width: 8),
                Text('Expires ${_formatDate(doc.expiryDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            if (doc.notes != null) ...[
              const SizedBox(height: 4),
              Text(doc.notes!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Renew'),
                  onPressed: () => _showRenewDialog(doc),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () => _deleteDocument(doc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';
}

class _DocumentSearchDelegate extends SearchDelegate<String> {
  final DocumentExpiryService _service;
  _DocumentSearchDelegate(this._service);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) =>
    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = query.isEmpty ? _service.documents : _service.search(query);
    if (results.isEmpty) {
      return const Center(child: Text('No documents found.'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final doc = results[i];
        return ListTile(
          leading: Text(doc.category.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(doc.name),
          subtitle: Text('${doc.urgency.emoji} ${doc.daysUntilExpiry < 0 ? "Expired" : "${doc.daysUntilExpiry} days left"}'),
          trailing: doc.issuer != null ? Text(doc.issuer!, style: const TextStyle(fontSize: 12)) : null,
        );
      },
    );
  }
}
