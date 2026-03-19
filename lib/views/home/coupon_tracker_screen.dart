import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/coupon_entry.dart';
import '../../core/services/coupon_tracker_service.dart';
import '../../core/services/persistent_state_mixin.dart';

/// Coupon & Deal Tracker Screen.
///
/// 4-tab UI:
///   - Active: current usable coupons sorted by expiry
///   - Redeemed: used coupons with savings log
///   - Analytics: savings summary, category breakdown, store stats
///   - Search: filter by name, store, code, or tag
class CouponTrackerScreen extends StatefulWidget {
  const CouponTrackerScreen({super.key});

  @override
  State<CouponTrackerScreen> createState() => _CouponTrackerScreenState();
}

class _CouponTrackerScreenState extends State<CouponTrackerScreen>
    with TickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'coupon_tracker_data';
  @override
  String exportData() => _service.exportToJson();
  @override
  void importData(String json) => _service.importFromJson(json);

  final CouponTrackerService _service = CouponTrackerService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<CouponEntry> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    initPersistence();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons & Deals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.local_offer), text: 'Active'),
            Tab(icon: Icon(Icons.check_circle), text: 'Redeemed'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildRedeemedTab(),
          _buildAnalyticsTab(),
          _buildSearchTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCouponDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Active Tab ──

  Widget _buildActiveTab() {
    final active = _service.getActive()
      ..sort((a, b) {
        final aExp = a.expirationDate ?? DateTime(2999);
        final bExp = b.expirationDate ?? DateTime(2999);
        return aExp.compareTo(bExp);
      });
    final expired = _service.getExpired();

    if (active.isEmpty && expired.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No coupons yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap + to add your first coupon or deal.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (active.isNotEmpty) ...[
          Text('Active (${active.length})',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...active.map((c) => _buildCouponCard(c)),
        ],
        if (expired.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Expired (${expired.length})',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          ...expired.map((c) => _buildCouponCard(c)),
        ],
      ],
    );
  }

  // ── Redeemed Tab ──

  Widget _buildRedeemedTab() {
    final redeemed = _service.getRedeemed()
      ..sort((a, b) => (b.redeemedAt ?? b.createdAt)
          .compareTo(a.redeemedAt ?? a.createdAt));

    if (redeemed.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No redeemed coupons yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Redeem a coupon to track your savings.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.savings, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Total Saved: \$${_service.totalSaved.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...redeemed.map((c) => _buildCouponCard(c)),
      ],
    );
  }

  // ── Analytics Tab ──

  Widget _buildAnalyticsTab() {
    final summary = _service.getSummary();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _statRow('Total Coupons', '${summary.totalCoupons}'),
                  _statRow('Active', '${summary.activeCount}'),
                  _statRow('Redeemed', '${summary.redeemedCount}'),
                  _statRow('Expired', '${summary.expiredCount}'),
                  if (summary.expiringSoonCount > 0)
                    _statRow('⚠️ Expiring Soon',
                        '${summary.expiringSoonCount}'),
                  const Divider(),
                  _statRow('💰 Total Saved',
                      '\$${summary.totalSaved.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          if (summary.categoryBreakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('By Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...summary.categoryBreakdown.entries.map((e) => Card(
                  child: ListTile(
                    leading: Text(e.key.emoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(e.key.label),
                    trailing: Text('${e.value}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )),
          ],
          if (summary.storeBreakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('By Store',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(summary.storeBreakdown.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .take(10)
                .map((e) => ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.store, size: 20, color: Colors.grey),
                      title: Text(e.key),
                      trailing: Text('${e.value} coupons'),
                    )),
          ],
        ],
      ),
    );
  }

  // ── Search Tab ──

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search coupons, codes, stores...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      })
                  : null,
            ),
            onChanged: (q) =>
                setState(() => _searchResults = _service.search(q)),
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty && _searchController.text.isEmpty
              ? const Center(
                  child: Text('Type to search your coupons',
                      style: TextStyle(color: Colors.grey)))
              : _searchResults.isEmpty
                  ? const Center(child: Text('No results found'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) => _buildCouponCard(_searchResults[i]),
                    ),
        ),
      ],
    );
  }

  // ── Shared Widgets ──

  Widget _buildCouponCard(CouponEntry coupon) {
    final isExpired = coupon.status == CouponStatus.expired;
    final isRedeemed = coupon.status == CouponStatus.redeemed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isExpired
          ? Colors.grey.shade100
          : isRedeemed
              ? Colors.green.shade50
              : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: coupon.category.color.withOpacity(0.2),
          child: Text(coupon.category.emoji,
              style: const TextStyle(fontSize: 20)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                coupon.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isExpired ? TextDecoration.lineThrough : null,
                  color: isExpired ? Colors.grey : null,
                ),
              ),
            ),
            if (coupon.isFavorite)
              const Icon(Icons.star, size: 16, color: Colors.amber),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: coupon.status.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    coupon.discountDisplay,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: coupon.status.color,
                    ),
                  ),
                ),
                if (coupon.store != null) ...[
                  const SizedBox(width: 8),
                  Text(coupon.store!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
            if (coupon.code != null)
              Row(
                children: [
                  Text('Code: ${coupon.code}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: coupon.code!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Code copied!'),
                            duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Icon(Icons.copy, size: 14, color: Colors.grey),
                  ),
                ],
              ),
            if (coupon.expirationDate != null && !isRedeemed)
              Text(
                coupon.isExpiringSoon
                    ? '⚠️ Expires in ${coupon.daysUntilExpiry}d'
                    : isExpired
                        ? 'Expired'
                        : 'Expires: ${_formatDate(coupon.expirationDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: coupon.isExpiringSoon
                      ? Colors.orange
                      : isExpired
                          ? Colors.red
                          : Colors.grey,
                ),
              ),
            if (isRedeemed && coupon.savedAmount != null)
              Text('Saved: \$${coupon.savedAmount!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () => _showCouponDetail(coupon),
        isThreeLine: true,
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );

  String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  // ── Dialogs ──

  void _showAddCouponDialog() {
    String title = '', code = '', store = '', description = '';
    var category = CouponCategory.other;
    var discountType = DiscountType.percentage;
    double? discountValue;
    double? minPurchase;
    DateTime? expiry;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Coupon'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title *'),
                onChanged: (v) => title = v,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Promo Code'),
                onChanged: (v) => code = v,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Store'),
                onChanged: (v) => store = v,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CouponCategory>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: CouponCategory.values
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text('${c.emoji} ${c.label}')))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => category = v ?? category),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DiscountType>(
                value: discountType,
                decoration:
                    const InputDecoration(labelText: 'Discount Type'),
                items: DiscountType.values
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => discountType = v ?? discountType),
              ),
              const SizedBox(height: 8),
              if (discountType == DiscountType.percentage ||
                  discountType == DiscountType.fixedAmount)
                TextField(
                  decoration: InputDecoration(
                      labelText: discountType == DiscountType.percentage
                          ? 'Discount %'
                          : 'Discount Amount (\$)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => discountValue = double.tryParse(v),
                ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                    labelText: 'Min Purchase (\$)', hintText: 'Optional'),
                keyboardType: TextInputType.number,
                onChanged: (v) => minPurchase = double.tryParse(v),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                onChanged: (v) => description = v,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(expiry == null
                    ? 'No expiration set'
                    : 'Expires: ${_formatDate(expiry!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setDialogState(() => expiry = picked);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (title.trim().isEmpty) return;
                setState(() {
                  _service.addCoupon(CouponEntry(
                    id: 'cpn_${DateTime.now().millisecondsSinceEpoch}',
                    title: title.trim(),
                    code: code.isNotEmpty ? code.trim() : null,
                    store: store.isNotEmpty ? store.trim() : null,
                    description:
                        description.isNotEmpty ? description.trim() : null,
                    category: category,
                    discountType: discountType,
                    discountValue: discountValue,
                    minimumPurchase: minPurchase,
                    expirationDate: expiry,
                    createdAt: DateTime.now(),
                  ));
                  persistState();
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCouponDetail(CouponEntry coupon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text(coupon.category.emoji,
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: coupon.status.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(coupon.status.label,
                            style: TextStyle(
                                color: coupon.status.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ]),
              const Divider(height: 24),
              _statRow('Discount', coupon.discountDisplay),
              if (coupon.store != null) _statRow('Store', coupon.store!),
              if (coupon.code != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Code',
                        style: TextStyle(color: Colors.grey)),
                    Row(children: [
                      Text(coupon.code!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 16)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: coupon.code!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Code copied!'),
                                duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ]),
                  ],
                ),
              if (coupon.minimumPurchase != null)
                _statRow('Min Purchase',
                    '\$${coupon.minimumPurchase!.toStringAsFixed(2)}'),
              if (coupon.expirationDate != null)
                _statRow('Expires', _formatDate(coupon.expirationDate!)),
              if (coupon.description != null) ...[
                const Divider(),
                Text(coupon.description!,
                    style: const TextStyle(color: Colors.grey)),
              ],
              if (coupon.savedAmount != null)
                _statRow('Saved',
                    '\$${coupon.savedAmount!.toStringAsFixed(2)}'),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      coupon.isFavorite ? Icons.star : Icons.star_border,
                      color: coupon.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _service.toggleFavorite(coupon.id);
                        persistState();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  if (coupon.status == CouponStatus.active)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Redeem'),
                      onPressed: () => _showRedeemDialog(coupon),
                    ),
                  if (coupon.status == CouponStatus.redeemed)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo Redeem'),
                      onPressed: () {
                        setState(() {
                          _service.unmarkRedeemed(coupon.id);
                          persistState();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _service.removeCoupon(coupon.id);
                        persistState();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedeemDialog(CouponEntry coupon) {
    double? saved;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem Coupon'),
        content: TextField(
          decoration: const InputDecoration(
              labelText: 'Amount Saved (\$)', hintText: 'Optional'),
          keyboardType: TextInputType.number,
          onChanged: (v) => saved = double.tryParse(v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _service.markRedeemed(coupon.id, savedAmount: saved);
                persistState();
              });
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}
