import 'package:flutter/material.dart';
import '../../core/services/aspect_ratio_service.dart';

/// Aspect Ratio Calculator — compute ratios, resize dimensions, browse
/// common presets for photo/video/design work.
class AspectRatioScreen extends StatefulWidget {
  const AspectRatioScreen({super.key});

  @override
  State<AspectRatioScreen> createState() => _AspectRatioScreenState();
}

class _AspectRatioScreenState extends State<AspectRatioScreen>
    with SingleTickerProviderStateMixin {
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  late TabController _tabController;

  String _ratioText = '';
  String _orientationText = '';
  double _megapixels = 0;
  double _decimal = 0;

  // For resize calculator
  final _newWidthController = TextEditingController();
  final _newHeightController = TextEditingController();
  double _ratioW = 0;
  double _ratioH = 0;
  bool _lockRatio = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _newWidthController.dispose();
    _newHeightController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _analyze() {
    final w = int.tryParse(_widthController.text);
    final h = int.tryParse(_heightController.text);
    if (w == null || h == null || w <= 0 || h <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid width and height')),
      );
      return;
    }
    final (rw, rh) = AspectRatioService.simplify(w, h);
    setState(() {
      _ratioText = '$rw:$rh';
      _orientationText = AspectRatioService.orientation(w.toDouble(), h.toDouble());
      _megapixels = AspectRatioService.megapixels(w.toDouble(), h.toDouble());
      _decimal = AspectRatioService.toDecimal(rw.toDouble(), rh.toDouble());
      _ratioW = rw.toDouble();
      _ratioH = rh.toDouble();
    });
  }

  void _onNewWidthChanged(String val) {
    if (!_lockRatio || _ratioW <= 0) return;
    final w = double.tryParse(val);
    if (w == null || w <= 0) return;
    final h = AspectRatioService.calculateHeight(w, _ratioW, _ratioH);
    _newHeightController.text = h.round().toString();
  }

  void _onNewHeightChanged(String val) {
    if (!_lockRatio || _ratioH <= 0) return;
    final h = double.tryParse(val);
    if (h == null || h <= 0) return;
    final w = AspectRatioService.calculateWidth(h, _ratioW, _ratioH);
    _newWidthController.text = w.round().toString();
  }

  void _applyPreset(AspectRatioPreset preset) {
    setState(() {
      _ratioW = preset.w;
      _ratioH = preset.h;
      _ratioText = preset.label;
      _decimal = AspectRatioService.toDecimal(preset.w, preset.h);
      _orientationText = AspectRatioService.orientation(preset.w, preset.h);
      _megapixels = 0;
    });
    _newWidthController.clear();
    _newHeightController.clear();
    _tabController.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied ${preset.label} — ${preset.description}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aspect Ratio Calculator'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.crop), text: 'Analyze'),
            Tab(icon: Icon(Icons.photo_size_select_large), text: 'Resize'),
            Tab(icon: Icon(Icons.list), text: 'Presets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyzeTab(theme),
          _buildResizeTab(theme),
          _buildPresetsTab(theme),
        ],
      ),
    );
  }

  Widget _buildAnalyzeTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enter Dimensions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _widthController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Width (px)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.width_normal),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.close, size: 18),
              ),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (px)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.calculate),
            label: const Text('Analyze'),
          ),
          if (_ratioText.isNotEmpty) ...[
            const SizedBox(height: 24),
            _ResultCard(
              children: [
                _ResultRow('Aspect Ratio', _ratioText),
                _ResultRow('Decimal', _decimal.toStringAsFixed(4)),
                _ResultRow('Orientation', _orientationText),
                _ResultRow('Megapixels', '${_megapixels.toStringAsFixed(2)} MP'),
              ],
            ),
            const SizedBox(height: 16),
            // Visual preview
            Center(
              child: AspectRatio(
                aspectRatio: _ratioW / (_ratioH == 0 ? 1 : _ratioH),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Text(
                      _ratioText,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResizeTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_ratioText.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.secondary, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Analyze dimensions first or select a preset to lock the aspect ratio.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Locked ratio: $_ratioText',
                        style: theme.textTheme.titleSmall),
                    const Spacer(),
                    Switch(
                      value: _lockRatio,
                      onChanged: (v) => setState(() => _lockRatio = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newWidthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Width (px)',
                border: OutlineInputBorder(),
              ),
              onChanged: _onNewWidthChanged,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newHeightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Height (px)',
                border: OutlineInputBorder(),
              ),
              onChanged: _onNewHeightChanged,
            ),
            const SizedBox(height: 16),
            Text(
              'Type a new width or height and the other dimension '
              'will auto-calculate to maintain the ratio.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetsTab(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: AspectRatioService.presets.length,
      itemBuilder: (context, index) {
        final p = AspectRatioService.presets[index];
        return Card(
          child: ListTile(
            leading: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AspectRatio(
                  aspectRatio: p.w / p.h,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(p.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(p.description),
            trailing: Text(
              AspectRatioService.toDecimal(p.w, p.h).toStringAsFixed(2),
              style: theme.textTheme.bodySmall,
            ),
            onTap: () => _applyPreset(p),
          ),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final List<Widget> children;
  const _ResultCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
