import 'package:flutter/material.dart';
import '../../core/services/sun_moon_service.dart';
import '../../models/sun_moon_entry.dart';

/// Sun & Moon Tracker screen — shows sunrise/sunset, golden hour,
/// moon phase, and daylight info for any date and location.
class SunMoonScreen extends StatefulWidget {
  const SunMoonScreen({super.key});

  @override
  State<SunMoonScreen> createState() => _SunMoonScreenState();
}

class _SunMoonScreenState extends State<SunMoonScreen> {
  final _service = const SunMoonService();
  late DateTime _selectedDate;
  late SavedLocation _selectedLocation;
  late SunMoonData _data;
  bool _showWeekView = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedLocation = SunMoonService.defaultLocations.first; // Seattle
    _recalculate();
  }

  void _recalculate() {
    _data = _service.calculate(
      date: _selectedDate,
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sun & Moon'),
        actions: [
          IconButton(
            icon: Icon(_showWeekView ? Icons.today : Icons.date_range),
            tooltip: _showWeekView ? 'Day view' : 'Week view',
            onPressed: () => setState(() => _showWeekView = !_showWeekView),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pick date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationSelector(theme),
            const SizedBox(height: 12),
            _buildDateNav(theme),
            const SizedBox(height: 16),
            if (_showWeekView)
              _buildWeekView(theme)
            else ...[
              _buildMoonCard(theme, isDark),
              const SizedBox(height: 12),
              _buildSunCard(theme),
              const SizedBox(height: 12),
              _buildGoldenHourCard(theme),
              const SizedBox(height: 12),
              _buildUpcomingCard(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedLocation.id,
      decoration: InputDecoration(
        labelText: 'Location',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: SunMoonService.defaultLocations.map((loc) {
        return DropdownMenuItem(value: loc.id, child: Text(loc.name));
      }).toList(),
      onChanged: (id) {
        if (id == null) return;
        setState(() {
          _selectedLocation =
              SunMoonService.defaultLocations.firstWhere((l) => l.id == id);
          _recalculate();
        });
      },
    );
  }

  Widget _buildDateNav(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeDate(-1),
        ),
        TextButton(
          onPressed: _pickDate,
          child: Text(
            _formatDate(_selectedDate),
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeDate(1),
        ),
        if (!_isToday(_selectedDate))
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _recalculate();
              });
            },
            child: const Text('Today'),
          ),
      ],
    );
  }

  Widget _buildMoonCard(ThemeData theme, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _data.moonPhase.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 8),
            Text(
              _data.moonPhase.label,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${(_data.moonIllumination * 100).toStringAsFixed(0)}% illuminated · Day ${_data.moonAge}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(178),
              ),
            ),
            const SizedBox(height: 12),
            _buildMoonPhaseBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMoonPhaseBar(ThemeData theme) {
    final phases = MoonPhase.values;
    final currentIdx = phases.indexOf(_data.moonPhase);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: phases.map((phase) {
        final isActive = phase == phases[currentIdx];
        return Column(
          children: [
            Text(
              phase.emoji,
              style: TextStyle(
                fontSize: isActive ? 24 : 16,
                color: isActive ? null : theme.colorScheme.onSurface.withAlpha(102),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSunCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Sun', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('🌅 Sunrise', _formatTime(_data.sunrise)),
            _infoRow('☀️ Solar Noon', _formatTime(_data.solarNoon)),
            _infoRow('🌇 Sunset', _formatTime(_data.sunset)),
            const Divider(),
            _infoRow('📏 Daylight', _data.daylightFormatted),
            if (_data.isSunUp)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('☀️ Sun is currently up'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldenHourCard(ThemeData theme) {
    return Card(
      color: _data.isGoldenHourNow ? Colors.amber.withAlpha(38) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Golden Hour', style: theme.textTheme.titleMedium),
                if (_data.isGoldenHourNow) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('NOW',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(
              '🌄 Morning',
              '${_formatTime(_data.goldenHourMorningStart)} – ${_formatTime(_data.goldenHourMorningEnd)}',
            ),
            _infoRow(
              '🌆 Evening',
              '${_formatTime(_data.goldenHourEveningStart)} – ${_formatTime(_data.goldenHourEveningEnd)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Best for outdoor photography 📸',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(ThemeData theme) {
    final nextFull = _service.nextFullMoon(_selectedDate);
    final nextNew = _service.nextNewMoon(_selectedDate);
    final daysToFull = nextFull.difference(_selectedDate).inDays;
    final daysToNew = nextNew.difference(_selectedDate).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upcoming', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _infoRow(
              '🌕 Next Full Moon',
              '${_formatDate(nextFull)} (${daysToFull}d)',
            ),
            _infoRow(
              '🌑 Next New Moon',
              '${_formatDate(nextNew)} (${daysToNew}d)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView(ThemeData theme) {
    final weekData = _service.calculateRange(
      start: _selectedDate,
      days: 7,
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
    );

    return Column(
      children: weekData.map((d) {
        final isToday = _isToday(d.date);
        return Card(
          color: isToday ? theme.colorScheme.primaryContainer.withAlpha(76) : null,
          child: ListTile(
            leading: Text(d.moonPhase.emoji, style: const TextStyle(fontSize: 28)),
            title: Text(_formatDate(d.date)),
            subtitle: Text(
              '☀️ ${_formatTime(d.sunrise)} – ${_formatTime(d.sunset)}  ·  ${d.daylightFormatted}',
            ),
            trailing: Text(
              '${(d.moonIllumination * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall,
            ),
            onTap: () {
              setState(() {
                _selectedDate = d.date;
                _showWeekView = false;
                _recalculate();
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _recalculate();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _recalculate();
      });
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime time) {
    final h = time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }
}
