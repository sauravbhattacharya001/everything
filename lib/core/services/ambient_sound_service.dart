/// Service for managing ambient sound mixer state.
///
/// Each [AmbientSound] represents a loopable ambient audio source
/// with individual volume control.  The mixer allows multiple sounds
/// to play simultaneously so users can compose their ideal atmosphere.
///
/// Note: actual audio playback requires a platform audio plugin such as
/// `just_audio` or `audioplayers`.  This service manages the *state*
/// (which sounds are active, their volumes, saved presets) and exposes
/// a clean API that a playback layer can drive from.

class AmbientSound {
  final String id;
  final String label;
  final String icon; // emoji
  final String category;
  double volume; // 0.0 – 1.0
  bool active;

  AmbientSound({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
    this.volume = 0.5,
    this.active = false,
  });

  AmbientSound copyWith({double? volume, bool? active}) => AmbientSound(
        id: id,
        label: label,
        icon: icon,
        category: category,
        volume: volume ?? this.volume,
        active: active ?? this.active,
      );
}

class SoundPreset {
  final String name;
  final Map<String, double> volumes; // soundId → volume (only active ones)
  final DateTime createdAt;

  const SoundPreset({
    required this.name,
    required this.volumes,
    required this.createdAt,
  });
}

class AmbientSoundService {
  static final List<AmbientSound> defaultSounds = [
    // Nature
    AmbientSound(id: 'rain', label: 'Rain', icon: '🌧️', category: 'Nature'),
    AmbientSound(id: 'thunder', label: 'Thunder', icon: '⛈️', category: 'Nature'),
    AmbientSound(id: 'ocean', label: 'Ocean Waves', icon: '🌊', category: 'Nature'),
    AmbientSound(id: 'river', label: 'River', icon: '🏞️', category: 'Nature'),
    AmbientSound(id: 'forest', label: 'Forest', icon: '🌲', category: 'Nature'),
    AmbientSound(id: 'birds', label: 'Birds', icon: '🐦', category: 'Nature'),
    AmbientSound(id: 'wind', label: 'Wind', icon: '💨', category: 'Nature'),
    AmbientSound(id: 'crickets', label: 'Crickets', icon: '🦗', category: 'Nature'),
    AmbientSound(id: 'campfire', label: 'Campfire', icon: '🔥', category: 'Nature'),
    // Urban
    AmbientSound(id: 'cafe', label: 'Café Chatter', icon: '☕', category: 'Urban'),
    AmbientSound(id: 'traffic', label: 'City Traffic', icon: '🚗', category: 'Urban'),
    AmbientSound(id: 'train', label: 'Train', icon: '🚂', category: 'Urban'),
    AmbientSound(id: 'keyboard', label: 'Keyboard Typing', icon: '⌨️', category: 'Urban'),
    AmbientSound(id: 'construction', label: 'Construction', icon: '🏗️', category: 'Urban'),
    // White Noise
    AmbientSound(id: 'white', label: 'White Noise', icon: '📻', category: 'Noise'),
    AmbientSound(id: 'pink', label: 'Pink Noise', icon: '🩷', category: 'Noise'),
    AmbientSound(id: 'brown', label: 'Brown Noise', icon: '🟤', category: 'Noise'),
    // Mechanical
    AmbientSound(id: 'fan', label: 'Fan', icon: '🌀', category: 'Mechanical'),
    AmbientSound(id: 'clock', label: 'Clock Ticking', icon: '🕐', category: 'Mechanical'),
    AmbientSound(id: 'washing', label: 'Washing Machine', icon: '🫧', category: 'Mechanical'),
  ];

  final List<AmbientSound> _sounds;
  final List<SoundPreset> _presets = [];
  DateTime? _timerEnd;

  AmbientSoundService()
      : _sounds = defaultSounds.map((s) => s.copyWith()).toList();

  List<AmbientSound> get sounds => List.unmodifiable(_sounds);
  List<AmbientSound> get activeSounds => _sounds.where((s) => s.active).toList();
  List<SoundPreset> get presets => List.unmodifiable(_presets);
  DateTime? get timerEnd => _timerEnd;
  bool get hasTimer => _timerEnd != null && _timerEnd!.isAfter(DateTime.now());

  List<String> get categories =>
      _sounds.map((s) => s.category).toSet().toList();

  List<AmbientSound> soundsInCategory(String category) =>
      _sounds.where((s) => s.category == category).toList();

  void toggleSound(String id) {
    final s = _sounds.firstWhere((s) => s.id == id);
    s.active = !s.active;
    if (!s.active) s.volume = 0.5;
  }

  void setVolume(String id, double volume) {
    final s = _sounds.firstWhere((s) => s.id == id);
    s.volume = volume.clamp(0.0, 1.0);
  }

  void stopAll() {
    for (final s in _sounds) {
      s.active = false;
    }
    _timerEnd = null;
  }

  void setTimer(Duration duration) {
    _timerEnd = DateTime.now().add(duration);
  }

  void clearTimer() => _timerEnd = null;

  void savePreset(String name) {
    final volumes = <String, double>{};
    for (final s in activeSounds) {
      volumes[s.id] = s.volume;
    }
    _presets.add(SoundPreset(
      name: name,
      volumes: volumes,
      createdAt: DateTime.now(),
    ));
  }

  void loadPreset(SoundPreset preset) {
    stopAll();
    for (final entry in preset.volumes.entries) {
      final s = _sounds.firstWhere((s) => s.id == entry.key,
          orElse: () => _sounds.first);
      if (s.id == entry.key) {
        s.active = true;
        s.volume = entry.value;
      }
    }
  }

  void deletePreset(int index) {
    if (index >= 0 && index < _presets.length) {
      _presets.removeAt(index);
    }
  }
}
