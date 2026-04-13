import 'package:flutter/material.dart';
import '../../core/services/password_strength_service.dart';

/// Interactive password strength analyzer with real-time entropy calculation,
/// crack-time estimation, pattern detection, and improvement suggestions.
class PasswordStrengthScreen extends StatefulWidget {
  const PasswordStrengthScreen({super.key});

  @override
  State<PasswordStrengthScreen> createState() => _PasswordStrengthScreenState();
}

class _PasswordStrengthScreenState extends State<PasswordStrengthScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  PasswordAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {
      _analysis = PasswordStrengthService.analyze(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(int score) {
    if (score < 20) return Colors.red;
    if (score < 40) return Colors.orange;
    if (score < 60) return Colors.amber;
    if (score < 80) return Colors.lightGreen;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final a = _analysis;
    return Scaffold(
      appBar: AppBar(title: const Text('Password Strength Analyzer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Enter password to analyze',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 24),
          if (a != null && a.password.isNotEmpty) ...[
            // Score bar
            _buildScoreBar(a),
            const SizedBox(height: 16),
            // Stats cards
            _buildStatsRow(a),
            const SizedBox(height: 16),
            // Character composition
            _buildCompositionCard(a),
            const SizedBox(height: 16),
            // Patterns detected
            if (a.patterns.isNotEmpty) ...[
              _buildSectionTitle('⚠️ Patterns Detected'),
              ...a.patterns.map((p) => _buildPatternTile(p)),
              const SizedBox(height: 16),
            ],
            // Suggestions
            if (a.suggestions.isNotEmpty) ...[
              _buildSectionTitle('💡 Suggestions'),
              ...a.suggestions.map((s) => _buildSuggestionTile(s)),
            ],
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Type a password to see its strength analysis',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(PasswordAnalysis a) {
    final color = _scoreColor(a.score);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(a.label,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text('${a.score}/100',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: a.score / 100,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(PasswordAnalysis a) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
              '🔐 Entropy', '${a.entropy.toStringAsFixed(1)} bits'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard('⏱️ Crack Time', a.crackTimeLabel),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard('📏 Length', '${a.password.length} chars'),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionCard(PasswordAnalysis a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Character Composition',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _compRow('Lowercase (a-z)', a.hasLower),
            _compRow('Uppercase (A-Z)', a.hasUpper),
            _compRow('Digits (0-9)', a.hasDigit),
            _compRow('Symbols (!@#\$)', a.hasSymbol),
            _compRow('Unicode', a.hasUnicode),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Unique characters: ${a.uniqueChars}'),
                Text('Charset size: ${a.charsetSize}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _compRow(String label, bool present) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(present ? Icons.check_circle : Icons.cancel,
              size: 20, color: present ? Colors.green : Colors.red.shade300),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child:
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPatternTile(String pattern) {
    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: Colors.orange),
        title: Text(pattern),
        dense: true,
      ),
    );
  }

  Widget _buildSuggestionTile(String suggestion) {
    return Card(
      color: Colors.blue.shade50,
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline, color: Colors.blue),
        title: Text(suggestion),
        dense: true,
      ),
    );
  }
}
