import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/emergency_profile.dart';
import '../../core/services/emergency_card_service.dart';

/// Emergency Card Screen — 4-tab UI for managing emergency medical information.
///
/// Tabs:
///   Profile: Personal info (name, DOB, blood type, address, language, organ donor)
///   Contacts: Emergency contacts with add/edit/delete and priority ordering
///   Medical: Allergies, conditions, medications, insurance policies
///   Card: Read-only emergency card view with completeness score and share text
class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key});

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'emergency_card_profile';
  late TabController _tabController;
  final _service = const EmergencyCardService();

  EmergencyProfile _profile = EmergencyProfile(fullName: '');

  // Profile form controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _languageController = TextEditingController();
  final _instructionsController = TextEditingController();
  DateTime? _selectedDob;
  BloodType _selectedBloodType = BloodType.unknown;
  bool _isOrganDonor = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null && data.isNotEmpty) {
      final parsed = EmergencyProfile.fromJsonString(data);
      if (parsed != null) {
        setState(() {
          _profile = parsed;
          _syncFormFromProfile();
        });
      }
    }
  }

  void _syncFormFromProfile() {
    _nameController.text = _profile.fullName;
    _addressController.text = _profile.address ?? '';
    _languageController.text = _profile.primaryLanguage ?? '';
    _instructionsController.text = _profile.specialInstructions ?? '';
    _selectedDob = _profile.dateOfBirth;
    _selectedBloodType = _profile.bloodType;
    _isOrganDonor = _profile.isOrganDonor;
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _profile.toJsonString());
  }

  void _updateProfile(EmergencyProfile updated) {
    setState(() => _profile = updated);
    _saveProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _languageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  // ─── Profile Tab ──────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Completeness indicator
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Profile Completeness',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Text('${_profile.completenessScore}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _completenessColor,
                            )),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _profile.completenessScore / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: _completenessColor,
                ),
                const SizedBox(height: 4),
                Text(_profile.completenessLabel,
                    style: TextStyle(color: _completenessColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Name
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _updateProfile(_profile.copyWith(fullName: v)),
        ),
        const SizedBox(height: 12),

        // Date of Birth
        ListTile(
          leading: const Icon(Icons.cake),
          title: Text(_selectedDob != null
              ? '${_selectedDob!.month}/${_selectedDob!.day}/${_selectedDob!.year}'
              : 'Date of Birth'),
          subtitle: _profile.age != null ? Text('Age: ${_profile.age}') : null,
          trailing: const Icon(Icons.calendar_today),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDob ?? DateTime(1990),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              _selectedDob = picked;
              _updateProfile(_profile.copyWith(dateOfBirth: picked));
            }
          },
        ),
        const SizedBox(height: 12),

        // Blood Type
        DropdownButtonFormField<BloodType>(
          value: _selectedBloodType,
          decoration: const InputDecoration(
            labelText: 'Blood Type',
            prefixIcon: Icon(Icons.bloodtype),
            border: OutlineInputBorder(),
          ),
          items: BloodType.values
              .map((bt) => DropdownMenuItem(
                    value: bt,
                    child: Text('${bt.emoji} ${bt.label}'),
                  ))
              .toList(),
          onChanged: (bt) {
            if (bt != null) {
              _selectedBloodType = bt;
              _updateProfile(_profile.copyWith(bloodType: bt));
            }
          },
        ),
        const SizedBox(height: 12),

        // Address
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Home Address',
            prefixIcon: Icon(Icons.home),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (v) => _updateProfile(_profile.copyWith(address: v)),
        ),
        const SizedBox(height: 12),

        // Language
        TextField(
          controller: _languageController,
          decoration: const InputDecoration(
            labelText: 'Primary Language',
            prefixIcon: Icon(Icons.language),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) =>
              _updateProfile(_profile.copyWith(primaryLanguage: v)),
        ),
        const SizedBox(height: 12),

        // Organ Donor
        SwitchListTile(
          title: const Text('Organ Donor'),
          subtitle: const Text('I am a registered organ donor'),
          secondary: const Icon(Icons.favorite),
          value: _isOrganDonor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          onChanged: (v) {
            _isOrganDonor = v;
            _updateProfile(_profile.copyWith(isOrganDonor: v));
          },
        ),
        const SizedBox(height: 12),

        // Special Instructions
        TextField(
          controller: _instructionsController,
          decoration: const InputDecoration(
            labelText: 'Special Instructions',
            prefixIcon: Icon(Icons.warning_amber),
            border: OutlineInputBorder(),
            hintText: 'e.g. DNR, religious considerations...',
          ),
          maxLines: 3,
          onChanged: (v) =>
              _updateProfile(_profile.copyWith(specialInstructions: v)),
        ),
      ],
    );
  }

  Color get _completenessColor {
    final s = _profile.completenessScore;
    if (s >= 80) return Colors.green;
    if (s >= 50) return Colors.orange;
    return Colors.red;
  }

  // ─── Contacts Tab ─────────────────────────────────────────────────────────

  Widget _buildContactsTab() {
    final sorted = _service.contactsByPriority(_profile);
    return Column(
      children: [
        // Add button
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Emergency Contact'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
          ),
        ),
        if (sorted.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.contacts, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No emergency contacts yet',
                      style: TextStyle(color: Colors.grey)),
                  Text('Add at least one contact for safety',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (ctx, i) {
                final contact = sorted[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(contact.relationship.emoji),
                    ),
                    title: Row(
                      children: [
                        Text(contact.name),
                        if (contact.isPrimary) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Primary',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.blue)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📞 ${contact.phone}'),
                        Text(contact.relationship.label,
                            style: const TextStyle(fontSize: 12)),
                        if (contact.email != null)
                          Text('✉️ ${contact.email}',
                              style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'primary') {
                          _setPrimaryContact(contact.id);
                        } else if (action == 'delete') {
                          _deleteContact(contact.id);
                        }
                      },
                      itemBuilder: (_) => [
                        if (!contact.isPrimary)
                          const PopupMenuItem(
                            value: 'primary',
                            child: Text('Set as Primary'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child:
                              Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _setPrimaryContact(String id) {
    final updated = _profile.contacts.map((c) {
      return c.copyWith(isPrimary: c.id == id);
    }).toList();
    _updateProfile(_profile.copyWith(contacts: updated));
  }

  void _deleteContact(String id) {
    final updated =
        _profile.contacts.where((c) => c.id != id).toList();
    _updateProfile(_profile.copyWith(contacts: updated));
  }

  void _showAddContactDialog() {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final emailC = TextEditingController();
    final notesC = TextEditingController();
    var relationship = ContactRelationship.friend;
    var isPrimary = _profile.contacts.isEmpty; // auto-primary if first

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneC,
                  decoration: const InputDecoration(
                    labelText: 'Phone *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailC,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ContactRelationship>(
                  value: relationship,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                  ),
                  items: ContactRelationship.values
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text('${r.emoji} ${r.label}'),
                          ))
                      .toList(),
                  onChanged: (r) {
                    if (r != null) {
                      setDialogState(() => relationship = r);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesC,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                CheckboxListTile(
                  title: const Text('Primary Contact'),
                  value: isPrimary,
                  onChanged: (v) =>
                      setDialogState(() => isPrimary = v ?? false),
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
                if (nameC.text.trim().isEmpty || phoneC.text.trim().isEmpty) {
                  return;
                }
                final contact = EmergencyContact(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameC.text.trim(),
                  phone: phoneC.text.trim(),
                  email: emailC.text.trim().isEmpty
                      ? null
                      : emailC.text.trim(),
                  relationship: relationship,
                  isPrimary: isPrimary,
                  notes: notesC.text.trim().isEmpty
                      ? null
                      : notesC.text.trim(),
                );
                var contacts = List<EmergencyContact>.from(_profile.contacts);
                if (isPrimary) {
                  contacts = contacts
                      .map((c) => c.copyWith(isPrimary: false))
                      .toList();
                }
                contacts.add(contact);
                _updateProfile(_profile.copyWith(contacts: contacts));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Medical Tab ──────────────────────────────────────────────────────────

  Widget _buildMedicalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Allergies section
        _buildSectionHeader('Allergies', Icons.warning_amber, Colors.orange,
            onAdd: _showAddAllergyDialog),
        if (_profile.allergies.isEmpty)
          const _EmptyHint(text: 'No allergies recorded')
        else
          ..._profile.allergies.map(_buildAllergyTile),
        const Divider(height: 32),

        // Medical conditions section
        _buildSectionHeader('Medical Conditions', Icons.medical_services,
            Colors.red,
            onAdd: _showAddConditionDialog),
        if (_profile.conditions.isEmpty)
          const _EmptyHint(text: 'No conditions recorded')
        else
          ..._profile.conditions.map(_buildConditionTile),
        const Divider(height: 32),

        // Medications section
        _buildSectionHeader(
            'Current Medications', Icons.medication, Colors.blue,
            onAdd: _showAddMedicationDialog),
        if (_profile.currentMedications.isEmpty)
          const _EmptyHint(text: 'No medications recorded')
        else
          ..._profile.currentMedications.asMap().entries.map((e) =>
              ListTile(
                leading: const Icon(Icons.medication, color: Colors.blue),
                title: Text(e.value),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    final meds =
                        List<String>.from(_profile.currentMedications);
                    meds.removeAt(e.key);
                    _updateProfile(
                        _profile.copyWith(currentMedications: meds));
                  },
                ),
              )),
        const Divider(height: 32),

        // Insurance section
        _buildSectionHeader(
            'Insurance Policies', Icons.shield, Colors.teal,
            onAdd: _showAddInsuranceDialog),
        if (_profile.insurancePolicies.isEmpty)
          const _EmptyHint(text: 'No insurance policies recorded')
        else
          ..._profile.insurancePolicies.map(_buildInsuranceTile),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color,
      {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
              color: color,
            ),
        ],
      ),
    );
  }

  Widget _buildAllergyTile(Allergy allergy) {
    return Card(
      child: ListTile(
        leading: Text(allergy.severity.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(allergy.allergen),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Severity: ${allergy.severity.label}'),
            if (allergy.reaction != null) Text('Reaction: ${allergy.reaction}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            final updated =
                _profile.allergies.where((a) => a.id != allergy.id).toList();
            _updateProfile(_profile.copyWith(allergies: updated));
          },
        ),
      ),
    );
  }

  Widget _buildConditionTile(MedicalCondition condition) {
    return Card(
      child: ListTile(
        leading:
            Text(condition.severity.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(condition.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Severity: ${condition.severity.label}'),
            if (condition.treatingDoctor != null)
              Text('Doctor: ${condition.treatingDoctor}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            final updated = _profile.conditions
                .where((c) => c.id != condition.id)
                .toList();
            _updateProfile(_profile.copyWith(conditions: updated));
          },
        ),
      ),
    );
  }

  Widget _buildInsuranceTile(InsurancePolicy policy) {
    return Card(
      child: ListTile(
        leading: Text(policy.type.emoji, style: const TextStyle(fontSize: 24)),
        title: Text('${policy.type.label} — ${policy.provider}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Policy: ${policy.policyNumber}'),
            if (policy.memberId != null) Text('Member ID: ${policy.memberId}'),
            if (policy.isExpired)
              const Text('⚠️ EXPIRED',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            final updated = _profile.insurancePolicies
                .where((p) => p.id != policy.id)
                .toList();
            _updateProfile(_profile.copyWith(insurancePolicies: updated));
          },
        ),
      ),
    );
  }

  void _showAddAllergyDialog() {
    final allergenC = TextEditingController();
    final reactionC = TextEditingController();
    var severity = AllergySeverity.moderate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Allergy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: allergenC,
                decoration: const InputDecoration(
                  labelText: 'Allergen *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AllergySeverity>(
                value: severity,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                items: AllergySeverity.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.emoji} ${s.label}'),
                        ))
                    .toList(),
                onChanged: (s) {
                  if (s != null) setDialogState(() => severity = s);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reactionC,
                decoration: const InputDecoration(
                  labelText: 'Reaction',
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
                if (allergenC.text.trim().isEmpty) return;
                final allergy = Allergy(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  allergen: allergenC.text.trim(),
                  severity: severity,
                  reaction: reactionC.text.trim().isEmpty
                      ? null
                      : reactionC.text.trim(),
                );
                final list = List<Allergy>.from(_profile.allergies)
                  ..add(allergy);
                _updateProfile(_profile.copyWith(allergies: list));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddConditionDialog() {
    final nameC = TextEditingController();
    final doctorC = TextEditingController();
    var severity = ConditionSeverity.moderate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Medical Condition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: 'Condition *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ConditionSeverity>(
                value: severity,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                items: ConditionSeverity.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.emoji} ${s.label}'),
                        ))
                    .toList(),
                onChanged: (s) {
                  if (s != null) setDialogState(() => severity = s);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: doctorC,
                decoration: const InputDecoration(
                  labelText: 'Treating Doctor',
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
                if (nameC.text.trim().isEmpty) return;
                final condition = MedicalCondition(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameC.text.trim(),
                  severity: severity,
                  treatingDoctor: doctorC.text.trim().isEmpty
                      ? null
                      : doctorC.text.trim(),
                );
                final list = List<MedicalCondition>.from(_profile.conditions)
                  ..add(condition);
                _updateProfile(_profile.copyWith(conditions: list));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMedicationDialog() {
    final medC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Medication'),
        content: TextField(
          controller: medC,
          decoration: const InputDecoration(
            labelText: 'Medication name *',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (medC.text.trim().isEmpty) return;
              final meds = List<String>.from(_profile.currentMedications)
                ..add(medC.text.trim());
              _updateProfile(_profile.copyWith(currentMedications: meds));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddInsuranceDialog() {
    final providerC = TextEditingController();
    final policyC = TextEditingController();
    final memberC = TextEditingController();
    final phoneC = TextEditingController();
    var type = InsuranceType.health;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Insurance Policy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<InsuranceType>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: InsuranceType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.emoji} ${t.label}'),
                          ))
                      .toList(),
                  onChanged: (t) {
                    if (t != null) setDialogState(() => type = t);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: providerC,
                  decoration: const InputDecoration(
                    labelText: 'Provider *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: policyC,
                  decoration: const InputDecoration(
                    labelText: 'Policy Number *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: memberC,
                  decoration: const InputDecoration(
                    labelText: 'Member ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneC,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
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
                if (providerC.text.trim().isEmpty ||
                    policyC.text.trim().isEmpty) return;
                final policy = InsurancePolicy(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: type,
                  provider: providerC.text.trim(),
                  policyNumber: policyC.text.trim(),
                  memberId: memberC.text.trim().isEmpty
                      ? null
                      : memberC.text.trim(),
                  phone: phoneC.text.trim().isEmpty
                      ? null
                      : phoneC.text.trim(),
                );
                final list =
                    List<InsurancePolicy>.from(_profile.insurancePolicies)
                      ..add(policy);
                _updateProfile(_profile.copyWith(insurancePolicies: list));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Card Tab ─────────────────────────────────────────────────────────────

  Widget _buildCardTab() {
    final text = _service.generateTextCard(_profile);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Emergency card preview
        Card(
          color: Colors.red.shade50,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emergency, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EMERGENCY MEDICAL CARD',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              )),
                          if (_profile.fullName.isNotEmpty)
                            Text(_profile.fullName,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Quick facts row
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (_profile.bloodType != BloodType.unknown)
                      _buildCardChip(
                          '🩸 ${_profile.bloodType.label}', Colors.red),
                    if (_profile.age != null)
                      _buildCardChip('🎂 Age ${_profile.age}', Colors.blue),
                    if (_profile.isOrganDonor)
                      _buildCardChip('❤️ Organ Donor', Colors.pink),
                  ],
                ),

                // Critical allergies
                if (_profile.allergies.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('⚠️ ALLERGIES',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 4),
                  ..._profile.allergies.map((a) => Text(
                      '  ${a.severity.emoji} ${a.allergen}'
                      '${a.reaction != null ? ' — ${a.reaction}' : ''}')),
                ],

                // Conditions
                if (_profile.conditions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('🏥 CONDITIONS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  ..._profile.conditions.map((c) =>
                      Text('  ${c.severity.emoji} ${c.name}')),
                ],

                // Medications
                if (_profile.currentMedications.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('💊 MEDICATIONS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 4),
                  ..._profile.currentMedications
                      .map((m) => Text('  • $m')),
                ],

                // Primary contact
                if (_profile.primaryContact != null) ...[
                  const SizedBox(height: 16),
                  const Text('📞 EMERGENCY CONTACT',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  Text(
                      '  ${_profile.primaryContact!.name} (${_profile.primaryContact!.relationship.label})'),
                  Text('  ${_profile.primaryContact!.phone}'),
                ],

                // Special instructions
                if (_profile.specialInstructions != null &&
                    _profile.specialInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('⚡ SPECIAL INSTRUCTIONS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple)),
                  const SizedBox(height: 4),
                  Text('  ${_profile.specialInstructions}'),
                ],

                const SizedBox(height: 16),
                Text(
                  'Last updated: ${_profile.updatedAt.month}/${_profile.updatedAt.day}/${_profile.updatedAt.year}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Share text
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 8),
                    Text('Shareable Text',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // Copy to clipboard would go here in a real app
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Emergency card text copied!')),
                        );
                      },
                      tooltip: 'Copy to clipboard',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(text,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12)),
                ),
              ],
            ),
          ),
        ),

        // Validation warnings
        if (_service.validationWarnings(_profile).isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('Missing Information',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._service.validationWarnings(_profile).map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $f',
                            style: TextStyle(color: Colors.amber.shade900)),
                      )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Emergency Card'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
            Tab(icon: Icon(Icons.medical_services), text: 'Medical'),
            Tab(icon: Icon(Icons.credit_card), text: 'Card'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildContactsTab(),
          _buildMedicalTab(),
          _buildCardTab(),
        ],
      ),
    );
  }
}

/// Helper widget for empty state hints.
class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
    );
  }
}
