import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/event_tag.dart';
import '../../models/recurrence_rule.dart';

/// A bottom sheet dialog for creating or editing events.
///
/// Shows fields for title, description, date/time, and priority.
/// Returns the completed [EventModel] via [Navigator.pop] on save,
/// or null if cancelled.
class EventFormDialog extends StatefulWidget {
  /// If provided, the form is in edit mode and pre-filled with this event's data.
  final EventModel? existingEvent;

  const EventFormDialog({this.existingEvent, Key? key}) : super(key: key);

  /// Shows the event form as a modal bottom sheet.
  ///
  /// Returns the created/edited [EventModel], or null if dismissed.
  static Future<EventModel?> show(BuildContext context,
      {EventModel? event}) {
    return showModalBottomSheet<EventModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EventFormDialog(existingEvent: event),
    );
  }

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late EventPriority _selectedPriority;
  late List<EventTag> _selectedTags;
  bool _isRecurring = false;
  RecurrenceFrequency _recurrenceFrequency = RecurrenceFrequency.weekly;
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final event = widget.existingEvent;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');
    _selectedDate = event?.date ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(event?.date ?? DateTime.now());
    _selectedPriority = event?.priority ?? EventPriority.medium;
    _selectedTags = List.of(event?.tags ?? []);
    _isRecurring = event?.recurrence != null;
    if (event?.recurrence != null) {
      _recurrenceFrequency = event!.recurrence!.frequency;
      _recurrenceInterval = event.recurrence!.interval;
      _recurrenceEndDate = event.recurrence!.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final recurrence = _isRecurring
        ? RecurrenceRule(
            frequency: _recurrenceFrequency,
            interval: _recurrenceInterval,
            endDate: _recurrenceEndDate,
          )
        : null;

    final event = EventModel(
      id: widget.existingEvent?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _combinedDateTime,
      priority: _selectedPriority,
      tags: _selectedTags,
      recurrence: recurrence,
    );

    Navigator.of(context).pop(event);
  }

  void _showAddTagDialog() {
    // Suggest presets that aren't already selected
    final available = EventTag.presets
        .where((preset) => !_selectedTags.contains(preset))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final customController = TextEditingController();
        int selectedColorIdx = 0;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Preset tags
                    if (available.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Quick Add',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: available.map((tag) {
                          return ActionChip(
                            label: Text(
                              tag.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: tag.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: tag.color.withAlpha(25),
                            onPressed: () {
                              setState(() => _selectedTags.add(tag));
                              Navigator.of(ctx).pop();
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],

                    // Custom tag
                    const SizedBox(height: 20),
                    Text(
                      'Custom Tag',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customController,
                            decoration: InputDecoration(
                              hintText: 'Tag name',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                            ),
                            textCapitalization: TextCapitalization.words,
                            maxLength: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final name = customController.text.trim();
                            if (name.isEmpty) return;
                            final newTag = EventTag(
                              name: name,
                              colorIndex: selectedColorIdx,
                            );
                            if (!_selectedTags.contains(newTag)) {
                              setState(() => _selectedTags.add(newTag));
                            }
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Color picker
                    Row(
                      children: List.generate(EventTag.palette.length, (i) {
                        final isSelected = selectedColorIdx == i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setSheetState(() => selectedColorIdx = i);
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: EventTag.palette[i],
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.black, width: 2.5)
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? _selectedDate.add(const Duration(days: 90)),
      firstDate: _selectedDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _recurrenceEndDate = picked);
    }
  }

  Widget _buildRecurrenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle
        Row(
          children: [
            Icon(Icons.repeat, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text(
              'Repeat',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            Switch(
              value: _isRecurring,
              onChanged: (val) => setState(() => _isRecurring = val),
            ),
          ],
        ),

        // Recurrence settings (shown when toggled on)
        if (_isRecurring) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Frequency selector
                Row(
                  children: [
                    Text(
                      'Every',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Interval dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _recurrenceInterval,
                          isDense: true,
                          items: List.generate(12, (i) => i + 1)
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v'),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _recurrenceInterval = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Frequency dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<RecurrenceFrequency>(
                            value: _recurrenceFrequency,
                            isDense: true,
                            isExpanded: true,
                            items: RecurrenceFrequency.values
                                .map((f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(
                                        _recurrenceInterval == 1
                                            ? f.label
                                            : _frequencyPluralLabel(f),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _recurrenceFrequency = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // End date
                Row(
                  children: [
                    Icon(Icons.event_busy, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Ends:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_recurrenceEndDate == null)
                      TextButton(
                        onPressed: _pickRecurrenceEndDate,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Never (tap to set)',
                            style: TextStyle(fontSize: 13)),
                      )
                    else ...[
                      GestureDetector(
                        onTap: _pickRecurrenceEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy')
                                .format(_recurrenceEndDate!),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _recurrenceEndDate = null),
                        child: Icon(Icons.clear,
                            size: 18, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Summary
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          RecurrenceRule(
                            frequency: _recurrenceFrequency,
                            interval: _recurrenceInterval,
                            endDate: _recurrenceEndDate,
                          ).summary,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _frequencyPluralLabel(RecurrenceFrequency freq) {
    switch (freq) {
      case RecurrenceFrequency.daily:
        return 'Days';
      case RecurrenceFrequency.weekly:
        return 'Weeks';
      case RecurrenceFrequency.monthly:
        return 'Months';
      case RecurrenceFrequency.yearly:
        return 'Years';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                _isEditing ? 'Edit Event' : 'New Event',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Event title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'Enter event title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length > 100) {
                    return 'Title must be 100 characters or fewer';
                  }
                  return null;
                },
                autofocus: !_isEditing,
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add details about the event',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 8),

              // Date & Time row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Time',
                          prefixIcon: const Icon(Icons.access_time),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Priority selector
              const Text(
                'Priority',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: EventPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              priority.icon,
                              size: 14,
                              color:
                                  isSelected ? Colors.white : priority.color,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                priority.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white
                                      : priority.color,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: priority.color,
                        backgroundColor: priority.color.withAlpha(25),
                        onSelected: (_) {
                          setState(() => _selectedPriority = priority);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Tags selector
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Show selected tags
                  ..._selectedTags.map((tag) => Chip(
                        label: Text(
                          tag.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: tag.color,
                        deleteIconColor: Colors.white70,
                        onDeleted: () {
                          setState(() => _selectedTags.remove(tag));
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )),
                  // Add tag button
                  ActionChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 4),
                        Text('Add Tag', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    onPressed: _showAddTagDialog,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Recurrence toggle & settings
              _buildRecurrenceSection(),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_isEditing ? 'Save Changes' : 'Create Event'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
