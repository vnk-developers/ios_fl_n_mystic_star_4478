import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_star_journey/core/router/routes.dart';
import 'package:mystic_star_journey/features/onboard/data/onboarding_prefs.dart';
import 'package:mystic_star_journey/features/onboard/presentation/widgets/onboard_base.dart';

class _A {
  static const bg1 = 'assets/images/onboard/bg_onboard.png';
  static const bgSun = 'assets/images/onboard/bg_sun.png';

  static const ill1 = 'assets/images/onboard/onboard1.png';
  static const ill2 = 'assets/images/onboard/onboard2.png';
  static const ill3 = 'assets/images/onboard/onboard3.png';

  static const next = 'assets/images/onboard/btn/next.png';
  static const cont = 'assets/images/onboard/btn/continue.png';
  static const okay = 'assets/images/onboard/btn/okay.png';
  static const letsGo = 'assets/images/onboard/btn/letsgo.png';

  static const icon0 = 'assets/images/onboard/onboard0_icon.png';
  static const icon1 = 'assets/images/onboard/onboard1icon.png';
}

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key, required this.controller});
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return OnboardBaseFrame(
      backgroundAsset: _A.bg1,
      buttonAsset: _A.next,
      title: 'Greetings, stargazer!',
      body:
          " I am Astronimus, your guide through a world of brilliance and danger. Catch golden stars, earn points, and beware of dark traps. Together we will navigate the mysteries of the cosmos and discover the true power of light.",
      iconAsset: _A.icon0,
      centerIcon: true, // 👈 по центру зверху
      onPressed: () => controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }
}

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key, required this.controller});
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return OnboardBaseFrame(
      backgroundAsset: _A.bgSun,
      illustrationAsset: _A.ill1,
      buttonAsset: _A.cont,
      title: 'Greetings, stargazer!',
      body:
          " I am Astronimus, your guide through a world of brilliance and danger. Catch golden stars, earn points, and beware of dark traps. Together we will navigate the mysteries of the cosmos and discover the true power of light.",
      useImagePlate: true, // 👈 текст поверх плашки
      iconAsset: _A.icon1, // 👈 іконка у верхньому лівому куті
      onPressed: () => controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }
}

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key, required this.controller});
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return OnboardBaseFrame(
      backgroundAsset: _A.bgSun,
      illustrationAsset: _A.ill2,
      buttonAsset: _A.okay,
      useImagePlate: true,

      title: 'Collect the Stars!',
      body:
          "Each star you catch brings you points. The more you gather, the brighter your path shines. Aim high, stargazer, and let your score illuminate the cosmos!",
      onPressed: () => controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }
}

Future<void> _finish(BuildContext context) async {
  await OnboardingPrefs.setSeen();
  if (context.mounted) context.go(AppRoutes.menu);
}

class OnboardingScreen4 extends StatelessWidget {
  const OnboardingScreen4({super.key, required this.controller});
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return OnboardBaseFrame(
      backgroundAsset: _A.bgSun,
      illustrationAsset: _A.ill3,
      buttonAsset: _A.letsGo,
      useImagePlate: true,

      title: 'Beware the Shadows!',
      body:
          "Not all that glitters is safe. Dark stars await to steal your time and strength. Dodge them wisely — only then will the true power of light be yours",
      onPressed: () => _finish(context),
    );
  }
}
