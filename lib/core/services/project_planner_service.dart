import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_backend.dart';

/// A single task within a project milestone.
class ProjectTask {
  String id;
  String title;
  bool completed;
  DateTime? dueDate;

  ProjectTask({
    required this.id,
    required this.title,
    this.completed = false,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        'dueDate': dueDate?.toIso8601String(),
      };

  factory ProjectTask.fromJson(Map<String, dynamic> json) => ProjectTask(
        id: json['id'] as String,
        title: json['title'] as String,
        completed: json['completed'] as bool? ?? false,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'] as String)
            : null,
      );
}

/// A milestone grouping tasks within a project.
class Milestone {
  String id;
  String title;
  DateTime? targetDate;
  List<ProjectTask> tasks;

  Milestone({
    required this.id,
    required this.title,
    this.targetDate,
    List<ProjectTask>? tasks,
  }) : tasks = tasks ?? [];

  double get progress {
    if (tasks.isEmpty) return 0;
    return tasks.where((t) => t.completed).length / tasks.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetDate': targetDate?.toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as String,
        title: json['title'] as String,
        targetDate: json['targetDate'] != null
            ? DateTime.tryParse(json['targetDate'] as String)
            : null,
        tasks: (json['tasks'] as List<dynamic>?)
                ?.map((t) => ProjectTask.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// A project with milestones and metadata.
class Project {
  String id;
  String name;
  String? description;
  DateTime createdAt;
  String colorHex;
  List<Milestone> milestones;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.colorHex = 'FF6750A4',
    List<Milestone>? milestones,
  }) : milestones = milestones ?? [];

  double get progress {
    final allTasks = milestones.expand((m) => m.tasks).toList();
    if (allTasks.isEmpty) return 0;
    return allTasks.where((t) => t.completed).length / allTasks.length;
  }

  int get totalTasks => milestones.fold(0, (s, m) => s + m.tasks.length);
  int get completedTasks =>
      milestones.fold(0, (s, m) => s + m.tasks.where((t) => t.completed).length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'colorHex': colorHex,
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        colorHex: json['colorHex'] as String? ?? 'FF6750A4',
        milestones: (json['milestones'] as List<dynamic>?)
                ?.map((m) => Milestone.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// Persistence service for projects.
class ProjectPlannerService {
  static const _key = 'project_planner_projects';
  List<Project> _projects = [];

  List<Project> get projects => List.unmodifiable(_projects);

  Future<void> load() async {
    final raw = await StorageBackend.read(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _projects =
          list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _save() async {
    await StorageBackend.write(
        _key, jsonEncode(_projects.map((p) => p.toJson()).toList()));
  }

  Future<void> addProject(Project project) async {
    _projects.add(project);
    await _save();
  }

  Future<void> updateProject(Project project) async {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      _projects[idx] = project;
      await _save();
    }
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    await _save();
  }

  String nextId() => DateTime.now().microsecondsSinceEpoch.toString();
}
