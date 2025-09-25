// lib/features/game/presentation/game_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_star_journey/core/router/routes.dart';
import 'package:mystic_star_journey/features/game/domain/game_notifier.dart';
import 'package:mystic_star_journey/features/game/domain/progress_service.dart';
import 'package:mystic_star_journey/features/game/presentation/widget/gold_btn.dart';
import 'package:mystic_star_journey/features/game/presentation/widget/gold_icon_btn.dart';
import 'package:mystic_star_journey/features/game/presentation/widget/result_screen.dart';

import '../data/levels.dart';
import '../domain/star.dart';

// --- Іконки/асети верх/низ ---
const _icHome = 'assets/images/game/home.png';
const _icBooster = 'assets/images/game/booster.png';
const _icTrophy = 'assets/images/game/trophy.png';
const _badStar = 'assets/images/game/bad_star.png';

final _progressProvider = Provider((ref) => ProgressService());
final gameProvider = StateNotifierProvider.family<GameNotifier, GameState, int>(
  (ref, levelIndex) => GameNotifier(
    levelIndex: levelIndex,
    progress: ref.read(_progressProvider),
  ),
);

class GamePage extends ConsumerStatefulWidget {
  const GamePage({
    super.key,
    required this.level, // 1-based з роутера
    this.onBack,
    this.onFinished,
  });

  final int level;
  final VoidCallback? onBack;
  final void Function(GameResult result)? onFinished;

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  bool _started = false;
  bool _resultShown = false;

  int get levelIndex => (widget.level - 1).clamp(0, levels.length - 1);

  @override
  void initState() {
    super.initState();
  }

  // кількість бустерів за типом
  final boosterCountProvider = FutureProvider.family<int, String>((
    ref,
    type,
  ) async {
    final ps = ref.read(_progressProvider);
    return ps.getBoosterCount(type);
  });

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(gameProvider(levelIndex));
    final ctrl = ref.read(gameProvider(levelIndex).notifier);

    final goal = _objectiveCount(levels[levelIndex].objective);
    final progress = (goal == 0) ? 0.0 : (st.score / goal).clamp(0.0, 1.0);
    // Слухаємо зміну стану: коли гра зупинилась — показуємо результат
    ref.listen<GameState>(gameProvider(levelIndex), (prev, next) {
      // пропускаємо перший build (коли ще не стартували)
      if (!_started) return;

      final wasRunning = prev?.isRunning ?? false;
      final nowRunning = next.isRunning;

      if (wasRunning && !nowRunning && !_resultShown) {
        _resultShown = true;
        final goal = _objectiveCount(levels[levelIndex].objective);
        final passed = next.score >= goal;
        // _showResultDialog(passed: passed, score: next.score, goal: goal);
        _showResultOverlay(passed: passed, score: next.score, goal: goal);
      }
    });
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(levels[levelIndex].bg, fit: BoxFit.cover),

          SafeArea(
            child: Column(
              children: [
                // ----- TOP BAR -----
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _RoundIconButton(
                        asset: _icHome,
                        fallbackIcon: Icons.home_rounded,
                        onTap: () async {
                          final res = await ctrl.stopAndResult();
                          widget.onBack?.call();
                          widget.onFinished?.call(res);
                          if (mounted) context.pop();
                        },
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _GoldProgressBar(value: progress)),
                      const SizedBox(width: 10),
                      _GoldChip(
                        icon: Icons.star_rounded,
                        text: '${st.score}/$goal',
                      ),
                    ],
                  ),
                ),

                // ----- PLAYFIELD -----
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, cons) {
                      final w = cons.maxWidth;
                      final h = cons.maxHeight;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final star in st.stars)
                            _StarButton(
                              star: star,
                              asset: star.isBad
                                  ? _badStar
                                  : levels[levelIndex].star,
                              left: (star.pos.dx * w) - star.size / 2,
                              top: (star.pos.dy * h) - star.size / 2,
                              onTap: () => ref
                                  .read(gameProvider(levelIndex).notifier)
                                  .tapStar(star.id),
                            ),

                          if (!st.isRunning && !_started)
                            _CenterOverlay(
                              title: levels[levelIndex].title,
                              objective: levels[levelIndex].objective,
                              desc: levels[levelIndex].desc,
                              timeLabel: '${st.timeLeft}s',
                              onStart: () {
                                _started = true;
                                ref
                                    .read(gameProvider(levelIndex).notifier)
                                    .start();
                              },
                            ),

                          Positioned(
                            right: 12,
                            top: 56,
                            child: _GoldChip(
                              icon: Icons.timer_rounded,
                              text: '${st.timeLeft}s',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ----- BOTTOM BAR -----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ❄️ Freeze (2s)
                      _BadgeButton(
                        asset:
                            _icBooster, // заміни на окрему іконку, якщо є, напр. 'assets/images/game/boost_freeze.png'
                        fallbackIcon: Icons.ac_unit_rounded,
                        badge: ref
                            .watch(
                              boosterCountProvider(
                                ProgressService.boosterFreeze2s,
                              ),
                            )
                            .maybeWhen(data: (v) => v, orElse: () => 0),
                        onTap: () async {
                          final count = ref
                              .read(
                                boosterCountProvider(
                                  ProgressService.boosterFreeze2s,
                                ),
                              )
                              .maybeWhen(data: (v) => v, orElse: () => 0);
                          if (count <= 0)
                            return _snack(context, 'No Freeze boosters');
                          final ok = await ctrl.useFreeze2s();
                          if (!ok)
                            return _snack(
                              context,
                              'Already frozen or not running',
                            );
                          ref.invalidate(
                            boosterCountProvider(
                              ProgressService.boosterFreeze2s,
                            ),
                          );
                          _snack(context, 'Time frozen for 2s');
                        },
                      ),
                      const SizedBox(width: 18),

                      // 🏆 Perfect Run (no dark stars)
                      _BadgeButton(
                        asset:
                            _icTrophy, // або своя іконка напр. 'assets/images/game/boost_perfect.png'
                        fallbackIcon: Icons.emoji_events_rounded,
                        badge: ref
                            .watch(
                              boosterCountProvider(
                                ProgressService.boosterPerfectRun,
                              ),
                            )
                            .maybeWhen(data: (v) => v, orElse: () => 0),
                        onTap: () async {
                          final count = ref
                              .read(
                                boosterCountProvider(
                                  ProgressService.boosterPerfectRun,
                                ),
                              )
                              .maybeWhen(data: (v) => v, orElse: () => 0);
                          if (count <= 0)
                            return _snack(context, 'No Perfect Run boosters');
                          final ok = await ctrl.usePerfectRun();
                          if (!ok) return _snack(context, 'Already active');
                          ref.invalidate(
                            boosterCountProvider(
                              ProgressService.boosterPerfectRun,
                            ),
                          );
                          _snack(context, 'Dark stars removed');
                        },
                      ),
                      const SizedBox(width: 18),

                      // ✨ Double reward (on win)
                      _BadgeButton(
                        asset:
                            _icBooster, // або 'assets/images/game/boost_double.png'
                        fallbackIcon: Icons.auto_awesome_rounded,
                        badge: ref
                            .watch(
                              boosterCountProvider(
                                ProgressService.boosterDouble,
                              ),
                            )
                            .maybeWhen(data: (v) => v, orElse: () => 0),
                        onTap: () async {
                          final count = ref
                              .read(
                                boosterCountProvider(
                                  ProgressService.boosterDouble,
                                ),
                              )
                              .maybeWhen(data: (v) => v, orElse: () => 0);
                          if (count <= 0)
                            return _snack(context, 'No Double Reward boosters');
                          final ok = await ctrl.useDoubleReward();
                          if (!ok) return _snack(context, 'Already active');
                          ref.invalidate(
                            boosterCountProvider(ProgressService.boosterDouble),
                          );
                          _snack(context, 'Double reward activated');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // void _openBoosterSheet(BuildContext context, WidgetRef ref, int levelIndex) {
  //   final ctrl = ref.read(gameProvider(levelIndex).notifier);
  //   final ps = ref.read(_progressProvider);

  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.black87,
  //     builder: (ctx) => FutureBuilder<List<int>>(
  //       future: Future.wait<int>([
  //         ps.getBoosterCount(ProgressService.boosterFreeze2s),
  //         ps.getBoosterCount(ProgressService.boosterPerfectRun),
  //         ps.getBoosterCount(ProgressService.boosterDouble),
  //       ]),
  //       builder: (ctx, snap) {
  //         final f = snap.data?[0] ?? 0;
  //         final p = snap.data?[1] ?? 0;
  //         final d = snap.data?[2] ?? 0;

  //         return SafeArea(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               _boosterTile(
  //                 icon: Icons.ac_unit_rounded,
  //                 title: 'Freeze time (2s)',
  //                 subtitle: 'Pause timer & falling for 2s',
  //                 count: f,
  //                 onTap: f > 0
  //                     ? () async {
  //                         final ok = await ctrl.useFreeze2s();
  //                         Navigator.pop(ctx);
  //                         if (!ok && context.mounted) {
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             const SnackBar(
  //                               content: Text('No Freeze boosters'),
  //                             ),
  //                           );
  //                         } else {
  //                           ref.invalidate(
  //                             boostersCountProvider,
  //                           ); // оновити бейдж
  //                         }
  //                       }
  //                     : null,
  //               ),
  //               _boosterTile(
  //                 icon: Icons.emoji_events_rounded,
  //                 title: 'Perfect Run',
  //                 subtitle: 'Remove dark stars & stop their spawn',
  //                 count: p,
  //                 onTap: p > 0
  //                     ? () async {
  //                         final ok = await ctrl.usePerfectRun();
  //                         Navigator.pop(ctx);
  //                         if (!ok && context.mounted) {
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             const SnackBar(
  //                               content: Text('No Perfect Run boosters'),
  //                             ),
  //                           );
  //                         } else {
  //                           ref.invalidate(boostersCountProvider);
  //                         }
  //                       }
  //                     : null,
  //               ),
  //               _boosterTile(
  //                 icon: Icons.auto_awesome_rounded,
  //                 title: 'Double reward',
  //                 subtitle: 'Double coins if you win',
  //                 count: d,
  //                 onTap: d > 0
  //                     ? () async {
  //                         final ok = await ctrl.useDoubleReward();
  //                         Navigator.pop(ctx);
  //                         if (!ok && context.mounted) {
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             const SnackBar(
  //                               content: Text('No Double Reward boosters'),
  //                             ),
  //                           );
  //                         } else {
  //                           ref.invalidate(boostersCountProvider);
  //                         }
  //                       }
  //                     : null,
  //               ),
  //               const SizedBox(height: 8),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _boosterTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      enabled: count > 0,
      leading: Icon(icon, color: const Color(0xFFFFD36E)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD36E).withOpacity(0.5)),
        ),
        child: Text('x$count', style: const TextStyle(color: Colors.white)),
      ),
      onTap: onTap,
    );
  }

  Future<void> _showResultOverlay({
    required bool passed,
    required int score,
    required int goal,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'result',
      barrierColor: Colors.black.withOpacity(0.8),
      pageBuilder: (_, __, ___) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ResultFullScreen(
            passed: passed,
            score: score,
            goal: goal,
            onRetry: _onRetry,
            onContinue: _onContinue,
            onNext: _onNext,
          ),
        );
      },
    );
  }

  Future<void> _showResultDialog({
    required bool passed,
    required int score,
    required int goal,
  }) async {
    // Блюр + затемнення + два різні стани
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'result',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return Stack(
          children: [
            Center(
              child: Material(
                // 👈 ДОДАЛИ
                type: MaterialType.transparency,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: passed
                        ? Colors.black.withOpacity(0.55)
                        : const Color(0xFF3B0000).withOpacity(0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: passed
                          ? const Color(0xFFFFD773)
                          : Colors.redAccent,
                      width: 2,
                    ),
                  ),
                  child: passed
                      ? _WinContent(
                          score: score,
                          goal: goal,
                          onContinue: _onContinue,
                          onNext: _onNext,
                        )
                      : _LoseContent(onRetry: _onRetry),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onRetry() {
    Navigator.of(context).pop(); // закрити overlay
    ref.invalidate(gameProvider(levelIndex)); // скинути стан рівня
    _started = true;
    _resultShown = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider(levelIndex).notifier).start();
    });
  }

  void _onContinue() {
    Navigator.of(context).pop(); // закрити overlay
    Navigator.of(
      context,
    ).pop<bool>(true); // повернутись на LevelSelect з флагом "пройшов"
  }

  void _onNext() {
    Navigator.of(context).pop(); // закрити overlay
    final nextLevel = levelIndex + 2; // 1-based для роутера
    if (nextLevel <= levels.length) {
      // якщо використовуєш go_router:
      context.push('${AppRoutes.game}/$nextLevel');
      // або Navigator: Navigator.of(context).pushNamed('/game/$nextLevel');
    } else {
      Navigator.of(context).pop<bool>(true);
    }
  }
}

// ======= Win / Lose віджети (простий стиль під макет) =======

class _LoseContent extends StatelessWidget {
  const _LoseContent({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'YOU',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 56,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'LOST',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 56,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Don't worry, you\nalmost made it.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFD36E),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        GoldButton(label: 'TRY AGAIN', onTap: onRetry),
      ],
    );
  }
}

class _WinContent extends StatelessWidget {
  const _WinContent({
    required this.score,
    required this.goal,
    required this.onContinue,
    required this.onNext,
  });
  final int score;
  final int goal;
  final VoidCallback onContinue;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'LEVEL COMPLETE!',
          style: TextStyle(
            color: Color(0xFFFFD36E),
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        // Можна поставити велике зображення зірки тут
        const Icon(Icons.star_rounded, size: 96, color: Color(0xFFFFE08A)),
        const SizedBox(height: 12),
        const Text(
          'GREAT JOB!',
          style: TextStyle(
            color: Color(0xFFFFD36E),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Stars collected: $score/$goal',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        GoldButton(label: 'CONTINUE', onTap: onContinue),
        const SizedBox(height: 12),
        GoldIconButton(icon: Icons.play_arrow_rounded, onTap: onNext),
      ],
    );
  }
}

// ======= решта твоїх допоміжних віджетів (без змін) =======
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.asset,
    required this.fallbackIcon,
    required this.onTap,
  });
  final String asset;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.black.withOpacity(0.25),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: _AssetOrIcon(asset: asset, icon: fallbackIcon, size: 22),
        ),
      ),
    );
  }
}

class _GoldProgressBar extends StatelessWidget {
  const _GoldProgressBar({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD773), width: 2),
        color: Colors.black.withOpacity(0.25),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.10)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFE08A), Color(0xFFFFC24B)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldChip extends StatelessWidget {
  const _GoldChip({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD773), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFFD773)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFFE08A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterOverlay extends StatelessWidget {
  const _CenterOverlay({
    required this.title,
    required this.objective,
    required this.desc,
    required this.timeLabel,
    required this.onStart,
  });
  final String title;
  final String objective;
  final String desc;
  final String timeLabel;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              objective,
              style: const TextStyle(
                color: Color(0xFFFFE08A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            _GoldChip(icon: Icons.timer_rounded, text: timeLabel),
            const SizedBox(height: 16),
            GoldButton(label: 'Start', onTap: onStart),
          ],
        ),
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  const _StarButton({
    required this.star,
    required this.asset,
    required this.left,
    required this.top,
    required this.onTap,
  });
  final Star star;
  final String asset;
  final double left;
  final double top;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 100),
          scale: 1.0,
          child: Image.asset(asset, width: star.size, height: star.size),
        ),
      ),
    );
  }
}

class _BadgeButton extends StatelessWidget {
  const _BadgeButton({
    required this.asset,
    required this.fallbackIcon,
    required this.badge,
    required this.onTap,
  });
  final String asset;
  final IconData fallbackIcon;
  final int badge;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    const double side = 56;
    final radius = BorderRadius.circular(14);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.black.withOpacity(0.25),
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: SizedBox(
              width: side,
              height: side,
              child: Center(
                child: _AssetOrIcon(asset: asset, icon: fallbackIcon, size: 26),
              ),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AssetOrIcon extends StatelessWidget {
  const _AssetOrIcon({
    required this.asset,
    required this.icon,
    required this.size,
  });
  final String asset;
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(icon, size: size, color: const Color(0xFFFFD773)),
    );
  }
}

// ===== helper =====
int _objectiveCount(String objective) {
  final m = RegExp(r'(\d+)').firstMatch(objective); // 👈 лише один слеш
  if (m != null) return int.tryParse(m.group(1)!) ?? 0;
  return 0;
}
