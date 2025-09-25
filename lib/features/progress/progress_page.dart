import 'package:flutter/material.dart';
import 'package:mystic_star_journey/features/game/domain/progress_service.dart';
import 'package:share_plus/share_plus.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key, this.onBack});
  final VoidCallback? onBack;

  // BG
  static const _bg = 'assets/images/bg.png';

  // ── Progress assets
  static const _icStars = 'assets/images/progress/stars_colect.png';
  static const _icFastest = 'assets/images/progress/fastest_time.png';
  static const _icTotal = 'assets/images/progress/total_time.png';

  static const _btnResetBg = 'assets/images/progress/reset_bg.png';
  static const _btnShare = 'assets/images/progress/share_btn.png';
  static const _btnBack = 'assets/images/progress/back.png';

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final _ps = ProgressService();

  static const _gold = Color(0xFFDAA020);

  int _totalStars = 0;
  int _playSeconds = 0;
  int? _fastestSec;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stars = await _ps.getTotalStars();
    final secs = await _ps.getPlaytimeSeconds();
    final fast = await _ps.getFastestCompletionSec();
    if (!mounted) return;
    setState(() {
      _totalStars = stars;
      _playSeconds = secs;
      _fastestSec = fast;
      _loading = false;
    });
  }

  String _fmtPlaytime(int seconds) {
    if (seconds <= 0) return '0 sec';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h >= 1) return m == 0 ? '$h hour${h == 1 ? '' : 's'}' : '$h h $m min';
    if (m >= 1) return s == 0 ? '$m min' : '$m min $s sec';
    return '$s sec';
  }

  @override
  Widget build(BuildContext context) {
    const gold = _gold;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ProgressPage._bg, fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.7)),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Top bar ───────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          children: [
                            _ImageRoundBtn(
                              size: 44,
                              asset: ProgressPage._btnBack,
                              onTap:
                                  widget.onBack ??
                                  () => Navigator.of(context).maybePop(),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: gold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ─── Stats ─────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _StatRow(
                              iconAsset: ProgressPage._icStars,
                              title: 'STARS COLLECTED:',
                              value: '$_totalStars',
                            ),
                            const SizedBox(height: 14),
                            _StatRow(
                              iconAsset: ProgressPage._icFastest,
                              title: 'FASTEST LEVEL COMPLETION:',
                              value: _fastestSec != null
                                  ? '${_fastestSec!} sec'
                                  : '—',
                            ),
                            const SizedBox(height: 14),
                            _StatRow(
                              iconAsset: ProgressPage._icTotal,
                              title: 'TOTAL TIME IN THE GAME:',
                              value: _fmtPlaytime(_playSeconds),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ─── Bottom buttons ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ResetImageButton(
                                label: 'RESET PROGRESS',
                                onTap: () async {
                                  final ok =
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Reset progress?'),
                                          content: const Text(
                                            'This will erase stats and records.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Reset'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;

                                  if (ok) {
                                    await _ps.resetAll();
                                    await _load();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ImageRoundBtn(
                              size: 56,
                              asset: ProgressPage._btnShare,
                              onTap: () {
                                final fastest = _fastestSec != null
                                    ? '${_fastestSec!} sec'
                                    : '—';
                                final totalTime = _fmtPlaytime(_playSeconds);

                                final text =
                                    '''
                                  🌟 My progress in Mystic Star Journey 🌟

                                  ⭐ Stars collected: $_totalStars
                                  ⏱ Fastest level: $fastest
                                  🕒 Total time: $totalTime
                                  ''';

                                Share.share(text, subject: 'My game progress');
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
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Widgets
/// ─────────────────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.iconAsset,
    required this.title,
    required this.value,
  });

  final String iconAsset;
  final String title;
  final String value;

  static const _gold = Color(0xFFDAA020);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D).withOpacity(0.70),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withOpacity(0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withOpacity(0.35)),
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(iconAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _gold,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageRoundBtn extends StatelessWidget {
  const _ImageRoundBtn({
    required this.asset,
    required this.onTap,
    this.size = 44,
  });

  final String asset;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(12);
    return Material(
      color: Colors.black.withOpacity(0.20),
      borderRadius: r,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        child: SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: r,
            child: Image.asset(asset, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _ResetImageButton extends StatelessWidget {
  const _ResetImageButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  static const _gold = Color(0xFFDAA020);

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: r,
            image: const DecorationImage(
              image: AssetImage(ProgressPage._btnResetBg),
              fit: BoxFit.fill,
              // 👉 якщо у png є безпечний центр — розкоментуй:
              // centerSlice: Rect.fromLTWH(30, 20, 10, 10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
