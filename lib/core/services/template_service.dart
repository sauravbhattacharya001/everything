import 'package:shared_preferences/shared_preferences.dart';
import '../../models/event_template.dart';

/// Service for managing event templates (built-in presets + custom user templates).
///
/// Provides CRUD operations for custom templates and access to built-in presets.
/// Custom templates are persisted via SharedPreferences.
class TemplateService {
  static const String _storageKey = 'event_templates';

  final SharedPreferences _prefs;

  List<EventTemplate> _customTemplates = [];

  TemplateService(this._prefs) {
    _loadTemplates();
  }

  /// All available templates: built-in presets first, then custom templates.
  List<EventTemplate> get allTemplates => [
        ...EventTemplate.presets,
        ..._customTemplates,
      ];

  /// Only the built-in preset templates.
  List<EventTemplate> get presets => EventTemplate.presets;

  /// Only user-created custom templates.
  List<EventTemplate> get customTemplates => List.unmodifiable(_customTemplates);

  /// Total number of templates (built-in + custom).
  int get totalCount => EventTemplate.presets.length + _customTemplates.length;

  /// Number of custom templates.
  int get customCount => _customTemplates.length;

  /// Maximum number of custom templates allowed.
  static const int maxCustomTemplates = 50;

  /// Adds a new custom template. Returns true if added, false if limit reached
  /// or a template with the same ID already exists.
  bool addTemplate(EventTemplate template) {
    if (_customTemplates.length >= maxCustomTemplates) return false;
    if (_customTemplates.any((t) => t.id == template.id)) return false;
    if (EventTemplate.presets.any((t) => t.id == template.id)) return false;
    _customTemplates.add(template);
    _saveTemplates();
    return true;
  }

  /// Updates an existing custom template. Returns true if found and updated.
  /// Built-in templates cannot be updated.
  bool updateTemplate(EventTemplate template) {
    final index = _customTemplates.indexWhere((t) => t.id == template.id);
    if (index < 0) return false;
    _customTemplates[index] = template;
    _saveTemplates();
    return true;
  }

  /// Removes a custom template by ID. Returns true if found and removed.
  /// Built-in templates cannot be removed.
  bool removeTemplate(String id) {
    final lengthBefore = _customTemplates.length;
    _customTemplates.removeWhere((t) => t.id == id);
    if (_customTemplates.length < lengthBefore) {
      _saveTemplates();
      return true;
    }
    return false;
  }

  /// Finds a template by ID across both built-in and custom templates.
  EventTemplate? findById(String id) {
    try {
      return allTemplates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Searches templates by name (case-insensitive substring match).
  List<EventTemplate> search(String query) {
    if (query.isEmpty) return allTemplates;
    final lower = query.toLowerCase();
    return allTemplates
        .where((t) =>
            t.name.toLowerCase().contains(lower) ||
            t.defaultTitle.toLowerCase().contains(lower))
        .toList();
  }

  /// Removes all custom templates.
  void clearCustomTemplates() {
    _customTemplates.clear();
    _saveTemplates();
  }

  /// Reorders a custom template. Moves the template at [oldIndex] to [newIndex].
  /// Returns true if reordered successfully.
  bool reorderTemplate(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _customTemplates.length) return false;
    if (newIndex < 0 || newIndex >= _customTemplates.length) return false;
    if (oldIndex == newIndex) return true;
    final template = _customTemplates.removeAt(oldIndex);
    _customTemplates.insert(newIndex, template);
    _saveTemplates();
    return true;
  }

  void _loadTemplates() {
    final json = _prefs.getString(_storageKey);
    _customTemplates = EventTemplate.fromJsonString(json);
  }

  void _saveTemplates() {
    _prefs.setString(_storageKey, EventTemplate.toJsonString(_customTemplates));
  }
}
