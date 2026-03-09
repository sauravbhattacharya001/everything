import 'package:flutter/material.dart';
import '../../core/services/pet_care_service.dart';
import '../../models/pet_entry.dart';

/// Pet Care Tracker — manage pets, log care activities, track health records,
/// and view insights about your pet care habits.
class PetCareTrackerScreen extends StatefulWidget {
  const PetCareTrackerScreen({super.key});

  @override
  State<PetCareTrackerScreen> createState() => _PetCareTrackerScreenState();
}

class _PetCareTrackerScreenState extends State<PetCareTrackerScreen>
    with SingleTickerProviderStateMixin {
  final PetCareService _service = const PetCareService();
  late TabController _tabController;

  final List<Pet> _pets = [];
  final List<CareEntry> _careEntries = [];
  final List<HealthRecord> _healthRecords = [];
  int _nextPetId = 1;
  int _nextCareId = 1;
  int _nextHealthId = 1;
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Pet? get _activePet {
    if (_selectedPetId == null || _pets.isEmpty) return null;
    return _pets.cast<Pet?>().firstWhere(
      (p) => p?.id == _selectedPetId,
      orElse: () => null,
    );
  }

  // ─── Pet Management ─────────────────────────────────────────

  void _addPet() {
    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    PetType selectedType = PetType.dog;
    DateTime? selectedBirthday;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Pet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    prefixIcon: Icon(Icons.pets),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PetType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: PetType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text('${t.emoji} ${t.label}'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Breed (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg, optional)',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedBirthday != null
                      ? 'Birthday: ${_formatDate(selectedBirthday!)}'
                      : 'Set birthday (optional)'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().subtract(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedBirthday = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
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
                final pet = Pet(
                  id: 'pet${_nextPetId++}',
                  name: nameCtrl.text.trim(),
                  type: selectedType,
                  breed: breedCtrl.text.trim().isEmpty ? null : breedCtrl.text.trim(),
                  birthday: selectedBirthday,
                  weightKg: double.tryParse(weightCtrl.text),
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                );
                setState(() {
                  _pets.add(pet);
                  _selectedPetId ??= pet.id;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _removePet(String petId) {
    setState(() {
      _pets.removeWhere((p) => p.id == petId);
      _careEntries.removeWhere((e) => e.petId == petId);
      _healthRecords.removeWhere((r) => r.petId == petId);
      if (_selectedPetId == petId) {
        _selectedPetId = _pets.isNotEmpty ? _pets.first.id : null;
      }
    });
  }

  // ─── Care Logging ───────────────────────────────────────────

  void _addCareEntry() {
    if (_activePet == null) return;
    CareCategory selectedCategory = CareCategory.feeding;
    PetMood? selectedMood;
    final noteCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Log Care for ${_activePet!.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CareCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Activity'),
                  items: CareCategory.values.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.emoji} ${c.label}'),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PetMood?>(
                  value: selectedMood,
                  decoration: const InputDecoration(labelText: 'Pet Mood (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Not set')),
                    ...PetMood.values.map((m) => DropdownMenuItem(
                      value: m,
                      child: Text('${m.emoji} ${m.label}'),
                    )),
                  ],
                  onChanged: (v) => setDialogState(() => selectedMood = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes, optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cost (\$, optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
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
                setState(() {
                  _careEntries.add(CareEntry(
                    id: 'care${_nextCareId++}',
                    petId: _activePet!.id,
                    timestamp: DateTime.now(),
                    category: selectedCategory,
                    note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                    durationMinutes: int.tryParse(durationCtrl.text),
                    mood: selectedMood,
                    cost: double.tryParse(costCtrl.text),
                  ));
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${selectedCategory.emoji} ${selectedCategory.label} logged for ${_activePet!.name}'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeCareEntry(int index, List<CareEntry> list) {
    final entry = list[index];
    final globalIndex = _careEntries.indexOf(entry);
    if (globalIndex < 0) return;
    setState(() => _careEntries.removeAt(globalIndex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${entry.category.label} entry'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => setState(() => _careEntries.insert(globalIndex, entry)),
        ),
      ),
    );
  }

  // ─── Health Records ─────────────────────────────────────────

  void _addHealthRecord() {
    if (_activePet == null) return;
    CareCategory selectedType = CareCategory.vetVisit;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    DateTime? nextDue;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Health Record for ${_activePet!.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CareCategory>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [CareCategory.vetVisit, CareCategory.vaccination, CareCategory.medication]
                      .map((c) => DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.label}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Weight (kg, optional)'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(nextDue != null
                      ? 'Next due: ${_formatDate(nextDue!)}'
                      : 'Set next due date (optional)'),
                  trailing: const Icon(Icons.event),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) setDialogState(() => nextDue = picked);
                  },
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
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  _healthRecords.add(HealthRecord(
                    id: 'health${_nextHealthId++}',
                    petId: _activePet!.id,
                    date: DateTime.now(),
                    type: selectedType,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    weightKg: double.tryParse(weightCtrl.text),
                    nextDue: nextDue,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

  String _formatDate(DateTime dt) =>
      '${dt.month}/${dt.day}/${dt.year}';

  String _formatDateTime(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pets), text: 'Pets'),
            Tab(icon: Icon(Icons.list_alt), text: 'Care Log'),
            Tab(icon: Icon(Icons.medical_services), text: 'Health'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPetsTab(theme),
          _buildCareLogTab(theme),
          _buildHealthTab(theme),
          _buildInsightsTab(theme),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton(
          onPressed: _addPet,
          tooltip: 'Add pet',
          child: const Icon(Icons.add),
        );
      case 1:
        return _activePet != null
            ? FloatingActionButton(
                onPressed: _addCareEntry,
                tooltip: 'Log care activity',
                child: const Icon(Icons.add),
              )
            : null;
      case 2:
        return _activePet != null
            ? FloatingActionButton(
                onPressed: _addHealthRecord,
                tooltip: 'Add health record',
                child: const Icon(Icons.add),
              )
            : null;
      default:
        return null;
    }
  }

  // ─── Pets Tab ───────────────────────────────────────────────

  Widget _buildPetsTab(ThemeData theme) {
    if (_pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No pets yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Tap + to add your first pet',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pets.length,
      itemBuilder: (ctx, i) {
        final pet = _pets[i];
        final isSelected = pet.id == _selectedPetId;
        final todayCount = _service.todayEntries(_careEntries, pet.id).length;
        return Card(
          elevation: isSelected ? 3 : 1,
          color: isSelected ? theme.colorScheme.primaryContainer : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              child: Text(pet.type.emoji, style: const TextStyle(fontSize: 24)),
            ),
            title: Text(pet.name,
                style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text([
              pet.type.label,
              if (pet.breed != null) pet.breed!,
              pet.ageLabel,
              if (pet.weightKg != null) '${pet.weightKg}kg',
            ].join(' · ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (todayCount > 0)
                  Chip(
                    label: Text('$todayCount today'),
                    visualDensity: VisualDensity.compact,
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removePet(pet.id),
                  tooltip: 'Remove ${pet.name}',
                ),
              ],
            ),
            onTap: () => setState(() => _selectedPetId = pet.id),
          ),
        );
      },
    );
  }

  // ─── Care Log Tab ───────────────────────────────────────────

  Widget _buildCareLogTab(ThemeData theme) {
    if (_activePet == null) {
      return _emptyState(theme, Icons.list_alt, 'Add a pet first');
    }
    final entries = _service.entriesForPet(_careEntries, _selectedPetId!);
    if (entries.isEmpty) {
      return _emptyState(theme, Icons.list_alt,
          'No care entries for ${_activePet!.name}\nTap + to log an activity');
    }

    // Pet selector + list
    return Column(
      children: [
        _buildPetSelector(theme),
        // Quick action chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _quickCareChip(CareCategory.feeding, theme),
              const SizedBox(width: 8),
              _quickCareChip(CareCategory.walking, theme),
              const SizedBox(width: 8),
              _quickCareChip(CareCategory.play, theme),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            itemBuilder: (ctx, i) {
              final entry = entries[i];
              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: theme.colorScheme.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _removeCareEntry(i, entries),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(entry.category.emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(entry.category.label),
                    subtitle: Text([
                      _formatDateTime(entry.timestamp),
                      if (entry.durationMinutes != null) '${entry.durationMinutes}min',
                      if (entry.mood != null) '${entry.mood!.emoji} ${entry.mood!.label}',
                      if (entry.cost != null) '\$${entry.cost!.toStringAsFixed(2)}',
                      if (entry.note != null) entry.note!,
                    ].join(' · ')),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quickCareChip(CareCategory category, ThemeData theme) {
    return ActionChip(
      avatar: Text(category.emoji),
      label: Text(category.label),
      onPressed: () {
        if (_activePet == null) return;
        setState(() {
          _careEntries.add(CareEntry(
            id: 'care${_nextCareId++}',
            petId: _activePet!.id,
            timestamp: DateTime.now(),
            category: category,
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.emoji} ${category.label} logged!'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  // ─── Health Tab ─────────────────────────────────────────────

  Widget _buildHealthTab(ThemeData theme) {
    if (_activePet == null) {
      return _emptyState(theme, Icons.medical_services, 'Add a pet first');
    }
    final records = _service.healthForPet(_healthRecords, _selectedPetId!);
    final overdue = _service.overdueRecords(_healthRecords, _selectedPetId!);
    final upcoming = _service.upcomingRecords(_healthRecords, _selectedPetId!);

    return Column(
      children: [
        _buildPetSelector(theme),
        // Alerts
        if (overdue.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${overdue.length} overdue: ${overdue.map((r) => r.title).join(", ")}',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
        if (upcoming.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${upcoming.length} due soon: ${upcoming.map((r) => r.title).join(", ")}',
                    style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: records.isEmpty
              ? _emptyState(theme, Icons.medical_services,
                  'No health records\nTap + to add one')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final r = records[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: r.isOverdue
                              ? theme.colorScheme.errorContainer
                              : r.isDueSoon
                                  ? theme.colorScheme.tertiaryContainer
                                  : null,
                          child: Text(r.type.emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(r.title),
                        subtitle: Text([
                          _formatDate(r.date),
                          if (r.description != null) r.description!,
                          if (r.weightKg != null) '${r.weightKg}kg',
                          if (r.nextDue != null) 'Next: ${_formatDate(r.nextDue!)}',
                          if (r.isOverdue) '⚠️ OVERDUE',
                        ].join(' · ')),
                        isThreeLine: r.description != null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Insights Tab ──────────────────────────────────────────

  Widget _buildInsightsTab(ThemeData theme) {
    if (_activePet == null) {
      return _emptyState(theme, Icons.insights, 'Add a pet first');
    }
    final pet = _activePet!;
    final streak = _service.careStreak(_careEntries, pet.id);
    final avgDaily = _service.avgDailyCare(_careEntries, pet.id);
    final totalSpent = _service.totalCost(_careEntries, pet.id);
    final lastFed = _service.lastFeeding(_careEntries, pet.id);
    final lastWalked = _service.lastWalk(_careEntries, pet.id);
    final categoryMap = _service.categoryBreakdown(_careEntries, pet.id);
    final moodMap = _service.moodDistribution(_careEntries, pet.id);
    final weekly = _service.weeklySummary(_careEntries, pet.id);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPetSelector(theme),
          const SizedBox(height: 8),
          // Summary cards
          Row(
            children: [
              Expanded(child: _statCard(theme, '🔥', 'Streak', '$streak days')),
              const SizedBox(width: 8),
              Expanded(child: _statCard(theme, '📊', 'Avg/Day', avgDaily.toStringAsFixed(1))),
              const SizedBox(width: 8),
              Expanded(child: _statCard(theme, '💰', 'Spent', '\$${totalSpent.toStringAsFixed(0)}')),
            ],
          ),
          const SizedBox(height: 16),
          // Last fed / walked
          if (lastFed != null || lastWalked != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Status', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (lastFed != null)
                      Text('🍖 Last fed: ${_timeAgo(lastFed)}'),
                    if (lastWalked != null)
                      Text('🦮 Last walk: ${_timeAgo(lastWalked)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Weekly bar chart
          if (weekly.any((v) => v > 0)) ...[
            Text('Last 7 Days', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final max = weekly.reduce((a, b) => a > b ? a : b);
                  final height = max > 0 ? (weekly[i] / max) * 80 : 0.0;
                  final now = DateTime.now();
                  final day = now.subtract(Duration(days: 6 - i));
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${weekly[i]}',
                            style: theme.textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Container(
                          height: height,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(weekdays[day.weekday - 1],
                            style: theme.textTheme.labelSmall),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Category breakdown
          if (categoryMap.isNotEmpty) ...[
            Text('Activity Breakdown', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...(categoryMap.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
              .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${e.key.emoji} ${e.key.label}'),
                    const Spacer(),
                    Text('${e.value}', style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
              )),
            const SizedBox(height: 16),
          ],
          // Mood distribution
          if (moodMap.isNotEmpty) ...[
            Text('Mood Observations', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: moodMap.entries.map((e) => Chip(
                avatar: Text(e.key.emoji),
                label: Text('${e.key.label}: ${e.value}'),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Shared Widgets ─────────────────────────────────────────

  Widget _buildPetSelector(ThemeData theme) {
    if (_pets.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<String>(
        segments: _pets.map((p) => ButtonSegment(
          value: p.id,
          label: Text(p.name),
          icon: Text(p.type.emoji),
        )).toList(),
        selected: {_selectedPetId ?? ''},
        onSelectionChanged: (sel) => setState(() => _selectedPetId = sel.first),
      ),
    );
  }

  Widget _statCard(ThemeData theme, String emoji, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}
