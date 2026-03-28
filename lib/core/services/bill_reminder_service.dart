import 'dart:convert';
import '../../models/bill_entry.dart';

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
class BillReminderService {
  final List<BillEntry> _bills = [];

  List<BillEntry> get bills => List.unmodifiable(_bills);

  void addBill(BillEntry bill) => _bills.add(bill);

  void updateBill(BillEntry bill) {
    final idx = _bills.indexWhere((b) => b.id == bill.id);
    if (idx >= 0) _bills[idx] = bill;
  }

  void removeBill(String id) => _bills.removeWhere((b) => b.id == id);

  void markPaid(String id) {
    final idx = _bills.indexWhere((b) => b.id == id);
    if (idx >= 0) {
      _bills[idx] = _bills[idx].copyWith(isPaid: true, paidDate: DateTime.now());
    }
  }

  void markUnpaid(String id) {
    final idx = _bills.indexWhere((b) => b.id == id);
    if (idx >= 0) {
      _bills[idx] = _bills[idx].copyWith(isPaid: false, paidDate: null);
    }
  }

  /// Get bills sorted by due date.
  List<BillEntry> getSorted({bool? paidFilter}) {
    var list = List<BillEntry>.from(_bills);
    if (paidFilter != null) {
      list = list.where((b) => b.isPaid == paidFilter).toList();
    }
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// Get overdue bills.
  List<BillEntry> get overdueBills =>
      _bills.where((b) => b.isOverdue).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  /// Get bills due soon (within N days).
  List<BillEntry> getDueSoon([int days = 7]) =>
      _bills.where((b) => b.isDueSoon(days)).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  /// Monthly cost estimate (normalizes all frequencies to monthly).
  double get estimatedMonthlyCost {
    double total = 0;
    for (final bill in _bills) {
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
    for (final bill in _bills) {
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

  String exportToJson() =>
      jsonEncode(_bills.map((b) => b.toJson()).toList());

  void importFromJson(String json) {
    _bills.clear();
    final list = jsonDecode(json) as List;
    for (final item in list) {
      _bills.add(BillEntry.fromJson(item as Map<String, dynamic>));
    }
  }
}
