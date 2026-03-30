import 'package:flutter/material.dart';

/// A timezone converter that lets users convert a specific time
/// from one timezone to another.
///
/// Unlike the World Clock (which shows current times), this tool
/// lets you answer "If it's 3 PM in Tokyo, what time is it in New York?"
class TimezoneConverterScreen extends StatefulWidget {
  const TimezoneConverterScreen({super.key});

  @override
  State<TimezoneConverterScreen> createState() =>
      _TimezoneConverterScreenState();
}

class _TimezoneConverterScreenState extends State<TimezoneConverterScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  String _fromZone = 'UTC';
  String _toZone = 'US/Pacific';

  // History of recent conversions
  final List<_ConversionRecord> _history = [];

  static const Map<String, int> _timezoneOffsets = {
    'UTC': 0,
    'US/Eastern': -5,
    'US/Central': -6,
    'US/Mountain': -7,
    'US/Pacific': -8,
    'US/Alaska': -9,
    'US/Hawaii': -10,
    'Europe/London': 0,
    'Europe/Paris': 1,
    'Europe/Berlin': 1,
    'Europe/Moscow': 3,
    'Europe/Istanbul': 3,
    'Asia/Dubai': 4,
    'Asia/Kolkata': 5,
    'Asia/Bangkok': 7,
    'Asia/Singapore': 8,
    'Asia/Hong_Kong': 8,
    'Asia/Shanghai': 8,
    'Asia/Tokyo': 9,
    'Asia/Seoul': 9,
    'Australia/Sydney': 11,
    'Australia/Perth': 8,
    'Pacific/Auckland': 13,
    'Pacific/Fiji': 12,
    'America/Sao_Paulo': -3,
    'America/Buenos_Aires': -3,
    'America/Mexico_City': -6,
    'Africa/Cairo': 2,
    'Africa/Lagos': 1,
    'Africa/Johannesburg': 2,
    'Asia/Karachi': 5,
    'Asia/Dhaka': 6,
    'Asia/Jakarta': 7,
  };

  static const Map<String, String> _timezoneLabels = {
    'UTC': 'UTC (±0:00)',
    'US/Eastern': 'New York (UTC−5)',
    'US/Central': 'Chicago (UTC−6)',
    'US/Mountain': 'Denver (UTC−7)',
    'US/Pacific': 'Los Angeles (UTC−8)',
    'US/Alaska': 'Anchorage (UTC−9)',
    'US/Hawaii': 'Honolulu (UTC−10)',
    'Europe/London': 'London (UTC±0)',
    'Europe/Paris': 'Paris (UTC+1)',
    'Europe/Berlin': 'Berlin (UTC+1)',
    'Europe/Moscow': 'Moscow (UTC+3)',
    'Europe/Istanbul': 'Istanbul (UTC+3)',
    'Asia/Dubai': 'Dubai (UTC+4)',
    'Asia/Kolkata': 'Kolkata (UTC+5:30)',
    'Asia/Bangkok': 'Bangkok (UTC+7)',
    'Asia/Singapore': 'Singapore (UTC+8)',
    'Asia/Hong_Kong': 'Hong Kong (UTC+8)',
    'Asia/Shanghai': 'Shanghai (UTC+8)',
    'Asia/Tokyo': 'Tokyo (UTC+9)',
    'Asia/Seoul': 'Seoul (UTC+9)',
    'Australia/Sydney': 'Sydney (UTC+11)',
    'Australia/Perth': 'Perth (UTC+8)',
    'Pacific/Auckland': 'Auckland (UTC+13)',
    'Pacific/Fiji': 'Fiji (UTC+12)',
    'America/Sao_Paulo': 'São Paulo (UTC−3)',
    'America/Buenos_Aires': 'Buenos Aires (UTC−3)',
    'America/Mexico_City': 'Mexico City (UTC−6)',
    'Africa/Cairo': 'Cairo (UTC+2)',
    'Africa/Lagos': 'Lagos (UTC+1)',
    'Africa/Johannesburg': 'Johannesburg (UTC+2)',
    'Asia/Karachi': 'Karachi (UTC+5)',
    'Asia/Dhaka': 'Dhaka (UTC+6)',
    'Asia/Jakarta': 'Jakarta (UTC+7)',
  };

  /// Special handling for half-hour offsets.
  int _getOffsetMinutes(String zone) {
    if (zone == 'Asia/Kolkata') return 330; // +5:30
    return (_timezoneOffsets[zone] ?? 0) * 60;
  }

  DateTime _convertTime() {
    final fromOffset = _getOffsetMinutes(_fromZone);
    final toOffset = _getOffsetMinutes(_toZone);
    final diff = toOffset - fromOffset;

    final sourceDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return sourceDateTime.add(Duration(minutes: diff));
  }

  void _swapZones() {
    setState(() {
      final tmp = _fromZone;
      _fromZone = _toZone;
      _toZone = tmp;
    });
  }

  void _saveToHistory() {
    final converted = _convertTime();
    setState(() {
      _history.insert(
        0,
        _ConversionRecord(
          fromZone: _fromZone,
          toZone: _toZone,
          sourceTime: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          ),
          convertedTime: converted,
        ),
      );
      if (_history.length > 20) _history.removeLast();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversion saved to history'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _setNow() {
    setState(() {
      _selectedTime = TimeOfDay.now();
      _selectedDate = DateTime.now();
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _timeDiffLabel() {
    final fromOffset = _getOffsetMinutes(_fromZone);
    final toOffset = _getOffsetMinutes(_toZone);
    final diffMinutes = toOffset - fromOffset;
    final hours = diffMinutes ~/ 60;
    final mins = (diffMinutes % 60).abs();
    if (diffMinutes == 0) return 'Same timezone';
    final sign = diffMinutes > 0 ? '+' : '';
    if (mins == 0) return '${sign}${hours}h';
    return '${sign}${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final converted = _convertTime();
    final dayDiff = DateTime(converted.year, converted.month, converted.day)
        .difference(DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day))
        .inDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timezone Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            tooltip: 'Set to now',
            onPressed: _setNow,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            tooltip: 'Save conversion',
            onPressed: _saveToHistory,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Source time card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 8),
                  _buildZoneDropdown(_fromZone, (v) {
                    setState(() => _fromZone = v!);
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.schedule),
                          label: Text(_selectedTime.format(context)),
                          onPressed: _pickTime,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}'),
                          onPressed: _pickDate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Swap button + diff label
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_timeDiffLabel(),
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.swap_vert),
                  tooltip: 'Swap timezones',
                  onPressed: _swapZones,
                ),
              ],
            ),
          ),

          // Result card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 8),
                  _buildZoneDropdown(_toZone, (v) {
                    setState(() => _toZone = v!);
                  }),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _formatTime(converted),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                        Text(
                          _formatDate(converted),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                        if (dayDiff != 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: dayDiff > 0
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              dayDiff > 0
                                  ? '+$dayDiff day${dayDiff > 1 ? 's' : ''}'
                                  : '$dayDiff day${dayDiff < -1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    dayDiff > 0 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Multi-zone comparison
          const SizedBox(height: 24),
          Text('Quick Compare',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._buildQuickCompare(),

          // History
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('History',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () => setState(() => _history.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._history.map(_buildHistoryTile),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneDropdown(
      String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _timezoneOffsets.keys.map((zone) {
        return DropdownMenuItem(
          value: zone,
          child: Text(
            _timezoneLabels[zone] ?? zone,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  List<Widget> _buildQuickCompare() {
    final popular = [
      'US/Pacific',
      'US/Eastern',
      'Europe/London',
      'Europe/Berlin',
      'Asia/Tokyo',
      'Asia/Shanghai',
      'Australia/Sydney',
    ].where((z) => z != _fromZone).toList();

    final sourceDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final fromOffset = _getOffsetMinutes(_fromZone);

    return popular.map((zone) {
      final toOffset = _getOffsetMinutes(zone);
      final diff = toOffset - fromOffset;
      final converted = sourceDateTime.add(Duration(minutes: diff));
      final dayDiff = DateTime(converted.year, converted.month, converted.day)
          .difference(DateTime(
              _selectedDate.year, _selectedDate.month, _selectedDate.day))
          .inDays;

      return ListTile(
        dense: true,
        leading: const Icon(Icons.public, size: 20),
        title: Text(_timezoneLabels[zone]?.split(' (').first ?? zone),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_formatTime(converted),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (dayDiff != 0)
              Text(
                ' (${dayDiff > 0 ? '+' : ''}$dayDiff)',
                style: TextStyle(
                  fontSize: 12,
                  color: dayDiff > 0 ? Colors.green : Colors.orange,
                ),
              ),
          ],
        ),
        onTap: () {
          setState(() => _toZone = zone);
        },
      );
    }).toList();
  }

  Widget _buildHistoryTile(_ConversionRecord record) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.history, size: 18),
      title: Text(
        '${_formatTime(record.sourceTime)} ${record.fromZone.split('/').last}'
        ' → ${_formatTime(record.convertedTime)} ${record.toZone.split('/').last}',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        _formatDate(record.sourceTime),
        style: const TextStyle(fontSize: 11),
      ),
      onTap: () {
        setState(() {
          _fromZone = record.fromZone;
          _toZone = record.toZone;
          _selectedTime = TimeOfDay(
              hour: record.sourceTime.hour,
              minute: record.sourceTime.minute);
          _selectedDate = record.sourceTime;
        });
      },
    );
  }
}

class _ConversionRecord {
  final String fromZone;
  final String toZone;
  final DateTime sourceTime;
  final DateTime convertedTime;

  _ConversionRecord({
    required this.fromZone,
    required this.toZone,
    required this.sourceTime,
    required this.convertedTime,
  });
}
