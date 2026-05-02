import 'dart:convert';
import 'dart:math';

/// Personal Runway Engine — autonomous financial resilience calculator.
///
/// Computes how long you can sustain your current lifestyle if income stops,
/// combining savings, monthly expenses, debts, and subscriptions into a
/// real-time runway countdown. Includes scenario modeling, burn-rate tracking,
/// autonomous alerts, and recommendations to extend your runway.
///
/// Core concepts:
/// - **Runway**: months of living expenses covered by liquid savings
/// - **Burn Rate**: monthly net cash outflow
/// - **Scenario**: what-if model (job loss, emergency, sabbatical)
/// - **Resilience Score**: 0-100 composite of runway, diversification, trend
/// - **Alert**: proactive warning when runway drops below threshold
/// - **Recommendation**: autonomous suggestion to extend runway

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Categories for savings/asset accounts.
enum AssetCategory {
  checking,
  savings,
  moneyMarket,
  investment,
  crypto,
  cash,
  emergencyFund,
  other;

  String get label {
    switch (this) {
      case AssetCategory.checking:
        return 'Checking';
      case AssetCategory.savings:
        return 'Savings';
      case AssetCategory.moneyMarket:
        return 'Money Market';
      case AssetCategory.investment:
        return 'Investment';
      case AssetCategory.crypto:
        return 'Crypto';
      case AssetCategory.cash:
        return 'Cash';
      case AssetCategory.emergencyFund:
        return 'Emergency Fund';
      case AssetCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case AssetCategory.checking:
        return '🏦';
      case AssetCategory.savings:
        return '💰';
      case AssetCategory.moneyMarket:
        return '📈';
      case AssetCategory.investment:
        return '📊';
      case AssetCategory.crypto:
        return '₿';
      case AssetCategory.cash:
        return '💵';
      case AssetCategory.emergencyFund:
        return '🛡️';
      case AssetCategory.other:
        return '📦';
    }
  }

  /// Liquidity score 0-1 (how quickly can this be converted to cash).
  double get liquidity {
    switch (this) {
      case AssetCategory.checking:
        return 1.0;
      case AssetCategory.savings:
        return 0.95;
      case AssetCategory.moneyMarket:
        return 0.9;
      case AssetCategory.cash:
        return 1.0;
      case AssetCategory.emergencyFund:
        return 0.95;
      case AssetCategory.investment:
        return 0.7;
      case AssetCategory.crypto:
        return 0.6;
      case AssetCategory.other:
        return 0.5;
    }
  }
}

/// Expense categories for burn rate computation.
enum ExpenseCategory {
  housing,
  utilities,
  food,
  transportation,
  insurance,
  healthcare,
  subscriptions,
  debtPayments,
  childcare,
  entertainment,
  clothing,
  personalCare,
  education,
  savings,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.housing:
        return 'Housing';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.insurance:
        return 'Insurance';
      case ExpenseCategory.healthcare:
        return 'Healthcare';
      case ExpenseCategory.subscriptions:
        return 'Subscriptions';
      case ExpenseCategory.debtPayments:
        return 'Debt Payments';
      case ExpenseCategory.childcare:
        return 'Childcare';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.clothing:
        return 'Clothing';
      case ExpenseCategory.personalCare:
        return 'Personal Care';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.savings:
        return 'Savings Contributions';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.housing:
        return '🏠';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.food:
        return '🍽️';
      case ExpenseCategory.transportation:
        return '🚗';
      case ExpenseCategory.insurance:
        return '🛡️';
      case ExpenseCategory.healthcare:
        return '🏥';
      case ExpenseCategory.subscriptions:
        return '📱';
      case ExpenseCategory.debtPayments:
        return '💳';
      case ExpenseCategory.childcare:
        return '👶';
      case ExpenseCategory.entertainment:
        return '🎬';
      case ExpenseCategory.clothing:
        return '👕';
      case ExpenseCategory.personalCare:
        return '💆';
      case ExpenseCategory.education:
        return '📚';
      case ExpenseCategory.savings:
        return '🐷';
      case ExpenseCategory.other:
        return '📦';
    }
  }

  /// Whether this expense is essential (must-pay even in austerity).
  bool get isEssential {
    switch (this) {
      case ExpenseCategory.housing:
      case ExpenseCategory.utilities:
      case ExpenseCategory.food:
      case ExpenseCategory.insurance:
      case ExpenseCategory.healthcare:
      case ExpenseCategory.debtPayments:
      case ExpenseCategory.childcare:
        return true;
      default:
        return false;
    }
  }
}

/// Scenario type for what-if modeling.
enum ScenarioType {
  jobLoss,
  medicalEmergency,
  sabbatical,
  careerChange,
  relocation,
  marketCrash,
  custom;

  String get label {
    switch (this) {
      case ScenarioType.jobLoss:
        return 'Job Loss';
      case ScenarioType.medicalEmergency:
        return 'Medical Emergency';
      case ScenarioType.sabbatical:
        return 'Sabbatical';
      case ScenarioType.careerChange:
        return 'Career Change';
      case ScenarioType.relocation:
        return 'Relocation';
      case ScenarioType.marketCrash:
        return 'Market Crash';
      case ScenarioType.custom:
        return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case ScenarioType.jobLoss:
        return '📉';
      case ScenarioType.medicalEmergency:
        return '🚑';
      case ScenarioType.sabbatical:
        return '🏖️';
      case ScenarioType.careerChange:
        return '🔄';
      case ScenarioType.relocation:
        return '🚚';
      case ScenarioType.marketCrash:
        return '💥';
      case ScenarioType.custom:
        return '⚙️';
    }
  }

  String get description {
    switch (this) {
      case ScenarioType.jobLoss:
        return 'Complete loss of primary income';
      case ScenarioType.medicalEmergency:
        return 'Unexpected medical costs + reduced income';
      case ScenarioType.sabbatical:
        return 'Voluntary time off with no income';
      case ScenarioType.careerChange:
        return 'Income gap during transition';
      case ScenarioType.relocation:
        return 'Moving costs + temporary double expenses';
      case ScenarioType.marketCrash:
        return 'Investment portfolio loses 30-50% value';
      case ScenarioType.custom:
        return 'User-defined scenario';
    }
  }
}

/// Severity level for alerts.
enum AlertSeverity {
  info,
  warning,
  critical;

  String get label {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case AlertSeverity.info:
        return 'ℹ️';
      case AlertSeverity.warning:
        return '⚠️';
      case AlertSeverity.critical:
        return '🚨';
    }
  }
}

/// Resilience tier based on composite score.
enum ResilienceTier {
  fragile,
  vulnerable,
  stable,
  resilient,
  antifragile;

  String get label {
    switch (this) {
      case ResilienceTier.fragile:
        return 'Fragile';
      case ResilienceTier.vulnerable:
        return 'Vulnerable';
      case ResilienceTier.stable:
        return 'Stable';
      case ResilienceTier.resilient:
        return 'Resilient';
      case ResilienceTier.antifragile:
        return 'Antifragile';
    }
  }

  String get emoji {
    switch (this) {
      case ResilienceTier.fragile:
        return '🔴';
      case ResilienceTier.vulnerable:
        return '🟠';
      case ResilienceTier.stable:
        return '🟡';
      case ResilienceTier.resilient:
        return '🟢';
      case ResilienceTier.antifragile:
        return '💎';
    }
  }
}

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

/// A liquid asset / savings account.
class RunwayAsset {
  final String id;
  final String name;
  final AssetCategory category;
  final double balance;
  final DateTime lastUpdated;

  const RunwayAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.balance,
    required this.lastUpdated,
  });

  /// Effective liquid value after applying category liquidity factor.
  double get liquidValue => balance * category.liquidity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.index,
        'balance': balance,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory RunwayAsset.fromJson(Map<String, dynamic> json) => RunwayAsset(
        id: json['id'] as String,
        name: json['name'] as String,
        category: AssetCategory.values[json['category'] as int],
        balance: (json['balance'] as num).toDouble(),
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );
}

/// A recurring monthly expense.
class RunwayExpense {
  final String id;
  final String name;
  final ExpenseCategory category;
  final double monthlyAmount;
  final bool isFixed;

  const RunwayExpense({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyAmount,
    this.isFixed = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.index,
        'monthlyAmount': monthlyAmount,
        'isFixed': isFixed,
      };

  factory RunwayExpense.fromJson(Map<String, dynamic> json) => RunwayExpense(
        id: json['id'] as String,
        name: json['name'] as String,
        category: ExpenseCategory.values[json['category'] as int],
        monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
        isFixed: json['isFixed'] as bool? ?? true,
      );
}

/// A what-if scenario result.
class ScenarioResult {
  final ScenarioType type;
  final String name;
  final double adjustedRunwayMonths;
  final double adjustedBurnRate;
  final double adjustedLiquidAssets;
  final double portfolioHaircut;
  final double additionalMonthlyExpense;
  final double incomeReplacementRate;
  final List<String> recommendations;

  const ScenarioResult({
    required this.type,
    required this.name,
    required this.adjustedRunwayMonths,
    required this.adjustedBurnRate,
    required this.adjustedLiquidAssets,
    this.portfolioHaircut = 0.0,
    this.additionalMonthlyExpense = 0.0,
    this.incomeReplacementRate = 0.0,
    this.recommendations = const [],
  });
}

/// A runway alert.
class RunwayAlert {
  final AlertSeverity severity;
  final String title;
  final String message;
  final String recommendation;
  final DateTime timestamp;

  const RunwayAlert({
    required this.severity,
    required this.title,
    required this.message,
    required this.recommendation,
    required this.timestamp,
  });
}

/// An autonomous recommendation to extend runway.
class RunwayRecommendation {
  final String title;
  final String description;
  final double potentialSavingsPerMonth;
  final double runwayExtensionMonths;
  final String priority; // high, medium, low

  const RunwayRecommendation({
    required this.title,
    required this.description,
    required this.potentialSavingsPerMonth,
    required this.runwayExtensionMonths,
    required this.priority,
  });
}

/// A historical runway snapshot for trend analysis.
class RunwaySnapshot {
  final DateTime date;
  final double runwayMonths;
  final double burnRate;
  final double liquidAssets;
  final double resilienceScore;

  const RunwaySnapshot({
    required this.date,
    required this.runwayMonths,
    required this.burnRate,
    required this.liquidAssets,
    required this.resilienceScore,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'runwayMonths': runwayMonths,
        'burnRate': burnRate,
        'liquidAssets': liquidAssets,
        'resilienceScore': resilienceScore,
      };

  factory RunwaySnapshot.fromJson(Map<String, dynamic> json) =>
      RunwaySnapshot(
        date: DateTime.parse(json['date'] as String),
        runwayMonths: (json['runwayMonths'] as num).toDouble(),
        burnRate: (json['burnRate'] as num).toDouble(),
        liquidAssets: (json['liquidAssets'] as num).toDouble(),
        resilienceScore: (json['resilienceScore'] as num).toDouble(),
      );
}

/// Burn rate breakdown by category.
class BurnRateBreakdown {
  final ExpenseCategory category;
  final double amount;
  final double percentage;
  final bool isEssential;

  const BurnRateBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.isEssential,
  });
}

/// Complete runway analysis result.
class RunwayAnalysis {
  final double totalLiquidAssets;
  final double totalGrossAssets;
  final double monthlyBurnRate;
  final double essentialBurnRate;
  final double discretionaryBurnRate;
  final double runwayMonthsFull;
  final double runwayMonthsEssentialOnly;
  final double resilienceScore;
  final ResilienceTier tier;
  final List<BurnRateBreakdown> burnBreakdown;
  final List<ScenarioResult> scenarios;
  final List<RunwayAlert> alerts;
  final List<RunwayRecommendation> recommendations;
  final List<RunwaySnapshot> history;
  final double? runwayTrendPerMonth;
  final DateTime analyzedAt;

  const RunwayAnalysis({
    required this.totalLiquidAssets,
    required this.totalGrossAssets,
    required this.monthlyBurnRate,
    required this.essentialBurnRate,
    required this.discretionaryBurnRate,
    required this.runwayMonthsFull,
    required this.runwayMonthsEssentialOnly,
    required this.resilienceScore,
    required this.tier,
    required this.burnBreakdown,
    required this.scenarios,
    required this.alerts,
    required this.recommendations,
    required this.history,
    this.runwayTrendPerMonth,
    required this.analyzedAt,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Autonomous personal runway calculator and resilience analyzer.
///
/// Engines:
/// 1. **Runway Calculator** — computes months of living from liquid assets ÷ burn rate
/// 2. **Burn Rate Analyzer** — breaks down expenses into essential vs discretionary
/// 3. **Scenario Simulator** — models what-if events (job loss, emergency, etc.)
/// 4. **Resilience Scorer** — composite 0-100 score across multiple dimensions
/// 5. **Alert Generator** — proactive warnings when thresholds are breached
/// 6. **Recommendation Engine** — autonomous suggestions to extend runway
/// 7. **Trend Tracker** — historical snapshots with linear regression trend
class RunwayEngineService {
  final List<RunwayAsset> _assets = [];
  final List<RunwayExpense> _expenses = [];
  final List<RunwaySnapshot> _history = [];

  // Configurable thresholds
  double criticalRunwayMonths;
  double warningRunwayMonths;
  double targetRunwayMonths;

  RunwayEngineService({
    this.criticalRunwayMonths = 3.0,
    this.warningRunwayMonths = 6.0,
    this.targetRunwayMonths = 12.0,
  });

  List<RunwayAsset> get assets => List.unmodifiable(_assets);
  List<RunwayExpense> get expenses => List.unmodifiable(_expenses);
  List<RunwaySnapshot> get history => List.unmodifiable(_history);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  void addAsset(RunwayAsset asset) => _assets.add(asset);

  void removeAsset(String id) => _assets.removeWhere((a) => a.id == id);

  void updateAsset(RunwayAsset updated) {
    final idx = _assets.indexWhere((a) => a.id == updated.id);
    if (idx >= 0) _assets[idx] = updated;
  }

  void addExpense(RunwayExpense expense) => _expenses.add(expense);

  void removeExpense(String id) => _expenses.removeWhere((e) => e.id == id);

  void updateExpense(RunwayExpense updated) {
    final idx = _expenses.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) _expenses[idx] = updated;
  }

  void addSnapshot(RunwaySnapshot snapshot) => _history.add(snapshot);

  // ---------------------------------------------------------------------------
  // Engine 1: Runway Calculator
  // ---------------------------------------------------------------------------

  double get totalGrossAssets =>
      _assets.fold(0.0, (sum, a) => sum + a.balance);

  double get totalLiquidAssets =>
      _assets.fold(0.0, (sum, a) => sum + a.liquidValue);

  double get monthlyBurnRate =>
      _expenses.fold(0.0, (sum, e) => sum + e.monthlyAmount);

  double get essentialBurnRate => _expenses
      .where((e) => e.category.isEssential)
      .fold(0.0, (sum, e) => sum + e.monthlyAmount);

  double get discretionaryBurnRate => monthlyBurnRate - essentialBurnRate;

  /// Full runway: liquid assets ÷ total burn rate.
  double get runwayMonthsFull =>
      monthlyBurnRate > 0 ? totalLiquidAssets / monthlyBurnRate : double.infinity;

  /// Austerity runway: liquid assets ÷ essential-only burn rate.
  double get runwayMonthsEssentialOnly =>
      essentialBurnRate > 0
          ? totalLiquidAssets / essentialBurnRate
          : double.infinity;

  // ---------------------------------------------------------------------------
  // Engine 2: Burn Rate Analyzer
  // ---------------------------------------------------------------------------

  List<BurnRateBreakdown> analyzeBurnRate() {
    final total = monthlyBurnRate;
    if (total <= 0) return [];

    final byCategory = <ExpenseCategory, double>{};
    for (final e in _expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0.0) + e.monthlyAmount;
    }

    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .map((e) => BurnRateBreakdown(
              category: e.key,
              amount: e.value,
              percentage: (e.value / total) * 100,
              isEssential: e.key.isEssential,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Engine 3: Scenario Simulator
  // ---------------------------------------------------------------------------

  List<ScenarioResult> runScenarios() {
    final liquid = totalLiquidAssets;
    final burn = monthlyBurnRate;
    if (burn <= 0) return [];

    return [
      _simulateJobLoss(liquid, burn),
      _simulateMedicalEmergency(liquid, burn),
      _simulateSabbatical(liquid, burn),
      _simulateCareerChange(liquid, burn),
      _simulateRelocation(liquid, burn),
      _simulateMarketCrash(liquid, burn),
    ];
  }

  ScenarioResult _simulateJobLoss(double liquid, double burn) {
    // Assume unemployment benefits replace 40% of discretionary spending reduction
    final austerityBurn = essentialBurnRate + (discretionaryBurnRate * 0.3);
    final runway = austerityBurn > 0 ? liquid / austerityBurn : double.infinity;
    return ScenarioResult(
      type: ScenarioType.jobLoss,
      name: 'Job Loss',
      adjustedRunwayMonths: runway,
      adjustedBurnRate: austerityBurn,
      adjustedLiquidAssets: liquid,
      incomeReplacementRate: 0.0,
      recommendations: [
        if (runway < 6) 'Build emergency fund to cover 6 months of essentials',
        if (runway < 3) 'URGENT: Less than 3 months runway — reduce expenses immediately',
        'Consider income protection insurance',
        'Maintain professional network for faster re-employment',
      ],
    );
  }

  ScenarioResult _simulateMedicalEmergency(double liquid, double burn) {
    // Assume \$5k-15k one-time cost + 20% higher monthly for 6 months
    final oneTimeCost = 10000.0;
    final adjustedLiquid = liquid - oneTimeCost;
    final adjustedBurn = burn * 1.2;
    final runway = adjustedBurn > 0
        ? (adjustedLiquid > 0 ? adjustedLiquid / adjustedBurn : 0)
        : double.infinity;
    return ScenarioResult(
      type: ScenarioType.medicalEmergency,
      name: 'Medical Emergency',
      adjustedRunwayMonths: runway,
      adjustedBurnRate: adjustedBurn,
      adjustedLiquidAssets: adjustedLiquid,
      additionalMonthlyExpense: burn * 0.2,
      recommendations: [
        'Review health insurance coverage and deductibles',
        'Maintain HSA/FSA contributions',
        if (runway < 3) 'Medical emergency would be financially devastating — prioritize emergency fund',
      ],
    );
  }

  ScenarioResult _simulateSabbatical(double liquid, double burn) {
    // No income, full expenses continue
    final runway = burn > 0 ? liquid / burn : double.infinity;
    return ScenarioResult(
      type: ScenarioType.sabbatical,
      name: 'Sabbatical (6 months)',
      adjustedRunwayMonths: runway,
      adjustedBurnRate: burn,
      adjustedLiquidAssets: liquid,
      incomeReplacementRate: 0.0,
      recommendations: [
        'Save ${(burn * 6).toStringAsFixed(0)} before taking a 6-month sabbatical',
        if (runway >= 12) 'You can comfortably take a 6-month sabbatical',
        if (runway < 6) 'Not enough runway for a sabbatical — build savings first',
      ],
    );
  }

  ScenarioResult _simulateCareerChange(double liquid, double burn) {
    // Assume 3-month gap + training costs
    final trainingCost = 3000.0;
    final adjustedLiquid = liquid - trainingCost;
    final runway = burn > 0
        ? (adjustedLiquid > 0 ? adjustedLiquid / burn : 0)
        : double.infinity;
    return ScenarioResult(
      type: ScenarioType.careerChange,
      name: 'Career Change',
      adjustedRunwayMonths: runway,
      adjustedBurnRate: burn,
      adjustedLiquidAssets: adjustedLiquid,
      additionalMonthlyExpense: 0,
      recommendations: [
        'Budget 3-6 months of expenses for career transition',
        'Consider part-time work during transition',
        if (runway < 6) 'Build more savings before making a career switch',
      ],
    );
  }

  ScenarioResult _simulateRelocation(double liquid, double burn) {
    // Moving costs + 2 months of double rent
    final movingCost = 5000.0;
    final doubleRent = _expenses
            .where((e) => e.category == ExpenseCategory.housing)
            .fold(0.0, (sum, e) => sum + e.monthlyAmount) *
        2;
    final adjustedLiquid = liquid - movingCost - doubleRent;
    final adjustedBurn = burn * 1.1; // Slightly higher in new location
    final runway = adjustedBurn > 0
        ? (adjustedLiquid > 0 ? adjustedLiquid / adjustedBurn : 0)
        : double.infinity;
    return ScenarioResult(
      type: ScenarioType.relocation,
      name: 'Relocation',
      adjustedRunwayMonths: runway,
      adjustedBurnRate: adjustedBurn,
      adjustedLiquidAssets: adjustedLiquid,
      additionalMonthlyExpense: burn * 0.1,
      recommendations: [
        'Budget \$${(movingCost + doubleRent).toStringAsFixed(0)} for moving costs',
        'Research cost of living in target area',
        if (runway < 3) 'Relocation would strain finances — save more first',
      ],
    );
  }

  ScenarioResult _simulateMarketCrash(double liquid, double burn) {
    // Investments lose 40%, other assets unaffected
    double adjustedLiquid = 0;
    for (final a in _assets) {
      if (a.category == AssetCategory.investment ||
          a.category == AssetCategory.crypto) {
        adjustedLiquid += a.liquidValue * 0.6; // 40% loss
      } else {
        adjustedLiquid += a.liquidValue;
      }
    }
    final runway = burn > 0 ? adjustedLiquid / burn : double.infinity;
    final haircut = liquid - adjustedLiquid;
    return ScenarioResult(
      type: ScenarioType.marketCrash,
      name: 'Market Crash (-40%)',
      adjustedRunwayMonths: runway,
      adjustedBurnRate: burn,
      adjustedLiquidAssets: adjustedLiquid,
      portfolioHaircut: haircut,
      recommendations: [
        'Diversify assets — don\'t keep all savings in volatile investments',
        'Maintain 3-6 months in high-liquidity accounts (checking/savings)',
        if (haircut > liquid * 0.3)
          'Over 30% of your runway is in volatile assets — consider rebalancing',
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Engine 4: Resilience Scorer
  // ---------------------------------------------------------------------------

  /// Composite resilience score 0-100.
  ///
  /// Dimensions (weighted):
  /// - Runway length (35%): months of coverage
  /// - Asset diversification (20%): spread across categories
  /// - Essential coverage (20%): runway for essentials only
  /// - Trend direction (15%): improving or worsening
  /// - Liquidity ratio (10%): liquid vs gross assets
  double computeResilienceScore() {
    if (_assets.isEmpty && _expenses.isEmpty) return 0;

    // Runway length score (35%)
    final rMonths = runwayMonthsFull;
    final runwayScore = rMonths.isInfinite
        ? 100.0
        : (rMonths / targetRunwayMonths * 100).clamp(0, 100).toDouble();

    // Asset diversification score (20%)
    final categories = <AssetCategory>{};
    for (final a in _assets) {
      if (a.balance > 0) categories.add(a.category);
    }
    final diversificationScore =
        (categories.length / AssetCategory.values.length * 100).clamp(0, 100).toDouble();

    // Essential coverage score (20%)
    final essentialMonths = runwayMonthsEssentialOnly;
    final essentialScore = essentialMonths.isInfinite
        ? 100.0
        : (essentialMonths / (targetRunwayMonths * 1.5) * 100).clamp(0, 100).toDouble();

    // Trend score (15%)
    final trend = _computeTrend();
    final trendScore = trend == null
        ? 50.0
        : (50 + trend * 10).clamp(0, 100).toDouble(); // positive trend boosts score

    // Liquidity ratio score (10%)
    final gross = totalGrossAssets;
    final liquidityScore = gross > 0
        ? (totalLiquidAssets / gross * 100).clamp(0, 100).toDouble()
        : 0.0;

    return (runwayScore * 0.35 +
            diversificationScore * 0.20 +
            essentialScore * 0.20 +
            trendScore * 0.15 +
            liquidityScore * 0.10)
        .clamp(0, 100);
  }

  ResilienceTier computeTier(double score) {
    if (score >= 85) return ResilienceTier.antifragile;
    if (score >= 70) return ResilienceTier.resilient;
    if (score >= 50) return ResilienceTier.stable;
    if (score >= 30) return ResilienceTier.vulnerable;
    return ResilienceTier.fragile;
  }

  // ---------------------------------------------------------------------------
  // Engine 5: Alert Generator
  // ---------------------------------------------------------------------------

  List<RunwayAlert> generateAlerts() {
    final alerts = <RunwayAlert>[];
    final now = DateTime.now();
    final rMonths = runwayMonthsFull;

    if (rMonths < criticalRunwayMonths) {
      alerts.add(RunwayAlert(
        severity: AlertSeverity.critical,
        title: 'Critical Runway',
        message:
            'Only ${rMonths.toStringAsFixed(1)} months of runway remaining!',
        recommendation:
            'Immediately reduce discretionary spending and explore additional income sources.',
        timestamp: now,
      ));
    } else if (rMonths < warningRunwayMonths) {
      alerts.add(RunwayAlert(
        severity: AlertSeverity.warning,
        title: 'Low Runway',
        message:
            '${rMonths.toStringAsFixed(1)} months of runway — below recommended ${warningRunwayMonths.toStringAsFixed(0)} months.',
        recommendation:
            'Start building your emergency fund and review discretionary expenses.',
        timestamp: now,
      ));
    }

    // Burn rate concentration alert
    final breakdown = analyzeBurnRate();
    for (final b in breakdown) {
      if (b.percentage > 40) {
        alerts.add(RunwayAlert(
          severity: AlertSeverity.warning,
          title: 'Expense Concentration',
          message:
              '${b.category.label} is ${b.percentage.toStringAsFixed(0)}% of your burn rate.',
          recommendation:
              'High concentration in one category increases vulnerability. Explore ways to reduce ${b.category.label.toLowerCase()} costs.',
          timestamp: now,
        ));
      }
    }

    // Negative trend alert
    final trend = _computeTrend();
    if (trend != null && trend < -0.5) {
      alerts.add(RunwayAlert(
        severity: AlertSeverity.warning,
        title: 'Declining Runway',
        message:
            'Runway is shrinking by ${(-trend).toStringAsFixed(1)} months per month.',
        recommendation:
            'Your financial resilience is trending down. Review recent expense changes.',
        timestamp: now,
      ));
    }

    // Asset staleness alert
    final staleAssets = _assets
        .where(
            (a) => DateTime.now().difference(a.lastUpdated).inDays > 30)
        .toList();
    if (staleAssets.isNotEmpty) {
      alerts.add(RunwayAlert(
        severity: AlertSeverity.info,
        title: 'Stale Balances',
        message:
            '${staleAssets.length} asset(s) haven\'t been updated in over 30 days.',
        recommendation:
            'Update your account balances for a more accurate runway calculation.',
        timestamp: now,
      ));
    }

    return alerts;
  }

  // ---------------------------------------------------------------------------
  // Engine 6: Recommendation Engine
  // ---------------------------------------------------------------------------

  List<RunwayRecommendation> generateRecommendations() {
    final recs = <RunwayRecommendation>[];
    final burn = monthlyBurnRate;
    if (burn <= 0) return recs;

    final breakdown = analyzeBurnRate();

    // Find discretionary categories that could be cut
    for (final b in breakdown) {
      if (!b.isEssential && b.amount > 0) {
        final potentialCut = b.amount * 0.3; // Suggest 30% reduction
        final extension = totalLiquidAssets > 0 && (burn - potentialCut) > 0
            ? totalLiquidAssets / (burn - potentialCut) - runwayMonthsFull
            : 0.0;
        if (extension > 0.1) {
          recs.add(RunwayRecommendation(
            title: 'Reduce ${b.category.label}',
            description:
                'Cut ${b.category.label.toLowerCase()} spending by 30% to extend runway by ${extension.toStringAsFixed(1)} months.',
            potentialSavingsPerMonth: potentialCut,
            runwayExtensionMonths: extension,
            priority: extension > 2 ? 'high' : (extension > 1 ? 'medium' : 'low'),
          ));
        }
      }
    }

    // Diversification recommendation
    final categories = <AssetCategory>{};
    for (final a in _assets) {
      if (a.balance > 0) categories.add(a.category);
    }
    if (categories.length < 3 && _assets.isNotEmpty) {
      recs.add(RunwayRecommendation(
        title: 'Diversify Assets',
        description:
            'You only have ${categories.length} asset type(s). Spread savings across checking, savings, and investments for better resilience.',
        potentialSavingsPerMonth: 0,
        runwayExtensionMonths: 0,
        priority: 'medium',
      ));
    }

    // Emergency fund recommendation
    final emergencyFund = _assets
        .where((a) => a.category == AssetCategory.emergencyFund)
        .fold(0.0, (sum, a) => sum + a.balance);
    final sixMonthEssentials = essentialBurnRate * 6;
    if (emergencyFund < sixMonthEssentials && essentialBurnRate > 0) {
      final deficit = sixMonthEssentials - emergencyFund;
      recs.add(RunwayRecommendation(
        title: 'Build Emergency Fund',
        description:
            'Your emergency fund covers ${emergencyFund > 0 ? (emergencyFund / essentialBurnRate).toStringAsFixed(1) : "0"} months of essentials. Target: 6 months (\$${sixMonthEssentials.toStringAsFixed(0)}). Deficit: \$${deficit.toStringAsFixed(0)}.',
        potentialSavingsPerMonth: 0,
        runwayExtensionMonths: 0,
        priority: emergencyFund < essentialBurnRate * 3 ? 'high' : 'medium',
      ));
    }

    // Sort by runway extension (descending), then priority
    recs.sort((a, b) {
      final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final pa = priorityOrder[a.priority] ?? 2;
      final pb = priorityOrder[b.priority] ?? 2;
      if (pa != pb) return pa.compareTo(pb);
      return b.runwayExtensionMonths.compareTo(a.runwayExtensionMonths);
    });

    return recs;
  }

  // ---------------------------------------------------------------------------
  // Engine 7: Trend Tracker
  // ---------------------------------------------------------------------------

  /// Linear regression slope of runway months over time.
  /// Returns months-gained-per-month, or null if insufficient data.
  double? _computeTrend() {
    if (_history.length < 2) return null;

    // Use last 12 snapshots
    final recent = _history.length > 12
        ? _history.sublist(_history.length - 12)
        : _history;

    final n = recent.length;
    final firstDate = recent.first.date;
    final xs = recent
        .map((s) => s.date.difference(firstDate).inDays / 30.0)
        .toList();
    final ys = recent.map((s) => s.runwayMonths).toList();

    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double denominator = 0;
    for (int i = 0; i < n; i++) {
      numerator += (xs[i] - meanX) * (ys[i] - meanY);
      denominator += (xs[i] - meanX) * (xs[i] - meanX);
    }

    if (denominator == 0) return 0;
    return numerator / denominator;
  }

  // ---------------------------------------------------------------------------
  // Full Analysis
  // ---------------------------------------------------------------------------

  /// Run complete runway analysis across all 7 engines.
  RunwayAnalysis analyze() {
    final score = computeResilienceScore();
    final tier = computeTier(score);
    final trend = _computeTrend();

    // Take a snapshot
    final snapshot = RunwaySnapshot(
      date: DateTime.now(),
      runwayMonths: runwayMonthsFull.isInfinite ? 999 : runwayMonthsFull,
      burnRate: monthlyBurnRate,
      liquidAssets: totalLiquidAssets,
      resilienceScore: score,
    );

    return RunwayAnalysis(
      totalLiquidAssets: totalLiquidAssets,
      totalGrossAssets: totalGrossAssets,
      monthlyBurnRate: monthlyBurnRate,
      essentialBurnRate: essentialBurnRate,
      discretionaryBurnRate: discretionaryBurnRate,
      runwayMonthsFull: runwayMonthsFull,
      runwayMonthsEssentialOnly: runwayMonthsEssentialOnly,
      resilienceScore: score,
      tier: tier,
      burnBreakdown: analyzeBurnRate(),
      scenarios: runScenarios(),
      alerts: generateAlerts(),
      recommendations: generateRecommendations(),
      history: List.from(_history)..add(snapshot),
      runwayTrendPerMonth: trend,
      analyzedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'assets': _assets.map((a) => a.toJson()).toList(),
        'expenses': _expenses.map((e) => e.toJson()).toList(),
        'history': _history.map((s) => s.toJson()).toList(),
        'criticalRunwayMonths': criticalRunwayMonths,
        'warningRunwayMonths': warningRunwayMonths,
        'targetRunwayMonths': targetRunwayMonths,
      };

  factory RunwayEngineService.fromJson(Map<String, dynamic> json) {
    final service = RunwayEngineService(
      criticalRunwayMonths:
          (json['criticalRunwayMonths'] as num?)?.toDouble() ?? 3.0,
      warningRunwayMonths:
          (json['warningRunwayMonths'] as num?)?.toDouble() ?? 6.0,
      targetRunwayMonths:
          (json['targetRunwayMonths'] as num?)?.toDouble() ?? 12.0,
    );

    final assets = json['assets'] as List<dynamic>? ?? [];
    for (final a in assets) {
      service.addAsset(RunwayAsset.fromJson(a as Map<String, dynamic>));
    }

    final expenses = json['expenses'] as List<dynamic>? ?? [];
    for (final e in expenses) {
      service.addExpense(RunwayExpense.fromJson(e as Map<String, dynamic>));
    }

    final history = json['history'] as List<dynamic>? ?? [];
    for (final s in history) {
      service.addSnapshot(RunwaySnapshot.fromJson(s as Map<String, dynamic>));
    }

    return service;
  }
}
