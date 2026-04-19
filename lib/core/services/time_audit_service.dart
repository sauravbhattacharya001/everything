import 'dart:math';

/// Category of time usage.
enum TimeCategory {
  work('Work', 0xFF2196F3),
  health('Health', 0xFF4CAF50),
  social('Social', 0xFF9C27B0),
  learning('Learning', 0xFFFF9800),
  rest('Rest', 0xFF009688),
  chores('Chores', 0xFF795548);

  final String label;
  final int colorValue;
  const TimeCategory(this.label, this.colorValue);
}

/// A single block of time usage.
class TimeBlock {
  final TimeCategory category;
  final int startHour; // 0-23
  final double duration; // hours
  final int quality; // 0-100
  final int dayOfWeek; // 1=Mon, 7=Sun

  const TimeBlock({
    required this.category,
    required this.startHour,
    required this.duration,
    required this.quality,
    required this.dayOfWeek,
  });
}

/// A detected productivity window.
class ProductivityWindow {
  final int startHour;
  final int endHour;
  final double avgQuality;
  final TimeCategory dominantCategory;
  final String recommendation;

  const ProductivityWindow({
    required this.startHour,
    required this.endHour,
    required this.avgQuality,
    required this.dominantCategory,
    required this.recommendation,
  });

  String get hourRange =>
      '${_formatHour(startHour)} – ${_formatHour(endHour)}';

  static String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }
}

/// A low-quality time hotspot.
class TimeHotspot {
  final int dayOfWeek;
  final int startHour;
  final double duration;
  final TimeCategory category;
  final int quality;
  final String issue;
  final String suggestion;

  const TimeHotspot({
    required this.dayOfWeek,
    required this.startHour,
    required this.duration,
    required this.category,
    required this.quality,
    required this.issue,
    required this.suggestion,
  });

  bool get isSevere => quality < 30;

  String get dayLabel => const [
        '',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][dayOfWeek];
}

/// A proactive optimization recommendation.
class OptimizationTip {
  final String title;
  final String description;
  final String icon; // emoji
  final int impactScore; // 1-10

  const OptimizationTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.impactScore,
  });
}

/// Category balance comparison.
class CategoryBalance {
  final TimeCategory category;
  final double actualHours;
  final double idealHours;

  const CategoryBalance({
    required this.category,
    required this.actualHours,
    required this.idealHours,
  });

  double get deviation => actualHours - idealHours;
  bool get overAllocated => deviation > 1.0;
  bool get underAllocated => deviation < -1.0;
}

/// Service that generates simulated time-usage data and analysis.
class TimeAuditService {
  final _rng = Random(42);

  /// Generate ~50 simulated time blocks across a week.
  List<TimeBlock> generateWeeklyBlocks() {
    final blocks = <TimeBlock>[];
    for (int day = 1; day <= 7; day++) {
      int hour = 6 + _rng.nextInt(2); // wake 6-7
      while (hour < 23) {
        final category = _pickCategory(hour, day);
        final duration = 1.0 + _rng.nextInt(3) * 0.5;
        final quality = _qualityForContext(category, hour, day);
        blocks.add(TimeBlock(
          category: category,
          startHour: hour,
          duration: duration,
          quality: quality,
          dayOfWeek: day,
        ));
        hour += duration.ceil();
      }
    }
    return blocks;
  }

  TimeCategory _pickCategory(int hour, int day) {
    if (day >= 6) {
      // weekend
      final options = [
        TimeCategory.rest,
        TimeCategory.social,
        TimeCategory.health,
        TimeCategory.learning
      ];
      return options[_rng.nextInt(options.length)];
    }
    if (hour < 9) return TimeCategory.health;
    if (hour < 12) return TimeCategory.work;
    if (hour == 12) return TimeCategory.rest;
    if (hour < 15) return TimeCategory.work;
    if (hour < 17) {
      return _rng.nextBool() ? TimeCategory.learning : TimeCategory.work;
    }
    if (hour < 19) return TimeCategory.chores;
    return _rng.nextBool() ? TimeCategory.social : TimeCategory.rest;
  }

  int _qualityForContext(TimeCategory cat, int hour, int day) {
    int base = 50 + _rng.nextInt(30);
    // Morning focus boost
    if (hour >= 9 && hour <= 11 && cat == TimeCategory.work) base += 20;
    // Post-lunch dip
    if (hour >= 13 && hour <= 14) base -= 15;
    // Tuesday afternoon slump pattern
    if (day == 2 && hour >= 14 && hour <= 16) base -= 20;
    // Weekend rest is higher quality
    if (day >= 6 && cat == TimeCategory.rest) base += 15;
    return base.clamp(10, 100);
  }

  /// Find peak performance hours.
  List<ProductivityWindow> analyzeProductivityWindows(List<TimeBlock> blocks) {
    // Average quality per hour bucket
    final hourQuality = <int, List<int>>{};
    final hourCategories = <int, Map<TimeCategory, int>>{};
    for (final b in blocks) {
      for (int h = b.startHour; h < b.startHour + b.duration.ceil(); h++) {
        hourQuality.putIfAbsent(h, () => []).add(b.quality);
        hourCategories.putIfAbsent(h, () => {});
        hourCategories[h]![b.category] =
            (hourCategories[h]![b.category] ?? 0) + 1;
      }
    }

    // Find contiguous high-quality windows
    final windows = <ProductivityWindow>[];
    final sortedHours = hourQuality.keys.toList()..sort();
    int? windowStart;
    double windowSum = 0;
    int windowCount = 0;

    for (int i = 0; i < sortedHours.length; i++) {
      final h = sortedHours[i];
      final avg =
          hourQuality[h]!.reduce((a, b) => a + b) / hourQuality[h]!.length;

      if (avg >= 60) {
        windowStart ??= h;
        windowSum += avg;
        windowCount++;
      }

      if (avg < 60 || i == sortedHours.length - 1) {
        if (windowStart != null && windowCount >= 2) {
          final endH = avg < 60 ? h : h + 1;
          final dominant = _dominantCategory(hourCategories, windowStart, endH);
          windows.add(ProductivityWindow(
            startHour: windowStart,
            endHour: endH,
            avgQuality: windowSum / windowCount,
            dominantCategory: dominant,
            recommendation: _windowRecommendation(windowStart, endH, dominant),
          ));
        }
        if (avg < 60) {
          windowStart = null;
          windowSum = 0;
          windowCount = 0;
        }
      }
    }

    windows.sort((a, b) => b.avgQuality.compareTo(a.avgQuality));
    return windows.take(5).toList();
  }

  TimeCategory _dominantCategory(
      Map<int, Map<TimeCategory, int>> cats, int start, int end) {
    final counts = <TimeCategory, int>{};
    for (int h = start; h < end; h++) {
      if (cats.containsKey(h)) {
        for (final entry in cats[h]!.entries) {
          counts[entry.key] = (counts[entry.key] ?? 0) + entry.value;
        }
      }
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _windowRecommendation(int start, int end, TimeCategory cat) {
    if (cat == TimeCategory.work && start < 12) {
      return 'Peak focus window — schedule deep work and creative tasks here.';
    }
    if (cat == TimeCategory.learning) {
      return 'High absorption period — ideal for studying or skill-building.';
    }
    if (cat == TimeCategory.health && start < 9) {
      return 'Morning vitality peak — maintain this exercise routine.';
    }
    return 'Consistent quality — protect this time from interruptions.';
  }

  /// Find low-quality time blocks.
  List<TimeHotspot> detectWastedTime(List<TimeBlock> blocks) {
    final hotspots = <TimeHotspot>[];
    for (final b in blocks) {
      if (b.quality < 45) {
        hotspots.add(TimeHotspot(
          dayOfWeek: b.dayOfWeek,
          startHour: b.startHour,
          duration: b.duration,
          category: b.category,
          quality: b.quality,
          issue: _diagnoseIssue(b),
          suggestion: _suggestFix(b),
        ));
      }
    }
    hotspots.sort((a, b) => a.quality.compareTo(b.quality));
    return hotspots.take(8).toList();
  }

  String _diagnoseIssue(TimeBlock b) {
    if (b.startHour >= 13 && b.startHour <= 14) {
      return 'Post-lunch energy crash affecting ${b.category.label.toLowerCase()} quality.';
    }
    if (b.dayOfWeek == 2 && b.startHour >= 14) {
      return 'Recurring Tuesday afternoon slump pattern detected.';
    }
    if (b.category == TimeCategory.work && b.startHour >= 17) {
      return 'Diminishing returns on late work — fatigue accumulation.';
    }
    return 'Low engagement detected — possible context-switching or distraction.';
  }

  String _suggestFix(TimeBlock b) {
    if (b.startHour >= 13 && b.startHour <= 14) {
      return 'Try a 15-min walk or lighter tasks. Schedule creative work before lunch.';
    }
    if (b.dayOfWeek == 2 && b.startHour >= 14) {
      return 'Block Tuesday afternoons for low-stakes admin or social catchups.';
    }
    if (b.category == TimeCategory.work && b.startHour >= 17) {
      return 'Hard-stop work at 5 PM. Move overflow to morning windows.';
    }
    return 'Try the 2-minute rule: if distracted, do one tiny task to rebuild momentum.';
  }

  /// Generate proactive optimization recommendations.
  List<OptimizationTip> generateOptimizations(List<TimeBlock> blocks) {
    return const [
      OptimizationTip(
        title: 'Protect Your Morning Focus',
        description:
            'Your 9–11 AM window shows 85%+ quality for deep work. Block it — no meetings, no Slack.',
        icon: '🎯',
        impactScore: 9,
      ),
      OptimizationTip(
        title: 'Redesign Tuesday Afternoons',
        description:
            'Consistent quality dip Tue 2–4 PM. Schedule walking meetings, admin, or learning content here.',
        icon: '📅',
        impactScore: 7,
      ),
      OptimizationTip(
        title: 'Post-Lunch Transition Ritual',
        description:
            'Add a 10-min walk after lunch. Data shows it cuts your afternoon dip by 40 minutes.',
        icon: '🚶',
        impactScore: 8,
      ),
      OptimizationTip(
        title: 'Learning Window Discovery',
        description:
            'Your 4–5 PM slot shows high learning receptivity. Move skill practice here from evenings.',
        icon: '📚',
        impactScore: 6,
      ),
      OptimizationTip(
        title: 'Weekend Recovery Balance',
        description:
            'You rest well on weekends but skip social time. One social block Saturday = better Monday energy.',
        icon: '👥',
        impactScore: 5,
      ),
      OptimizationTip(
        title: 'Hard Stop at 5 PM',
        description:
            'Work after 5 PM averages 35% quality. Those hours are better spent on health or rest.',
        icon: '🛑',
        impactScore: 8,
      ),
      OptimizationTip(
        title: 'Chore Batching Opportunity',
        description:
            'Scattered chores fragment your evenings. Batch into one 90-min block on Wednesday.',
        icon: '🧹',
        impactScore: 5,
      ),
    ];
  }

  /// Category balance: actual vs ideal hours per week.
  List<CategoryBalance> getTimeBalance(List<TimeBlock> blocks) {
    final actual = <TimeCategory, double>{};
    for (final b in blocks) {
      actual[b.category] = (actual[b.category] ?? 0) + b.duration;
    }
    // Ideal weekly distribution (out of ~112 waking hours)
    const ideal = {
      TimeCategory.work: 40.0,
      TimeCategory.health: 10.0,
      TimeCategory.social: 12.0,
      TimeCategory.learning: 10.0,
      TimeCategory.rest: 25.0,
      TimeCategory.chores: 10.0,
    };
    return TimeCategory.values.map((cat) {
      return CategoryBalance(
        category: cat,
        actualHours: actual[cat] ?? 0,
        idealHours: ideal[cat] ?? 10,
      );
    }).toList();
  }

  /// Balance score 0-100.
  int calculateBalanceScore(List<CategoryBalance> balances) {
    double totalDeviation = 0;
    double totalIdeal = 0;
    for (final b in balances) {
      totalDeviation += b.deviation.abs();
      totalIdeal += b.idealHours;
    }
    final ratio = 1.0 - (totalDeviation / totalIdeal).clamp(0.0, 1.0);
    return (ratio * 100).round();
  }

  /// Days of consecutive balanced time use.
  int getBalanceStreak() => 4; // simulated
}
