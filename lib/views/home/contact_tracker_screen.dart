import 'package:flutter/material.dart';
import '../../core/services/contact_tracker_service.dart';
import '../../models/contact.dart';

/// Contact Tracker screen — manage contacts, log interactions,
/// track follow-ups, and view network health.
class ContactTrackerScreen extends StatefulWidget {
  const ContactTrackerScreen({super.key});

  @override
  State<ContactTrackerScreen> createState() => _ContactTrackerScreenState();
}

class _ContactTrackerScreenState extends State<ContactTrackerScreen>
    with SingleTickerProviderStateMixin {
  final ContactTrackerService _service = ContactTrackerService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RelationshipCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
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
        title: const Text('Contact Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Contacts'),
            Tab(icon: Icon(Icons.notifications_active), text: 'Follow-ups'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'Health'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ContactsTab(
            service: _service,
            searchController: _searchController,
            searchQuery: _searchQuery,
            categoryFilter: _categoryFilter,
            onCategoryChanged: (c) => setState(() => _categoryFilter = c),
            onChanged: () => setState(() {}),
          ),
          _FollowUpsTab(service: _service, onChanged: () => setState(() {})),
          _HealthTab(service: _service),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Contact'),
      ),
    );
  }

  Future<void> _showAddContactDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AddContactDialog(service: _service),
    );
    if (result == true) setState(() {});
  }
}

// ─── CONTACTS TAB ───────────────────────────────────────────────────────────

class _ContactsTab extends StatelessWidget {
  final ContactTrackerService service;
  final TextEditingController searchController;
  final String searchQuery;
  final RelationshipCategory? categoryFilter;
  final ValueChanged<RelationshipCategory?> onCategoryChanged;
  final VoidCallback onChanged;

  const _ContactsTab({
    required this.service,
    required this.searchController,
    required this.searchQuery,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    var contacts = searchQuery.isNotEmpty
        ? service.search(searchQuery)
        : service.activeContacts();

    if (categoryFilter != null) {
      contacts =
          contacts.where((c) => c.category == categoryFilter).toList();
    }

    contacts.sort((a, b) => a.name.compareTo(b.name));

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('All'),
                  selected: categoryFilter == null,
                  onSelected: (_) => onCategoryChanged(null),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              ...RelationshipCategory.values.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('${cat.emoji} ${cat.label}'),
                      selected: categoryFilter == cat,
                      onSelected: (_) => onCategoryChanged(
                          categoryFilter == cat ? null : cat),
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Contact list
        Expanded(
          child: contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isNotEmpty
                            ? 'No matching contacts'
                            : 'No contacts yet',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first contact',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final now = DateTime.now();
                    final daysSince = contact.daysSinceLastContact(now);
                    final overdue = contact.isOverdue(now);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: overdue
                            ? Colors.red[100]
                            : Colors.blue[100],
                        child: Text(
                          contact.category.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      title: Text(
                        contact.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          contact.category.label,
                          if (contact.company != null) contact.company!,
                          if (daysSince != null)
                            '${daysSince}d ago'
                          else
                            'Never contacted',
                        ].join(' · '),
                        style: TextStyle(
                          color: overdue ? Colors.red[700] : null,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (overdue)
                            const Icon(Icons.warning_amber,
                                color: Colors.orange, size: 20),
                          if (contact.hasBirthdaySoon(now))
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text('🎂', style: TextStyle(fontSize: 16)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.add_comment, size: 20),
                            tooltip: 'Log interaction',
                            onPressed: () => _showLogInteractionDialog(
                                context, contact),
                          ),
                        ],
                      ),
                      onTap: () =>
                          _showContactDetail(context, contact),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showLogInteractionDialog(
      BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (ctx) => _LogInteractionDialog(
        service: service,
        contact: contact,
      ),
    ).then((result) {
      if (result == true) onChanged();
    });
  }

  void _showContactDetail(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContactDetailSheet(
        service: service,
        contact: contact,
        onChanged: onChanged,
      ),
    );
  }
}

// ─── FOLLOW-UPS TAB ─────────────────────────────────────────────────────────

class _FollowUpsTab extends StatelessWidget {
  final ContactTrackerService service;
  final VoidCallback onChanged;

  const _FollowUpsTab({required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final overdue = service.overdueContacts(now);
    final birthdays = service.upcomingBirthdays(now);

    if (overdue.isEmpty && birthdays.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text(
              'All caught up!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'No overdue follow-ups or upcoming birthdays',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdue.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.notification_important, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text(
                'Overdue Follow-ups (${overdue.length})',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...overdue.map((reminder) => Card(
                color: Colors.red[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Text(reminder.contact.category.emoji,
                        style: const TextStyle(fontSize: 16)),
                  ),
                  title: Text(
                    reminder.contact.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${reminder.daysOverdue}d overdue · '
                    'Urgency: ${reminder.urgencyScore.toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                  trailing: _urgencyBadge(reminder.urgencyScore),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => _LogInteractionDialog(
                        service: service,
                        contact: reminder.contact,
                      ),
                    ).then((result) {
                      if (result == true) onChanged();
                    });
                  },
                ),
              )),
          const SizedBox(height: 24),
        ],
        if (birthdays.isNotEmpty) ...[
          Row(
            children: [
              const Text('🎂', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Upcoming Birthdays (${birthdays.length})',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...birthdays.map((bday) => Card(
                color: Colors.purple[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    child: const Text('🎂',
                        style: TextStyle(fontSize: 18)),
                  ),
                  title: Text(
                    bday.contact.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'In ${bday.daysUntil} day${bday.daysUntil == 1 ? '' : 's'}'
                    '${bday.turningAge != null ? ' · Turning ${bday.turningAge}' : ''}',
                    style: TextStyle(color: Colors.purple[700], fontSize: 13),
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _urgencyBadge(double score) {
    Color color;
    if (score >= 70) {
      color = Colors.red;
    } else if (score >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.yellow[700]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        '${score.toStringAsFixed(0)}%',
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

// ─── HEALTH TAB ─────────────────────────────────────────────────────────────

class _HealthTab extends StatelessWidget {
  final ContactTrackerService service;

  const _HealthTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final health = service.networkHealth(now);
    final trends = service.interactionTrends();

    if (health.totalContacts == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Add contacts to see network health',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Health score card
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  health.grade,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _gradeColor(health.grade),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Network Health Score',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: health.healthScore / 100,
                  backgroundColor: Colors.grey[200],
                  color: _gradeColor(health.grade),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${health.healthScore.toStringAsFixed(1)} / 100',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            _StatCard(
              icon: Icons.people,
              label: 'Total',
              value: '${health.totalContacts}',
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _StatCard(
              icon: Icons.check_circle,
              label: 'On Track',
              value: '${health.activeContacts}',
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _StatCard(
              icon: Icons.warning,
              label: 'Overdue',
              value: '${health.overdueContacts}',
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            _StatCard(
              icon: Icons.person_off,
              label: 'Never',
              value: '${health.neverContacted}',
              color: Colors.grey,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Category breakdown
        if (health.categoryBreakdown.isNotEmpty) ...[
          const Text('By Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...health.categoryBreakdown.map((cs) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(cs.category.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${cs.category.label} (${cs.count})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (cs.overdueCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cs.overdueCount} overdue',
                          style: TextStyle(
                              fontSize: 11, color: Colors.red[700]),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '~${cs.avgDaysSinceContact.toStringAsFixed(0)}d avg',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )),
        ],

        // Interaction trends
        if (trends.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Interaction Trends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...trends.take(10).map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      t.trend == 'increasing'
                          ? Icons.trending_up
                          : t.trend == 'decreasing'
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      size: 18,
                      color: t.trend == 'increasing'
                          ? Colors.green
                          : t.trend == 'decreasing'
                              ? Colors.red
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t.contact.displayName,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    Text(
                      '${t.totalInteractions} interactions · ~${t.avgDaysBetween.toStringAsFixed(0)}d apart',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )),
        ],

        // Contact method distribution
        if (health.methodDistribution.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Contact Methods',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: health.methodDistribution.entries.map((e) {
              return Chip(
                avatar: Icon(_methodIcon(e.key), size: 16),
                label: Text('${e.key.label}: ${e.value}',
                    style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  IconData _methodIcon(ContactMethod method) {
    switch (method) {
      case ContactMethod.phone:
        return Icons.phone;
      case ContactMethod.email:
        return Icons.email;
      case ContactMethod.text:
        return Icons.chat;
      case ContactMethod.inPerson:
        return Icons.person;
      case ContactMethod.videoCall:
        return Icons.videocam;
      case ContactMethod.socialMedia:
        return Icons.share;
      case ContactMethod.other:
        return Icons.more_horiz;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ADD CONTACT DIALOG ─────────────────────────────────────────────────────

class _AddContactDialog extends StatefulWidget {
  final ContactTrackerService service;

  const _AddContactDialog({required this.service});

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  RelationshipCategory _category = RelationshipCategory.friend;
  ContactMethod _method = ContactMethod.text;
  ContactFrequency _frequency = ContactFrequency.monthly;
  DateTime? _birthday;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Contact'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Name *', prefixIcon: Icon(Icons.person)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nicknameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nickname',
                      prefixIcon: Icon(Icons.face)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RelationshipCategory>(
                  value: _category,
                  decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category)),
                  items: RelationshipCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.emoji} ${c.label}')))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ContactMethod>(
                  value: _method,
                  decoration: const InputDecoration(
                      labelText: 'Preferred Method',
                      prefixIcon: Icon(Icons.contact_phone)),
                  items: ContactMethod.values
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(m.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _method = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ContactFrequency>(
                  value: _frequency,
                  decoration: const InputDecoration(
                      labelText: 'Follow-up Frequency',
                      prefixIcon: Icon(Icons.schedule)),
                  items: ContactFrequency.values
                      .map((f) => DropdownMenuItem(
                          value: f, child: Text(f.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _companyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Company',
                      prefixIcon: Icon(Icons.business)),
                ),
                const SizedBox(height: 8),
                // Birthday picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake),
                  title: Text(_birthday != null
                      ? '${_birthday!.month}/${_birthday!.day}/${_birthday!.year}'
                      : 'Set birthday'),
                  trailing: _birthday != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _birthday = null),
                        )
                      : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _birthday ?? DateTime(1990, 1, 1),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _birthday = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.service.addContact(
              name: _nameCtrl.text,
              nickname: _nicknameCtrl.text.isEmpty
                  ? null
                  : _nicknameCtrl.text,
              category: _category,
              preferredMethod: _method,
              desiredFrequency: _frequency,
              email:
                  _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
              phone:
                  _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
              company: _companyCtrl.text.isEmpty
                  ? null
                  : _companyCtrl.text,
              notes:
                  _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
              birthday: _birthday,
            );
            Navigator.of(context).pop(true);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ─── LOG INTERACTION DIALOG ─────────────────────────────────────────────────

class _LogInteractionDialog extends StatefulWidget {
  final ContactTrackerService service;
  final Contact contact;

  const _LogInteractionDialog(
      {required this.service, required this.contact});

  @override
  State<_LogInteractionDialog> createState() =>
      _LogInteractionDialogState();
}

class _LogInteractionDialogState extends State<_LogInteractionDialog> {
  final _noteCtrl = TextEditingController();
  ContactMethod _method = ContactMethod.text;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _method = widget.contact.preferredMethod;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log Interaction with ${widget.contact.displayName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ContactMethod>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Method'),
              items: ContactMethod.values
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                  '${_date.month}/${_date.day}/${_date.year}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration:
                  const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.service.logInteraction(
              contactId: widget.contact.id,
              note: _noteCtrl.text.isEmpty ? 'Reached out' : _noteCtrl.text,
              method: _method,
              date: _date,
            );
            Navigator.of(context).pop(true);
          },
          child: const Text('Log'),
        ),
      ],
    );
  }
}

// ─── CONTACT DETAIL SHEET ───────────────────────────────────────────────────

class _ContactDetailSheet extends StatelessWidget {
  final ContactTrackerService service;
  final Contact contact;
  final VoidCallback onChanged;

  const _ContactDetailSheet({
    required this.service,
    required this.contact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysSince = contact.daysSinceLastContact(now);
    final daysUntilDue = contact.daysUntilDue(now);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue[100],
                  child: Text(contact.category.emoji,
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      if (contact.nickname != null)
                        Text('"${contact.nickname}"',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic)),
                      Text(
                        '${contact.category.label}'
                        '${contact.company != null ? ' · ${contact.company}' : ''}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Status info
            Row(
              children: [
                _InfoChip(
                  icon: Icons.schedule,
                  label: daysSince != null
                      ? '${daysSince}d since contact'
                      : 'Never contacted',
                  color: contact.isOverdue(now) ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                if (daysUntilDue != null)
                  _InfoChip(
                    icon: daysUntilDue <= 0
                        ? Icons.warning
                        : Icons.event,
                    label: daysUntilDue <= 0
                        ? 'Overdue!'
                        : 'Due in ${daysUntilDue}d',
                    color:
                        daysUntilDue <= 0 ? Colors.red : Colors.green,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Contact info
            if (contact.email != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.email, size: 20),
                title: Text(contact.email!),
              ),
            if (contact.phone != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.phone, size: 20),
                title: Text(contact.phone!),
              ),
            if (contact.birthday != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.cake, size: 20),
                title: Text(
                    '${contact.birthday!.month}/${contact.birthday!.day}/${contact.birthday!.year}'),
              ),
            if (contact.notes != null && contact.notes!.isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.notes, size: 20),
                title: Text(contact.notes!),
              ),

            // Interaction history
            const Divider(height: 24),
            Text(
              'Interaction History (${contact.interactions.length})',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (contact.interactions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No interactions logged yet',
                    style: TextStyle(color: Colors.grey[400])),
              )
            else
              ...contact.interactions.reversed.take(20).map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.blue[300]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i.date.month}/${i.date.day}/${i.date.year} · ${i.method.label}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500]),
                              ),
                              if (i.note.isNotEmpty)
                                Text(i.note,
                                    style:
                                        const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      service.archiveContact(contact.id);
                      onChanged();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.archive),
                    label: const Text('Archive'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => _LogInteractionDialog(
                          service: service,
                          contact: contact,
                        ),
                      ).then((result) {
                        if (result == true) {
                          onChanged();
                          Navigator.of(context).pop();
                        }
                      });
                    },
                    icon: const Icon(Icons.add_comment),
                    label: const Text('Log Interaction'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
