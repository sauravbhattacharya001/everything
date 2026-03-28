import 'package:flutter/material.dart';
import '../../core/services/periodic_table_service.dart';

/// Interactive periodic table with search, category filtering, and element details.
class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen> {
  String _query = '';
  String? _categoryFilter;

  static const _categoryColors = <String, Color>{
    'Alkali Metal': Color(0xFFFF6B6B),
    'Alkaline Earth Metal': Color(0xFFFFA94D),
    'Transition Metal': Color(0xFFFFD43B),
    'Post-Transition Metal': Color(0xFF69DB7C),
    'Metalloid': Color(0xFF38D9A9),
    'Nonmetal': Color(0xFF4DABF7),
    'Halogen': Color(0xFF748FFC),
    'Noble Gas': Color(0xFFDA77F2),
    'Lanthanide': Color(0xFFE599F7),
    'Actinide': Color(0xFFF783AC),
  };

  List<Element> get _filtered {
    var list = PeriodicTableService.search(_query);
    if (_categoryFilter != null) {
      list = list.where((e) => e.category == _categoryFilter).toList();
    }
    return list;
  }

  void _showDetail(Element el) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ElementDetail(element: el),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Periodic Table')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, symbol, or number…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Category chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _categoryFilter == null,
                    onSelected: (_) => setState(() => _categoryFilter = null),
                  ),
                ),
                ...PeriodicTableService.categories.map((cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(cat,
                            style: const TextStyle(fontSize: 12)),
                        selected: _categoryFilter == cat,
                        backgroundColor:
                            _categoryColors[cat]?.withValues(alpha: 0.2),
                        selectedColor:
                            _categoryColors[cat]?.withValues(alpha: 0.5),
                        onSelected: (_) => setState(() =>
                            _categoryFilter =
                                _categoryFilter == cat ? null : cat),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${filtered.length} elements',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Element grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 90,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.85,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final el = filtered[i];
                final color = _categoryColors[el.category] ??
                    theme.colorScheme.surfaceContainerHighest;
                return GestureDetector(
                  onTap: () => _showDetail(el),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(color: color, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${el.atomicNumber}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6))),
                        Text(el.symbol,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(el.name,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(fontSize: 8),
                            overflow: TextOverflow.ellipsis),
                        Text(el.massFormatted,
                            style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 8,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ElementDetail extends StatelessWidget {
  final Element element;
  const _ElementDetail({required this.element});

  @override
  Widget build(BuildContext context) {
    final el = element;
    final theme = Theme.of(context);
    final color = _PeriodicTableScreenState._categoryColors[el.category] ??
        theme.colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${el.atomicNumber}',
                      style: theme.textTheme.labelSmall),
                  Text(el.symbol,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(el.massFormatted,
                      style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(el.name, style: theme.textTheme.headlineSmall),
          ),
          Center(
            child: Chip(
              label: Text(el.category),
              backgroundColor: color.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 16),
          // Properties
          _propRow('Atomic Number', '${el.atomicNumber}'),
          _propRow('Atomic Mass', '${el.atomicMass}'),
          _propRow('Group', '${el.group}'),
          _propRow('Period', '${el.period}'),
          _propRow('Electron Config', el.electronConfig),
          if (el.electronegativity != null)
            _propRow('Electronegativity', '${el.electronegativity}'),
          if (el.density != null)
            _propRow('Density', '${el.density} g/cm³'),
          if (el.meltingPoint != null)
            _propRow('Melting Point', '${el.meltingPoint} K'),
          if (el.boilingPoint != null)
            _propRow('Boiling Point', '${el.boilingPoint} K'),
          if (el.yearDiscovered != null)
            _propRow(
                'Discovered',
                el.yearDiscovered! < 0
                    ? '~${el.yearDiscovered!.abs()} BC'
                    : '${el.yearDiscovered}'),
        ],
      ),
    );
  }

  Widget _propRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
