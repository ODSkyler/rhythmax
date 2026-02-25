import 'package:flutter/material.dart';

import 'music_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLastSourceKey = 'last_active_source';

class SourceManager extends ChangeNotifier{
  SourceManager._internal();
  static final SourceManager instance = SourceManager._internal();

  final Map<String, MusicSource> _sources = {};

  MusicSource? _activeSource;

  void notifySourceUpdated() {
    notifyListeners();
  }

  void registerSource(MusicSource source) {
    _sources[source.id] = source;
    _activeSource ??= source;
  }


  List<MusicSource> get sources => _sources.values.toList();

  MusicSource get activeSource {
    if (_activeSource == null) {
      throw Exception('No active music source registered');
    }
    return _activeSource!;
  }

  Future<void> setActiveSource(String sourceId) async {
    if (!_sources.containsKey(sourceId)) return;

    _activeSource = _sources[sourceId];
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastSourceKey, sourceId);
  }

  Future<void> restoreLastSource() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_kLastSourceKey);

    if (savedId != null && _sources.containsKey(savedId)) {
      _activeSource = _sources[savedId];
      notifyListeners();
    }
  }
}
