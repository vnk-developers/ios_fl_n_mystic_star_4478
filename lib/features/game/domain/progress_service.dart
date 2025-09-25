import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  // ----- уже були -----
  static const _kUnlockedLevel = 'msj_unlocked_level';
  static const _kBestPrefix = 'msj_best_level_';

  // ----- статистика (опц.) -----
  static const _kTotalStars = 'msj_total_stars';
  static const _kPlaytimeSeconds = 'msj_playtime_seconds';
  static const _kFastestCompletion = 'msj_fastest_completion_sec';

  // ----- валюта (гаманець) -----
  static const _kWalletStars = 'msj_wallet_stars';

  // ----- інвентар бустерів -----
  static const boosterFreeze2s = 'freeze2s';
  static const boosterPerfectRun = 'perfect_run';
  static const boosterDouble = 'double_reward';

  static String _invKey(String type) => 'msj_inv_$type';

  // ===== Unlocked / best =====
  Future<int> getUnlockedLevel() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kUnlockedLevel) ?? 0;
  }

  Future<void> setUnlockedLevel(int index) async {
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_kUnlockedLevel) ?? 0;
    if (index > cur) await sp.setInt(_kUnlockedLevel, index);
  }

  Future<int> getBestForLevel(int levelIndex) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt('$_kBestPrefix$levelIndex') ?? 0;
  }

  Future<void> setBestForLevel(int levelIndex, int value) async {
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt('$_kBestPrefix$levelIndex') ?? 0;
    if (value > cur) await sp.setInt('$_kBestPrefix$levelIndex', value);
  }

  // ---------- статистика ----------
  Future<int> getTotalStars() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kTotalStars) ?? 0;
  }

  Future<void> addStars(int delta) async {
    if (delta <= 0) return;
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_kTotalStars) ?? 0;
    await sp.setInt(_kTotalStars, cur + delta);
  }

  Future<int> getPlaytimeSeconds() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kPlaytimeSeconds) ?? 0;
  }

  Future<void> addPlaytimeSeconds(int delta) async {
    if (delta <= 0) return;
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_kPlaytimeSeconds) ?? 0;
    await sp.setInt(_kPlaytimeSeconds, cur + delta);
  }

  Future<int?> getFastestCompletionSec() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kFastestCompletion);
  }

  Future<void> considerFastestCompletion(int secondsUsed) async {
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_kFastestCompletion);
    if (secondsUsed <= 0) return;
    if (cur == null || secondsUsed < cur) {
      await sp.setInt(_kFastestCompletion, secondsUsed);
    }
  }

  // ===== Валюта (гаманець) =====
  Future<int> getWalletStars() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kWalletStars) ?? 0;
  }

  Future<void> addWalletStars(int delta) async {
    if (delta == 0) return;
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_kWalletStars) ?? 0;
    final next = cur + delta;
    await sp.setInt(_kWalletStars, next < 0 ? 0 : next);
  }

  Future<bool> trySpendWalletStars(int cost) async {
    if (cost <= 0) return true;
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_kWalletStars) ?? 0;
    if (cur < cost) return false;
    await sp.setInt(_kWalletStars, cur - cost);
    return true;
  }

  // ===== Інвентар бустерів =====
  Future<int> getBoosterCount(String type) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_invKey(type)) ?? 0;
  }

  Future<void> addBooster(String type, int delta) async {
    if (delta == 0) return;
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_invKey(type)) ?? 0;
    final next = cur + delta;
    await sp.setInt(_invKey(type), next < 0 ? 0 : next);
  }

  Future<bool> tryUseBooster(String type) async {
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_invKey(type)) ?? 0;
    if (cur <= 0) return false;
    await sp.setInt(_invKey(type), cur - 1);
    return true;
  }

  // ===== Reset =====
  Future<void> resetAll() async {
    final sp = await SharedPreferences.getInstance();

    await sp.remove(_kUnlockedLevel);
    await sp.remove(_kTotalStars);
    await sp.remove(_kPlaytimeSeconds);
    await sp.remove(_kFastestCompletion);
    await sp.remove(_kWalletStars);

    // best per level
    for (final k
        in sp.getKeys().where((k) => k.startsWith(_kBestPrefix)).toList()) {
      await sp.remove(k);
    }
    // inventory
    for (final t in [boosterFreeze2s, boosterPerfectRun, boosterDouble]) {
      await sp.remove(_invKey(t));
    }
  }
}
