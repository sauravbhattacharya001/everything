# Service Catalog

This file is an **auto-generated index** of every service in `lib/core/services`. It exists to help developers (and AI coding agents) navigate the codebase without grepping all 200+ files.

- Source of truth: `lib/core/services/*.dart`
- Total services indexed: **240**
- Categories: **9**
- Descriptions are extracted from each file's leading doc comments (`///`). Update those comments to update this catalog.

> **Note**: Some services live under `lib/data/repositories` (persistence adapters) or `lib/state` (BLoCs / providers). This index covers business-logic services only.

## Table of Contents

- [Calendar & Events](#calendar--events) (11)
- [Tasks & Productivity](#tasks--productivity) (48)
- [Goals & Habits](#goals--habits) (26)
- [Health & Wellness](#health--wellness) (30)
- [Finance](#finance) (23)
- [Trackers & Logging](#trackers--logging) (30)
- [Calculators & Converters](#calculators--converters) (36)
- [Games & Fun](#games--fun) (26)
- [Data, Backup & Security](#data-backup--security) (8)

---

## Calendar & Events

- `agenda_digest_service` - Configuration for agenda digest generation.  A single day's agenda within a digest.
- `conflict_detector` - Severity of a scheduling conflict.  A detected conflict between two events.
- `travel_time_estimator` - Travel Time Estimator - computes estimated travel times between events based on geographic distance and transport mode, and detects scheduling conflicts where consecutive events don't leave enough travel time.
- `countdown_timer_service` - Service for managing countdown timers to specific events or deadlines.  A single countdown entry with a name and target date/time.
- `event_deduplication_service` - A pair of events suspected to be duplicates, with a similarity score  and a classification of why they were flagged.  Classification of why two events are considered duplicates.
- `event_pattern_service` - Event Pattern Recognizer - analyzes historical events to discover  recurring patterns the user hasn't explicitly formalized, detect  scheduling habits, and predict likely future events.
- `event_search_service` - Event Search Service - full-text search and advanced filtering for events.   Provides fuzzy text matching across event titles, descriptions, and locations,  combined with structured filters for priority, tags, date range...
- `event_service` - Callback for persistence failures that the UI layer can handle  (e.g. showing a snackbar or marking an event as unsaved).  Coordinates event persistence and in-memory state management.
- `event_sharing_service` - Supported sharing formats for events.  Service that generates shareable representations of events.   Supports plain text, markdown, and deep-link URLs for Google Calendar
- `free_slot_finder` - Free Slot Finder - discovers available time slots in a user's calendar.   Given a list of existing events and constraints (date range, working hours,  minimum slot duration), this service finds gaps where new events can ...
- `ics_export_service` - Service for generating iCalendar (ICS/RFC 5545) content from events.   Supports single event export, bulk export, and recurrence rules.  The generated .ics files can be imported into Google Calendar,
- `snooze_service` - Event Snooze Service - postpone events by preset intervals with  full snooze history tracking, serial-snooze detection, and smart  reschedule suggestions.

## Tasks & Productivity

- `attention_debt_service` - Attention Debt Tracker - autonomous cognitive overhead monitor that tracks  deferred decisions, postponed tasks, and accumulated mental load items.  Models "attention debt" like financial debt: items accrue cognitive int...
- `chronotype_optimizer_service` - Chronotype Optimizer Engine - autonomous circadian rhythm analyzer.   Analyzes activity timing patterns to detect the user's natural chronotype,  identifies peak performance windows for different task types, and provides
- `command_palette_service` - A quick-action that can be executed from the command palette.
- `context_switcher_service` - Smart Context Switcher Service - autonomous life-context detection  with activity pattern analysis, recency weighting, time-of-day  heuristics, and proactive tool suggestions.  Life context categories the user may be ope...
- `crud_service` - Generic CRUD service that eliminates the boilerplate duplicated across  20+ tracker services in the app.   Provides: add, update (by id), remove (by id), getById, clear,
- `daily_review_service` - Daily Review Service - aggregates a day's events into a structured  end-of-day review with completion stats, mood/energy tracking,  highlights, and day-over-day comparison.
- `daily_standup_service` - Daily Standup service - manages quick morning check-ins with  yesterday/today/blockers format. Tracks streaks and completion rates.
- `daily_timeline_service` - Represents a block of time in the daily timeline.   A [TimelineBlock] is either an event or a free gap between events.  Blocks are ordered chronologically and provide metadata for rendering
- `daily_top_three_advisor_service` - Daily Top Three Advisor - agentic synthesizer for "what should I actually  do today?".   Sibling to GoalPortfolioOptimizerService (weekly trade-offs),
- `decision_fatigue_service` - Decision Fatigue Detector - autonomous decision quality monitor that  tracks decision-making patterns throughout the day, detects cognitive  degradation signals, estimates remaining decision capacity, identifies  peak qu...
- `decision_journal_service` - Decision Journal Service - track important decisions, record outcomes,  and analyze decision-making patterns over time.   Use this for structured decision logging: capture context, alternatives,
- `decision_matrix_service` - Decision Matrix service - weighted multi-criteria decision analysis.   Users define options and criteria with weights, score each option  on each criterion, and the service computes weighted totals and ranks.
- `drift_detector_service` - Personal Drift Detector Service - autonomous lifestyle regression  early warning system that monitors gradual negative changes humans  don't notice (the "boiling frog" problem).
- `eisenhower_matrix_service` - Eisenhower Matrix Service - categorizes events into four quadrants  based on urgency and importance for prioritization.   Quadrants:
- `experiment_engine_service` - Life Experiment Engine - autonomous self-experimentation framework.   Users define hypotheses about their habits and wellness, the engine  designs experiments with baseline vs intervention periods, records data,
- `focus_entropy_engine_service` - Focus Entropy Engine - autonomous focus fragmentation detector.   Uses Shannon entropy to measure how scattered attention is across life  domains. Tracks context-switching costs, identifies deep-work blocks,
- `focus_time_service` - Focus Time Service - analyzes calendar schedules to find uninterrupted  deep-work blocks, compute schedule fragmentation, and suggest optimal  focus windows.
- `friction_journal_service` - Friction Journal Engine - autonomous micro-frustration tracker that detects,  categorizes, and patterns recurring friction points in daily life. It surfaces  elimination strategies, tracks friction debt accumulation over...
- `kanban_board_service` - Kanban Board Service - manage boards with customizable columns and cards.   Features:  - Multiple boards with custom names and colors
- `life_dashboard_service` - Aggregated score for a single wellness dimension.  Trend direction for a dimension over time.  A single day's aggregated life score snapshot.  Full dashboard result with all computed data.
- `life_score_service` - The 8 life dimensions tracked by the Life Score Dashboard.  A single assessment entry: scores for all 8 dimensions at a point in time.
- `momentum_engine_service` - Momentum Engine - autonomous completion velocity tracker that monitors  task/habit/goal throughput, classifies momentum state, detects blockers,  and generates adaptive micro-nudges to sustain productive flow.
- `morning_briefing_service` - Morning Briefing service - aggregates signals across trackers to produce  a daily briefing with proactive insights and recommendations.   This is an "inter-system awareness" feature: it correlates data from
- `pattern_detector_service` - Strength classification for a discovered pattern.  A single discovered correlation pattern.  Predictability info for one tracker.  Service that analyses demo tracker data for cross-tracker patterns.
- `persistent_state_mixin` - Mixin for StatefulWidget states that need to persist service data  across app restarts via SharedPreferences.   Subclasses must implement [storageKey], [exportData], and [importData].
- `pomodoro_service` - Pomodoro Timer Service - manages work/break intervals using the  Pomodoro Technique. Tracks completed pomodoros, total focus time,  and session history.
- `productivity_score_service` - Configurable weights for each productivity dimension.
- `project_planner_service` - A single task within a project milestone.  A milestone grouping tasks within a project.
- `quick_capture_service` - Statistics for the capture inbox.  Weekly inbox report.
- `regret_minimization_service` - Regret Minimization Engine - autonomous decision outcome tracker that  analyzes past decisions for regret patterns, identifies cognitive biases,  generates forward-looking wisdom, and helps users make decisions they'll  ...
- `ritual_engine_service` - Adaptive Ritual Engine - autonomous daily ritual optimizer that tracks  routine execution patterns, learns optimal timing windows, detects  disruptions, and generates micro-adjustments to improve ritual adherence.
- `routine_builder_service` - Daily Routine Builder - service logic for ordered step sequences.   Model types (TimeSlot, RoutineStep, Routine, StepStatus, StepCompletion,  RoutineRun, RoutineAnalytics) live in models/routine.dart and are
- `screen_persistence` - Generic persistence helper for tracker screens that store lists of entries  in memory. Provides save/load via [StorageBackend] using model  toJson/fromJson serialization.
- `screen_time_tracker_service` - Breakdown of screen time for a single [AppCategory].  Aggregated screen-time metrics for a single calendar day.  A screen-time limit violation for a specific app or category.  Aggregated screen-time statistics for a seve...
- `service_persistence` - Mixin for adding persistence to stateful services.   Routes all storage through [StorageBackend], which automatically  encrypts sensitive keys (medical, financial, diary data) via
- `storage_backend` - Unified read/write layer that routes storage operations through the  correct backend based on key sensitivity.   Sensitive keys (medical, financial, diary data) are encrypted at rest
- `streak_guardian_service` - Smart Streak Guardian Service - autonomous streak risk monitoring  across all app trackers with proactive warnings, rescue strategies,  and streak health scoring.
- `streak_tracker` - Event Streak Tracker - analyzes event activity patterns to calculate  consecutive-day streaks, activity rates, and streak history.   A "streak" is a series of consecutive calendar days where at least one
- `task_batching_advisor_service` - Task Batching Advisor - agentic clustering advisor that groups pending tasks  by shared context, location, and tool so the user can crush them in batched  windows instead of paying the context-switch tax on every single ...
- `template_service` - Service for managing event templates (built-in presets + custom user templates).   Provides CRUD operations for custom templates and access to built-in presets.  Custom templates are persisted via SharedPreferences.
- `time_audit_service` - Category of time usage.  A single block of time usage.  A detected productivity window.
- `time_budget_service` - Time Budget Service - analyzes how users allocate their time across  event tags, priorities, and days of the week, with configurable  budget targets and overload detection.
- `time_capsule_service` - Service for managing time capsules with local persistence.
- `time_tracker_service` - Service for time tracking analytics and data operations.
- `weekly_planner_service` - Weekly Planner Service - generates a structured weekly plan by analyzing  upcoming events, active goals, scheduled habits, and available free time.   Produces a day-by-day plan with:
- `weekly_reflection_service` - Represents one day's aggregated cross-tracker snapshot.  A detected weekly pattern or insight.  Auto-generated goal suggestion for next week.
- `weekly_report_service` - A summary report for a week's worth of events.  Service that generates weekly productivity reports from event data.
- `weekly_review_synthesizer_service` - Weekly Review Synthesizer Service - agentic end-of-week reflection +  next-week pre-commitment advisor.   Sibling to GoalPortfolioOptimizerService (weekly trade-off),

## Goals & Habits

- `accountability_service` - A single commitment/promise the user tracks.  Icon identifier for sources (avoids importing flutter/material here).  A proactive nudge message.  Weekly trend data point.
- `achievement_service` - Achievement Service - gamification layer that awards badges based on  milestones across all trackers (habits, events, goals, mood, sleep,  fitness, nutrition, productivity, social, learning).
- `affirmation_service` - A single affirmation entry.  Service that manages daily affirmations.
- `balance_radar_engine_service` - Life Balance Radar Engine - autonomous multi-dimensional life balance  assessment. Tracks activity across 8 life dimensions, detects imbalances  via variance/threshold analysis, generates rebalancing recommendations,  an...
- `behavioral_fingerprint_service` - Behavioral Fingerprint Engine - autonomous behavioral signature analysis  that creates a multi-dimensional identity fingerprint from daily patterns  and detects when the user deviates significantly from their baseline se...
- `burnout_detector_service` - Smart Burnout Detector Service - autonomous burnout risk analysis  with multi-signal monitoring, pattern detection, resilience scoring,  and proactive recovery recommendations.  Burnout risk level classification.
- `daily_challenge_service` - Category for daily challenges.  Difficulty level for a challenge.  A single daily challenge definition.  Record of a completed or skipped challenge.
- `daily_journal_service` - Service for managing daily journal / diary entries.
- `goal_autopilot_service` - Goal Autopilot Service - autonomous goal monitoring with  completion prediction, stall detection, velocity tracking,  and proactive recommendations.  Risk level for a goal.
- `goal_checkin_cadence_advisor_service` - Goal Check-in Cadence Advisor - agentic per-goal review-discipline  advisor for a portfolio of goals.   Sibling to:
- `goal_deadline_risk_advisor_service` - Goal Deadline Risk Advisor - agentic deadline-risk forecaster for a  portfolio of goals.   Sibling to:
- `goal_portfolio_optimizer_service` - Goal Portfolio Optimizer Service - agentic cross-goal trade-off advisor.   While [GoalAutopilotService] analyzes risk per individual goal, real users  have *limited weekly capacity* and must make trade-offs across many g...
- `goal_tracker_service` - Goal Tracker Service - manage long-term goals with milestones,  progress tracking, deadlines, and category-based organization.  Summary stats for goal tracking.  Main service for goal tracking.
- `habit_correlation_engine_service` - Habit Correlation Engine - autonomous cross-tracker correlation discovery.   Finds hidden connections between habits, mood, sleep, energy, and other  tracked metrics using Pearson correlation, lagged analysis, synergy
- `habit_insights_service` - ─── Enums ─────────────────────────────────────────────────────────── ─── Data classes ────────────────────────────────────────────────────
- `habit_momentum_service` - Habit Momentum Service - agentic cross-habit streak/risk advisor.   While individual trackers (water, exercise, meditation, sleep, journaling...)  each show their own streak, real users juggle many habits at once. When
- `habit_recovery_advisor_service` - Habit Recovery Advisor - agentic per-habit recovery planner for **broken  or lapsed** habits in a portfolio.   Sibling to:
- `habit_tracker_service` - Habit Tracker service - manages daily habits with streaks and completion tracking.   Each habit has a name, icon, target frequency (daily/weekly), and tracks  completions by date. The service computes current streaks, co...
- `learning_tracker_service` - Service for managing learning items and analytics.
- `life_coach_service` - Represents a nudge/recommendation from the life coach.
- `runway_engine_service` - Personal Runway Engine - autonomous financial resilience calculator.   Computes how long you can sustain your current lifestyle if income stops,  combining savings, monthly expenses, debts, and subscriptions into a
- `savings_goal_service` - Service for managing savings goals with contributions, projections,  and progress tracking.
- `serendipity_engine_service` - Serendipity Engine - autonomous detection of unexpected connections between  disparate life areas. Surfaces "lucky" insights that feel coincidental but  are data-driven, mining patterns across all tracked signals to find...
- `skill_tracker_service` - Report for a single skill's learning progress.  Weekly practice summary.
- `social_capital_engine_service` - Social Capital Engine - autonomous relationship network health analyzer.   Goes beyond simple contact tracking to perform network-level analysis:  strength scoring with exponential decay, decay prediction, cluster
- `stress_cascade_engine_service` - Stress Cascade Engine - autonomous stress propagation and resilience analyzer.   Models how stress in one life domain cascades to others, tracks resilience  buffers, detects tipping points, and forecasts recovery traject...

## Health & Wellness

- `allergy_tracker_service` - Service for managing allergy log entries with encrypted local persistence.   Allergy data (allergens, reactions, severity) is sensitive health  information and is encrypted at rest via [EncryptedPreferencesService].
- `blood_pressure_service` - Summary statistics for a collection of BP readings.  Trend direction for blood pressure over time.  Blood pressure tracking service with statistics, trends, and insights.
- `blood_sugar_service` - Summary statistics for blood sugar readings.  Trend direction for blood sugar over time.  Blood sugar tracking service with statistics, trends, and insights.
- `bmi_calculator_service` - Service for BMI calculation, categorization, and history tracking.  BMI category with label, color hint, and range info.
- `body_measurement_service` - Service for managing body measurement entries.   Refactored to extend [CrudService], eliminating duplicated CRUD  boilerplate (add, update, delete, export/import) while preserving
- `breathing_exercise_service` - A breathing pattern defines the phases and timing of a breathing exercise.
- `caffeine_tracker_service` - Configuration for caffeine tracking.  Daily caffeine summary.  Service for caffeine tracking calculations.
- `chess_clock_service` - Chess clock service supporting multiple time control modes.  A time control configuration.
- `digital_detox_service` - A completed or in-progress digital detox session.   Tracks the user's attempt to stay screen-free for [targetMinutes],  recording [actualMinutes] achieved and any [distractions] encountered.
- `dream_journal_service` - Dream pattern analysis result.  Dream statistics summary.  Service for managing dream journal entries.
- `energy_budget_planner_service` - Energy Budget Planner Service - agentic daily energy/calendar load advisor.   Most planners only ask "does this event fit in my calendar?". The harder  question users actually live is "does this *day* fit in my body?" - ...
- `energy_optimizer_service` - Smart Energy Optimizer Service - autonomous energy prediction with  cross-tracker correlation, circadian modeling, and proactive  work/rest window recommendations.  Energy window types for scheduling recommendations.
- `energy_tracker_service` - Average energy level for a time slot with sample count.  Impact of a factor on energy level relative to baseline.  Energy statistics for a single day.
- `eye_break_service` - Service for the 20-20-20 Eye Break Reminder.   The rule: every 20 minutes of screen time, look at something  20 feet away for 20 seconds to reduce eye strain.
- `fasting_tracker_service` - Weekly fasting summary.  Service for fasting tracker analytics and logic.
- `gratitude_journal_service` - Daily gratitude summary.  Streak information for gratitude journaling.  Weekly gratitude report.
- `medication_tracker_service` - Service for medication tracking logic - adherence, streaks, insights.
- `meditation_tracker_service` - Configuration for meditation tracking.  Daily meditation summary.
- `mood_journal_service` - Service for managing mood journal entries with encrypted local persistence.   Mood journal data (emotions, activities, notes) is sensitive mental  health information and is encrypted at rest via [EncryptedPreferencesServ...
- `reaction_time_service` - In-memory service for tracking reaction time test results.
- `sleep_calculator_service` - Service for calculating optimal sleep and wake times based on  90-minute sleep cycles.   Sleep occurs in ~90-minute cycles. Waking between cycles (rather
- `sleep_tracker_service` - Service for managing sleep log entries with local persistence and analytics.   Sleep data is encrypted at rest via [EncryptedPreferencesService].  Plaintext entries written before this migration are transparently
- `sobriety_counter_service` - Service for tracking sobriety streaks with milestones and multiple trackers.
- `social_battery_service` - ─── Enums ────────────────────────────────────────────────────── ─── Data Classes ───────────────────────────────────────────────
- `spo2_service` - Summary statistics for SpO2 readings.  Trend direction for SpO2 over time.  Blood oxygen tracking service with statistics, trends, and insights.
- `symptom_tracker_service` - Service for managing symptom log entries with encrypted local persistence.   Symptom data (body area, triggers, severity) is sensitive health  information and is encrypted at rest via [EncryptedPreferencesService].
- `water_tracker_service` - Configuration for daily water intake goals.  Daily hydration summary.
- `weight_tracker_service` - Service for weight tracking analytics.
- `willpower_budget_service` - Willpower Budget Engine - autonomous cognitive resource manager that  models daily willpower as a finite, depletable resource (ego depletion  theory). Tracks cognitive demands, estimates remaining budget, predicts  decis...
- `workout_tracker_service` - Configuration for workout tracking.  Personal record for an exercise.  Weekly workout summary.

## Finance

- `meeting_cost_service` - Service for calculating the real cost of meetings based on attendee count, average hourly rate, and duration.
- `bill_reminder_service` - Summary of monthly bill spending.  Service for managing bill reminders.   Refactored to extend [CrudService], eliminating duplicated CRUD
- `budget_planner_service` - Service for managing monthly budgets with category allocations,  spending comparison, templates, and insights.
- `compound_interest_service` - Represents a single point in the compound interest projection.  Frequency of compounding or contributions.  Service for compound interest calculations.
- `coupon_tracker_service` - Summary statistics for the coupon collection.  Service for managing coupons, promo codes, and deals.   Extends [CrudService] for standard CRUD + JSON persistence,
- `currency_converter_service` - Offline currency converter with common exchange rates.   Rates are bundled so the converter works without network access.  Users can update rates manually or use the provided defaults.
- `debt_payoff_service` - Payoff strategy type.  A single month in a payoff schedule.  Summary of a payoff plan.  Service for managing debts and computing payoff strategies.
- `expense_forecast_service` - Trend direction for a category forecast.  Severity levels for alerts and anomalies.  Forecast for a single expense category.  A detected spending anomaly.
- `expense_tracker_service` - Configuration for expense tracking budgets.  Daily spending summary.
- `fire_calculator_service` - A single year in the FIRE projection.  Summary result of a FIRE calculation.  Withdrawal strategy for determining the FIRE number.
- `gift_service` - Service for gift tracker analytics and management logic.
- `invoice_service` - Service for creating and managing simple invoices.
- `loan_calculator_service` - Loan/EMI calculator with amortization schedule generation.
- `loyalty_tracker_service` - Alert for expiring points or membership.  Breakdown by program type.  Monthly earning/redeeming trend.  Top earning category insight.
- `mortgage_calculator_service` - A single row in the amortization schedule.  Summary of a mortgage calculation.  Service for mortgage payment calculations.
- `net_worth_tracker_service` - Monthly net worth snapshot for historical tracking.  Breakdown of net worth by account category.  Comprehensive net worth report.
- `salary_calculator_service` - Service for salary / net-pay calculations.   Supports gross-to-net conversion with:  - Federal income tax (2024 brackets, simplified)
- `subscription_rotation_advisor_service` - Subscription Rotation Advisor - agentic per-subscription keep/downgrade/  pause/cancel/swap advisor for a portfolio of recurring expenses.   Sibling to:
- `subscription_tracker_service` - Alert for an upcoming subscription billing event.  Spending breakdown for a single [SubscriptionCategory].  High-level subscription portfolio summary with cost metrics and alerts.  Service for managing and analyzing recu...
- `tax_calculator_service` - Filing status for US federal income tax.  A single tax bracket.  Result of a tax calculation.  Tax owed in a specific bracket.
- `tip_calculator_service` - Service for tip calculations with split, rounding, and history.
- `unit_price_service` - Service for comparing unit prices across products.
- `warranty_tracker_service` - Alert for warranties expiring soon.  Breakdown of warranties by category.  Overall warranty portfolio summary.
- `wishlist_service` - Service for wishlist analytics and management.

## Trackers & Logging

- `birthday_tracker_service` - Type of occasion being tracked.  A single tracked occasion (birthday, anniversary, etc.).
- `bookmark_service` - Service for bookmark analytics and management.
- `bucket_list_service` - Service for bucket list analytics and insights.
- `chore_tracker_service` - Service for chore tracking analytics and logic.
- `commute_tracker_service` - Service for commute tracking analytics and summaries.
- `contact_tracker_service` - Statistics for a relationship category.  A contact needing follow-up with urgency scoring.  Interaction frequency trend for a contact.  Birthday coming up soon.
- `document_expiry_service` - Service for managing document expiry tracking - CRUD, filtering, analytics.   Extends [CrudService] for standard CRUD + JSON persistence,  adding document-specific urgency tracking, category filtering,
- `emergency_card_service` - Service for emergency info card analytics and utilities.   Provides query, filtering, validation, and export methods for  emergency profiles. Stateless - all data is passed as arguments.
- `flash_card_service` - A single flash card with question and answer.
- `fuel_gauge_service` - Status levels for fuel gauge dimensions.  Trend direction comparing to previous reading.
- `fuel_log_service` - Statistics summary for the fuel log.  Service for managing fuel log entries and computing stats.
- `grocery_list_service` - Grocery List Service - manage multiple grocery lists with categorized items,  quantities, price estimates, and shopping history.  Summary statistics for grocery tracking.  Main service for grocery list management.
- `home_inventory_service` - Room-level inventory summary.  Category-level inventory summary.  Overall home inventory summary for insurance.  Service for managing home inventory items.
- `home_maintenance_service` - Service for managing home maintenance tasks - CRUD, scheduling, analytics.   Extends [CrudService] for standard CRUD + JSON persistence,  adding maintenance-specific scheduling, completion tracking, and
- `library_book_service` - Summary of library book activity.  Service for managing library book borrowings.
- `meal_tracker_service` - Nutrition goals configuration.  Daily nutrition summary.
- `movie_tracker_service` - Service for managing movie log entries with local persistence.
- `music_practice_service` - Music Practice Tracker service - log instrument practice sessions,  track streaks, and monitor progress toward goals.
- `packing_list_service` - Packing List Service - create, manage, and reuse packing lists with  trip-type templates, weight tracking, and progress monitoring.  Built-in packing suggestions by template type.
- `pantry_tracker_service` - Pantry Tracker Service - manage pantry items with expiration tracking,  low-stock alerts, and category/location filtering.  Summary statistics for the pantry.  Main service for pantry management.
- `pet_care_service` - Service for pet care analytics and insights.
- `plant_care_service` - Summary of a single plant's care status.  Fleet-level garden summary.
- `quote_collection_service` - Service for managing a quote collection with search, filtering,  and "quote of the day" functionality.
- `reading_list_service` - Reading challenge / annual goal.  Reading streak info.  Genre distribution stats.
- `recipe_book_service` - Recipe Book Service - manage recipes with ingredients, steps, tags,  ratings, meal planning, and grocery list generation.  Weekly meal plan entry.  Summary statistics for the recipe collection.
- `travel_log_service` - Service for computing travel log statistics and insights.
- `vehicle_maintenance_service` - Alert for upcoming or overdue maintenance.  Cost breakdown by category.  Summary of maintenance across all vehicles.
- `vocabulary_builder_service` - Service for managing vocabulary words with quiz and review features.
- `watchlist_service` - Service for watchlist analytics and recommendations.
- `wiki_service` - Summary statistics for the personal wiki.  Service for managing personal wiki pages.

## Calculators & Converters

- `age_calculator_service` - Service that computes a detailed age breakdown from a birth date.   In addition to exact years/months/days, it produces fun lifetime  statistics (heartbeats, breaths, steps walked, words spoken, etc.)
- `aspect_ratio_service` - Service for aspect ratio calculations, conversions, and common presets.
- `base_converter_service` - Service for converting numbers between bases (binary, octal, decimal, hex)  with support for arbitrary bases 2-36.
- `cipher_tool_service` - Cipher Tool service providing encode/decode for multiple ciphers.
- `color_blindness_service` - Types of color vision deficiency.  Simulates how colors appear to people with color vision deficiency.
- `color_contrast_service` - WCAG contrast ratio result with pass/fail for AA and AAA levels.  Service for checking WCAG 2.1 color contrast ratios.
- `color_mixer_service` - Represents a color in the mixer with its weight.  Color mixing modes.  Service for mixing colors using various blend modes.
- `color_palette_service` - A named color palette with its harmony type.  Supported color harmony types.  Generates harmonious color palettes from a base hue.
- `cron_expression_service` - Service for building and parsing standard 5-field cron expressions.   Fields: minute  hour  day-of-month  month  day-of-week
- `date_calculator_service` - Date Calculator service - compute differences between dates and  add/subtract durations from a given date.
- `gpa_calculator_service` - Service for GPA (Grade Point Average) calculations.   Supports both US 4.0 scale and weighted GPA with custom credit hours.
- `grade_calculator_service` - A single graded assignment/exam entry.  Letter grade thresholds.
- `gradient_generator_service` - Types of gradients the generator can produce.  A single color stop in a gradient.  Preset gradient definitions.
- `hash_generator_service` - Service for computing cryptographic hash digests of text input.
- `json_formatter_service` - Result of a JSON formatting/validation operation.  Statistics about a parsed JSON document.  A node in the JSON tree view.
- `lorem_ipsum_service` - Modes of Lorem Ipsum generation.  Service that generates placeholder Latin text (Lorem Ipsum).
- `markdown_preview_service` - Service for parsing and rendering Markdown to styled widgets.   Supports: headings (h1-h6), bold, italic, bold+italic, strikethrough,  inline code, code blocks, blockquotes, ordered/unordered lists,
- `matrix_calculator_service` - Service for matrix arithmetic operations.   Supports addition, subtraction, multiplication, transpose,  determinant (up to 10×10), and inverse (via Gauss-Jordan).
- `morse_code_service` - Morse Code Translator service.   Converts text ↔ Morse code with support for letters, digits,  and common punctuation. Provides both encoding and decoding.
- `nato_phonetic_service` - NATO Phonetic Alphabet Converter service.   Converts text to NATO phonetic alphabet words and back.  Supports letters (A-Z) and digits (0-9).
- `pace_calculator_service` - Running/cycling pace calculator service.   Supports three calculation modes:  - Given distance + time → pace & speed
- `password_generator_service` - Configuration and result types for password generation.
- `password_strength_service` - Service for analyzing password strength with entropy calculation,  crack-time estimation, pattern detection, and improvement tips.
- `percentage_calculator_service` - Service for common percentage calculations.
- `periodic_table_service` - Data and logic for an interactive periodic table of elements.
- `qr_generator_service` - Minimal QR Code generator using Mode Byte, ECC-L, version 1-6.  No external packages required.
- `regex_tester_service` - Service for regex testing and pattern analysis.   User-supplied regular expressions are executed in a separate [Isolate]  with a hard timeout to prevent ReDoS (Regular Expression Denial of
- `roman_numeral_service` - Service for converting between Roman numerals and decimal numbers.
- `scientific_calculator_service` - A simple expression-based scientific calculator service.   Supports: +, -, *, /, ^, parentheses, and functions:  sin, cos, tan, asin, acos, atan, log, ln, sqrt, abs, factorial (!)
- `sort_visualizer_service` - Supported sorting algorithms.  A single step in the sorting visualization.  Generates step-by-step sorting visualizations.
- `subnet_calculator_service` - Service for IPv4 subnet calculations.
- `sun_moon_service` - Astronomical calculation service for sun/moon positions.   Uses standard solar position algorithms (simplified Meeus) for  sunrise/sunset and a basic lunar phase model. No external API needed.
- `text_stats_service` - Analyzes text and returns detailed statistics including word count,  character count, sentence count, paragraph count, reading time, and  character/word frequency distributions.
- `typing_speed_service` - Holds results of a typing speed test.  Service that manages typing speed test logic.
- `unit_converter_service` - Unit converter service supporting multiple measurement categories.   Each category contains a set of units with conversion factors relative  to a base unit. Temperature uses custom formulas instead.
- `world_clock_service` - Service that manages saved world-clock time zones with persistence.   Each preset carries both its *standard-time* UTC offset and an optional  [DstRule] so that the displayed wall-clock time tracks daylight saving

## Games & Fun

- `ambient_sound_service` - Service for managing ambient sound mixer state.   Each [AmbientSound] represents a loopable ambient audio source  with individual volume control.  The mixer allows multiple sounds
- `ascii_art_service` - Service for generating ASCII art text banners.   Supports multiple font styles and produces multi-line ASCII banners  from plain text input.
- `coin_flip_service` - Result of a single coin flip.  Statistics for coin flip history.  Service that handles coin flip logic, history, and statistics.
- `dice_roller_service` - Represents a single die with a configurable number of sides.  A complete roll result containing all dice rolled.  Common die types used in tabletop gaming.  Service for rolling dice and tracking history.
- `game_2048_service` - Directions for swiping in the 2048 game.  Service that manages the 2048 game logic.   Maintains a 4×4 grid of tile values (0 = empty), handles
- `game_of_life_service` - Service for Conway's Game of Life cellular automaton.   Manages a toroidal grid where cells live or die according to the classic  B3/S23 rule: a dead cell with exactly 3 live neighbors is born, and a
- `hangman_service` - Hangman game service - classic word guessing game.
- `interval_timer_service` - Service for interval timer (work/rest rounds for workouts, HIIT, etc.).  A saved interval timer preset.  Built-in presets for common interval workouts.
- `memory_game_service` - A card in the memory matching game.  Difficulty levels for the memory game.  Game statistics for a completed round.  Service that manages memory card game state and history.
- `metronome_service` - Metronome service - provides tempo tracking, tap-tempo detection,  and common time-signature presets.
- `minesweeper_service` - Difficulty presets for Minesweeper.  Cell state for Minesweeper grid.  Game state enum.  Service managing Minesweeper game logic.
- `pixel_art_service` - Represents a single pixel art canvas with undo/redo support.
- `quick_poll_service` - A single poll with a question and options.
- `random_decision_service` - Random Decision Maker Service - create lists of options, spin to decide,  track decision history, and manage weighted randomness.   Features:
- `rps_service` - Possible moves in Rock Paper Scissors.  Result of a single round.  A single round result.  Statistics for RPS history.
- `score_keeper_service` - Score Keeper service for tracking game scores across multiple players.   Supports named game sessions, per-round scoring, undo, and winner  detection. All data is ephemeral (lives in memory per app session).
- `simon_says_service` - Business logic for the Simon Says memory game.   The game shows a sequence of colored-button flashes that the player must  reproduce in the same order.  Each successful round adds one more flash.
- `sketch_pad_service` - A single stroke on the sketch canvas.  Service that manages sketch pad state with undo/redo support.
- `snake_game_service` - Direction the snake is moving.  A point on the grid.  Service that manages Snake game logic.
- `speed_reader_service` - Speed reading mode.  A single reading session record.  Service for RSVP (Rapid Serial Visual Presentation) speed reading.
- `spin_wheel_service` - A single spin result.  Preset wheel configurations.  Service that manages wheel options, spinning, and history.
- `stopwatch_service` - Stopwatch service with lap tracking, split times, and session history.  Result of lap statistics computation.
- `sudoku_service` - Difficulty levels for Sudoku puzzles.  Service that generates and manages Sudoku puzzles.
- `tally_counter_service` - Service for managing multiple named tally counters with history.  A single tally counter with name, count, and optional target.
- `tetris_game_service` - The 7 standard Tetromino types.  A point on the Tetris board.  A falling tetromino piece with position and rotation.
- `tic_tac_toe_service` - Tic Tac Toe service - game logic with optional AI opponent.   Supports two modes:  - Two-player (local): players alternate turns

## Data, Backup & Security

- `auth_service` - Firebase-backed authentication service.   Wraps [FirebaseAuth] to provide email/password login, sign-up,  password reset, and logout. All Firebase errors are translated
- `correlation_analyzer_service` - A single correlation between two variables.  Strength categories for correlations.
- `data_backup_service` - Unified data backup and restore service.   Discovers all registered storage keys, exports their data into a single  JSON backup, and restores from a backup with optional merge/replace
- `dependency_tracker` - Represents a dependency relationship between two events.   [blockerId] is the event that must be completed before [dependentId].
- `encrypted_backup_service` - Encrypts and decrypts backup data using AES-256-CBC with PBKDF2 key  derivation.   The backup JSON produced by [DataBackupService] contains sensitive
- `encrypted_preferences_service` - Encrypts sensitive tracker data before writing to SharedPreferences.   ## Problem
- `heatmap_service` - A single cell in the heatmap representing one day's event activity.  A full week row in the heatmap (Sun-Sat or Mon-Sun).  Summary statistics for the heatmap period.
- `secure_storage_service` - Secure storage service for sensitive data (tokens, credentials).   Uses platform-specific secure storage:  - iOS: Keychain

---

## Regenerating this file

This file is currently maintained by hand (with help from the repo gardener). The categorization rules and extraction logic live in the gardener task script. To refresh:

1. Add or remove services in `lib/core/services/`.
2. Ensure each new file starts with a `///` doc comment describing what it does.
3. Re-run the catalog generator (or ask the gardener to rebuild it on its next pass).

## Conventions

- **One service per file.** File name = `snake_case_service.dart`; class name = `PascalCaseService`.
- **Pure business logic.** Services should not depend on `flutter/material.dart` - keep widgets in `lib/views`.
- **Persistence via `PersistentStateMixin` or repositories** rather than direct `SharedPreferences` calls.
- **Sensitive data** (health, financial, contacts) is encrypted via `EncryptedPreferencesService` / `SecureStorageService`.
- **Tests live in `test/`** mirroring the service file name: `<service>_test.dart` or `<service>_service_test.dart`.


