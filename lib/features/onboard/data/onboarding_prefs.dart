// lib/core/onboarding/onboarding_prefs.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPrefs {
  static const _kSeenKey = 'seen_onboarding_v1'; // версіонуй ключ за потреби

  static Future<bool> getSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSeenKey) ?? false;
  }

  static Future<void> setSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeenKey, true);
  }
}

final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  return OnboardingPrefs.getSeen();
});
