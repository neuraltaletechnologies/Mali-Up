import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'emotional_design.dart';

export 'emotional_design.dart' show EmotionalLottieScene;

class PageIntroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final EmotionalLottieScene scene;
  final EdgeInsetsGeometry padding;
  final double animationSize;

  const PageIntroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.scene,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 8),
    this.animationSize = 62,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          EmotionalLottieSpot(
            scene: scene,
            size: animationSize,
          ),
        ],
      ),
    );
  }
}