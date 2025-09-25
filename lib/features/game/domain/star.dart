import 'dart:ui';

class Star {
  final int id;

  /// Нормалізовані координати 0..1 (x,y) відносно ігрового поля
  final Offset pos;

  /// Нормалізована швидкість (частка від висоти екрана за 1 секунду)
  /// vy > 0 -> вниз; vx дає легкий «дрейф» вліво/вправо
  final double vy;
  final double vx;

  /// Розмір у логічних px
  final double size;

  /// Погана зірка (штраф -2s) чи добра (+1 очко)
  final bool isBad;

  const Star({
    required this.id,
    required this.pos,
    required this.size,
    required this.isBad,
    required this.vy,
    this.vx = 0,
  });

  /// Створює копію зі зміненою позицією
  Star moved(Offset newPos) =>
      Star(id: id, pos: newPos, size: size, isBad: isBad, vy: vy, vx: vx);
}
