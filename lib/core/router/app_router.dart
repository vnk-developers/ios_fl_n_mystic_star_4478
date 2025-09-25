import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mystic_star_journey/features/about/presentation/about_page.dart';
import 'package:mystic_star_journey/core/router/routes.dart';
import 'package:mystic_star_journey/features/menu/menu_page.dart';
import 'package:mystic_star_journey/features/onboard/presentation/onboarding_flow_page.dart';
import 'package:mystic_star_journey/features/game/presentation/level_select_page.dart';
import 'package:mystic_star_journey/features/game/presentation/game_page.dart';
import 'package:mystic_star_journey/features/progress/progress_page.dart';
import 'package:mystic_star_journey/features/shop/presentation/shop_page.dart';
import 'package:share_plus/share_plus.dart';

GoRouter createAppRouter({required bool seenOnboarding}) {
  return GoRouter(
    // initialLocation: AppRoutes.onboarding,
    initialLocation: seenOnboarding ? AppRoutes.menu : AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (c, s) => const MaterialPage(child: OnboardingFlowPage()),
      ),

      // MENU
      GoRoute(
        path: AppRoutes.menu,
        builder: (c, s) => MenuPage(
          onPlay: () => c.push(
            AppRoutes.levelSelect,
          ), // 👈 тепер веде на екран вибору рівнів
          onProgress: () => c.push(AppRoutes.progress),
          onShop: () => c.push(AppRoutes.shop),
          onAbout: () => c.push(AppRoutes.about),
        ),
      ),
      GoRoute(
        path: AppRoutes.shop,
        builder: (c, s) => ShopPage(onBack: () => c.pop()),
      ),

      GoRoute(
        path: AppRoutes.about,
        builder: (c, s) => AboutPage(
          onShare: () {
            Share.share('Check out Mystic Star Journey!');
          },
        ),
      ),

      GoRoute(
        path: AppRoutes.levelSelect,
        builder: (c, s) => LevelSelectPage(
          onBack: () => c.pop(),
          onPlay: (level) {
            // повертаємо майбутній результат з GamePage: true = пройшов
            return c.push<bool>('${AppRoutes.game}/$level');
          },
        ),
      ),

      GoRoute(
        path: '${AppRoutes.game}/:level',
        builder: (c, s) {
          final level = int.tryParse(s.pathParameters['level'] ?? '1') ?? 1;
          return GamePage(level: level);
        },
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (c, s) => const ProgressPage(),
      ),
    ],
  );
}
