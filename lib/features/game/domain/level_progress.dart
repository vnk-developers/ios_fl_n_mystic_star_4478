import 'package:shared_preferences/shared_preferences.dart';

class LevelProgress {
  static const _key = 'completed_levels_v1';
  static final LevelProgress instance = LevelProgress._();
  LevelProgress._();

  SharedPreferences? _prefs;
  Set<int> _completed = {};

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getStringList(_key) ?? const [];
    _completed = raw.map(int.parse).toSet();
  }

  bool isCompleted(int levelNum) => _completed.contains(levelNum);

  Future<void> markCompleted(int levelNum) async {
    _completed.add(levelNum);
    await _prefs?.setStringList(
      _key,
      _completed.map((e) => e.toString()).toList(),
    );
  }

  Future<void> reset() async {
    _completed.clear();
    await _prefs?.remove(_key);
  }
}
