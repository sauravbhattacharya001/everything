import 'package:flutter/material.dart';
import '../../core/services/command_palette_service.dart';
import 'package:flutter/services.dart';
import '../home/calendar_screen.dart';
import '../home/stats_screen.dart';
import '../home/heatmap_screen.dart';
import '../home/countdown_screen.dart';
import '../home/agenda_timeline_screen.dart';
import '../home/weekly_report_screen.dart';
import '../home/daily_review_screen.dart';
import '../home/life_dashboard_screen.dart';
import '../home/habit_tracker_screen.dart';
import '../home/goals_screen.dart';
import '../home/mood_journal_screen.dart';
import '../home/water_tracker_screen.dart';
import '../home/workout_tracker_screen.dart';
import '../home/meal_tracker_screen.dart';
import '../home/sleep_tracker_screen.dart';
import '../home/symptom_tracker_screen.dart';
import '../home/allergy_tracker_screen.dart';
import '../home/movie_tracker_screen.dart';
import '../home/energy_tracker_screen.dart';
import '../home/pomodoro_screen.dart';
import '../home/time_tracker_screen.dart';
import '../home/focus_time_screen.dart';
import '../home/routine_builder_screen.dart';
import '../home/chore_tracker_screen.dart';
import '../home/time_budget_screen.dart';
import '../home/screen_time_tracker_screen.dart';
import '../home/weekly_planner_screen.dart';
import '../home/expense_tracker_screen.dart';
import '../home/subscription_tracker_screen.dart';
import '../home/savings_goal_screen.dart';
import '../home/net_worth_tracker_screen.dart';
import '../home/budget_planner_screen.dart';
import '../home/contact_tracker_screen.dart';
import '../home/gratitude_journal_screen.dart';
import '../home/dream_journal_screen.dart';
import '../home/decision_journal_screen.dart';
import '../home/reading_list_screen.dart';
import '../home/skill_tracker_screen.dart';
import '../home/pet_care_tracker_screen.dart';
import '../home/plant_care_tracker_screen.dart';
import '../home/medication_tracker_screen.dart';
import '../home/commute_tracker_screen.dart';
import '../home/bucket_list_screen.dart';
import '../home/travel_log_screen.dart';
import '../home/wishlist_screen.dart';
import '../home/watchlist_screen.dart';
import '../home/gift_tracker_screen.dart';
import '../home/burnout_detector_screen.dart';
import '../home/energy_optimizer_screen.dart';

/// Spotlight-style command palette overlay.
///
/// Shows a searchable list of all screens and quick actions.
/// Open with the FAB or keyboard shortcut (Ctrl+K / Cmd+K).
class CommandPaletteOverlay extends StatefulWidget {
  const CommandPaletteOverlay({super.key});

  /// Show the command palette as a modal overlay.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command Palette',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim, secondaryAnim) {
        return const CommandPaletteOverlay();
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.05),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(opacity: curve, child: child),
        );
      },
    );
  }

  @override
  State<CommandPaletteOverlay> createState() => _CommandPaletteOverlayState();
}

class _CommandPaletteOverlayState extends State<CommandPaletteOverlay> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late List<PaletteAction> _allActions;
  List<PaletteAction> _filtered = [];
  int _selectedIndex = 0;

  static final _screenRoutes = <String, Widget Function()>{
    'nav_calendar': () => CalendarScreen(),
    'nav_stats': () => StatsScreen(),
    'nav_heatmap': () => HeatmapScreen(),
    'nav_countdown': () => CountdownScreen(),
    'nav_agenda': () => AgendaTimelineScreen(),
    'nav_weekly_report': () => WeeklyReportScreen(),
    'nav_daily_review': () => DailyReviewScreen(),
    'nav_life_dashboard': () => LifeDashboardScreen(),
    'nav_habits': () => HabitTrackerScreen(),
    'nav_goals': () => GoalsScreen(),
    'nav_mood': () => MoodJournalScreen(),
    'nav_water': () => WaterTrackerScreen(),
    'nav_workout': () => WorkoutTrackerScreen(),
    'nav_meal': () => MealTrackerScreen(),
    'nav_sleep': () => SleepTrackerScreen(),
    'nav_symptoms': () => SymptomTrackerScreen(),
    'nav_allergies': () => AllergyTrackerScreen(),
    'nav_movies': () => MovieTrackerScreen(),
    'nav_energy': () => EnergyTrackerScreen(),
    'nav_pomodoro': () => PomodoroScreen(),
    'nav_time_tracker': () => TimeTrackerScreen(),
    'nav_focus': () => FocusTimeScreen(),
    'nav_routine': () => RoutineBuilderScreen(),
    'nav_chores': () => ChoreTrackerScreen(),
    'nav_time_budget': () => TimeBudgetScreen(),
    'nav_screen_time': () => ScreenTimeTrackerScreen(),
    'nav_weekly_planner': () => WeeklyPlannerScreen(),
    'nav_expenses': () => ExpenseTrackerScreen(),
    'nav_subscriptions': () => SubscriptionTrackerScreen(),
    'nav_savings': () => SavingsGoalScreen(),
    'nav_net_worth': () => NetWorthTrackerScreen(),
    'nav_budget': () => BudgetPlannerScreen(),
    'nav_contacts': () => ContactTrackerScreen(),
    'nav_gratitude': () => GratitudeJournalScreen(),
    'nav_dreams': () => DreamJournalScreen(),
    'nav_decisions': () => DecisionJournalScreen(),
    'nav_reading': () => ReadingListScreen(),
    'nav_skills': () => SkillTrackerScreen(),
    'nav_pet': () => PetCareTrackerScreen(),
    'nav_plant': () => PlantCareTrackerScreen(),
    'nav_medication': () => MedicationTrackerScreen(),
    'nav_commute': () => CommuteTrackerScreen(),
    'nav_bucket_list': () => BucketListScreen(),
    'nav_travel': () => TravelLogScreen(),
    'nav_wishlist': () => WishlistScreen(),
    'nav_watchlist': () => WatchlistScreen(),
    'nav_gifts': () => GiftTrackerScreen(),
    'nav_burnout': () => BurnoutDetectorScreen(),
    'nav_energy_optimizer': () => EnergyOptimizerScreen(),
  };

  @override
  void initState() {
    super.initState();
    _allActions = CommandPaletteService.instance.buildActions();
    _applyFilter('');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyFilter(String query) {
    final lowerQuery = query.toLowerCase();
    final scored = <MapEntry<PaletteAction, double>>[];
    for (final action in _allActions) {
      final score = action.matchScore(lowerQuery);
      if (score > 0.0) {
        scored.add(MapEntry(action, score));
      }
    }

    // Sort by: recent first (if no query), then score, then category
    final recentIds = CommandPaletteService.instance.recentScreenIds;
    scored.sort((a, b) {
      // Recents always on top when no query
      if (query.isEmpty) {
        final aRecent = recentIds.indexOf(a.key.id);
        final bRecent = recentIds.indexOf(b.key.id);
        if (aRecent != -1 && bRecent == -1) return -1;
        if (aRecent == -1 && bRecent != -1) return 1;
        if (aRecent != -1 && bRecent != -1) return aRecent.compareTo(bRecent);
      }
      // Quick actions before navigation when queried
      if (query.isNotEmpty) {
        final aIsAction = a.key.category == 'Quick Actions';
        final bIsAction = b.key.category == 'Quick Actions';
        if (aIsAction && !bIsAction && a.value >= b.value) return -1;
        if (!aIsAction && bIsAction && b.value >= a.value) return 1;
      }
      final scoreCmp = b.value.compareTo(a.value);
      if (scoreCmp != 0) return scoreCmp;
      return a.key.label.compareTo(b.key.label);
    });

    setState(() {
      _filtered = scored.map((e) => e.key).toList();
      _selectedIndex = 0;
    });
  }

  void _executeAction(PaletteAction action) {
    Navigator.of(context).pop(); // Close palette

    if (action.id.startsWith('nav_')) {
      final builder = _screenRoutes[action.id];
      if (builder != null) {
        CommandPaletteService.instance.recordVisit(action.id);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => builder()),
        );
      }
    }
    // Quick actions could be wired to specific dialogs here
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, _filtered.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, _filtered.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_filtered.isNotEmpty) {
        _executeAction(_filtered[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final selectedColor = isDark
        ? Colors.deepPurple.withOpacity(0.3)
        : Colors.deepPurple.withOpacity(0.08);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            elevation: 16,
            borderRadius: BorderRadius.circular(16),
            color: bgColor,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: _handleKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSearchField(hintColor, borderColor),
                    if (_filtered.isNotEmpty)
                      Flexible(
                        child: _buildResultList(selectedColor, hintColor),
                      ),
                    if (_filtered.isEmpty && _controller.text.isNotEmpty)
                      _buildEmptyState(hintColor),
                    _buildFooter(hintColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(Color hintColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: hintColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search screens, actions...',
                hintStyle: TextStyle(color: hintColor),
                border: InputBorder.none,
              ),
              onChanged: _applyFilter,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hintColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('ESC', style: TextStyle(fontSize: 11, color: hintColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList(Color selectedColor, Color hintColor) {
    String? lastCategory;
    final recentIds = CommandPaletteService.instance.recentScreenIds;
    final showRecents = _controller.text.isEmpty;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final action = _filtered[index];
        final isSelected = index == _selectedIndex;
        final showCategory = action.category != lastCategory;
        lastCategory = action.category;
        final isRecent = recentIds.contains(action.id) && showRecents;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCategory)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                child: Text(
                  isRecent && index < recentIds.length ? 'Recent' : action.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hintColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            InkWell(
              onTap: () => _executeAction(action),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isSelected ? selectedColor : Colors.transparent,
                child: Row(
                  children: [
                    Icon(action.icon, size: 20,
                        color: isSelected ? Colors.deepPurple : hintColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(action.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              )),
                          if (action.subtitle != null)
                            Text(action.subtitle!,
                                style: TextStyle(
                                    fontSize: 12, color: hintColor)),
                        ],
                      ),
                    ),
                    if (isRecent)
                      Icon(Icons.history, size: 14, color: hintColor),
                    if (isSelected)
                      Icon(Icons.keyboard_return, size: 14, color: hintColor),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(Color hintColor) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 40, color: hintColor),
          const SizedBox(height: 8),
          Text('No matching screens or actions',
              style: TextStyle(color: hintColor)),
        ],
      ),
    );
  }

  Widget _buildFooter(Color hintColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.keyboard, size: 14, color: hintColor),
          const SizedBox(width: 6),
          Text(
            '\u2191\u2193 navigate  \u23CE open  esc close',
            style: TextStyle(fontSize: 11, color: hintColor),
          ),
          const Spacer(),
          Text(
            '${_filtered.length} results',
            style: TextStyle(fontSize: 11, color: hintColor),
          ),
        ],
      ),
    );
  }
}
