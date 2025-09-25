import 'package:flutter/material.dart';
import 'package:mystic_star_journey/core/theme/gradient_border_image.dart';

class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.bg,
    required this.star,
    required this.title,
    required this.desc,
    required this.isUnlocked,
    required this.onPlay,
  });

  final String bg;
  final String star;
  final String title;
  final String desc;
  final bool isUnlocked;
  final VoidCallback onPlay;

  static const _panel = 'assets/images/game/bg_level.png';
  static const _lock = 'assets/images/game/lock.png';
  static const _play = 'assets/images/game/play.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(_panel),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: isUnlocked
            ? _Unlocked(
                onPlay: onPlay,
                bg: bg,
                star: star,
                title: title,
                desc: desc,
              )
            : _Locked(), // 👈 вигляд як на скріні
      ),
    );
  }
}

// ───────────────── unlocked ─────────────────
class _Unlocked extends StatelessWidget {
  const _Unlocked({
    required this.onPlay,
    required this.bg,
    required this.star,
    required this.title,
    required this.desc,
  });

  final VoidCallback onPlay;
  final String bg, star, title, desc;

  static const _play = 'assets/images/game/play.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Зображення рівня з рамкою + зірочка
        Stack(
          alignment: Alignment.center,
          children: [
            GradientBorderImage(
              asset: bg,
              // size: 140, // 👈 трохи більше по висоті
              width: 132,
              height: 170,
              borderRadius: 16,
              borderWidth: 2,
            ),
            Image.asset(star, width: 116, height: 116, fit: BoxFit.contain),
          ],
        ),

        const SizedBox(width: 16),

        // Текст + кнопка
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),

              // Кнопка PLAY (PNG з assets)
              GestureDetector(
                onTap: onPlay,
                child: Image.asset(
                  _play,
                  width: 160,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────── locked (як на макеті) ─────────────────
class _Locked extends StatelessWidget {
  const _Locked();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        // замок
        Padding(
          padding: EdgeInsets.only(right: 14),
          child: Image(
            image: AssetImage('assets/images/game/lock.png'),
            width: 48,
            fit: BoxFit.contain,
          ),
        ),
        // текст
        Expanded(
          child: Text(
            'Complete the previous level\nto unlock',
            style: TextStyle(
              color: Color(0xFFFFB800), // золото
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
