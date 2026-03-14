import 'package:flutter/material.dart';
import '../../core/services/plant_care_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/plant_entry.dart';

/// Plant Care Tracker - manage plants, log care activities, track watering
/// schedules, monitor health, and view garden insights.
class PlantCareTrackerScreen extends StatefulWidget {
  const PlantCareTrackerScreen({super.key});

  @override
  State<PlantCareTrackerScreen> createState() => _PlantCareTrackerScreenState();
}

class _PlantCareTrackerScreenState extends State<PlantCareTrackerScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'plant_care_data';
  @override
  String exportData() => _service.export();
  @override
  void importData(String json) => _service.import(json);

  final PlantCareService _service = PlantCareService();
  late TabController _tabController;
  String? _selectedPlantId;
  String _searchQuery = '';
  PlantType? _filterType;
  bool _showArchived = false;

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

  PlantProfile? get _activePlant {
    if (_selectedPlantId == null) return null;
    return _service.getPlant(_selectedPlantId!);
  }

  List<PlantProfile> get _filteredPlants {
    var plants = _showArchived ? _service.archivedPlants : _service.activePlants;
    if (_filterType != null) {
      plants = plants.where((p) => p.type == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      plants = plants
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q) ||
              p.type.label.toLowerCase().contains(q))
          .toList();
    }
    return plants;
  }

  // ─── Plant Management ─────────────────────────────────────

  void _addPlant() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final intervalCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    PlantType selectedType = PlantType.other;
    SunlightLevel selectedSunlight = SunlightLevel.indirect;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Plant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Plant Name *',
                    prefixIcon: Icon(Icons.local_florist),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PlantType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: PlantType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.emoji} ${t.label}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      selectedType = v!;
                      if (intervalCtrl.text.isEmpty) {
                        intervalCtrl.text = v.defaultWateringDays.toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SunlightLevel>(
                  value: selectedSunlight,
                  decoration: const InputDecoration(labelText: 'Sunlight'),
                  items: SunlightLevel.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.emoji} ${s.label}'),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedSunlight = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location (e.g. Living Room)',
                    prefixIcon: Icon(Icons.room),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: intervalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Watering interval (days)',
                    hintText: '${selectedType.defaultWateringDays}',
                    prefixIcon: const Icon(Icons.water_drop),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.note),
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
                setState(() {
                  final plant = _service.addPlant(
                    name: nameCtrl.text,
                    type: selectedType,
                    sunlight: selectedSunlight,
                    location: locationCtrl.text,
                    wateringIntervalDays: int.tryParse(intervalCtrl.text),
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                  );
                  _selectedPlantId ??= plant.id;
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

  void _logCare(PlantProfile plant) {
    PlantCareAction selectedAction = PlantCareAction.watering;
    PlantHealth? selectedHealth;
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Care for ${plant.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick action chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PlantCareAction.values.map((a) {
                    return ChoiceChip(
                      label: Text('${a.emoji} ${a.label}'),
                      selected: selectedAction == a,
                      onSelected: (s) =>
                          setDialogState(() => selectedAction = a),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Health observation
                const Text('Health Observed (optional):',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Skip'),
                      selected: selectedHealth == null,
                      onSelected: (s) =>
                          setDialogState(() => selectedHealth = null),
                    ),
                    ...PlantHealth.values.map((h) => ChoiceChip(
                          label: Text('${h.emoji} ${h.label}'),
                          selected: selectedHealth == h,
                          onSelected: (s) =>
                              setDialogState(() => selectedHealth = h),
                        )),
                  ],
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
                setState(() {
                  _service.logCare(
                    plantId: plant.id,
                    action: selectedAction,
                    healthObserved: selectedHealth,
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌱 Plant Care'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.local_florist), text: 'Plants'),
            Tab(icon: Icon(Icons.water_drop), text: 'Schedule'),
            Tab(icon: Icon(Icons.history), text: 'Care Log'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.inventory_2 : Icons.inventory_2_outlined),
            onPressed: () => setState(() => _showArchived = !_showArchived),
            tooltip: _showArchived ? 'Show active' : 'Show archived',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlant,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlantsTab(),
          _buildScheduleTab(),
          _buildCareLogTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  // ─── Tab 1: Plants ────────────────────────────────────────

  Widget _buildPlantsTab() {
    final plants = _filteredPlants;

    return Column(
      children: [
        // Search + filter
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search plants...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<PlantType?>(
                icon: Badge(
                  isLabelVisible: _filterType != null,
                  child: const Icon(Icons.filter_list),
                ),
                onSelected: (v) => setState(() => _filterType = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All Types')),
                  ...PlantType.values.map((t) => PopupMenuItem(
                        value: t,
                        child: Text('${t.emoji} ${t.label}'),
                      )),
                ],
              ),
            ],
          ),
        ),
        // Summary strip
        if (_service.activePlants.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryChip('🌿', '${_service.activePlants.length}', 'Plants'),
                _summaryChip('💧', '${_service.getOverduePlants().length}', 'Overdue'),
                _summaryChip('🔥', '${_service.getGardenCareStreak()}', 'Streak'),
              ],
            ),
          ),
        // Plant list
        Expanded(
          child: plants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_florist, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        _showArchived ? 'No archived plants' : 'Add your first plant!',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: plants.length,
                  itemBuilder: (ctx, i) => _buildPlantCard(plants[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildPlantCard(PlantProfile plant) {
    final lastHealth = _service.getLastHealth(plant.id);
    final overdue = _service.isOverdue(plant.id);
    final overdueDays = _service.overdueDays(plant.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: overdue
          ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.3)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          child: Text(plant.type.emoji, style: const TextStyle(fontSize: 24)),
        ),
        title: Row(
          children: [
            Flexible(child: Text(plant.name)),
            if (lastHealth != null) ...[
              const SizedBox(width: 6),
              Text(lastHealth.emoji, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
        subtitle: Text(
          [
            plant.type.label,
            if (plant.location.isNotEmpty) plant.location,
            '${plant.sunlight.emoji} ${plant.sunlight.label}',
            if (overdue) '⚠️ ${overdueDays}d overdue',
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick water button
            IconButton(
              icon: const Icon(Icons.water_drop, color: Colors.blue),
              onPressed: () => setState(() {
                _service.logCare(
                  plantId: plant.id,
                  action: PlantCareAction.watering,
                );
              }),
              tooltip: 'Quick water',
            ),
            // Full care log
            IconButton(
              icon: const Icon(Icons.add_task),
              onPressed: () => _logCare(plant),
              tooltip: 'Log care',
            ),
          ],
        ),
        onTap: () => _showPlantDetail(plant),
        onLongPress: () => _showPlantActions(plant),
      ),
    );
  }

  void _showPlantDetail(PlantProfile plant) {
    final summary = _service.getPlantSummary(plant.id);
    final recentCare = _service.getCareLog(plant.id, limit: 10);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Center(
              child: Text(plant.type.emoji,
                  style: const TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(plant.name,
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            if (plant.notes != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(plant.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
              ),
            const SizedBox(height: 16),
            // Stats grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard('Type', plant.type.label),
                _statCard('Light', plant.sunlight.label),
                _statCard('Water', 'Every ${plant.wateringIntervalDays}d'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard('Health',
                    summary.lastHealth?.label ?? 'Unknown'),
                _statCard('Streak', '${summary.careStreak} days'),
                _statCard('Actions', '${summary.totalCareActions}'),
              ],
            ),
            const SizedBox(height: 16),
            if (summary.isOverdue)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠️ Overdue by ${summary.overdueDays} days!',
                  style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 16),
            // Care action breakdown
            if (summary.actionCounts.isNotEmpty) ...[
              Text('Care Breakdown',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.actionCounts.entries.map((e) {
                  return Chip(
                    avatar: Text(e.key.emoji),
                    label: Text('${e.key.label}: ${e.value}'),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Recent care log
            Text('Recent Care',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (recentCare.isEmpty)
              const Text('No care logged yet')
            else
              ...recentCare.map((e) => ListTile(
                    dense: true,
                    leading: Text(e.action.emoji,
                        style: const TextStyle(fontSize: 20)),
                    title: Text(e.action.label),
                    subtitle: Text(_formatDate(e.timestamp)),
                    trailing: e.healthObserved != null
                        ? Text(e.healthObserved!.emoji)
                        : null,
                  )),
          ],
        ),
      ),
    );
  }

  void _showPlantActions(PlantProfile plant) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Plant'),
              onTap: () {
                Navigator.pop(ctx);
                _editPlant(plant);
              },
            ),
            ListTile(
              leading: Icon(plant.isArchived
                  ? Icons.unarchive
                  : Icons.archive),
              title: Text(plant.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                setState(() {
                  _service.updatePlant(plant.id,
                      isArchived: !plant.isArchived);
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                setState(() {
                  _service.removePlant(plant.id);
                  if (_selectedPlantId == plant.id) {
                    _selectedPlantId = null;
                  }
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editPlant(PlantProfile plant) {
    final nameCtrl = TextEditingController(text: plant.name);
    final locationCtrl = TextEditingController(text: plant.location);
    final intervalCtrl =
        TextEditingController(text: plant.wateringIntervalDays.toString());
    final notesCtrl = TextEditingController(text: plant.notes ?? '');
    PlantType selectedType = plant.type;
    SunlightLevel selectedSunlight = plant.sunlight;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Plant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PlantType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: PlantType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text('${t.emoji} ${t.label}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SunlightLevel>(
                  value: selectedSunlight,
                  decoration: const InputDecoration(labelText: 'Sunlight'),
                  items: SunlightLevel.values
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text('${s.emoji} ${s.label}')))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedSunlight = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: intervalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Watering interval (days)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _service.updatePlant(
                    plant.id,
                    name: nameCtrl.text,
                    type: selectedType,
                    sunlight: selectedSunlight,
                    location: locationCtrl.text,
                    wateringIntervalDays: int.tryParse(intervalCtrl.text),
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                  );
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

  // ─── Tab 2: Schedule ──────────────────────────────────────

  Widget _buildScheduleTab() {
    final overdue = _service.getOverduePlants();
    final upcoming = _service.getPlantsNeedingWaterSoon(withinDays: 3)
        .where((p) => !overdue.any((o) => o.id == p.id))
        .toList();
    final allOk = _service.activePlants
        .where((p) =>
            !overdue.any((o) => o.id == p.id) &&
            !upcoming.any((u) => u.id == p.id))
        .toList();

    if (_service.activePlants.isEmpty) {
      return const Center(
        child: Text('Add plants to see watering schedule'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (overdue.isNotEmpty) ...[
          _sectionHeader('⚠️ Overdue', Colors.red),
          ...overdue.map((p) => _scheduleCard(p, isOverdue: true)),
          const SizedBox(height: 16),
        ],
        if (upcoming.isNotEmpty) ...[
          _sectionHeader('📅 Water Soon', Colors.orange),
          ...upcoming.map((p) => _scheduleCard(p, isOverdue: false)),
          const SizedBox(height: 16),
        ],
        if (allOk.isNotEmpty) ...[
          _sectionHeader('✅ All Good', Colors.green),
          ...allOk.map((p) => _scheduleCard(p, isOverdue: false)),
        ],
      ],
    );
  }

  Widget _scheduleCard(PlantProfile plant, {required bool isOverdue}) {
    final next = _service.getNextWatering(plant.id);
    final lastWatered = _service.getLastWatered(plant.id);
    final days = _service.overdueDays(plant.id);

    return Card(
      child: ListTile(
        leading: Text(plant.type.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(plant.name),
        subtitle: Text(
          lastWatered != null
              ? 'Last watered: ${_formatDate(lastWatered)}'
              : 'Never watered',
        ),
        trailing: isOverdue
            ? Chip(
                label: Text('${days}d late',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.red,
              )
            : next != null
                ? Text(_formatDate(next),
                    style: const TextStyle(color: Colors.grey))
                : null,
        onTap: () => setState(() {
          _service.logCare(
              plantId: plant.id, action: PlantCareAction.watering);
        }),
      ),
    );
  }

  // ─── Tab 3: Care Log ──────────────────────────────────────

  Widget _buildCareLogTab() {
    final allEntries = _service.careLog.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (allEntries.isEmpty) {
      return const Center(child: Text('No care activities logged yet'));
    }

    return ListView.builder(
      itemCount: allEntries.length,
      itemBuilder: (ctx, i) {
        final entry = allEntries[i];
        final plant = _service.getPlant(entry.plantId);
        return Dismissible(
          key: Key(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => setState(() {
            _service.removeCareEntry(entry.id);
          }),
          child: ListTile(
            leading: Text(entry.action.emoji,
                style: const TextStyle(fontSize: 24)),
            title: Text(
              '${entry.action.label} - ${plant?.name ?? "Unknown"}',
            ),
            subtitle: Text([
              _formatDate(entry.timestamp),
              if (entry.healthObserved != null)
                'Health: ${entry.healthObserved!.emoji} ${entry.healthObserved!.label}',
              if (entry.notes != null) entry.notes!,
            ].join(' · ')),
          ),
        );
      },
    );
  }

  // ─── Tab 4: Insights ──────────────────────────────────────

  Widget _buildInsightsTab() {
    final summary = _service.getGardenSummary();
    final recommendations = _service.getRecommendations();

    if (_service.plants.isEmpty) {
      return const Center(child: Text('Add plants to see insights'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Health score
        Center(
          child: Column(
            children: [
              Text(
                summary.healthGrade,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: _gradeColor(summary.healthGrade),
                ),
              ),
              Text('Garden Health',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${summary.overallHealthScore.toStringAsFixed(0)}/100'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Stats grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statCard('Active', '${summary.activePlants}'),
            _statCard('Overdue', '${summary.overduePlants}'),
            _statCard('Streak', '${summary.careStreak}d'),
            _statCard('Actions', '${summary.totalCareActions}'),
          ],
        ),
        const SizedBox(height: 24),
        // Plant type breakdown
        if (summary.byType.isNotEmpty) ...[
          Text('By Type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summary.byType.entries.map((e) {
              return Chip(
                avatar: Text(e.key.emoji),
                label: Text('${e.key.label}: ${e.value}'),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        // Location breakdown
        if (summary.byLocation.isNotEmpty) ...[
          Text('By Location', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summary.byLocation.entries.map((e) {
              return Chip(
                avatar: const Icon(Icons.room, size: 16),
                label: Text('${e.key}: ${e.value}'),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),
        // Recommendations
        if (recommendations.isNotEmpty) ...[
          Text('Recommendations',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...recommendations.map((tip) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(tip),
                ),
              )),
        ],
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────

  Widget _summaryChip(String emoji, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$emoji $value',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: color)),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.lightGreen;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      default: return Colors.red;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
