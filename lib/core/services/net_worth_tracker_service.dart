import 'dart:convert';
import 'dart:math';
import '../../models/net_worth_account.dart';

/// Monthly net worth snapshot for historical tracking.
class MonthlyNetWorth {
  final int year;
  final int month;
  final double totalAssets;
  final double totalLiabilities;

  const MonthlyNetWorth({
    required this.year,
    required this.month,
    required this.totalAssets,
    required this.totalLiabilities,
  });

  double get netWorth => totalAssets - totalLiabilities;

  DateTime get date => DateTime(year, month);

  String get label =>
      '${_monthNames[month - 1]} $year';

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

/// Breakdown of net worth by account category.
class CategoryBreakdown {
  final AccountCategory category;
  final double total;
  final int accountCount;
  final double percentOfType;

  const CategoryBreakdown({
    required this.category,
    required this.total,
    required this.accountCount,
    required this.percentOfType,
  });
}

/// Comprehensive net worth report.
class NetWorthReport {
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final double? monthOverMonthChange;
  final double? monthOverMonthPercent;
  final double? yearOverYearChange;
  final int totalAccounts;
  final int staleAccounts;
  final List<CategoryBreakdown> assetBreakdown;
  final List<CategoryBreakdown> liabilityBreakdown;
  final List<MonthlyNetWorth> history;
  final String summary;
  final DateTime generatedAt;

  const NetWorthReport({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    this.monthOverMonthChange,
    this.monthOverMonthPercent,
    this.yearOverYearChange,
    required this.totalAccounts,
    required this.staleAccounts,
    required this.assetBreakdown,
    required this.liabilityBreakdown,
    required this.history,
    required this.summary,
    required this.generatedAt,
  });
}

/// Milestones for celebrating net worth achievements.
class NetWorthMilestone {
  final String label;
  final double target;
  final bool reached;
  final DateTime? reachedDate;

  const NetWorthMilestone({
    required this.label,
    required this.target,
    required this.reached,
    this.reachedDate,
  });
}

/// Service for managing financial accounts and computing net worth
/// over time with trend analysis and milestone tracking.
class NetWorthTrackerService {
  final List<NetWorthAccount> _accounts = [];

  List<NetWorthAccount> get accounts => List.unmodifiable(_accounts);

  List<NetWorthAccount> get activeAccounts =>
      _accounts.where((a) => !a.isArchived).toList();

  List<NetWorthAccount> get assets =>
      activeAccounts.where((a) => a.type == AccountType.asset).toList();

  List<NetWorthAccount> get liabilities =>
      activeAccounts.where((a) => a.type == AccountType.liability).toList();

  // ── CRUD ──────────────────────────────────────────────────────────

  /// Add a new account. Returns the created account.
  NetWorthAccount addAccount({
    required String name,
    required AccountType type,
    AccountCategory category = AccountCategory.other,
    String? emoji,
    String? institution,
    String? notes,
    double? initialBalance,
  }) {
    if (name.trim().isEmpty) throw ArgumentError('Name cannot be empty');

    final account = NetWorthAccount(
      id: _generateId(),
      name: name.trim(),
      emoji: emoji ?? category.defaultEmoji,
      type: type,
      category: category,
      institution: institution,
      notes: notes,
      snapshots: initialBalance != null
          ? [BalanceSnapshot(date: DateTime.now(), balance: initialBalance)]
          : [],
    );
    _accounts.add(account);
    return account;
  }

  /// Update an existing account's properties (not balance).
  NetWorthAccount? updateAccount(
    String accountId, {
    String? name,
    String? emoji,
    AccountCategory? category,
    String? institution,
    String? notes,
  }) {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx == -1) return null;

    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    _accounts[idx] = _accounts[idx].copyWith(
      name: name,
      emoji: emoji,
      category: category,
      institution: institution,
      notes: notes,
    );
    return _accounts[idx];
  }

  /// Record a new balance snapshot for an account.
  BalanceSnapshot? recordBalance(
    String accountId,
    double balance, {
    DateTime? date,
    String? note,
  }) {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx == -1) return null;
    if (balance < 0) throw ArgumentError('Balance cannot be negative');

    final snapshot = BalanceSnapshot(
      date: date ?? DateTime.now(),
      balance: balance,
      note: note,
    );

    final updated = List<BalanceSnapshot>.from(_accounts[idx].snapshots)
      ..add(snapshot);
    _accounts[idx] = _accounts[idx].copyWith(snapshots: updated);
    return snapshot;
  }

  /// Archive an account (soft delete).
  bool archiveAccount(String accountId) {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx == -1) return false;
    _accounts[idx] = _accounts[idx].copyWith(isArchived: true);
    return true;
  }

  /// Restore an archived account.
  bool restoreAccount(String accountId) {
    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx == -1) return false;
    _accounts[idx] = _accounts[idx].copyWith(isArchived: false);
    return true;
  }

  /// Permanently remove an account.
  bool removeAccount(String accountId) {
    final before = _accounts.length;
    _accounts.removeWhere((a) => a.id == accountId);
    return _accounts.length < before;
  }

  /// Find account by ID.
  NetWorthAccount? getAccount(String accountId) {
    try {
      return _accounts.firstWhere((a) => a.id == accountId);
    } catch (_) {
      return null;
    }
  }

  // ── Net Worth Calculations ────────────────────────────────────────

  /// Current total assets.
  double get totalAssets =>
      assets.fold(0.0, (sum, a) => sum + a.currentBalance);

  /// Current total liabilities.
  double get totalLiabilities =>
      liabilities.fold(0.0, (sum, a) => sum + a.currentBalance);

  /// Current net worth (assets − liabilities).
  double get netWorth => totalAssets - totalLiabilities;

  /// Net worth at a specific date.
  double netWorthAt(DateTime date) {
    double assetTotal = 0;
    double liabilityTotal = 0;
    for (final account in _accounts.where((a) => !a.isArchived)) {
      final balance = account.balanceAt(date);
      if (account.type == AccountType.asset) {
        assetTotal += balance;
      } else {
        liabilityTotal += balance;
      }
    }
    return assetTotal - liabilityTotal;
  }

  /// Net worth change over the last N days.
  double? netWorthChange(int days) {
    final now = DateTime.now();
    final past = now.subtract(Duration(days: days));
    final pastNW = netWorthAt(past);
    if (pastNW == 0 && netWorth == 0) return null;
    return netWorth - pastNW;
  }

  /// Percent change over the last N days.
  double? netWorthChangePercent(int days) {
    final now = DateTime.now();
    final past = now.subtract(Duration(days: days));
    final pastNW = netWorthAt(past);
    if (pastNW == 0) return null;
    return (netWorth - pastNW) / pastNW.abs();
  }

  // ── Category Analysis ─────────────────────────────────────────────

  /// Breakdown of assets by category.
  List<CategoryBreakdown> get assetBreakdown =>
      _breakdownByType(AccountType.asset);

  /// Breakdown of liabilities by category.
  List<CategoryBreakdown> get liabilityBreakdown =>
      _breakdownByType(AccountType.liability);

  List<CategoryBreakdown> _breakdownByType(AccountType type) {
    final filtered = activeAccounts.where((a) => a.type == type).toList();
    final total = filtered.fold(0.0, (sum, a) => sum + a.currentBalance);

    final byCategory = <AccountCategory, List<NetWorthAccount>>{};
    for (final account in filtered) {
      byCategory.putIfAbsent(account.category, () => []).add(account);
    }

    final result = byCategory.entries.map((entry) {
      final catTotal =
          entry.value.fold(0.0, (sum, a) => sum + a.currentBalance);
      return CategoryBreakdown(
        category: entry.key,
        total: catTotal,
        accountCount: entry.value.length,
        percentOfType: total > 0 ? catTotal / total : 0.0,
      );
    }).toList();

    result.sort((a, b) => b.total.compareTo(a.total));
    return result;
  }

  // ── Historical Tracking ───────────────────────────────────────────

  /// Monthly net worth history for the past N months.
  List<MonthlyNetWorth> monthlyHistory({int months = 12}) {
    final now = DateTime.now();
    final history = <MonthlyNetWorth>[];

    for (int i = months - 1; i >= 0; i--) {
      final year = now.month - i <= 0 ? now.year - 1 : now.year;
      final month = ((now.month - i - 1) % 12) + 1;
      final endOfMonth = DateTime(
          month == 12 ? year + 1 : year, month == 12 ? 1 : month + 1, 0);

      double monthAssets = 0;
      double monthLiabilities = 0;
      for (final account in _accounts.where((a) => !a.isArchived)) {
        final balance = account.balanceAt(endOfMonth);
        if (account.type == AccountType.asset) {
          monthAssets += balance;
        } else {
          monthLiabilities += balance;
        }
      }

      history.add(MonthlyNetWorth(
        year: year,
        month: month,
        totalAssets: monthAssets,
        totalLiabilities: monthLiabilities,
      ));
    }

    return history;
  }

  // ── Milestones ────────────────────────────────────────────────────

  /// Standard net worth milestones with achievement status.
  List<NetWorthMilestone> get milestones {
    final targets = [
      (label: 'First \$1K', amount: 1000.0),
      (label: '\$5K saved', amount: 5000.0),
      (label: '\$10K club', amount: 10000.0),
      (label: '\$25K mark', amount: 25000.0),
      (label: '\$50K halfway', amount: 50000.0),
      (label: '\$100K milestone', amount: 100000.0),
      (label: 'Quarter million', amount: 250000.0),
      (label: 'Half million', amount: 500000.0),
      (label: 'Millionaire', amount: 1000000.0),
    ];

    return targets.map((t) {
      final reached = netWorth >= t.amount;
      DateTime? reachedDate;

      if (reached) {
        // Estimate when milestone was reached from history
        final history = monthlyHistory(months: 60);
        for (final month in history) {
          if (month.netWorth >= t.amount) {
            reachedDate = month.date;
            break;
          }
        }
      }

      return NetWorthMilestone(
        label: t.label,
        target: t.amount,
        reached: reached,
        reachedDate: reachedDate,
      );
    }).toList();
  }

  /// Next milestone to reach (or null if all reached).
  NetWorthMilestone? get nextMilestone {
    final unreached = milestones.where((m) => !m.reached).toList();
    return unreached.isEmpty ? null : unreached.first;
  }

  /// Progress toward the next milestone (0.0 to 1.0).
  double get milestoneProgress {
    final next = nextMilestone;
    if (next == null) return 1.0;

    final prevTarget = milestones
        .where((m) => m.reached)
        .fold(0.0, (_, m) => m.target);

    final range = next.target - prevTarget;
    if (range <= 0) return 0.0;
    return ((netWorth - prevTarget) / range).clamp(0.0, 1.0);
  }

  // ── Stale Account Detection ───────────────────────────────────────

  /// Accounts that haven't been updated in over 30 days.
  List<NetWorthAccount> get staleAccounts =>
      activeAccounts.where((a) => a.isStale).toList();

  /// Accounts sorted by most recently updated first.
  List<NetWorthAccount> get recentlyUpdated {
    final sorted = List<NetWorthAccount>.from(activeAccounts);
    sorted.sort((a, b) {
      final aDays = a.daysSinceUpdate ?? 999;
      final bDays = b.daysSinceUpdate ?? 999;
      return aDays.compareTo(bDays);
    });
    return sorted;
  }

  // ── Debt Payoff Analysis ──────────────────────────────────────────

  /// Total debt (sum of all liability balances).
  double get totalDebt => totalLiabilities;

  /// Debt-to-asset ratio.
  double? get debtToAssetRatio =>
      totalAssets > 0 ? totalLiabilities / totalAssets : null;

  /// Estimated months to be debt-free at current paydown rate.
  int? get monthsToDebtFree {
    if (totalDebt <= 0) return 0;
    final history = monthlyHistory(months: 6);
    if (history.length < 2) return null;

    final first = history.first;
    final last = history.last;
    final months = history.length - 1;

    final debtReduction = first.totalLiabilities - last.totalLiabilities;
    if (debtReduction <= 0) return null; // debt is increasing

    final monthlyPaydown = debtReduction / months;
    return (last.totalLiabilities / monthlyPaydown).ceil();
  }

  // ── Report Generation ─────────────────────────────────────────────

  /// Generate a comprehensive net worth report.
  NetWorthReport generateReport({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final history = monthlyHistory(months: 13);

    // Month-over-month
    double? momChange;
    double? momPercent;
    if (history.length >= 2) {
      final current = history.last;
      final previous = history[history.length - 2];
      momChange = current.netWorth - previous.netWorth;
      if (previous.netWorth != 0) {
        momPercent = momChange! / previous.netWorth.abs();
      }
    }

    // Year-over-year
    double? yoyChange;
    if (history.length >= 13) {
      yoyChange = history.last.netWorth - history.first.netWorth;
    }

    final summary = _buildSummary(now);

    return NetWorthReport(
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      netWorth: netWorth,
      monthOverMonthChange: momChange,
      monthOverMonthPercent: momPercent,
      yearOverYearChange: yoyChange,
      totalAccounts: activeAccounts.length,
      staleAccounts: staleAccounts.length,
      assetBreakdown: assetBreakdown,
      liabilityBreakdown: liabilityBreakdown,
      history: history,
      summary: summary,
      generatedAt: now,
    );
  }

  String _buildSummary(DateTime now) {
    final buf = StringBuffer();
    buf.writeln('Net Worth Summary');
    buf.writeln('═' * 40);
    buf.writeln();

    // Current net worth
    buf.writeln('Net Worth: \$${netWorth.toStringAsFixed(2)}');
    buf.writeln('  Assets:      \$${totalAssets.toStringAsFixed(2)} '
        '(${assets.length} accounts)');
    buf.writeln('  Liabilities: \$${totalLiabilities.toStringAsFixed(2)} '
        '(${liabilities.length} accounts)');

    // Changes
    final change30 = netWorthChange(30);
    if (change30 != null) {
      final sign = change30 >= 0 ? '+' : '';
      buf.writeln();
      buf.writeln('30-day change: $sign\$${change30.toStringAsFixed(2)}');
    }

    final change90 = netWorthChange(90);
    if (change90 != null) {
      final sign = change90 >= 0 ? '+' : '';
      buf.writeln('90-day change: $sign\$${change90.toStringAsFixed(2)}');
    }

    // Debt ratio
    final ratio = debtToAssetRatio;
    if (ratio != null) {
      buf.writeln();
      buf.writeln('Debt-to-asset ratio: ${(ratio * 100).toStringAsFixed(1)}%');
      if (ratio > 0.5) {
        buf.writeln('⚠️ High debt ratio — consider prioritizing debt payoff');
      } else if (ratio < 0.2) {
        buf.writeln('✅ Healthy debt ratio');
      }
    }

    // Stale accounts
    final stale = staleAccounts;
    if (stale.isNotEmpty) {
      buf.writeln();
      buf.writeln('⚠️ ${stale.length} account(s) need balance updates:');
      for (final a in stale.take(5)) {
        buf.writeln('  • ${a.name} (${a.daysSinceUpdate} days ago)');
      }
    }

    // Milestone
    final next = nextMilestone;
    if (next != null) {
      final remaining = next.target - netWorth;
      buf.writeln();
      buf.writeln('Next milestone: ${next.label} '
          '(\$${remaining.toStringAsFixed(0)} to go)');
    }

    return buf.toString();
  }

  // ── Serialization ─────────────────────────────────────────────────

  /// Export all accounts as JSON string.
  String exportToJson() {
    final data = _accounts.map((a) => a.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import accounts from JSON string.
  /// Maximum entries allowed via [importFromJson] to prevent memory exhaustion.
  static const int maxImportEntries = 50000;

  int importFromJson(String jsonStr) {
    final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
    if (data.length > maxImportEntries) {
      throw ArgumentError(
        'Import exceeds maximum of $maxImportEntries entries '
        '(got ${data.length}). This limit prevents memory exhaustion '
        'from corrupted or malicious data.',
      );
    }
    int imported = 0;
    for (final item in data) {
      try {
        final account =
            NetWorthAccount.fromJson(item as Map<String, dynamic>);
        // Avoid duplicates by ID
        if (!_accounts.any((a) => a.id == account.id)) {
          _accounts.add(account);
          imported++;
        }
      } catch (_) {
        // Skip malformed entries
      }
    }
    return imported;
  }

  /// Clear all accounts.
  void clear() => _accounts.clear();

  // ── Helpers ───────────────────────────────────────────────────────

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(99999);
    return 'nw_${now}_$rand';
  }
}
