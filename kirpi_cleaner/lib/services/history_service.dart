import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clean_item.dart';

class HistoryService {
  static const _key = 'clean_sessions';

  static Future<List<CleanSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) => _fromJson(jsonDecode(s))).toList().reversed.toList();
  }

  static Future<void> saveSession(CleanSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(_toJson(session)));
    // Keep only last 30 sessions
    if (raw.length > 30) raw.removeAt(0);
    await prefs.setStringList(_key, raw);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Map<String, dynamic> _toJson(CleanSession s) => {
    'timestamp': s.timestamp.millisecondsSinceEpoch,
    'totalCleaned': s.totalCleaned,
    'itemsCount': s.itemsCount,
    'byCategory': s.byCategory.map(
      (k, v) => MapEntry(k.index.toString(), v),
    ),
  };

  static CleanSession _fromJson(Map<String, dynamic> j) {
    final Map<CleanCategory, int> byCategory = {};
    final raw = j['byCategory'] as Map<String, dynamic>? ?? {};
    raw.forEach((k, v) {
      final idx = int.tryParse(k);
      if (idx != null && idx < CleanCategory.values.length) {
        byCategory[CleanCategory.values[idx]] = v as int;
      }
    });
    return CleanSession(
      timestamp: DateTime.fromMillisecondsSinceEpoch(j['timestamp'] as int),
      totalCleaned: j['totalCleaned'] as int,
      byCategory: byCategory,
      itemsCount: j['itemsCount'] as int,
    );
  }
}
