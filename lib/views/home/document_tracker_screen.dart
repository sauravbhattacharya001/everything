import 'package:flutter/material.dart';
import '../../core/services/document_tracker_service.dart';
import '../../models/document_entry.dart';

/// Document Expiry Tracker — track passports, licenses, visas, insurance,
/// certifications, and more. Get expiry alerts, log renewals, view timeline.
class DocumentTrackerScreen extends StatefulWidget {
  const DocumentTrackerScreen({super.key});
  @override
  State<DocumentTrackerScreen> createState() => _DocumentTrackerScreenState();
}

class _DocumentTrackerScreenState extends State<DocumentTrackerScreen>
    with SingleTickerProviderStateMixin {
  final DocumentTrackerService _service = DocumentTrackerService();
  late TabController _tabController;
  DocumentCategory? _filterCat;
  String _searchQuery = '';
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSampleData();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  void _loadSampleData() {
    final now = DateTime.now();
    _service.addDocument(DocumentEntry(id: 'd1', name: 'US Passport',
      category: DocumentCategory.passport, issuer: 'US Department of State',
      documentNumber: 'X12345678', issueDate: now.subtract(const Duration(days: 3000)),
      expiryDate: now.add(const Duration(days: 650)), holder: 'Self', reminderDaysBefore: 180));
    _service.addDocument(DocumentEntry(id: 'd2', name: "Driver's License",
      category: DocumentCategory.driversLicense, issuer: 'WA DOL',
      documentNumber: 'WDL1234567', issueDate: now.subtract(const Duration(days: 1400)),
      expiryDate: now.add(const Duration(days: 45)), holder: 'Self', reminderDaysBefore: 60));
    _service.addDocument(DocumentEntry(id: 'd3', name: 'Auto Insurance',
      category: DocumentCategory.insurance, issuer: 'State Farm',
      documentNumber: 'POL-99887766', issueDate: now.subtract(const Duration(days: 300)),
      expiryDate: now.add(const Duration(days: 65)), holder: 'Self', reminderDaysBefore: 30,
      renewalHistory: [RenewalRecord(id: 'r1', renewedOn: now.subtract(const Duration(days: 300)),
        previousExpiry: now.subtract(const Duration(days: 300)),
        newExpiry: now.add(const Duration(days: 65)), cost: 1200.00)]));
    _service.addDocument(DocumentEntry(id: 'd4', name: 'AWS Solutions Architect',
      category: DocumentCategory.certification, issuer: 'Amazon Web Services',
      documentNumber: 'AWS-SAA-2024', issueDate: now.subtract(const Duration(days: 800)),
      expiryDate: now.subtract(const Duration(days: 10)), holder: 'Self', reminderDaysBefore: 90));
    _service.addDocument(DocumentEntry(id: 'd5', name: 'Gym Membership',
      category: DocumentCategory.membership, issuer: 'LA Fitness',
      documentNumber: 'MEM-445566', issueDate: now.subtract(const Duration(days: 330)),
      expiryDate: now.add(const Duration(days: 35)), holder: 'Self', reminderDaysBefore: 14));
    _service.addDocument(DocumentEntry(id: 'd6', name: 'Health Insurance Card',
      category: DocumentCategory.medicalCard, issuer: 'Premera Blue Cross',
      documentNumber: 'PBC-112233', issueDate: now.subtract(const Duration(days: 200)),
      expiryDate: now.add(const Duration(days: 165)), holder: 'Self', reminderDaysBefore: 30));
    _nextId = 7;
  }

  Color _uColor(ExpiryUrgency u) => switch (u) {
    ExpiryUrgency.expired => Colors.red, ExpiryUrgency.critical => Colors.deepOrange,
    ExpiryUrgency.warning => Colors.orange, ExpiryUrgency.upcoming => Colors.amber,
    ExpiryUrgency.safe => Colors.green,
  };

  IconData _uIcon(ExpiryUrgency u) => switch (u) {
    ExpiryUrgency.expired => Icons.error, ExpiryUrgency.critical => Icons.warning_amber,
    ExpiryUrgency.warning => Icons.access_time, ExpiryUrgency.upcoming => Icons.schedule,
    ExpiryUrgency.safe => Icons.check_circle,
  };

  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
  String _dText(int d) => d < 0 ? '${d.abs()}d overdue' : d == 0 ? 'Today!' : d == 1 ? 'Tomorrow' : '${d}d left';

  List<DocumentEntry> _filtered() {
    var docs = _service.documents.toList();
    if (_filterCat != null) docs = docs.where((d) => d.category == _filterCat).toList();
    if (_searchQuery.isNotEmpty) {
      docs = _service.search(_searchQuery);
      if (_filterCat != null) docs = docs.where((d) => d.category == _filterCat).toList();
    }
    docs.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return docs;
  }

  void _showAddDialog() {
    String name = ''; var cat = DocumentCategory.other;
    String issuer = '', docNum = '', holder = '', notes = '';
    var issue = DateTime.now(), expiry = DateTime.now().add(const Duration(days: 365));
    int remind = 30;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) =>
      AlertDialog(title: const Text('Add Document'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(decoration: const InputDecoration(labelText: 'Document Name *'), onChanged: (v) => name = v),
          const SizedBox(height: 8),
          DropdownButtonFormField<DocumentCategory>(value: cat,
            decoration: const InputDecoration(labelText: 'Category'),
            items: DocumentCategory.values.map((c) => DropdownMenuItem(value: c,
              child: Text('${c.icon} ${c.label}'))).toList(),
            onChanged: (v) => ss(() => cat = v!)),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(labelText: 'Issuer'), onChanged: (v) => issuer = v),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(labelText: 'Document Number'), onChanged: (v) => docNum = v),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(labelText: 'Holder'), onChanged: (v) => holder = v),
          const SizedBox(height: 8),
          ListTile(contentPadding: EdgeInsets.zero, title: Text('Issue: ${_fmt(issue)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async { final p = await showDatePicker(context: ctx, initialDate: issue,
              firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) ss(() => issue = p); }),
          ListTile(contentPadding: EdgeInsets.zero, title: Text('Expiry: ${_fmt(expiry)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async { final p = await showDatePicker(context: ctx, initialDate: expiry,
              firstDate: DateTime(2000), lastDate: DateTime(2100)); if (p != null) ss(() => expiry = p); }),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(labelText: 'Remind days before', suffixText: 'days'),
            keyboardType: TextInputType.number, controller: TextEditingController(text: '$remind'),
            onChanged: (v) => remind = int.tryParse(v) ?? 30),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2, onChanged: (v) => notes = v),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (name.isEmpty) return;
            setState(() => _service.addDocument(DocumentEntry(id: 'd${_nextId++}', name: name,
              category: cat, issuer: issuer.isEmpty ? null : issuer,
              documentNumber: docNum.isEmpty ? null : docNum, issueDate: issue, expiryDate: expiry,
              holder: holder.isEmpty ? null : holder, notes: notes.isEmpty ? null : notes,
              reminderDaysBefore: remind)));
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ])));
  }

  void _showRenewDialog(DocumentEntry doc) {
    var newExp = doc.expiryDate.add(Duration(days: doc.totalValidityDays > 0 ? doc.totalValidityDays : 365));
    double cost = 0; String notes = '';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) =>
      AlertDialog(title: Text('Renew ${doc.name}'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Current expiry: ${_fmt(doc.expiryDate)}'), const SizedBox(height: 12),
          ListTile(contentPadding: EdgeInsets.zero, title: Text('New Expiry: ${_fmt(newExp)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async { final p = await showDatePicker(context: ctx, initialDate: newExp,
              firstDate: DateTime.now(), lastDate: DateTime(2100)); if (p != null) ss(() => newExp = p); }),
          TextField(decoration: const InputDecoration(labelText: 'Renewal Cost', prefixText: '\$'),
            keyboardType: TextInputType.number, onChanged: (v) => cost = double.tryParse(v) ?? 0),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(labelText: 'Notes'), onChanged: (v) => notes = v),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final r = RenewalRecord(id: 'r${DateTime.now().millisecondsSinceEpoch}',
              renewedOn: DateTime.now(), previousExpiry: doc.expiryDate, newExpiry: newExp,
              cost: cost > 0 ? cost : null, notes: notes.isEmpty ? null : notes);
            setState(() => _service.renewDocument(doc.id, r, newExp));
            Navigator.pop(ctx);
          }, child: const Text('Renew')),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Document Tracker'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.list_alt), text: 'All'),
          Tab(icon: Icon(Icons.warning_amber), text: 'Alerts'),
          Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          Tab(icon: Icon(Icons.analytics), text: 'Summary'),
        ])),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
      body: TabBarView(controller: _tabController, children: [
        _allTab(theme), _alertsTab(theme), _timelineTab(theme), _summaryTab(theme),
      ]),
    );
  }

  Widget _allTab(ThemeData theme) {
    final docs = _filtered();
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: TextField(
        decoration: InputDecoration(hintText: 'Search documents...', prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
        onChanged: (v) => setState(() => _searchQuery = v))),
      SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          FilterChip(label: const Text('All'), selected: _filterCat == null,
            onSelected: (_) => setState(() => _filterCat = null)),
          const SizedBox(width: 6),
          ...DocumentCategory.values.map((c) => Padding(padding: const EdgeInsets.only(right: 6),
            child: FilterChip(label: Text('${c.icon} ${c.label}'), selected: _filterCat == c,
              onSelected: (_) => setState(() => _filterCat = _filterCat == c ? null : c)))),
        ])),
      const SizedBox(height: 8),
      Expanded(child: docs.isEmpty ? const Center(child: Text('No documents found'))
        : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: docs.length, itemBuilder: (_, i) => _card(docs[i], theme))),
    ]);
  }

  Widget _card(DocumentEntry doc, ThemeData theme) {
    final c = _uColor(doc.urgency);
    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
      leading: CircleAvatar(backgroundColor: c.withOpacity(0.15),
        child: Icon(_uIcon(doc.urgency), color: c, size: 20)),
      title: Text('${doc.category.icon} ${doc.name}', style: theme.textTheme.titleSmall),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (doc.issuer != null) Text(doc.issuer!, style: theme.textTheme.bodySmall),
        Row(children: [
          Text('Expires: ${_fmt(doc.expiryDate)}', style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(_dText(doc.daysRemaining),
              style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: doc.percentElapsed / 100,
          backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(c)),
      ]),
      trailing: PopupMenuButton<String>(onSelected: (v) {
        if (v == 'renew') _showRenewDialog(doc);
        if (v == 'delete') setState(() => _service.removeDocument(doc.id));
      }, itemBuilder: (_) => [
        const PopupMenuItem(value: 'renew', child: Text('Renew')),
        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
      ]),
      isThreeLine: true,
    ));
  }

  Widget _alertsTab(ThemeData theme) {
    final alerts = _service.getAlerts();
    if (alerts.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
      SizedBox(height: 12), Text('All documents are in good standing!', style: TextStyle(fontSize: 16)),
    ]));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: alerts.length,
      itemBuilder: (_, i) {
        final a = alerts[i]; final c = _uColor(a.document.urgency);
        return Card(color: c.withOpacity(0.05), margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(a.daysUntilExpiry < 0 ? Icons.error : Icons.warning_amber, color: c),
            title: Text(a.message),
            subtitle: Text('${a.document.category.label} • ${a.document.holder ?? 'No holder'}',
              style: theme.textTheme.bodySmall),
            trailing: TextButton(onPressed: () => _showRenewDialog(a.document), child: const Text('Renew')),
          ));
      });
  }

  Widget _timelineTab(ThemeData theme) {
    final tl = _service.getExpiryTimeline();
    if (tl.isEmpty) return const Center(child: Text('No active documents'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: tl.length,
      itemBuilder: (_, i) {
        final doc = tl[i]; final c = _uColor(doc.urgency);
        return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
          SizedBox(width: 40, child: Column(children: [
            if (i > 0) Container(width: 2, height: 12, color: Colors.grey.shade300),
            CircleAvatar(radius: 8, backgroundColor: c,
              child: Icon(_uIcon(doc.urgency), size: 10, color: Colors.white)),
            if (i < tl.length - 1) Container(width: 2, height: 12, color: Colors.grey.shade300),
          ])),
          Expanded(child: Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${doc.category.icon} ${doc.name}', style: theme.textTheme.titleSmall),
                Text('${_fmt(doc.expiryDate)} • ${_dText(doc.daysRemaining)}',
                  style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w500)),
              ])),
              Chip(label: Text(doc.urgency.label, style: TextStyle(color: c, fontSize: 11)),
                backgroundColor: c.withOpacity(0.1), side: BorderSide.none, padding: EdgeInsets.zero),
            ])))),
        ]));
      });
  }

  Widget _summaryTab(ThemeData theme) {
    final s = _service.getSummary();
    final est = _service.estimateUpcomingRenewalCost();
    return SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [_st('Total', '${s.totalDocuments}', Colors.blue, theme),
          _st('Valid', '${s.validCount}', Colors.green, theme),
          _st('Expired', '${s.expiredCount}', Colors.red, theme)]),
        const SizedBox(height: 8),
        Row(children: [_st('Expiring', '${s.expiringSoonCount}', Colors.orange, theme),
          _st('Critical', '${s.criticalCount}', Colors.deepOrange, theme),
          _st('Cost', '\$${s.totalRenewalCost.toStringAsFixed(0)}', Colors.purple, theme)]),
        if (est > 0) ...[const SizedBox(height: 12),
          Card(color: Colors.amber.shade50, child: Padding(padding: const EdgeInsets.all(12),
            child: Row(children: [const Icon(Icons.attach_money, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Estimated upcoming renewal: \$${est.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium)])))],
        const SizedBox(height: 16),
        Text('By Category', style: theme.textTheme.titleMedium), const SizedBox(height: 8),
        ...s.categoryBreakdown.map((b) => Card(margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(leading: Text(b.category.icon, style: const TextStyle(fontSize: 24)),
            title: Text(b.category.label),
            subtitle: Text('${b.validCount} valid, ${b.expiredCount} expired'),
            trailing: Text('${b.count}', style: theme.textTheme.titleMedium)))),
        const SizedBox(height: 16),
        Text('By Holder', style: theme.textTheme.titleMedium), const SizedBox(height: 8),
        ..._service.getByHolderGrouped().entries.map((e) => Card(margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(leading: const Icon(Icons.person), title: Text(e.key),
            subtitle: Text('${e.value.where((d) => d.isValid).length} valid, '
              '${e.value.where((d) => d.isExpired).length} expired'),
            trailing: Text('${e.value.length}', style: theme.textTheme.titleMedium)))),
      ]));
  }

  Widget _st(String l, String v, Color c, ThemeData t) => Expanded(child:
    Card(margin: const EdgeInsets.symmetric(horizontal: 4), child:
      Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Text(v, style: t.textTheme.titleLarge?.copyWith(color: c)),
        const SizedBox(height: 4),
        Text(l, style: t.textTheme.bodySmall, textAlign: TextAlign.center),
      ]))));
}
