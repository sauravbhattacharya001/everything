import 'dart:convert';
import '../../models/skill_entry.dart';

/// Report for a single skill's learning progress.
class SkillReport {
  final String skillName;
  final SkillCategory category;
  final ProficiencyLevel currentLevel;
  final ProficiencyLevel targetLevel;
  final double levelProgress;
  final int totalMinutes;
  final double totalHours;
  final int sessionCount;
  final double averageQuality;
  final double milestoneProgress;
  final int completedMilestones;
  final int totalMilestones;
  final int daysSinceStart;
  final int? daysSinceLastPractice;
  final double weeklyGoalProgress;
  final String grade;
  final List<String> insights;

  SkillReport({
    required this.skillName,
    required this.category,
    required this.currentLevel,
    required this.targetLevel,
    required this.levelProgress,
    required this.totalMinutes,
    required this.totalHours,
    required this.sessionCount,
    required this.averageQuality,
    required this.milestoneProgress,
    required this.completedMilestones,
    required this.totalMilestones,
    required this.daysSinceStart,
    this.daysSinceLastPractice,
    required this.weeklyGoalProgress,
    required this.grade,
    required this.insights,
  });
}

/// Weekly practice summary.
class WeeklySummary {
  final DateTime weekStart;
  final int totalMinutes;
  final int sessionCount;
  final double averageQuality;
  final Map<String, int> minutesBySkill;
  final int goalMinutes;
  final double goalProgress;

  WeeklySummary({
    required this.weekStart,
    required this.totalMinutes,
    required this.sessionCount,
    required this.averageQuality,
    required this.minutesBySkill,
    required this.goalMinutes,
    required this.goalProgress,
  });
}

/// Overall learning portfolio report.
class LearningPortfolioReport {
  final int totalSkills;
  final int activeSkills;
  final int archivedSkills;
  final int totalMinutesAllTime;
  final double totalHoursAllTime;
  final int totalSessions;
  final Map<SkillCategory, int> skillsByCategory;
  final Map<ProficiencyLevel, int> skillsByLevel;
  final List<SkillReport> skillReports;
  final List<String> recommendations;

  LearningPortfolioReport({
    required this.totalSkills,
    required this.activeSkills,
    required this.archivedSkills,
    required this.totalMinutesAllTime,
    required this.totalHoursAllTime,
    required this.totalSessions,
    required this.skillsByCategory,
    required this.skillsByLevel,
    required this.skillReports,
    required this.recommendations,
  });
}

/// Practice streak info.
class PracticeStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPracticeDate;

  PracticeStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastPracticeDate,
  });
}

/// Service for tracking skills and learning progress.
class SkillTrackerService {
  final List<SkillEntry> _skills = [];

  List<SkillEntry> get skills => List.unmodifiable(_skills);
  List<SkillEntry> get activeSkills =>
      _skills.where((s) => !s.isArchived).toList();
  List<SkillEntry> get archivedSkills =>
      _skills.where((s) => s.isArchived).toList();

  void addSkill(SkillEntry skill) {
    if (_skills.any((s) => s.id == skill.id)) {
      throw ArgumentError('Skill with id ${skill.id} already exists');
    }
    _skills.add(skill);
  }

  SkillEntry? getSkill(String id) {
    try {
      return _skills.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateSkill(SkillEntry updated) {
    final idx = _skills.indexWhere((s) => s.id == updated.id);
    if (idx < 0) throw ArgumentError('Skill ${updated.id} not found');
    _skills[idx] = updated;
  }

  void removeSkill(String id) {
    _skills.removeWhere((s) => s.id == id);
  }

  void archiveSkill(String id) {
    final skill = getSkill(id);
    if (skill == null) throw ArgumentError('Skill $id not found');
    updateSkill(skill.copyWith(isArchived: true));
  }

  void unarchiveSkill(String id) {
    final skill = getSkill(id);
    if (skill == null) throw ArgumentError('Skill $id not found');
    updateSkill(skill.copyWith(isArchived: false));
  }

  void logPractice(String skillId, PracticeSession session) {
    final skill = getSkill(skillId);
    if (skill == null) throw ArgumentError('Skill $skillId not found');
    final sessions = List<PracticeSession>.from(skill.sessions)..add(session);
    final lastPracticed = skill.lastPracticedAt == null ||
            session.startTime.isAfter(skill.lastPracticedAt!)
        ? session.startTime
        : skill.lastPracticedAt;
    updateSkill(skill.copyWith(
      sessions: sessions,
      lastPracticedAt: lastPracticed,
    ));
  }

  void removePractice(String skillId, String sessionId) {
    final skill = getSkill(skillId);
    if (skill == null) throw ArgumentError('Skill $skillId not found');
    final sessions = skill.sessions.where((s) => s.id != sessionId).toList();
    final lastPracticed = sessions.isEmpty
        ? null
        : sessions.map((s) => s.startTime).reduce((a, b) => a.isAfter(b) ? a : b);
    updateSkill(skill.copyWith(
      sessions: sessions,
      lastPracticedAt: lastPracticed,
    ));
  }

  void addMilestone(String skillId, SkillMilestone milestone) {
    final skill = getSkill(skillId);
    if (skill == null) throw ArgumentError('Skill $skillId not found');
    final milestones = List<SkillMilestone>.from(skill.milestones)..add(milestone);
    updateSkill(skill.copyWith(milestones: milestones));
  }

  void completeMilestone(String skillId, String milestoneId, DateTime at) {
    final skill = getSkill(skillId);
    if (skill == null) throw ArgumentError('Skill $skillId not found');
    final milestones = skill.milestones.map((m) {
      if (m.id == milestoneId) return m.copyWith(completed: true, completedAt: at);
      return m;
    }).toList();
    updateSkill(skill.copyWith(milestones: milestones));
  }

  void uncompleteMilestone(String skillId, String milestoneId) {
    final skill = getSkill(skillId);
    if (skill == null) throw ArgumentError('Skill $skillId not found');
    final milestones = skill.milestones.map((m) {
      if (m.id == milestoneId) {
        return SkillMilestone(
          id: m.id, title: m.title, description: m.description,
          completed: false, completedAt: null, orderIndex: m.orderIndex,
        );
      }
      return m;
    }).toList();
    updateSkill(skill.copyWith(milestones: milestones));
  }

  void updateLevel(String skillId, ProficiencyLevel newLevel) {
    final skill = getSkill(skillId);
    if (skill == null) throw ArgumentError('Skill $skillId not found');
    updateSkill(skill.copyWith(currentLevel: newLevel));
  }

  List<SkillEntry> filterByCategory(SkillCategory category) =>
      activeSkills.where((s) => s.category == category).toList();

  List<SkillEntry> filterByLevel(ProficiencyLevel level) =>
      activeSkills.where((s) => s.currentLevel == level).toList();

  List<SkillEntry> filterByTag(String tag) =>
      activeSkills.where((s) => s.tags.contains(tag)).toList();

  List<SkillEntry> search(String query) {
    final q = query.toLowerCase();
    return _skills.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.category.label.toLowerCase().contains(q) ||
          s.tags.any((t) => t.toLowerCase().contains(q)) ||
          (s.notes?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<SkillEntry> neglectedSkills(DateTime now, {int days = 7}) {
    return activeSkills.where((s) {
      final d = s.daysSinceLastPractice(now);
      return d == null || d >= days;
    }).toList();
  }

  List<SkillEntry> sortByTotalTime({bool descending = true}) {
    final sorted = List<SkillEntry>.from(activeSkills);
    sorted.sort((a, b) => descending
        ? b.totalMinutes.compareTo(a.totalMinutes)
        : a.totalMinutes.compareTo(b.totalMinutes));
    return sorted;
  }

  int weeklyMinutes(String skillId, DateTime date) {
    final skill = getSkill(skillId);
    if (skill == null) return 0;
    final weekStart = date.subtract(Duration(days: date.weekday % 7));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    return skill.sessions
        .where((s) => !s.startTime.isBefore(start) && s.startTime.isBefore(end))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  double weeklyGoalProgress(String skillId, DateTime date) {
    final skill = getSkill(skillId);
    if (skill == null || skill.weeklyGoalMinutes <= 0) return 0;
    return weeklyMinutes(skillId, date) / skill.weeklyGoalMinutes;
  }

  PracticeStreak calculateStreak(DateTime now) {
    final allDates = <DateTime>{};
    for (final skill in activeSkills) {
      for (final session in skill.sessions) {
        final d = session.startTime;
        allDates.add(DateTime(d.year, d.month, d.day));
      }
    }
    if (allDates.isEmpty) {
      return PracticeStreak(currentStreak: 0, longestStreak: 0);
    }
    final sorted = allDates.toList()..sort();
    final today = DateTime(now.year, now.month, now.day);

    int longest = 1, current = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (sorted[i].difference(sorted[i - 1]).inDays > 1) {
        current = 1;
      }
    }

    int currentStreak = 0;
    if (today.difference(sorted.last).inDays <= 1) {
      currentStreak = 1;
      for (int i = sorted.length - 2; i >= 0; i--) {
        if (sorted[i + 1].difference(sorted[i]).inDays == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    return PracticeStreak(
      currentStreak: currentStreak,
      longestStreak: longest,
      lastPracticeDate: sorted.last,
    );
  }

  PracticeStreak calculateSkillStreak(String skillId, DateTime now) {
    final skill = getSkill(skillId);
    if (skill == null || skill.sessions.isEmpty) {
      return PracticeStreak(currentStreak: 0, longestStreak: 0);
    }
    final dates = <DateTime>{};
    for (final s in skill.sessions) {
      dates.add(DateTime(s.startTime.year, s.startTime.month, s.startTime.day));
    }
    final sorted = dates.toList()..sort();
    final today = DateTime(now.year, now.month, now.day);

    int longest = 1, current = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (sorted[i].difference(sorted[i - 1]).inDays > 1) {
        current = 1;
      }
    }

    int currentStreak = 0;
    if (today.difference(sorted.last).inDays <= 1) {
      currentStreak = 1;
      for (int i = sorted.length - 2; i >= 0; i--) {
        if (sorted[i + 1].difference(sorted[i]).inDays == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    return PracticeStreak(
      currentStreak: currentStreak,
      longestStreak: longest,
      lastPracticeDate: sorted.last,
    );
  }

  WeeklySummary getWeeklySummary(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday % 7));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));

    int totalMin = 0, sessionCount = 0, qualitySum = 0, goalMin = 0;
    final bySkill = <String, int>{};

    for (final skill in activeSkills) {
      goalMin += skill.weeklyGoalMinutes;
      for (final s in skill.sessions) {
        if (!s.startTime.isBefore(start) && s.startTime.isBefore(end)) {
          totalMin += s.durationMinutes;
          sessionCount++;
          qualitySum += s.quality;
          bySkill[skill.name] = (bySkill[skill.name] ?? 0) + s.durationMinutes;
        }
      }
    }

    return WeeklySummary(
      weekStart: start,
      totalMinutes: totalMin,
      sessionCount: sessionCount,
      averageQuality: sessionCount > 0 ? qualitySum / sessionCount : 0,
      minutesBySkill: bySkill,
      goalMinutes: goalMin,
      goalProgress: goalMin > 0 ? totalMin / goalMin : 0,
    );
  }

  Map<String, int> topTopics({int limit = 10}) {
    final counts = <String, int>{};
    for (final skill in _skills) {
      for (final s in skill.sessions) {
        if (s.topic != null && s.topic!.isNotEmpty) {
          counts[s.topic!] = (counts[s.topic!] ?? 0) + s.durationMinutes;
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  String _gradeFromProgress(double levelProg, double milestoneProg,
      double weeklyProg, double quality, int daysSincePractice) {
    double score = 0;
    score += levelProg * 25;
    score += milestoneProg * 25;
    score += (weeklyProg.clamp(0, 1)) * 25;
    score += (quality / 5.0) * 15;
    if (daysSincePractice > 14) {
      score -= 20;
    } else if (daysSincePractice > 7) {
      score -= 10;
    } else if (daysSincePractice > 3) {
      score -= 5;
    }
    score += 10;
    score = score.clamp(0, 100);
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  SkillReport generateSkillReport(String skillId, DateTime now) {
    final skill = getSkill(skillId);
    if (skill == null) throw ArgumentError('Skill $skillId not found');

    final daysSince = skill.daysSinceLastPractice(now);
    final wkProgress = weeklyGoalProgress(skillId, now);
    final insights = <String>[];

    if (daysSince != null && daysSince > 7) {
      insights.add("Haven't practiced in $daysSince days - consider a short session!");
    }
    if (wkProgress < 0.5) {
      insights.add(
          'Behind on weekly goal (${(wkProgress * 100).round()}%). Need ${skill.weeklyGoalMinutes - weeklyMinutes(skillId, now)} more minutes.');
    } else if (wkProgress >= 1.0) {
      insights.add('Weekly goal achieved! 🎉');
    }
    if (skill.milestones.isNotEmpty && skill.milestoneProgress < 0.5) {
      insights.add('Only ${(skill.milestoneProgress * 100).round()}% of milestones completed.');
    }
    if (skill.averageQuality < 3 && skill.sessions.length >= 3) {
      insights.add('Average session quality is low (${skill.averageQuality.toStringAsFixed(1)}). Try shorter, more focused sessions.');
    }
    if (skill.totalHours >= 100) {
      insights.add('Over 100 hours invested - impressive dedication! 💪');
    }

    return SkillReport(
      skillName: skill.name,
      category: skill.category,
      currentLevel: skill.currentLevel,
      targetLevel: skill.targetLevel,
      levelProgress: skill.levelProgress,
      totalMinutes: skill.totalMinutes,
      totalHours: skill.totalHours,
      sessionCount: skill.sessions.length,
      averageQuality: skill.averageQuality,
      milestoneProgress: skill.milestoneProgress,
      completedMilestones: skill.milestones.where((m) => m.completed).length,
      totalMilestones: skill.milestones.length,
      daysSinceStart: skill.daysSinceStart(now),
      daysSinceLastPractice: daysSince,
      weeklyGoalProgress: wkProgress,
      grade: _gradeFromProgress(skill.levelProgress, skill.milestoneProgress,
          wkProgress, skill.averageQuality, daysSince ?? 999),
      insights: insights,
    );
  }

  LearningPortfolioReport generatePortfolioReport(DateTime now) {
    final reports = activeSkills.map((s) => generateSkillReport(s.id, now)).toList();
    final byCategory = <SkillCategory, int>{};
    final byLevel = <ProficiencyLevel, int>{};
    for (final s in activeSkills) {
      byCategory[s.category] = (byCategory[s.category] ?? 0) + 1;
      byLevel[s.currentLevel] = (byLevel[s.currentLevel] ?? 0) + 1;
    }

    int totalMin = 0, totalSessions = 0;
    for (final s in _skills) {
      totalMin += s.totalMinutes;
      totalSessions += s.sessions.length;
    }

    final recommendations = <String>[];
    final neglected = neglectedSkills(now);
    if (neglected.isNotEmpty) {
      recommendations.add(
          'Neglected skills: ${neglected.map((s) => s.name).join(", ")}. Consider a quick review session.');
    }
    if (activeSkills.length > 5) {
      recommendations.add(
          'Tracking ${activeSkills.length} skills - consider focusing on fewer for faster progress.');
    }
    if (activeSkills.isEmpty) {
      recommendations.add('No active skills! Add something you want to learn.');
    }

    return LearningPortfolioReport(
      totalSkills: _skills.length,
      activeSkills: activeSkills.length,
      archivedSkills: archivedSkills.length,
      totalMinutesAllTime: totalMin,
      totalHoursAllTime: (totalMin / 60.0 * 10).round() / 10.0,
      totalSessions: totalSessions,
      skillsByCategory: byCategory,
      skillsByLevel: byLevel,
      skillReports: reports,
      recommendations: recommendations,
    );
  }

  String generateTextSummary(DateTime now) {
    final report = generatePortfolioReport(now);
    final buf = StringBuffer();
    buf.writeln('=== Learning Portfolio Summary ===');
    buf.writeln('Skills: ${report.activeSkills} active, ${report.archivedSkills} archived');
    buf.writeln('Total: ${report.totalHoursAllTime}h across ${report.totalSessions} sessions');
    buf.writeln();
    final streak = calculateStreak(now);
    buf.writeln('Practice streak: ${streak.currentStreak} days (longest: ${streak.longestStreak})');
    buf.writeln();
    for (final sr in report.skillReports) {
      buf.writeln('${sr.category.emoji} ${sr.skillName} [${sr.grade}] - ${sr.currentLevel.label} → ${sr.targetLevel.label}');
      buf.writeln('  ${sr.totalHours}h total, ${sr.sessionCount} sessions, quality ${sr.averageQuality.toStringAsFixed(1)}/5');
      if (sr.totalMilestones > 0) buf.writeln('  Milestones: ${sr.completedMilestones}/${sr.totalMilestones}');
      buf.writeln('  Weekly goal: ${(sr.weeklyGoalProgress * 100).round()}%');
      for (final insight in sr.insights) buf.writeln('  💡 $insight');
      buf.writeln();
    }
    if (report.recommendations.isNotEmpty) {
      buf.writeln('--- Recommendations ---');
      for (final r in report.recommendations) buf.writeln('• $r');
    }
    return buf.toString();
  }

  String toJson() => jsonEncode(_skills.map((s) => s.toJson()).toList());

  /// Maximum entries allowed via [loadFromJson].
  ///
  /// Prevents memory exhaustion (CWE-770) from oversized or malicious
  /// import data.  50 000 skill entries is well above any realistic
  /// usage while still fitting comfortably in memory.
  static const int maxImportEntries = 50000;

  void loadFromJson(String json) {
    // Parse into a temporary list first - if the JSON is malformed,
    // the existing skills are preserved instead of being cleared and lost.
    final list = jsonDecode(json) as List<dynamic>;
    if (list.length > maxImportEntries) {
      throw ArgumentError(
        'Import exceeds maximum of $maxImportEntries entries '
        '(got ${list.length}). This limit prevents memory exhaustion '
        'from corrupted or malicious data.',
      );
    }
    final parsed = <SkillEntry>[];
    for (final item in list) {
      parsed.add(SkillEntry.fromJson(item as Map<String, dynamic>));
    }
    _skills.clear();
    _skills.addAll(parsed);
  }
}
