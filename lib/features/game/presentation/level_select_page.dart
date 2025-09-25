import 'package:flutter/material.dart';
import 'package:mystic_star_journey/features/game/data/levels.dart';
import 'package:mystic_star_journey/features/game/domain/level_progress.dart';
import 'package:mystic_star_journey/features/game/presentation/widget/levels_card.dart';

class LevelSelectPage extends StatefulWidget {
  const LevelSelectPage({super.key, this.onBack, this.onPlay});

  final VoidCallback? onBack;

  /// Очікуємо, що екран гри повертає true, якщо рівень пройдено.
  final Future<bool?> Function(int level)? onPlay;

  // Assets
  static const _bg = 'assets/images/bg.png';
  static const _btnBack = 'assets/images/game/back.png';

  @override
  State<LevelSelectPage> createState() => _LevelSelectPageState();
}

class _LevelSelectPageState extends State<LevelSelectPage> {
  final progress = LevelProgress.instance;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await progress.init();
    if (mounted) setState(() => _ready = true);
  }

  bool _isUnlocked(int index) {
    // Перший рівень завжди відкритий, інші — якщо попередній завершено
    return index == 0 || progress.isCompleted(index);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(LevelSelectPage._bg, fit: BoxFit.cover),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Назад + Заголовок
                Row(
                  children: [
                    IconButton(
                      icon: Image.asset(LevelSelectPage._btnBack),
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Choose a level',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Список рівнів
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final isUnlocked = _isUnlocked(index);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: LevelCard(
                          bg: level.bg,
                          star: level.star,
                          title: level.title,
                          desc: level.desc,
                          isUnlocked: isUnlocked,
                          onPlay: () async {
                            final completed =
                                await (widget.onPlay?.call(index + 1) ??
                                    Future.value(false));
                            if (completed == true) {
                              await progress.markCompleted(index + 1);
                              if (mounted) setState(() {});
                            }
                          },

                          // onPlay: () async {
                          //   final completed =
                          //       await (widget.onPlay?.call(index + 1) ??
                          //           Future.value(false));
                          //   if (completed == true) {
                          //     await progress.markCompleted(index + 1);
                          //     if (mounted) setState(() {});
                          //   }
                          // },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
