import 'dart:convert';
import 'storage_backend.dart';

/// A single poll with a question and options.
class Poll {
  final String id;
  final String question;
  final List<String> options;
  final Map<int, int> votes; // option index -> vote count
  final DateTime createdAt;
  bool isClosed;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    Map<int, int>? votes,
    DateTime? createdAt,
    this.isClosed = false,
  })  : votes = votes ?? {},
        createdAt = createdAt ?? DateTime.now();

  int get totalVotes => votes.values.fold(0, (a, b) => a + b);

  int votesFor(int index) => votes[index] ?? 0;

  double percentFor(int index) {
    if (totalVotes == 0) return 0;
    return votesFor(index) / totalVotes;
  }

  int? get winningIndex {
    if (totalVotes == 0) return null;
    int maxVotes = -1;
    int? winner;
    for (final entry in votes.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winner = entry.key;
      }
    }
    return winner;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'votes': votes.map((k, v) => MapEntry(k.toString(), v)),
        'createdAt': createdAt.toIso8601String(),
        'isClosed': isClosed,
      };

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
        id: json['id'] as String,
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        votes: (json['votes'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), v as int)),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isClosed: json['isClosed'] as bool? ?? false,
      );
}

/// Local-only poll management service with SharedPreferences persistence.
class QuickPollService {
  static const _storageKey = 'quick_polls';
  List<Poll> _polls = [];
  bool _loaded = false;

  List<Poll> get polls => List.unmodifiable(_polls);

  Future<void> load() async {
    if (_loaded) return;
    final raw = await StorageBackend.read(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _polls = list.map((e) => Poll.fromJson(e as Map<String, dynamic>)).toList();
    }
    _loaded = true;
  }

  Future<void> _save() async {
    await StorageBackend.write(_storageKey, jsonEncode(_polls.map((p) => p.toJson()).toList()));
  }

  Future<Poll> createPoll(String question, List<String> options) async {
    final poll = Poll(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      options: options,
    );
    _polls.insert(0, poll);
    await _save();
    return poll;
  }

  Future<void> vote(String pollId, int optionIndex) async {
    final poll = _polls.firstWhere((p) => p.id == pollId);
    poll.votes[optionIndex] = (poll.votes[optionIndex] ?? 0) + 1;
    await _save();
  }

  Future<void> closePoll(String pollId) async {
    final poll = _polls.firstWhere((p) => p.id == pollId);
    poll.isClosed = true;
    await _save();
  }

  Future<void> deletePoll(String pollId) async {
    _polls.removeWhere((p) => p.id == pollId);
    await _save();
  }

  Future<void> resetVotes(String pollId) async {
    final poll = _polls.firstWhere((p) => p.id == pollId);
    poll.votes.clear();
    poll.isClosed = false;
    await _save();
  }
}
