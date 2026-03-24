import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MaliappLogo extends StatelessWidget {
  final double size;
  const MaliappLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.25),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded, 
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'MALIAPP',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.25,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        Text(
          'Business Suite',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: size * 0.1,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
