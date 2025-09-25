import 'package:flutter/material.dart';
import 'package:mystic_star_journey/features/game/domain/progress_service.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, this.onBack});
  final VoidCallback? onBack;

  // BG
  static const _bg = 'assets/images/bg.png';

  // shop assets
  static const _icFreeze = 'assets/images/shop/freeze.png';
  static const _icPerfect = 'assets/images/shop/perfect.png';
  static const _icDouble = 'assets/images/shop/dubling.png';
  static const _btnBg = 'assets/images/shop/exchange_bg.png';
  static const _star = 'assets/images/shop/stars.png';

  // ціни
  static const costFreeze = 5;
  static const costPerfect = 15;
  static const costDouble = 20;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final _ps = ProgressService();

  static const _gold = Color(0xFFDAA020);

  int _wallet = 0;
  int _invFreeze = 0;
  int _invPerfect = 0;
  int _invDouble = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = await _ps.getWalletStars();
    final f = await _ps.getBoosterCount(ProgressService.boosterFreeze2s);
    final pr = await _ps.getBoosterCount(ProgressService.boosterPerfectRun);
    final dr = await _ps.getBoosterCount(ProgressService.boosterDouble);
    if (!mounted) return;
    setState(() {
      _wallet = w;
      _invFreeze = f;
      _invPerfect = pr;
      _invDouble = dr;
      _loading = false;
    });
  }

  Future<void> _buy(String type, int cost) async {
    if (_loading) return;
    final ok = await _ps.trySpendWalletStars(cost);
    if (!ok) {
      _snack('Not enough stars ✨');
      return;
    }
    await _ps.addBooster(type, 1);
    _snack('Purchased!');
    await _load();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = _gold;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ShopPage._bg, fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.72)),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // ─── Top bar ────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          children: [
                            _RoundIcon(
                              onTap:
                                  widget.onBack ??
                                  () => Navigator.of(context).maybePop(),
                            ),
                            const Spacer(),
                            const Text(
                              'Shop',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: gold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ─── Balance row ────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'You have: ',
                            style: TextStyle(
                              color: gold,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$_wallet',
                            style: const TextStyle(
                              color: gold,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Image.asset(
                            ShopPage._star,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ─── Cards ──────────────────────────────────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                          child: Column(
                            children: [
                              _BoosterCard(
                                iconAsset: ShopPage._icFreeze,
                                title: 'Freeze time (2s)',
                                subtitle: 'Time stops for 2 seconds',
                                owned: _invFreeze,
                                cost: ShopPage.costFreeze,
                                onBuy: () => _buy(
                                  ProgressService.boosterFreeze2s,
                                  ShopPage.costFreeze,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _BoosterCard(
                                iconAsset: ShopPage._icPerfect,
                                title: 'Perfect Run',
                                subtitle: 'Beat level without dark stars',
                                owned: _invPerfect,
                                cost: ShopPage.costPerfect,
                                onBuy: () => _buy(
                                  ProgressService.boosterPerfectRun,
                                  ShopPage.costPerfect,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _BoosterCard(
                                iconAsset: ShopPage._icDouble,
                                title: 'Doubling the reward',
                                subtitle:
                                    'After completing a level, you get twice as many stars',
                                owned: _invDouble,
                                cost: ShopPage.costDouble,
                                onBuy: () => _buy(
                                  ProgressService.boosterDouble,
                                  ShopPage.costDouble,
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

/// ─────────────────────────────────────────────────────────────────────────────
/// Cards
/// ─────────────────────────────────────────────────────────────────────────────

class _BoosterCard extends StatelessWidget {
  const _BoosterCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.owned,
    required this.cost,
    required this.onBuy,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final int owned;
  final int cost;
  final VoidCallback onBuy;

  static const _gold = Color(0xFFDAA020);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D).withOpacity(0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.75), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // icon (картинка зліва)
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _gold.withOpacity(0.35), width: 1),
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(iconAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),

          // text + button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (owned > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _gold.withOpacity(0.5)),
                        ),
                        child: Text(
                          'x$owned',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, height: 1.15),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _GoldPriceButton(
                    label: 'Exchange',
                    price: cost,
                    onTap: onBuy,
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

class _GoldPriceButton extends StatelessWidget {
  const _GoldPriceButton({
    required this.label,
    required this.price,
    required this.onTap,
  });

  final String label;
  final int price;
  final VoidCallback onTap;

  static const _btnBg = ShopPage._btnBg;
  static const _star = ShopPage._star;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: r,
            image: const DecorationImage(
              image: AssetImage(_btnBg),
              fit: BoxFit.fill, // фон-картинка для кнопки
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              Image.asset(_star, height: 22, fit: BoxFit.contain),
              const SizedBox(width: 6),
              Text(
                '$price',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(12);
    return Material(
      color: Colors.black.withOpacity(0.25),
      borderRadius: r,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_rounded, color: Color(0xFFDAA020)),
        ),
      ),
    );
  }
}
