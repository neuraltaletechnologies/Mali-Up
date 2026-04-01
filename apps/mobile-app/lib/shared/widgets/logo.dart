import 'package:flutter/material.dart';

class MaliUpLogo extends StatelessWidget {
  final double size;
  final bool light; // Add this
  const MaliUpLogo({super.key, this.size = 100, this.light = false}); // Add this

  @override
  Widget build(BuildContext context) {
    final bool compact = size <= 70;
    
    // Define asset paths
    final String wordmarkAsset = light 
        ? 'assets/branding/mali_up_wordmark_light.png' 
        : 'assets/branding/mali_up_wordmark.png';
    
    final String iconAsset = light
        ? 'assets/branding/mali_up_icon_light.png'
        : 'assets/branding/mali_up_icon.png';

    return Image.asset(
      compact ? iconAsset : wordmarkAsset,
      width: compact ? size : size * 3.4,
      height: compact ? size : size * 1.45,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

