import 'dart:convert';

/// Types of attachments that can be added to an event.
enum AttachmentType {
  /// A file attachment (document, PDF, etc.).
  file,

  /// A photo or image attachment.
  photo,

  /// A web link / URL attachment.
  link;

  /// Display label for the attachment type.
  String get label {
    switch (this) {
      case AttachmentType.file:
        return 'File';
      case AttachmentType.photo:
        return 'Photo';
      case AttachmentType.link:
        return 'Link';
    }
  }

  /// Icon name associated with this attachment type.
  String get iconName {
    switch (this) {
      case AttachmentType.file:
        return 'attach_file';
      case AttachmentType.photo:
        return 'photo';
      case AttachmentType.link:
        return 'link';
    }
  }

  /// Converts a stored string back to an [AttachmentType].
  static AttachmentType fromString(String value) {
    return AttachmentType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => AttachmentType.file,
    );
  }
}

/// A single attachment on an event.
///
/// Each attachment has a [type] (file, photo, or link), a [name]
/// (display label), and a [uri] (path or URL). Optionally stores
/// [mimeType] and [sizeBytes] for files/photos.
///
/// Attachments are immutable — use [copyWith] to create modified copies.
class EventAttachment {
  /// Unique identifier for this attachment.
  final String id;

  /// The type of attachment.
  final AttachmentType type;

  /// Display name for the attachment.
  final String name;

  /// The URI, file path, or URL of the attachment.
  final String uri;

  /// Optional MIME type (e.g., 'image/png', 'application/pdf').
  final String? mimeType;

  /// Optional file size in bytes.
  final int? sizeBytes;

  /// When this attachment was added.
  final DateTime addedAt;

  /// Maximum allowed name length.
  static const int maxNameLength = 200;

  /// Maximum allowed URI length.
  static const int maxUriLength = 2048;

  /// Maximum number of attachments per event.
  static const int maxAttachments = 20;

  EventAttachment({
    required this.id,
    required this.type,
    required this.name,
    required this.uri,
    this.mimeType,
    this.sizeBytes,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Creates a new file attachment.
  factory EventAttachment.file({
    required String name,
    required String uri,
    String? mimeType,
    int? sizeBytes,
  }) {
    return EventAttachment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: AttachmentType.file,
      name: _truncate(name, maxNameLength),
      uri: _truncate(uri, maxUriLength),
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }

  /// Creates a new photo attachment.
  factory EventAttachment.photo({
    required String name,
    required String uri,
    String? mimeType,
    int? sizeBytes,
  }) {
    return EventAttachment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: AttachmentType.photo,
      name: _truncate(name, maxNameLength),
      uri: _truncate(uri, maxUriLength),
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }

  /// Creates a new link attachment.
  factory EventAttachment.link({
    required String name,
    required String uri,
  }) {
    return EventAttachment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: AttachmentType.link,
      name: _truncate(name, maxNameLength),
      uri: _truncate(uri, maxUriLength),
    );
  }

  static String _truncate(String value, int maxLen) {
    if (value.length <= maxLen) return value;
    return value.substring(0, maxLen);
  }

  /// Whether this attachment is a link type.
  bool get isLink => type == AttachmentType.link;

  /// Whether this attachment is a photo type.
  bool get isPhoto => type == AttachmentType.photo;

  /// Whether this attachment is a file type.
  bool get isFile => type == AttachmentType.file;

  /// Returns a human-readable file size string.
  String get formattedSize {
    if (sizeBytes == null) return '';
    final bytes = sizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Returns the file extension from the URI, or empty string.
  String get extension {
    final lastDot = uri.lastIndexOf('.');
    if (lastDot < 0 || lastDot == uri.length - 1) return '';
    final ext = uri.substring(lastDot + 1).toLowerCase();
    // Strip query params
    final queryIdx = ext.indexOf('?');
    if (queryIdx >= 0) return ext.substring(0, queryIdx);
    return ext;
  }

  /// Creates a copy with the given fields replaced.
  EventAttachment copyWith({
    String? id,
    AttachmentType? type,
    String? name,
    String? uri,
    String? mimeType,
    bool clearMimeType = false,
    int? sizeBytes,
    bool clearSizeBytes = false,
    DateTime? addedAt,
  }) {
    return EventAttachment(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      uri: uri ?? this.uri,
      mimeType: clearMimeType ? null : (mimeType ?? this.mimeType),
      sizeBytes: clearSizeBytes ? null : (sizeBytes ?? this.sizeBytes),
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Converts this attachment to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'uri': uri,
      if (mimeType != null) 'mimeType': mimeType,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  /// Creates an attachment from a JSON map.
  factory EventAttachment.fromJson(Map<String, dynamic> json) {
    return EventAttachment(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: AttachmentType.fromString(json['type'] as String? ?? 'file'),
      name: json['name'] as String? ?? '',
      uri: json['uri'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAttachment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          name == other.name &&
          uri == other.uri &&
          mimeType == other.mimeType &&
          sizeBytes == other.sizeBytes;

  @override
  int get hashCode => Object.hash(id, type, name, uri, mimeType, sizeBytes);

  @override
  String toString() =>
      'EventAttachment(id: $id, type: ${type.label}, name: $name, uri: $uri)';
}

/// A collection of attachments on an event.
///
/// Manages an ordered list of [EventAttachment] items with add, remove,
/// update, and query operations. Maximum [EventAttachment.maxAttachments]
/// items allowed.
///
/// The collection is immutable — all mutation methods return new instances.
class EventAttachments {
  final List<EventAttachment> _items;

  /// Creates an [EventAttachments] with the given items.
  const EventAttachments({List<EventAttachment> items = const []})
      : _items = items;

  /// Creates an empty attachments collection.
  const EventAttachments.empty() : _items = const [];

  /// All attachments in order.
  List<EventAttachment> get items => List.unmodifiable(_items);

  /// Number of attachments.
  int get count => _items.length;

  /// Whether there are any attachments.
  bool get hasAttachments => _items.isNotEmpty;

  /// Whether the maximum number of attachments has been reached.
  bool get isFull => _items.length >= EventAttachment.maxAttachments;

  /// How many more attachments can be added.
  int get remainingCapacity =>
      (EventAttachment.maxAttachments - _items.length).clamp(0, EventAttachment.maxAttachments);

  /// Returns attachments filtered by type.
  List<EventAttachment> byType(AttachmentType type) =>
      _items.where((a) => a.type == type).toList();

  /// Number of file attachments.
  int get fileCount => byType(AttachmentType.file).length;

  /// Number of photo attachments.
  int get photoCount => byType(AttachmentType.photo).length;

  /// Number of link attachments.
  int get linkCount => byType(AttachmentType.link).length;

  /// Total size of all attachments with known sizes (in bytes).
  int get totalSizeBytes {
    int total = 0;
    for (final item in _items) {
      if (item.sizeBytes != null) total += item.sizeBytes!;
    }
    return total;
  }

  /// Human-readable total size.
  String get formattedTotalSize {
    final bytes = totalSizeBytes;
    if (bytes == 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Gets an attachment by its ID, or null if not found.
  EventAttachment? getById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Whether an attachment with the given ID exists.
  bool containsId(String id) => getById(id) != null;

  /// Whether any attachment has the given URI.
  bool containsUri(String uri) => _items.any((a) => a.uri == uri);

  /// Adds an attachment. Returns a new collection.
  /// Ignores the add if already at max capacity or duplicate ID.
  EventAttachments addAttachment(EventAttachment attachment) {
    if (isFull) return this;
    if (containsId(attachment.id)) return this;
    return EventAttachments(items: [..._items, attachment]);
  }

  /// Removes an attachment by ID. Returns a new collection.
  EventAttachments removeAttachment(String id) {
    final filtered = _items.where((a) => a.id != id).toList();
    if (filtered.length == _items.length) return this;
    return EventAttachments(items: filtered);
  }

  /// Updates an attachment by ID. Returns a new collection.
  EventAttachments updateAttachment(String id, EventAttachment updated) {
    final newItems = _items.map((a) => a.id == id ? updated : a).toList();
    return EventAttachments(items: newItems);
  }

  /// Reorders an attachment from [oldIndex] to [newIndex].
  EventAttachments reorderAttachment(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return this;
    if (newIndex < 0 || newIndex >= _items.length) return this;
    if (oldIndex == newIndex) return this;
    final newItems = List<EventAttachment>.from(_items);
    final item = newItems.removeAt(oldIndex);
    newItems.insert(newIndex, item);
    return EventAttachments(items: newItems);
  }

  /// Removes all attachments of a given type.
  EventAttachments removeByType(AttachmentType type) {
    final filtered = _items.where((a) => a.type != type).toList();
    return EventAttachments(items: filtered);
  }

  /// Removes all attachments.
  EventAttachments clear() => const EventAttachments.empty();

  /// A short summary string like "2 files, 1 photo, 3 links".
  String get summary {
    if (!hasAttachments) return 'No attachments';
    final parts = <String>[];
    final fc = fileCount;
    final pc = photoCount;
    final lc = linkCount;
    if (fc > 0) parts.add('$fc ${fc == 1 ? 'file' : 'files'}');
    if (pc > 0) parts.add('$pc ${pc == 1 ? 'photo' : 'photos'}');
    if (lc > 0) parts.add('$lc ${lc == 1 ? 'link' : 'links'}');
    return parts.join(', ');
  }

  /// Converts to a JSON-encodable list.
  List<Map<String, dynamic>> toJson() =>
      _items.map((a) => a.toJson()).toList();

  /// Serializes to a JSON string for DB storage.
  String toJsonString() => jsonEncode(toJson());

  /// Creates from a JSON list.
  factory EventAttachments.fromJson(List<dynamic> json) {
    final items = json
        .whereType<Map<String, dynamic>>()
        .map((j) => EventAttachment.fromJson(j))
        .toList();
    // Enforce max
    final capped = items.length > EventAttachment.maxAttachments
        ? items.sublist(0, EventAttachment.maxAttachments)
        : items;
    return EventAttachments(items: capped);
  }

  /// Creates from a JSON string (as stored in DB). Returns empty on null/invalid.
  factory EventAttachments.fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return const EventAttachments.empty();
    }
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return EventAttachments.fromJson(decoded);
      }
      return const EventAttachments.empty();
    } catch (_) {
      return const EventAttachments.empty();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EventAttachments) return false;
    if (_items.length != other._items.length) return false;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i] != other._items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_items);

  @override
  String toString() => 'EventAttachments($summary)';
}
