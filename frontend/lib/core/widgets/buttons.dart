import 'package:flutter/material.dart';
import 'package:manocerca/core/theme/colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  const PrimaryButton({super.key, required this.text, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: C.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class OutlineButtonX extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  const OutlineButtonX({super.key, required this.text, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: C.light, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
