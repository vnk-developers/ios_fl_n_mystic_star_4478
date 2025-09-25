import 'package:flutter/material.dart';
import 'package:mystic_star_journey/features/game/presentation/widget/gold_btn.dart';
import 'package:mystic_star_journey/features/game/presentation/widget/gold_icon_btn.dart';

class ResultFullScreen extends StatelessWidget {
  const ResultFullScreen({
    super.key,
    required this.passed,
    required this.score,
    required this.goal,
    required this.onRetry,
    required this.onContinue,
    required this.onNext,
  });

  final bool passed;
  final int score;
  final int goal;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: passed
              ? [Colors.black, Colors.blueGrey.shade900]
              : [Colors.black, const Color(0xFF3B0000)],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/images/bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!passed) ...[
                const Text(
                  "YOU LOST",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 8,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Don't worry, you almost made it.",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD36E),
                  ),
                ),
                const SizedBox(height: 32),
                GoldButton(label: "TRY AGAIN", onTap: onRetry),
              ] else ...[
                const Text(
                  "LEVEL COMPLETE!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD36E),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(Icons.star, size: 100, color: Color(0xFFFFE08A)),
                const SizedBox(height: 16),
                Text(
                  "Stars collected: $score/$goal",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                GoldButton(label: "CONTINUE", onTap: onContinue),
                const SizedBox(height: 16),
                GoldIconButton(icon: Icons.play_arrow_rounded, onTap: onNext),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
