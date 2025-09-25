import 'dart:ui';
import 'package:flutter/material.dart';

class OnboardBaseFrame extends StatelessWidget {
  const OnboardBaseFrame({
    super.key,
    required this.backgroundAsset,
    required this.buttonAsset,
    required this.title,
    required this.body,
    this.onPressed,
    this.illustrationAsset,
    this.useImagePlate =
        false, // 👈 коли true — текст поверх ілюстрації (як екран 2)
    this.iconAsset,
    this.centerIcon = false, // 👈 коли true — центральна іконка 310x310
    this.plateBottomInset = 28, // 👈 відступ тексту від низу плашки
    this.plateSideInset = 24, // 👈 бокові відступи тексту на плашці
  });

  final String backgroundAsset;
  final String buttonAsset;
  final String title;
  final String body;
  final VoidCallback? onPressed;

  final String? illustrationAsset;
  final bool useImagePlate;

  final String? iconAsset;
  final bool centerIcon;

  final double plateBottomInset;
  final double plateSideInset;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Фон
        Image.asset(backgroundAsset, fit: BoxFit.cover),

        // Бекграундна іконка зліва вгорі — НЕ зсуває контент
        if (iconAsset != null && !centerIcon)
          Positioned(
            top: 60,
            left: -60,
            child: Image.asset(
              iconAsset!,
              width: 340,
              height: 340,
              fit: BoxFit.contain,
            ),
          ),

        // Центральна іконка 310x310 — поверх усього, але не впливає на розкладку
        if (iconAsset != null && centerIcon)
          Center(
            child: SizedBox(
              width: 310,
              height: 310,
              child: Image.asset(iconAsset!, fit: BoxFit.contain),
            ),
          ),

        // Основний контент
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                if (illustrationAsset != null)
                  useImagePlate
                      // ✅ Режим "як екран 2": плашка на всю ширину + текст поверх унизу
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            // робимо ширину = ширині екрану, висоту підлаштовуємо пропорційно
                            Image.asset(
                              illustrationAsset!,
                              width:
                                  size.width -
                                  40, // врахуємо горизонтальні падінги
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              left: plateSideInset,
                              right: plateSideInset,
                              bottom: plateBottomInset,
                              child: _TextBlock(title: title, body: body),
                            ),
                          ],
                        )
                      // Старий режим: герой справа + скляна табличка
                      : Column(
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: size.width * 0.62,
                                  maxHeight: size.height < 720 ? 260 : 320,
                                ),
                                child: Image.asset(
                                  illustrationAsset!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _InfoPlate(title: title, body: body),
                          ],
                        )
                else
                  // Якщо немає ілюстрації — рендеримо стандартну табличку
                  // _InfoPlate(title: title, body: body),
                  const SizedBox(height: 16),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: onPressed,
                  child: Image.asset(
                    buttonAsset,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center, // 👈 центруємо текст

          style: t.titleMedium?.copyWith(
            color: const Color(0xFFFFD249),
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          textAlign: TextAlign.center, // 👈 центруємо текст

          body,
          style: t.bodyMedium?.copyWith(
            color: const Color(0xFFE8E8E8),
            fontSize: 18,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _InfoPlate extends StatelessWidget {
  const _InfoPlate({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E).withOpacity(0.80),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFD249), width: 1.6),
          ),
          child: _TextBlock(title: title, body: body),
        ),
      ),
    );
  }
}
