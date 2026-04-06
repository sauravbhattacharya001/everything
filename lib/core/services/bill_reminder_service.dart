import '../../models/bill_entry.dart';
import 'crud_service.dart';

/// Summary of monthly bill spending.
class BillSummary {
  final double totalMonthly;
  final double totalPaid;
  final double totalUnpaid;
  final int overdueCount;
  final int dueSoonCount;
  final Map<BillCategory, double> byCategory;
  const BillSummary({
    required this.totalMonthly,
    required this.totalPaid,
    required this.totalUnpaid,
    required this.overdueCount,
    required this.dueSoonCount,
    required this.byCategory,
  });
}

/// Service for managing bill reminders.
///
/// Refactored to extend [CrudService], eliminating duplicated CRUD
/// boilerplate (add/update/remove, export/import) while preserving
/// all domain-specific methods (markPaid, getSorted, summaries).
class BillReminderService extends CrudService<BillEntry> {
  @override
  String getId(BillEntry item) => item.id;

  @override
  Map<String, dynamic> toJson(BillEntry item) => item.toJson();

  @override
  BillEntry fromJson(Map<String, dynamic> json) => BillEntry.fromJson(json);

  /// Convenience aliases to match the original API surface.
  List<BillEntry> get bills => items;

  void addBill(BillEntry bill) => add(bill);

  void updateBill(BillEntry bill) => update(bill);

  void removeBill(String id) => remove(id);

  void markPaid(String id) {
    final idx = indexById(id);
    if (idx >= 0) {
      updateAt(idx, itemsMutable[idx].copyWith(isPaid: true, paidDate: DateTime.now()));
    }
  }

  void markUnpaid(String id) {
    final idx = indexById(id);
    if (idx >= 0) {
      updateAt(idx, itemsMutable[idx].copyWith(isPaid: false, paidDate: null));
    }
  }

  /// Get bills sorted by due date.
  List<BillEntry> getSorted({bool? paidFilter}) {
    var list = List<BillEntry>.from(items);
    if (paidFilter != null) {
      list = list.where((b) => b.isPaid == paidFilter).toList();
    }
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// Get overdue bills.
  List<BillEntry> get overdueBills =>
      items.where((b) => b.isOverdue).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  /// Get bills due soon (within N days).
  List<BillEntry> getDueSoon([int days = 7]) =>
      items.where((b) => b.isDueSoon(days)).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  /// Monthly cost estimate (normalizes all frequencies to monthly).
  double get estimatedMonthlyCost {
    double total = 0;
    for (final bill in items) {
      switch (bill.frequency) {
        case BillFrequency.weekly:
          total += bill.amount * 4.33;
          break;
        case BillFrequency.biweekly:
          total += bill.amount * 2.17;
          break;
        case BillFrequency.monthly:
          total += bill.amount;
          break;
        case BillFrequency.quarterly:
          total += bill.amount / 3;
          break;
        case BillFrequency.semiannual:
          total += bill.amount / 6;
          break;
        case BillFrequency.annual:
          total += bill.amount / 12;
          break;
        case BillFrequency.oneTime:
          break; // don't include in monthly estimate
      }
    }
    return total;
  }

  /// Build a spending summary.
  BillSummary getSummary() {
    final byCategory = <BillCategory, double>{};
    double paid = 0, unpaid = 0;
    for (final bill in items) {
      byCategory[bill.category] =
          (byCategory[bill.category] ?? 0) + bill.amount;
      if (bill.isPaid) {
        paid += bill.amount;
      } else {
        unpaid += bill.amount;
      }
    }
    return BillSummary(
      totalMonthly: estimatedMonthlyCost,
      totalPaid: paid,
      totalUnpaid: unpaid,
      overdueCount: overdueBills.length,
      dueSoonCount: getDueSoon().length,
      byCategory: byCategory,
    );
  }
}
