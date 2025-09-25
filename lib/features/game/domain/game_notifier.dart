import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mystic_star_journey/features/game/domain/progress_service.dart';

import '../data/levels.dart';
import '../domain/star.dart';

class GameState {
  final int levelIndex;
  final int timeLeft; // сек
  final int score; // зібрані хороші зірки
  final List<Star> stars;
  final bool isRunning;

  const GameState({
    required this.levelIndex,
    required this.timeLeft,
    required this.score,
    required this.stars,
    required this.isRunning,
  });

  GameState copyWith({
    int? levelIndex,
    int? timeLeft,
    int? score,
    List<Star>? stars,
    bool? isRunning,
  }) => GameState(
    levelIndex: levelIndex ?? this.levelIndex,
    timeLeft: timeLeft ?? this.timeLeft,
    score: score ?? this.score,
    stars: stars ?? this.stars,
    isRunning: isRunning ?? this.isRunning,
  );
}

class GameNotifier extends StateNotifier<GameState> {
  final ProgressService progress;
  final _rand = Random();

  Timer? _tick; // 1 Гц — таймер рівня
  Timer? _spawner; // періодичний спавн
  Timer? _anim; // ~60 Гц — анімація падіння
  Timer? _freezeTimer; // для розмороження
  int _starId = 0;

  // буфери сесії (щоб не писати в SP щосекунди)
  int _sessionPlaySeconds = 0;
  int _sessionGoodStars = 0;

  // ===== активні бустери =====
  bool _isFrozen = false; // Freeze time (2s)
  bool _noBadActive = false; // Perfect Run
  bool _doubleRewardActive = false; // Double reward

  GameNotifier({required int levelIndex, required this.progress})
    : super(
        GameState(
          levelIndex: levelIndex,
          timeLeft: levels[levelIndex].timeSeconds,
          score: 0,
          stars: const [],
          isRunning: false,
        ),
      );

  // ---------- ПУБЛІЧНІ ВИКЛИКИ БУСТЕРІВ (викликає UI) ----------
  Future<bool> useFreeze2s() async {
    if (_isFrozen || !state.isRunning) return false;
    final ok = await progress.tryUseBooster(ProgressService.boosterFreeze2s);
    if (!ok) return false;

    _isFrozen = true;
    _freezeTimer?.cancel();
    _freezeTimer = Timer(const Duration(seconds: 2), () {
      _isFrozen = false;
    });
    return true;
  }

  Future<bool> usePerfectRun() async {
    if (_noBadActive) return false;
    final ok = await progress.tryUseBooster(ProgressService.boosterPerfectRun);
    if (!ok) return false;

    _noBadActive = true;
    // Прибрати вже наекрані «погані» зірки
    state = state.copyWith(stars: state.stars.where((s) => !s.isBad).toList());
    return true;
  }

  Future<bool> useDoubleReward() async {
    if (_doubleRewardActive) return false;
    final ok = await progress.tryUseBooster(ProgressService.boosterDouble);
    if (!ok) return false;

    _doubleRewardActive = true;
    return true;
  }

  // ---------- ГЕЙМПЛЕЙ ----------
  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _sessionPlaySeconds = 0;
    _sessionGoodStars = 0;

    // --- 1) Тік секундоміра
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isFrozen) return; // ⏸️ пауза часу
      _sessionPlaySeconds += 1;
      final left = state.timeLeft - 1;
      if (left <= 0) {
        _finish();
      } else {
        state = state.copyWith(timeLeft: left);
      }
    });

    // --- 2) Параметри складності і динамічний спавн під ціль
    final lvl = state.levelIndex;
    final levelData = levels[lvl];
    final goal = _objectiveCount(levelData.objective);
    final time = levelData.timeSeconds;

    final baseBadChance = min(0.35, 0.10 + lvl * 0.07); // 10% → ~35%
    final requiredGoodPerSec = goal / max(1, time);
    final requiredTotalPerSec =
        requiredGoodPerSec / max(0.05, (1.0 - baseBadChance));
    const safety = 1.35; // запас на промахи
    final targetPerSec = requiredTotalPerSec * safety;

    final spawnEveryMs = targetPerSec <= 0
        ? 400
        : (1000 / targetPerSec).clamp(120, 420).round();

    // стартовий «бурст»
    for (int i = 0; i < 3; i++) {
      _spawnOne(badChance: _noBadActive ? 0.0 : baseBadChance);
    }

    _spawner = Timer.periodic(Duration(milliseconds: spawnEveryMs), (_) {
      if (_isFrozen) return; // ⏸️ пауза спавну
      final bc = _noBadActive ? 0.0 : baseBadChance;
      _spawnOne(badChance: bc);
      if (_rand.nextDouble() < 0.25)
        _spawnOne(badChance: bc); // інколи подвійний

      // обмежуємо одночасні об'єкти
      final keep = max(20, 28 - lvl);
      if (state.stars.length > keep) {
        state = state.copyWith(
          stars: state.stars.sublist(state.stars.length - keep),
        );
      }
    });

    // --- 3) Анімація падіння (~60 FPS)
    const frame = Duration(milliseconds: 16);
    _anim = Timer.periodic(frame, (_) {
      if (!state.isRunning || _isFrozen) return; // ⏸️ пауза падіння
      const dt = 16 / 1000.0;

      final moved = <Star>[];
      for (final s in state.stars) {
        final nx = (s.pos.dx + s.vx * dt).clamp(0.02, 0.98);
        final ny = s.pos.dy + s.vy * dt;
        if (ny <= 1.05) moved.add(s.moved(Offset(nx, ny)));
      }
      if (!identical(moved, state.stars)) {
        state = state.copyWith(stars: moved);
      }
    });
  }

  void _spawnOne({required double badChance}) {
    final x = _rand.nextDouble().clamp(0.05, 0.95);
    final y = -0.10; // трохи над верхнім краєм

    final size = 44 + _rand.nextInt(28); // 44..72 px
    final baseVy = 0.35 + state.levelIndex * 0.12;
    final jitter = _rand.nextDouble() * 0.15;
    final vy = (baseVy + jitter).clamp(0.30, 1.10);
    final vx = (_rand.nextDouble() - 0.5) * 0.10; // -0.05..+0.05
    final isBad = _rand.nextDouble() < badChance;

    final star = Star(
      id: _starId++,
      pos: Offset(x, y),
      size: size.toDouble(),
      isBad: isBad,
      vy: vy,
      vx: vx,
    );

    state = state.copyWith(stars: [...state.stars, star]);
  }

  void tapStar(int id) {
    if (!state.isRunning) return;

    final idx = state.stars.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final star = state.stars[idx];

    final newList = [...state.stars]..removeAt(idx);

    if (star.isBad) {
      final left = max(1, state.timeLeft - 2);
      state = state.copyWith(timeLeft: left, stars: newList);
    } else {
      _sessionGoodStars += 1; // ⭐️ для total stars
      state = state.copyWith(score: state.score + 1, stars: newList);
    }
  }

  Future<GameResult> stopAndResult() async => _finish(force: true);

  Future<GameResult> _finish({bool force = false}) async {
    if (!state.isRunning && !force) {
      return GameResult(
        levelIndex: state.levelIndex,
        score: state.score,
        passed: false,
      );
    }

    _tick?.cancel();
    _spawner?.cancel();
    _anim?.cancel();
    _freezeTimer?.cancel();

    final levelData = levels[state.levelIndex];
    final goal = _objectiveCount(levelData.objective);
    final passed = state.score >= goal;

    // рекорд по рівню (макс очок)
    await progress.setBestForLevel(state.levelIndex, state.score);

    // 💰 винагорода: базова + подвоєння при перемозі і активному бустері
    await progress.addWalletStars(state.score);
    if (passed && _doubleRewardActive) {
      await progress.addWalletStars(state.score); // подвоїли
    }

    // ✍️ статистика за сесію
    await progress.addStars(_sessionGoodStars);
    await progress.addPlaytimeSeconds(_sessionPlaySeconds);

    if (passed) {
      // найшвидше проходження (менше — краще)
      final used = levelData.timeSeconds - state.timeLeft;
      await progress.considerFastestCompletion(used);

      // розблокувати наступний рівень
      final next = min(levels.length - 1, state.levelIndex + 1);
      await progress.setUnlockedLevel(next);
    }

    // скинути флаги бустерів
    _isFrozen = false;
    _noBadActive = false;
    _doubleRewardActive = false;

    final res = GameResult(
      levelIndex: state.levelIndex,
      score: state.score,
      passed: passed,
    );
    state = state.copyWith(isRunning: false);
    return res;
  }

  int _objectiveCount(String objective) {
    final m = RegExp(r'(\d+)').firstMatch(objective);
    if (m != null) return int.tryParse(m.group(1)!) ?? 9999;
    return 9999;
  }

  @override
  void dispose() {
    _tick?.cancel();
    _spawner?.cancel();
    _anim?.cancel();
    _freezeTimer?.cancel();
    super.dispose();
  }
}

class GameResult {
  final int levelIndex;
  final int score;
  final bool passed;
  const GameResult({
    required this.levelIndex,
    required this.score,
    required this.passed,
  });
}
