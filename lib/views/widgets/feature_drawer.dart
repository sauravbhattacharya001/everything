import 'package:flutter/material.dart';
import '../../core/utils/feature_registry.dart';

/// A categorized navigation drawer built from [FeatureRegistry].
///
/// Replaces the 50+ individual AppBar IconButtons with a searchable,
/// categorized list of all app features.
class FeatureDrawer extends StatefulWidget {
  const FeatureDrawer({super.key});

  @override
  State<FeatureDrawer> createState() => _FeatureDrawerState();
}

class _FeatureDrawerState extends State<FeatureDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FeatureEntry> _filteredFeatures() {
    if (_query.isEmpty) return FeatureRegistry.features;
    return FeatureRegistry.features
        .where((f) => f.searchLabel.contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFeatures();
    final grouped = <FeatureCategory, List<FeatureEntry>>{};
    for (final entry in filtered) {
      grouped.putIfAbsent(entry.category, () => []).add(entry);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search features...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _query = value.trim().toLowerCase());
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Feature list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No features match "$_query"',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        for (final category in FeatureCategory.values)
                          if (grouped.containsKey(category)) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Row(
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...grouped[category]!.map(
                              (feature) => ListTile(
                                leading: Icon(feature.icon),
                                title: Text(feature.label),
                                dense: true,
                                onTap: () {
                                  Navigator.of(context).pop(); // close drawer
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: feature.builder),
                                  );
                                },
                              ),
                            ),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
