import 'package:flutter/material.dart';

class MaliUpLogo extends StatelessWidget {
  final double size;
  const MaliUpLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    final bool compact = size <= 70;
    return Image.asset(
      compact
          ? 'assets/branding/mali_up_icon.png'
          : 'assets/branding/mali_up_wordmark.png',
      width: compact ? size : size * 3.4,
      height: compact ? size : size * 1.45,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

