import 'package:flutter/material.dart';

class GradientBorderImage extends StatelessWidget {
  final String asset;
  final double? size; // 👈 якщо задано, то і width, і height
  final double? width; // 👈 окремо ширина
  final double? height; // 👈 окремо висота
  final double borderRadius;
  final double borderWidth;

  const GradientBorderImage({
    super.key,
    required this.asset,
    this.size,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final imgWidth = size ?? width; // якщо size є → обидва однакові
    final imgHeight = size ?? height;

    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB800), // золото
            Color(0xFF5B4200), // темніший
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          width: imgWidth,
          height: imgHeight,
        ),
      ),
    );
  }
}
