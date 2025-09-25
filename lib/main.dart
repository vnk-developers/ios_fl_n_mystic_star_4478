// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mystic_star_journey/features/onboard/data/onboarding_prefs.dart';
import 'core/router/app_router.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  GoRouter? _router; // 👈 кеш

  @override
  void initState() {
    super.initState();
    // Як тільки провайдер віддасть значення — один раз створюємо роутер.
    ref
        .read(onboardingSeenProvider.future)
        .then((seen) {
          if (mounted && _router == null) {
            setState(() {
              _router = createAppRouter(seenOnboarding: seen);
            });
          }
        })
        .catchError((_) {
          if (mounted && _router == null) {
            setState(() {
              _router = createAppRouter(seenOnboarding: false);
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    // Поки не готовий роутер — показуємо простий екран завантаження.
    if (_router == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Whispers of Flame',
      debugShowCheckedModeBanner: false,
      routerConfig: _router!, // 👈 не створюємо заново
      theme: _buildTheme(),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFAF8E53),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
    );
  }
}
