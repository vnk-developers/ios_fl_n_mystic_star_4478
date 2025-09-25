import 'package:flutter/material.dart';

class GoldIconButton extends StatelessWidget {
  const GoldIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      // 👈 дає предка для InkWell
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          // 👈 градієнт тут
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE08A), Color(0xFFFFC24B)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(14),
          child: Icon(icon, size: 28, color: Colors.black),
        ),
      ),
    );
  }
}
