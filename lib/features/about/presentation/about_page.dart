import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, this.onBack, this.onShare});

  final VoidCallback? onBack;
  final VoidCallback? onShare;

  // Assets
  static const _bg = 'assets/images/bg.png'; // фон
  static const _board = 'assets/images/about/board.png';
  static const _left = 'assets/images/about/left.png';
  static const _right = 'assets/images/about/right.png';
  static const _share = 'assets/images/about/share.png';
  static const _back = 'assets/images/about/back.png';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Фон
          Image.asset(_bg, fit: BoxFit.cover),

          SafeArea(
            child: Column(
              children: [
                // 🔙 Верхня панель
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                        child: Image.asset(
                          _back,
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "About the app",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFD36E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // баланс для симетрії
                    ],
                  ),
                ),

                // Вміст
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Дошка
                        _Board(
                          width: w - 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Our app immerses you in a world of star adventures, where you need to collect stars, complete levels and discover new opportunities. Here you can use boosters – freezing time or doubling rewards, track your progress and get trophies.\n\n"
                                "The game's feature is interesting facts about the stars and space that you discover during your journey. This is a combination of entertainment and knowledge, which makes the app an exciting companion on your star journey.",
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.35,
                                  color: Color(0xFFDAA020),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Нижній ряд з картинками
                              SizedBox(
                                height: 160,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .end, // 👈 вирівнюємо вниз
                                  children: [
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ), // 👈 падінг знизу
                                          child: Image.asset(
                                            _left,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomRight,
                                        child: Image.asset(
                                          _right,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Кнопка Share
                        GestureDetector(
                          onTap: onShare,
                          child: Image.asset(
                            _share,
                            height: 88,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
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

// ---------- допоміжні віджети ----------

class _Board extends StatelessWidget {
  const _Board({required this.child, this.width});
  final Widget child;
  final double? width;

  static const _board = AboutPage._board;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(_board),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _RoundedBox extends StatelessWidget {
  const _RoundedBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD36E).withOpacity(0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Center(child: child),
    );
  }
}
