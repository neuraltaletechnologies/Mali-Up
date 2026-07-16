import 'package:flutter/material.dart';

import '../../../core/services/localization_service.dart';
import '../domain/models/expense_category.dart';

extension ExpenseCategoryStyle on ExpenseCategory {
  String get label => labelFor(LocalizationService.isSwahili ? 'sw' : 'en');

  Color get color => Color(colorValue);

  IconData get icon => switch (iconKey) {
    'home' => Icons.home_rounded,
    'bolt' => Icons.bolt_rounded,
    'people' => Icons.people_rounded,
    'transport' => Icons.local_shipping_rounded,
    'campaign' => Icons.campaign_rounded,
    'inventory' => Icons.inventory_2_rounded,
    'food' => Icons.restaurant_rounded,
    'maintenance' => Icons.handyman_rounded,
    'office' => Icons.business_center_rounded,
    'tax' => Icons.account_balance_rounded,
    'more' => Icons.more_horiz_rounded,
    _ => Icons.category_rounded,
  };
}
