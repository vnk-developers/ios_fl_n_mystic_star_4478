import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({
    super.key,
    this.onPlay,
    this.onProgress,
    this.onShop,
    this.onAbout,
    this.backgroundAsset = 'assets/images/onboard/bg_sun.png', // можеш змінити
  });

  final VoidCallback? onPlay;
  final VoidCallback? onProgress;
  final VoidCallback? onShop;
  final VoidCallback? onAbout;

  final String backgroundAsset;

  static const _menuIcon = 'assets/images/menu/menu_icon.png';
  static const _btnPlay = 'assets/images/menu/play.png';
  static const _btnProgress = 'assets/images/menu/progress.png';
  static const _btnShop = 'assets/images/menu/shop.png';
  static const _btnAbout = 'assets/images/menu/about.png';
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // фон
        Image.asset(backgroundAsset, fit: BoxFit.cover),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Stack(
              children: [
                // 🔹 Іконка зверху
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.asset(
                      _menuIcon,
                      fit: BoxFit.contain,
                      width: 310, // можна підрегулювати
                    ),
                  ),
                ),

                // 🔹 Кнопки внизу (закріплені)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuBtn(asset: _btnPlay, onTap: onPlay),
                      const SizedBox(height: 16),
                      _MenuBtn(asset: _btnProgress, onTap: onProgress),
                      const SizedBox(height: 16),
                      _MenuBtn(asset: _btnShop, onTap: onShop),
                      const SizedBox(height: 16),
                      _MenuBtn(asset: _btnAbout, onTap: onAbout),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuBtn extends StatelessWidget {
  const _MenuBtn({required this.asset, this.onTap});
  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}
