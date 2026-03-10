import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/net_worth_tracker_service.dart';
import 'package:everything/models/net_worth_account.dart';

void main() {
  late NetWorthTrackerService service;

  setUp(() {
    service = NetWorthTrackerService();
  });

  group('Account CRUD', () {
    test('addAccount creates account with correct properties', () {
      final account = service.addAccount(
        name: 'Checking',
        type: AccountType.asset,
        category: AccountCategory.checking,
        institution: 'Chase',
        initialBalance: 5000,
      );

      expect(account.name, 'Checking');
      expect(account.type, AccountType.asset);
      expect(account.category, AccountCategory.checking);
      expect(account.institution, 'Chase');
      expect(account.currentBalance, 5000);
      expect(account.emoji, '🏦');
      expect(service.accounts.length, 1);
    });

    test('addAccount trims name', () {
      final account = service.addAccount(
        name: '  Savings  ',
        type: AccountType.asset,
      );
      expect(account.name, 'Savings');
    });

    test('addAccount rejects empty name', () {
      expect(
        () => service.addAccount(name: '', type: AccountType.asset),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addAccount without initial balance has zero balance', () {
      final account = service.addAccount(
        name: 'Empty',
        type: AccountType.asset,
      );
      expect(account.currentBalance, 0.0);
      expect(account.snapshots, isEmpty);
    });

    test('updateAccount modifies properties', () {
      final account = service.addAccount(
        name: 'Old Name',
        type: AccountType.asset,
      );
      final updated = service.updateAccount(
        account.id,
        name: 'New Name',
        emoji: '🌟',
        institution: 'Bank of America',
      );

      expect(updated, isNotNull);
      expect(updated!.name, 'New Name');
      expect(updated.emoji, '🌟');
      expect(updated.institution, 'Bank of America');
    });

    test('updateAccount returns null for missing ID', () {
      expect(service.updateAccount('nope', name: 'X'), isNull);
    });

    test('updateAccount rejects empty name', () {
      final account = service.addAccount(
        name: 'Test',
        type: AccountType.asset,
      );
      expect(
        () => service.updateAccount(account.id, name: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('archiveAccount soft-deletes', () {
      final account = service.addAccount(
        name: 'To Archive',
        type: AccountType.asset,
      );
      expect(service.archiveAccount(account.id), true);
      expect(service.activeAccounts, isEmpty);
      expect(service.accounts.length, 1);
    });

    test('restoreAccount un-archives', () {
      final account = service.addAccount(
        name: 'Archived',
        type: AccountType.asset,
      );
      service.archiveAccount(account.id);
      expect(service.restoreAccount(account.id), true);
      expect(service.activeAccounts.length, 1);
    });

    test('getAccount finds by ID', () {
      final account = service.addAccount(
        name: 'Find Me',
        type: AccountType.asset,
      );
      expect(service.getAccount(account.id), isNotNull);
      expect(service.getAccount('missing'), isNull);
    });
  });

  group('Balance Recording', () {
    test('recordBalance adds snapshot', () {
      final account = service.addAccount(
        name: 'Checking',
        type: AccountType.asset,
        initialBalance: 1000,
      );

      service.recordBalance(account.id, 1500, note: 'Paycheck');
      final updated = service.getAccount(account.id)!;
      expect(updated.snapshots.length, 2);
      expect(updated.currentBalance, 1500);
    });

    test('recordBalance rejects negative', () {
      final account = service.addAccount(
        name: 'Test',
        type: AccountType.asset,
      );
      expect(
        () => service.recordBalance(account.id, -100),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('recordBalance returns null for missing account', () {
      expect(service.recordBalance('nope', 100), isNull);
    });

    test('recordBalance with custom date', () {
      final account = service.addAccount(
        name: 'Test',
        type: AccountType.asset,
      );
      final date = DateTime(2025, 6, 15);
      final snapshot = service.recordBalance(account.id, 2000, date: date);
      expect(snapshot!.date, date);
    });
  });

  group('Net Worth Calculations', () {
    test('netWorth with no accounts is zero', () {
      expect(service.netWorth, 0.0);
    });

    test('netWorth is assets minus liabilities', () {
      service.addAccount(
        name: 'Savings',
        type: AccountType.asset,
        initialBalance: 10000,
      );
      service.addAccount(
        name: 'Credit Card',
        type: AccountType.liability,
        initialBalance: 3000,
      );

      expect(service.totalAssets, 10000);
      expect(service.totalLiabilities, 3000);
      expect(service.netWorth, 7000);
    });

    test('archived accounts are excluded from calculations', () {
      final account = service.addAccount(
        name: 'Old',
        type: AccountType.asset,
        initialBalance: 5000,
      );
      service.archiveAccount(account.id);
      expect(service.netWorth, 0.0);
    });

    test('assets and liabilities lists filter correctly', () {
      service.addAccount(
        name: 'Asset1',
        type: AccountType.asset,
        initialBalance: 1000,
      );
      service.addAccount(
        name: 'Liability1',
        type: AccountType.liability,
        initialBalance: 500,
      );

      expect(service.assets.length, 1);
      expect(service.liabilities.length, 1);
    });
  });

  group('Category Breakdown', () {
    test('assetBreakdown groups by category', () {
      service.addAccount(
        name: 'Checking 1',
        type: AccountType.asset,
        category: AccountCategory.checking,
        initialBalance: 5000,
      );
      service.addAccount(
        name: 'Checking 2',
        type: AccountType.asset,
        category: AccountCategory.checking,
        initialBalance: 3000,
      );
      service.addAccount(
        name: 'Investment',
        type: AccountType.asset,
        category: AccountCategory.investment,
        initialBalance: 20000,
      );

      final breakdown = service.assetBreakdown;
      expect(breakdown.length, 2);

      final investment =
          breakdown.firstWhere((b) => b.category == AccountCategory.investment);
      expect(investment.total, 20000);
      expect(investment.accountCount, 1);

      final checking =
          breakdown.firstWhere((b) => b.category == AccountCategory.checking);
      expect(checking.total, 8000);
      expect(checking.accountCount, 2);
    });

    test('liabilityBreakdown sorts by total descending', () {
      service.addAccount(
        name: 'CC',
        type: AccountType.liability,
        category: AccountCategory.creditCard,
        initialBalance: 2000,
      );
      service.addAccount(
        name: 'Mortgage',
        type: AccountType.liability,
        category: AccountCategory.mortgage,
        initialBalance: 200000,
      );

      final breakdown = service.liabilityBreakdown;
      expect(breakdown.first.category, AccountCategory.mortgage);
    });
  });

  group('Debt Analysis', () {
    test('totalDebt equals total liabilities', () {
      service.addAccount(
        name: 'CC',
        type: AccountType.liability,
        initialBalance: 5000,
      );
      expect(service.totalDebt, 5000);
    });

    test('debtToAssetRatio is correct', () {
      service.addAccount(
        name: 'Savings',
        type: AccountType.asset,
        initialBalance: 10000,
      );
      service.addAccount(
        name: 'CC',
        type: AccountType.liability,
        initialBalance: 2000,
      );
      expect(service.debtToAssetRatio, 0.2);
    });

    test('debtToAssetRatio is null with no assets', () {
      service.addAccount(
        name: 'CC',
        type: AccountType.liability,
        initialBalance: 1000,
      );
      expect(service.debtToAssetRatio, isNull);
    });
  });

  group('Milestones', () {
    test('milestones with zero net worth', () {
      final ms = service.milestones;
      expect(ms.every((m) => !m.reached), true);
    });

    test('milestones with 10K net worth', () {
      service.addAccount(
        name: 'Savings',
        type: AccountType.asset,
        initialBalance: 10000,
      );

      final ms = service.milestones;
      final reached = ms.where((m) => m.reached).toList();
      expect(reached.length, 3); // 1K, 5K, 10K
    });

    test('nextMilestone returns first unreached', () {
      service.addAccount(
        name: 'Savings',
        type: AccountType.asset,
        initialBalance: 6000,
      );
      final next = service.nextMilestone;
      expect(next, isNotNull);
      expect(next!.target, 10000);
    });

    test('milestoneProgress between milestones', () {
      service.addAccount(
        name: 'Savings',
        type: AccountType.asset,
        initialBalance: 7500,
      );
      // Between 5K and 10K: (7500-5000)/(10000-5000) = 0.5
      expect(service.milestoneProgress, closeTo(0.5, 0.01));
    });
  });

  group('Stale Account Detection', () {
    test('new account is not stale', () {
      service.addAccount(
        name: 'Fresh',
        type: AccountType.asset,
        initialBalance: 1000,
      );
      expect(service.staleAccounts, isEmpty);
    });

    test('account with old snapshot is stale', () {
      final account = service.addAccount(
        name: 'Old',
        type: AccountType.asset,
      );
      service.recordBalance(
        account.id,
        1000,
        date: DateTime.now().subtract(const Duration(days: 60)),
      );
      expect(service.staleAccounts.length, 1);
    });
  });

  group('Report Generation', () {
    test('generates report with summary', () {
      service.addAccount(
        name: 'Savings',
        type: AccountType.asset,
        category: AccountCategory.savings,
        initialBalance: 15000,
      );
      service.addAccount(
        name: 'Credit Card',
        type: AccountType.liability,
        category: AccountCategory.creditCard,
        initialBalance: 2000,
      );

      final report = service.generateReport();
      expect(report.totalAssets, 15000);
      expect(report.totalLiabilities, 2000);
      expect(report.netWorth, 13000);
      expect(report.totalAccounts, 2);
      expect(report.summary.contains('Net Worth'), true);
      expect(report.assetBreakdown, isNotEmpty);
      expect(report.liabilityBreakdown, isNotEmpty);
    });

    test('report history has correct length', () {
      service.addAccount(
        name: 'Test',
        type: AccountType.asset,
        initialBalance: 1000,
      );

      final report = service.generateReport();
      // Default 13 months for MoM calculation
      expect(report.history.length, 13);
    });
  });

  group('Serialization', () {
    test('exportToJson and importFromJson round-trip', () {
      service.addAccount(
        name: 'Checking',
        type: AccountType.asset,
        category: AccountCategory.checking,
        institution: 'Chase',
        initialBalance: 5000,
      );
      service.addAccount(
        name: 'Mortgage',
        type: AccountType.liability,
        category: AccountCategory.mortgage,
        institution: 'Wells Fargo',
        initialBalance: 200000,
      );

      final json = service.exportToJson();
      expect(json.contains('Checking'), true);
      expect(json.contains('Mortgage'), true);

      final newService = NetWorthTrackerService();
      final imported = newService.importFromJson(json);
      expect(imported, 2);
      expect(newService.accounts.length, 2);
      expect(newService.netWorth, closeTo(-195000, 0.01));
    });

    test('importFromJson skips duplicates', () {
      final account = service.addAccount(
        name: 'Test',
        type: AccountType.asset,
        initialBalance: 1000,
      );

      final json = service.exportToJson();
      final imported = service.importFromJson(json);
      expect(imported, 0); // Already exists
      expect(service.accounts.length, 1);
    });

    test('importFromJson skips malformed entries', () {
      final imported = service.importFromJson('[{"bad": true}, {}]');
      expect(imported, 0);
    });

    test('clear removes all accounts', () {
      service.addAccount(
        name: 'Test',
        type: AccountType.asset,
        initialBalance: 1000,
      );
      service.clear();
      expect(service.accounts, isEmpty);
    });
  });

  group('NetWorthAccount Model', () {
    test('signedBalance positive for asset', () {
      final account = NetWorthAccount(
        id: 'test',
        name: 'Asset',
        type: AccountType.asset,
        snapshots: [BalanceSnapshot(date: DateTime.now(), balance: 1000)],
      );
      expect(account.signedBalance, 1000);
    });

    test('signedBalance negative for liability', () {
      final account = NetWorthAccount(
        id: 'test',
        name: 'Debt',
        type: AccountType.liability,
        snapshots: [BalanceSnapshot(date: DateTime.now(), balance: 5000)],
      );
      expect(account.signedBalance, -5000);
    });

    test('lastChange with two snapshots', () {
      final account = NetWorthAccount(
        id: 'test',
        name: 'Test',
        type: AccountType.asset,
        snapshots: [
          BalanceSnapshot(
            date: DateTime.now().subtract(const Duration(days: 30)),
            balance: 1000,
          ),
          BalanceSnapshot(date: DateTime.now(), balance: 1500),
        ],
      );
      expect(account.lastChange, 500);
    });

    test('lastChange null with one snapshot', () {
      final account = NetWorthAccount(
        id: 'test',
        name: 'Test',
        type: AccountType.asset,
        snapshots: [BalanceSnapshot(date: DateTime.now(), balance: 1000)],
      );
      expect(account.lastChange, isNull);
    });

    test('lastChangePercent calculates correctly', () {
      final account = NetWorthAccount(
        id: 'test',
        name: 'Test',
        type: AccountType.asset,
        snapshots: [
          BalanceSnapshot(
            date: DateTime.now().subtract(const Duration(days: 30)),
            balance: 1000,
          ),
          BalanceSnapshot(date: DateTime.now(), balance: 1200),
        ],
      );
      expect(account.lastChangePercent, closeTo(0.2, 0.001));
    });

    test('balanceAt returns correct historical balance', () {
      final past = DateTime(2025, 1, 15);
      final recent = DateTime(2025, 6, 15);
      final account = NetWorthAccount(
        id: 'test',
        name: 'Test',
        type: AccountType.asset,
        snapshots: [
          BalanceSnapshot(date: past, balance: 1000),
          BalanceSnapshot(date: recent, balance: 2000),
        ],
      );

      expect(account.balanceAt(DateTime(2025, 3, 1)), 1000);
      expect(account.balanceAt(DateTime(2025, 8, 1)), 2000);
      expect(account.balanceAt(DateTime(2024, 12, 1)), 0.0);
    });

    test('isStale detects old snapshots', () {
      final account = NetWorthAccount(
        id: 'test',
        name: 'Test',
        type: AccountType.asset,
        snapshots: [
          BalanceSnapshot(
            date: DateTime.now().subtract(const Duration(days: 45)),
            balance: 1000,
          ),
        ],
      );
      expect(account.isStale, true);
    });

    test('copyWith preserves unchanged fields', () {
      final original = NetWorthAccount(
        id: 'test',
        name: 'Original',
        type: AccountType.asset,
        category: AccountCategory.checking,
        institution: 'Chase',
      );
      final copy = original.copyWith(name: 'Updated');
      expect(copy.name, 'Updated');
      expect(copy.id, 'test');
      expect(copy.institution, 'Chase');
    });

    test('toJson and fromJson round-trip', () {
      final original = NetWorthAccount(
        id: 'test',
        name: 'Test Account',
        emoji: '💰',
        type: AccountType.asset,
        category: AccountCategory.investment,
        institution: 'Fidelity',
        notes: 'Retirement fund',
        snapshots: [
          BalanceSnapshot(
            date: DateTime(2025, 6, 15),
            balance: 50000,
            note: 'Q2 update',
          ),
        ],
      );

      final json = original.toJson();
      final restored = NetWorthAccount.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.category, original.category);
      expect(restored.institution, original.institution);
      expect(restored.notes, original.notes);
      expect(restored.snapshots.length, 1);
      expect(restored.snapshots.first.balance, 50000);
      expect(restored.snapshots.first.note, 'Q2 update');
    });
  });

  group('AccountCategory Extensions', () {
    test('defaultType returns correct type', () {
      expect(AccountCategory.checking.defaultType, AccountType.asset);
      expect(AccountCategory.savings.defaultType, AccountType.asset);
      expect(AccountCategory.creditCard.defaultType, AccountType.liability);
      expect(AccountCategory.mortgage.defaultType, AccountType.liability);
      expect(AccountCategory.studentLoan.defaultType, AccountType.liability);
    });

    test('label returns human-readable name', () {
      expect(AccountCategory.creditCard.label, 'Credit Card');
      expect(AccountCategory.studentLoan.label, 'Student Loan');
      expect(AccountCategory.checking.label, 'Checking');
    });

    test('defaultEmoji returns appropriate emoji', () {
      expect(AccountCategory.checking.defaultEmoji, '🏦');
      expect(AccountCategory.creditCard.defaultEmoji, '💳');
      expect(AccountCategory.crypto.defaultEmoji, '₿');
    });
  });

  group('Monthly History', () {
    test('monthlyHistory returns correct number of months', () {
      service.addAccount(
        name: 'Test',
        type: AccountType.asset,
        initialBalance: 1000,
      );
      final history = service.monthlyHistory(months: 6);
      expect(history.length, 6);
    });

    test('MonthlyNetWorth netWorth calculation', () {
      const month = MonthlyNetWorth(
        year: 2025,
        month: 6,
        totalAssets: 50000,
        totalLiabilities: 10000,
      );
      expect(month.netWorth, 40000);
      expect(month.label, 'Jun 2025');
    });
  });

  group('Net Worth Over Time', () {
    test('netWorthAt returns zero before any snapshots', () {
      service.addAccount(
        name: 'Test',
        type: AccountType.asset,
      );
      service.recordBalance(
        service.accounts.first.id,
        5000,
        date: DateTime(2025, 6, 1),
      );
      expect(service.netWorthAt(DateTime(2025, 1, 1)), 0.0);
    });

    test('netWorthChange returns difference', () {
      final account = service.addAccount(
        name: 'Test',
        type: AccountType.asset,
      );
      service.recordBalance(
        account.id,
        5000,
        date: DateTime.now().subtract(const Duration(days: 60)),
      );
      service.recordBalance(account.id, 8000);

      final change = service.netWorthChange(90);
      expect(change, isNotNull);
    });
  });
}
