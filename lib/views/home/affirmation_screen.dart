import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/affirmation_service.dart';

/// Daily Affirmation screen with today's affirmation, random shuffle,
/// category browsing, favorites, custom affirmations, and history.
class AffirmationScreen extends StatefulWidget {
  const AffirmationScreen({super.key});

  @override
  State<AffirmationScreen> createState() => _AffirmationScreenState();
}

class _AffirmationScreenState extends State<AffirmationScreen>
    with SingleTickerProviderStateMixin {
  final _service = AffirmationService();
  late Affirmation _current;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _selectedCategory;
  int _tabIndex = 0; // 0=Today, 1=Browse, 2=Favorites, 3=History

  @override
  void initState() {
    super.initState();
    _current = _service.getTodaysAffirmation();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _shuffle({String? category}) {
    _fadeController.reverse().then((_) {
      setState(() {
        _current = _service.getRandomAffirmation(category: category);
      });
      _fadeController.forward();
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 1)),
    );
  }

  void _showAddCustomDialog() {
    final textCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Affirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(
                labelText: 'Affirmation',
                hintText: 'I am...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Confidence, Growth',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (textCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _service.addCustom(
                    textCtrl.text.trim(),
                    catCtrl.text.trim().isEmpty ? 'Custom' : catCtrl.text.trim(),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Affirmation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add custom affirmation',
            onPressed: _showAddCustomDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildTab('Today', 0, Icons.today),
                _buildTab('Browse', 1, Icons.category),
                _buildTab('Favorites', 2, Icons.favorite),
                _buildTab('History', 3, Icons.history),
              ],
            ),
          ),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_tabIndex) {
      case 0:
        return _buildTodayTab(theme);
      case 1:
        return _buildBrowseTab(theme);
      case 2:
        return _buildFavoritesTab(theme);
      case 3:
        return _buildHistoryTab(theme);
      default:
        return _buildTodayTab(theme);
    }
  }

  Widget _buildTodayTab(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome,
                  size: 48, color: theme.colorScheme.primary.withOpacity(0.6)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _current.text,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Chip(
                label: Text(_current.category),
                avatar: const Icon(Icons.label, size: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: () => _shuffle(),
                    icon: const Icon(Icons.shuffle),
                    tooltip: 'Random affirmation',
                  ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    onPressed: () {
                      setState(() => _service.toggleFavorite(_current));
                    },
                    icon: Icon(
                      _service.isFavorite(_current)
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    tooltip: 'Toggle favorite',
                  ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    onPressed: () => _copyToClipboard(_current.text),
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to clipboard',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseTab(ThemeData theme) {
    final categories = _service.categories;
    if (_selectedCategory != null) {
      final items = _service.getByCategory(_selectedCategory!);
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedCategory = null),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(_selectedCategory!,
                    style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (ctx, i) => _affirmationTile(items[i], theme),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        final cat = categories[i];
        final count = _service.getByCategory(cat).length;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.folder),
            title: Text(cat),
            subtitle: Text('$count affirmation${count == 1 ? '' : 's'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _selectedCategory = cat),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab(ThemeData theme) {
    final favs = _service.favorites;
    if (favs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No favorites yet',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 4),
            Text('Tap the heart icon to save affirmations',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favs.length,
      itemBuilder: (ctx, i) => _affirmationTile(favs[i], theme, showHeart: true),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    final hist = _service.history;
    if (hist.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No history yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return Column(
      children: [
        if (hist.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _service.clearHistory());
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear'),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hist.length,
            itemBuilder: (ctx, i) => _affirmationTile(hist[i], theme,
                showTime: true),
          ),
        ),
      ],
    );
  }

  Widget _affirmationTile(Affirmation a, ThemeData theme,
      {bool showHeart = false, bool showTime = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(a.text, style: const TextStyle(fontStyle: FontStyle.italic)),
        subtitle: Text(
          showTime && a.shownAt != null
              ? '${a.category} • ${_formatTime(a.shownAt!)}'
              : a.category,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHeart)
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() => _service.toggleFavorite(a));
                },
              ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copyToClipboard(a.text),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
