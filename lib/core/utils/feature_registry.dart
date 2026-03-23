import 'package:flutter/material.dart';
import '../../views/home/agenda_timeline_screen.dart';
import '../../views/home/bucket_list_screen.dart';
import '../../views/home/budget_planner_screen.dart';
import '../../views/home/calendar_screen.dart';
import '../../views/home/chore_tracker_screen.dart';
import '../../views/home/commute_tracker_screen.dart';
import '../../views/home/contact_tracker_screen.dart';
import '../../views/home/countdown_screen.dart';
import '../../views/home/daily_review_screen.dart';
import '../../views/home/debt_payoff_screen.dart';
import '../../views/home/decision_journal_screen.dart';
import '../../views/home/document_expiry_screen.dart';
import '../../views/home/eisenhower_matrix_screen.dart';
import '../../views/home/emergency_card_screen.dart';
import '../../views/home/energy_tracker_screen.dart';
import '../../views/home/expense_tracker_screen.dart';
import '../../views/home/fasting_tracker_screen.dart';
import '../../views/home/focus_time_screen.dart';
import '../../views/home/gift_tracker_screen.dart';
import '../../views/home/goals_screen.dart';
import '../../views/home/gratitude_journal_screen.dart';
import '../../views/home/grocery_list_screen.dart';
import '../../views/home/habit_tracker_screen.dart';
import '../../views/home/heatmap_screen.dart';
import '../../views/home/home_inventory_screen.dart';
import '../../views/home/home_maintenance_screen.dart';
import '../../views/home/kanban_board_screen.dart';
import '../../views/home/learning_tracker_screen.dart';
import '../../views/home/life_dashboard_screen.dart';
import '../../views/home/loyalty_tracker_screen.dart';
import '../../views/home/meal_tracker_screen.dart';
import '../../views/home/medication_tracker_screen.dart';
import '../../views/home/meditation_tracker_screen.dart';
import '../../views/home/mood_journal_screen.dart';
import '../../views/home/net_worth_tracker_screen.dart';
import '../../views/home/packing_list_screen.dart';
import '../../views/home/parking_spot_screen.dart';
import '../../views/home/pet_care_tracker_screen.dart';
import '../../views/home/plant_care_tracker_screen.dart';
import '../../views/home/pomodoro_screen.dart';
import '../../views/home/productivity_score_screen.dart';
import '../../views/home/quick_capture_screen.dart';
import '../../views/home/quote_collection_screen.dart';
import '../../views/home/reading_list_screen.dart';
import '../../views/home/recipe_book_screen.dart';
import '../../views/home/routine_builder_screen.dart';
import '../../views/home/savings_goal_screen.dart';
import '../../views/home/screen_time_tracker_screen.dart';
import '../../views/home/skill_tracker_screen.dart';
import '../../views/home/sleep_tracker_screen.dart';
import '../../views/home/stats_screen.dart';
import '../../views/home/subscription_tracker_screen.dart';
import '../../views/home/time_budget_screen.dart';
import '../../views/home/time_tracker_screen.dart';
import '../../views/home/travel_log_screen.dart';
import '../../views/home/warranty_tracker_screen.dart';
import '../../views/home/watchlist_screen.dart';
import '../../views/home/water_tracker_screen.dart';
import '../../views/home/weekly_planner_screen.dart';
import '../../views/home/weekly_report_screen.dart';
import '../../views/home/blood_pressure_screen.dart';
import '../../views/home/body_measurement_screen.dart';
import '../../views/home/bookmark_screen.dart';
import '../../views/home/time_capsule_screen.dart';
import '../../views/home/wishlist_screen.dart';
import '../../views/home/workout_tracker_screen.dart';
import '../../views/home/random_decision_screen.dart';
import '../../views/home/unit_converter_screen.dart';
import '../../views/home/vehicle_maintenance_screen.dart';
import '../../views/home/coupon_tracker_screen.dart';
import '../../views/home/price_tracker_screen.dart';
import '../../views/home/world_clock_screen.dart';
import '../../views/home/tip_calculator_screen.dart';
import '../../views/home/loan_calculator_screen.dart';
import '../../views/home/password_generator_screen.dart';
import '../../views/home/color_palette_screen.dart';
import '../../views/home/expense_splitter_screen.dart';
import '../../views/home/stopwatch_screen.dart';
import '../../views/home/bmi_calculator_screen.dart';
import '../../views/home/flash_card_screen.dart';
import '../../views/home/score_keeper_screen.dart';
import '../../views/home/age_calculator_screen.dart';
import '../../views/home/morse_code_screen.dart';
import '../../views/home/music_practice_screen.dart';
import '../../views/home/dice_roller_screen.dart';
import '../../views/home/qr_generator_screen.dart';

/// A single navigable feature in the app.
class FeatureEntry {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final FeatureCategory category;

  const FeatureEntry({
    required this.label,
    required this.icon,
    required this.builder,
    required this.category,
  });
}

/// Categories for organizing features in the navigation drawer.
enum FeatureCategory {
  planning('Planning & Views', Icons.calendar_today),
  productivity('Productivity', Icons.trending_up),
  health('Health & Wellness', Icons.favorite),
  finance('Finance', Icons.attach_money),
  lifestyle('Lifestyle', Icons.palette),
  organization('Organization', Icons.folder),
  tracking('Tracking', Icons.analytics);

  final String label;
  final IconData icon;
  const FeatureCategory(this.label, this.icon);
}

/// Central registry of all navigable features in the app.
///
/// Adding a new feature screen requires only a single entry here —
/// the navigation drawer and any feature-discovery UI automatically
/// pick it up.
class FeatureRegistry {
  FeatureRegistry._();

  static final List<FeatureEntry> features = [
    // ── Planning & Views ──
    FeatureEntry(
      label: 'Daily Agenda',
      icon: Icons.view_timeline,
      category: FeatureCategory.planning,
      builder: (_) => const AgendaTimelineScreen(),
    ),
    FeatureEntry(
      label: 'Calendar',
      icon: Icons.calendar_month,
      category: FeatureCategory.planning,
      builder: (_) => const CalendarScreen(),
    ),
    FeatureEntry(
      label: 'Weekly Planner',
      icon: Icons.view_week,
      category: FeatureCategory.planning,
      builder: (_) => const WeeklyPlannerScreen(),
    ),
    FeatureEntry(
      label: 'Weekly Report',
      icon: Icons.assessment,
      category: FeatureCategory.planning,
      builder: (_) => const WeeklyReportScreen(),
    ),
    FeatureEntry(
      label: 'Countdowns',
      icon: Icons.timer,
      category: FeatureCategory.planning,
      builder: (_) => const CountdownScreen(),
    ),
    FeatureEntry(
      label: 'Daily Review',
      icon: Icons.rate_review,
      category: FeatureCategory.planning,
      builder: (_) => const DailyReviewScreen(),
    ),
    FeatureEntry(
      label: 'Life Dashboard',
      icon: Icons.dashboard,
      category: FeatureCategory.planning,
      builder: (_) => const LifeDashboardScreen(),
    ),

    // ── Productivity ──
    FeatureEntry(
      label: 'Pomodoro Timer',
      icon: Icons.av_timer,
      category: FeatureCategory.productivity,
      builder: (_) => const PomodoroScreen(),
    ),
    FeatureEntry(
      label: 'Focus Time',
      icon: Icons.center_focus_strong,
      category: FeatureCategory.productivity,
      builder: (_) => const FocusTimeScreen(),
    ),
    FeatureEntry(
      label: 'Habit Tracker',
      icon: Icons.track_changes,
      category: FeatureCategory.productivity,
      builder: (_) => const HabitTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Goals',
      icon: Icons.flag,
      category: FeatureCategory.productivity,
      builder: (_) => const GoalsScreen(),
    ),
    FeatureEntry(
      label: 'Routine Builder',
      icon: Icons.self_improvement,
      category: FeatureCategory.productivity,
      builder: (_) => const RoutineBuilderScreen(),
    ),
    FeatureEntry(
      label: 'Eisenhower Matrix',
      icon: Icons.grid_view_rounded,
      category: FeatureCategory.productivity,
      builder: (_) => const EisenhowerMatrixScreen(),
    ),
    FeatureEntry(
      label: 'Kanban Board',
      icon: Icons.view_kanban,
      category: FeatureCategory.productivity,
      builder: (_) => const KanbanBoardScreen(),
    ),
    FeatureEntry(
      label: 'Time Tracker',
      icon: Icons.timer,
      category: FeatureCategory.productivity,
      builder: (_) => const TimeTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Time Budget',
      icon: Icons.timer_outlined,
      category: FeatureCategory.productivity,
      builder: (_) => const TimeBudgetScreen(),
    ),
    FeatureEntry(
      label: 'Stopwatch',
      icon: Icons.timer,
      category: FeatureCategory.productivity,
      builder: (_) => const StopwatchScreen(),
    ),
    FeatureEntry(
      label: 'Skill Tracker',
      icon: Icons.school,
      category: FeatureCategory.productivity,
      builder: (_) => const SkillTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Learning Tracker',
      icon: Icons.school,
      category: FeatureCategory.productivity,
      builder: (_) => const LearningTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Flash Cards',
      icon: Icons.style,
      category: FeatureCategory.productivity,
      builder: (_) => const FlashCardScreen(),
    ),
    FeatureEntry(
      label: 'Productivity Score',
      icon: Icons.speed,
      category: FeatureCategory.productivity,
      builder: (_) => const ProductivityScoreScreen(),
    ),
    FeatureEntry(
      label: 'Activity Heatmap',
      icon: Icons.grid_view,
      category: FeatureCategory.productivity,
      builder: (_) => const HeatmapScreen(),
    ),
    FeatureEntry(
      label: 'Analytics',
      icon: Icons.bar_chart,
      category: FeatureCategory.productivity,
      builder: (_) => const StatsScreen(),
    ),
    FeatureEntry(
      label: 'Chore Tracker',
      icon: Icons.cleaning_services,
      category: FeatureCategory.productivity,
      builder: (_) => const ChoreTrackerScreen(),
    ),

    // ── Health & Wellness ──
    FeatureEntry(
      label: 'Mood Journal',
      icon: Icons.mood,
      category: FeatureCategory.health,
      builder: (_) => const MoodJournalScreen(),
    ),
    FeatureEntry(
      label: 'Sleep Tracker',
      icon: Icons.bedtime,
      category: FeatureCategory.health,
      builder: (_) => const SleepTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Meditation',
      icon: Icons.self_improvement,
      category: FeatureCategory.health,
      builder: (_) => const MeditationTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Water Tracker',
      icon: Icons.water_drop,
      category: FeatureCategory.health,
      builder: (_) => const WaterTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Fasting Tracker',
      icon: Icons.no_food,
      category: FeatureCategory.health,
      builder: (_) => const FastingTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Workout Tracker',
      icon: Icons.fitness_center,
      category: FeatureCategory.health,
      builder: (_) => const WorkoutTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Meal Tracker',
      icon: Icons.restaurant_menu,
      category: FeatureCategory.health,
      builder: (_) => const MealTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Energy Tracker',
      icon: Icons.bolt,
      category: FeatureCategory.health,
      builder: (_) => const EnergyTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Medication Tracker',
      icon: Icons.medication,
      category: FeatureCategory.health,
      builder: (_) => const MedicationTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Screen Time',
      icon: Icons.phone_android,
      category: FeatureCategory.health,
      builder: (_) => const ScreenTimeTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Gratitude Journal',
      icon: Icons.favorite,
      category: FeatureCategory.health,
      builder: (_) => const GratitudeJournalScreen(),
    ),
    FeatureEntry(
      label: 'BMI Calculator',
      icon: Icons.accessibility_new,
      category: FeatureCategory.health,
      builder: (_) => const BmiCalculatorScreen(),
    ),
    FeatureEntry(
      label: 'Body Measurements',
      icon: Icons.straighten,
      category: FeatureCategory.health,
      builder: (_) => const BodyMeasurementScreen(),
    ),
    FeatureEntry(
      label: 'Blood Pressure',
      icon: Icons.monitor_heart,
      category: FeatureCategory.health,
      builder: (_) => const BloodPressureScreen(),
    ),

    // ── Finance ──
    FeatureEntry(
      label: 'Expense Tracker',
      icon: Icons.account_balance_wallet,
      category: FeatureCategory.finance,
      builder: (_) => const ExpenseTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Budget Planner',
      icon: Icons.account_balance,
      category: FeatureCategory.finance,
      builder: (_) => const BudgetPlannerScreen(),
    ),
    FeatureEntry(
      label: 'Savings Goals',
      icon: Icons.savings,
      category: FeatureCategory.finance,
      builder: (_) => const SavingsGoalScreen(),
    ),
    FeatureEntry(
      label: 'Debt Payoff',
      icon: Icons.money_off,
      category: FeatureCategory.finance,
      builder: (_) => const DebtPayoffScreen(),
    ),
    FeatureEntry(
      label: 'Net Worth',
      icon: Icons.account_balance_wallet,
      category: FeatureCategory.finance,
      builder: (_) => const NetWorthTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Subscriptions',
      icon: Icons.subscriptions,
      category: FeatureCategory.finance,
      builder: (_) => const SubscriptionTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Loyalty Cards',
      icon: Icons.card_membership,
      category: FeatureCategory.finance,
      builder: (_) => const LoyaltyTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Coupon Tracker',
      icon: Icons.local_offer,
      category: FeatureCategory.finance,
      builder: (_) => const CouponTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Price Tracker',
      icon: Icons.price_check,
      category: FeatureCategory.finance,
      builder: (_) => const PriceTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Tip Calculator',
      icon: Icons.restaurant,
      category: FeatureCategory.finance,
      builder: (_) => const TipCalculatorScreen(),
    ),
    FeatureEntry(
      label: 'Loan Calculator',
      icon: Icons.account_balance,
      category: FeatureCategory.finance,
      builder: (_) => const LoanCalculatorScreen(),
    ),
    FeatureEntry(
      label: 'Expense Splitter',
      icon: Icons.group_work,
      category: FeatureCategory.finance,
      builder: (_) => const ExpenseSplitterScreen(),
    ),

    // ── Lifestyle ──
    FeatureEntry(
      label: 'Travel Log',
      icon: Icons.flight,
      category: FeatureCategory.lifestyle,
      builder: (_) => const TravelLogScreen(),
    ),
    FeatureEntry(
      label: 'Commute Tracker',
      icon: Icons.commute,
      category: FeatureCategory.lifestyle,
      builder: (_) => const CommuteTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Parking Spot',
      icon: Icons.local_parking,
      category: FeatureCategory.lifestyle,
      builder: (_) => const ParkingSpotScreen(),
    ),
    FeatureEntry(
      label: 'Contacts',
      icon: Icons.contacts,
      category: FeatureCategory.lifestyle,
      builder: (_) => const ContactTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Pet Care',
      icon: Icons.pets,
      category: FeatureCategory.lifestyle,
      builder: (_) => const PetCareTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Plant Care',
      icon: Icons.local_florist,
      category: FeatureCategory.lifestyle,
      builder: (_) => const PlantCareTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Recipe Book',
      icon: Icons.menu_book,
      category: FeatureCategory.lifestyle,
      builder: (_) => const RecipeBookScreen(),
    ),
    FeatureEntry(
      label: 'Quote Collection',
      icon: Icons.format_quote,
      category: FeatureCategory.lifestyle,
      builder: (_) => const QuoteCollectionScreen(),
    ),
    FeatureEntry(
      label: 'Music Practice',
      icon: Icons.music_note,
      category: FeatureCategory.lifestyle,
      builder: (_) => const MusicPracticeScreen(),
    ),
    FeatureEntry(
      label: 'Morse Code',
      icon: Icons.radio,
      category: FeatureCategory.lifestyle,
      builder: (_) => const MorseCodeScreen(),
    ),
    FeatureEntry(
      label: 'Decision Journal',
      icon: Icons.balance,
      category: FeatureCategory.lifestyle,
      builder: (_) => const DecisionJournalScreen(),
    ),
    FeatureEntry(
      label: 'Reading List',
      icon: Icons.book,
      category: FeatureCategory.lifestyle,
      builder: (_) => const ReadingListScreen(),
    ),

    // ── Organization ──
    FeatureEntry(
      label: 'Quick Capture',
      icon: Icons.inbox_outlined,
      category: FeatureCategory.organization,
      builder: (_) => const QuickCaptureScreen(),
    ),
    FeatureEntry(
      label: 'Bucket List',
      icon: Icons.format_list_bulleted_add,
      category: FeatureCategory.organization,
      builder: (_) => const BucketListScreen(),
    ),
    FeatureEntry(
      label: 'Wishlist',
      icon: Icons.shopping_cart_outlined,
      category: FeatureCategory.organization,
      builder: (_) => const WishlistScreen(),
    ),
    FeatureEntry(
      label: 'Watchlist',
      icon: Icons.movie_outlined,
      category: FeatureCategory.organization,
      builder: (_) => const WatchlistScreen(),
    ),
    FeatureEntry(
      label: 'Grocery Lists',
      icon: Icons.local_grocery_store,
      category: FeatureCategory.organization,
      builder: (_) => const GroceryListScreen(),
    ),
    FeatureEntry(
      label: 'Packing Lists',
      icon: Icons.luggage,
      category: FeatureCategory.organization,
      builder: (_) => const PackingListScreen(),
    ),
    FeatureEntry(
      label: 'Gift Tracker',
      icon: Icons.card_giftcard,
      category: FeatureCategory.organization,
      builder: (_) => const GiftTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Bookmarks',
      icon: Icons.bookmark_outlined,
      category: FeatureCategory.organization,
      builder: (_) => const BookmarkScreen(),
    ),

    // ── Tracking ──
    FeatureEntry(
      label: 'Home Inventory',
      icon: Icons.inventory_2,
      category: FeatureCategory.tracking,
      builder: (_) => const HomeInventoryScreen(),
    ),
    FeatureEntry(
      label: 'Home Maintenance',
      icon: Icons.home_repair_service,
      category: FeatureCategory.tracking,
      builder: (_) => const HomeMaintenanceScreen(),
    ),
    FeatureEntry(
      label: 'Warranty Tracker',
      icon: Icons.verified_user,
      category: FeatureCategory.tracking,
      builder: (_) => const WarrantyTrackerScreen(),
    ),
    FeatureEntry(
      label: 'Document Expiry',
      icon: Icons.assignment_late,
      category: FeatureCategory.tracking,
      builder: (_) => const DocumentExpiryScreen(),
    ),
    FeatureEntry(
      label: 'Emergency Card',
      icon: Icons.emergency,
      category: FeatureCategory.tracking,
      builder: (_) => const EmergencyCardScreen(),
    ),
    FeatureEntry(
      label: 'Time Capsules',
      icon: Icons.lock_clock,
      category: FeatureCategory.lifestyle,
      builder: (_) => const TimeCapsuleScreen(),
    ),
    FeatureEntry(
      label: 'Random Decision Maker',
      icon: Icons.casino,
      category: FeatureCategory.lifestyle,
      builder: (_) => const RandomDecisionScreen(),
    ),
    FeatureEntry(
      label: 'Vehicle Maintenance',
      icon: Icons.directions_car,
      category: FeatureCategory.tracking,
      builder: (_) => const VehicleMaintenanceScreen(),
    ),
    FeatureEntry(
      label: 'Unit Converter',
      icon: Icons.calculate,
      category: FeatureCategory.lifestyle,
      builder: (_) => const UnitConverterScreen(),
    ),
    FeatureEntry(
      label: 'World Clock',
      icon: Icons.public,
      category: FeatureCategory.lifestyle,
      builder: (_) => const WorldClockScreen(),
    ),
    FeatureEntry(
      label: 'Password Generator',
      icon: Icons.password,
      category: FeatureCategory.organization,
      builder: (_) => const PasswordGeneratorScreen(),
    ),
    FeatureEntry(
      label: 'Color Palette',
      icon: Icons.color_lens,
      category: FeatureCategory.lifestyle,
      builder: (_) => const ColorPaletteScreen(),
    ),
    FeatureEntry(
      label: 'Score Keeper',
      icon: Icons.scoreboard,
      category: FeatureCategory.lifestyle,
      builder: (_) => const ScoreKeeperScreen(),
    ),
    FeatureEntry(
      label: 'Age Calculator',
      icon: Icons.cake,
      category: FeatureCategory.lifestyle,
      builder: (_) => const AgeCalculatorScreen(),
    ),
    FeatureEntry(
      label: 'Dice Roller',
      icon: Icons.casino,
      category: FeatureCategory.lifestyle,
      builder: (_) => const DiceRollerScreen(),
    ),
    FeatureEntry(
      label: 'QR Code Generator',
      icon: Icons.qr_code_2,
      category: FeatureCategory.lifestyle,
      builder: (_) => const QrGeneratorScreen(),
    ),
  ];

  /// Returns features grouped by category, preserving category enum order.
  ///
  /// The result is computed once and cached since [features] is immutable.
  /// Previously this rebuilt the map on every access, which was wasteful
  /// when called from hot paths like the navigation drawer build method.
  static final Map<FeatureCategory, List<FeatureEntry>> grouped = _buildGrouped();

  static Map<FeatureCategory, List<FeatureEntry>> _buildGrouped() {
    final map = <FeatureCategory, List<FeatureEntry>>{};
    for (final category in FeatureCategory.values) {
      final entries = features.where((f) => f.category == category).toList();
      if (entries.isNotEmpty) {
        map[category] = entries;
      }
    }
    return Map.unmodifiable(map);
  }
}
