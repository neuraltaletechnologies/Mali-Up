import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/account_type.dart';

class AccountTypeSwitcher extends StatelessWidget {
  const AccountTypeSwitcher({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final AccountType selectedType;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: AccountType.values
            .map(
              (type) => Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedType == type
                          ? AppColors.primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${type.icon} ${type.label}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selectedType == type
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
