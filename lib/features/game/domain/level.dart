class Level {
  final String bg;
  final String star;
  final String title;
  final String desc;
  final String objective;
  final int timeSeconds;
  bool isCompleted; // 👈 можна змінювати після гри

  Level({
    required this.bg,
    required this.star,
    required this.title,
    required this.desc,
    required this.objective,
    required this.timeSeconds,
    this.isCompleted = false,
  });
}
