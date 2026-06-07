import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String name;
  final String createdAt;
  final bool isDefault;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isDefault = false,
  });

  factory ProductCategory.fromFirestore(Map<String, dynamic> data, String id) {
    return ProductCategory(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: data['createdAt']?.toString() ?? '',
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'isDefault': isDefault,
        'createdAt': createdAt,
      };

  ProductCategory copyWith({
    String? id,
    String? name,
    String? createdAt,
    bool? isDefault,
  }) =>
      ProductCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        isDefault: isDefault ?? this.isDefault,
      );

  /// Returns the icon most appropriate for this category name.
  IconData get icon => categoryIcon(name);

  /// Static icon resolver — keyed by normalised category name.
  static IconData categoryIcon(String name) {
    final key = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return _icons[key] ?? Icons.label_rounded;
  }

  static const Map<String, IconData> _icons = {
    // ── Pharmacy ──────────────────────────────────────────────────────────────
    'prescription_medicines': Icons.medication_rounded,
    'over_the_counter_medicines': Icons.local_pharmacy_rounded,
    'otc_medicines': Icons.local_pharmacy_rounded,
    'vitamins_supplements': Icons.science_rounded,
    'medical_equipment': Icons.medical_services_rounded,
    'first_aid': Icons.health_and_safety_rounded,
    'baby_care': Icons.child_care_rounded,
    'personal_care': Icons.spa_rounded,
    'health_monitoring_devices': Icons.monitor_heart_rounded,
    'medical_consumables': Icons.inventory_2_rounded,
    'herbal_products': Icons.eco_rounded,
    // ── Electronics ───────────────────────────────────────────────────────────
    'smartphones': Icons.smartphone_rounded,
    'feature_phones': Icons.phone_android_rounded,
    'laptops': Icons.laptop_rounded,
    'desktop_computers': Icons.desktop_windows_rounded,
    'accessories': Icons.cable_rounded,
    'chargers': Icons.battery_charging_full_rounded,
    'power_banks': Icons.battery_full_rounded,
    'networking_equipment': Icons.router_rounded,
    'audio_devices': Icons.headphones_rounded,
    'gaming_devices': Icons.sports_esports_rounded,
    'smart_home_devices': Icons.home_rounded,
    'components': Icons.memory_rounded,
    // ── Restaurant / Food ─────────────────────────────────────────────────────
    'food_ingredients': Icons.restaurant_rounded,
    'ingredients': Icons.restaurant_rounded,
    'fresh_produce': Icons.local_florist_rounded,
    'beverages': Icons.local_bar_rounded,
    'snacks': Icons.fastfood_rounded,
    'main_dishes': Icons.set_meal_rounded,
    'prepared_food': Icons.set_meal_rounded,
    'desserts': Icons.cake_rounded,
    'bakery': Icons.bakery_dining_rounded,
    'packaging_materials': Icons.inventory_rounded,
    'kitchen_supplies': Icons.kitchen_rounded,
    'frozen_foods': Icons.ac_unit_rounded,
    'condiments': Icons.soup_kitchen_rounded,
    // ── Boutique / Fashion ────────────────────────────────────────────────────
    'mens_clothing': Icons.man_rounded,
    'men_wear': Icons.man_rounded,
    'womens_clothing': Icons.woman_rounded,
    'women_wear': Icons.woman_rounded,
    'childrens_clothing': Icons.child_friendly_rounded,
    'kids_wear': Icons.child_friendly_rounded,
    'shoes': Icons.directions_walk_rounded,
    'bags': Icons.shopping_bag_rounded,
    'bags_accessories': Icons.shopping_bag_rounded,
    'jewelry': Icons.diamond_rounded,
    'beauty_products': Icons.face_retouching_natural_rounded,
    'fabrics': Icons.dry_cleaning_rounded,
    // ── Hardware ──────────────────────────────────────────────────────────────
    'building_materials': Icons.construction_rounded,
    'electrical_supplies': Icons.electrical_services_rounded,
    'plumbing_supplies': Icons.plumbing_rounded,
    'hand_tools': Icons.handyman_rounded,
    'power_tools': Icons.power_rounded,
    'paint': Icons.format_paint_rounded,
    'fasteners': Icons.settings_rounded,
    'safety_equipment': Icons.safety_check_rounded,
    'cement': Icons.domain_rounded,
    'steel': Icons.view_column_rounded,
    'timber': Icons.park_rounded,
    'plumbing': Icons.plumbing_rounded,
    'electrical': Icons.electrical_services_rounded,
    'tools': Icons.handyman_rounded,
    // ── Salon / Beauty ────────────────────────────────────────────────────────
    'hair_products': Icons.content_cut_rounded,
    'hair_equipment': Icons.dry_cleaning_rounded,
    'hair_care': Icons.content_cut_rounded,
    'skin_care': Icons.spa_rounded,
    'nail_products': Icons.brush_rounded,
    'nails': Icons.brush_rounded,
    'salon_equipment': Icons.chair_rounded,
    'cosmetics': Icons.face_retouching_natural_rounded,
    'barber_supplies': Icons.content_cut_rounded,
    'wigs_extensions': Icons.face_retouching_natural_rounded,
    // ── Wholesale / Retail ────────────────────────────────────────────────────
    'groceries': Icons.local_grocery_store_rounded,
    'household_products': Icons.home_rounded,
    'household_items': Icons.home_rounded,
    'cleaning_supplies': Icons.cleaning_services_rounded,
    'packaging': Icons.inventory_rounded,
    'general_merchandise': Icons.store_rounded,
    'stationery': Icons.edit_rounded,
    // ── Agriculture ───────────────────────────────────────────────────────────
    'seeds': Icons.grass_rounded,
    'fertilizers': Icons.science_rounded,
    'pesticides': Icons.bug_report_rounded,
    'feeds': Icons.pets_rounded,
    'produce': Icons.agriculture_rounded,
    // ── Transport / Automotive ────────────────────────────────────────────────
    'fuel': Icons.local_gas_station_rounded,
    'engine_oil': Icons.oil_barrel_rounded,
    'tyres': Icons.tire_repair_rounded,
    'spare_parts': Icons.build_rounded,
    'maintenance_supplies': Icons.build_circle_rounded,
    // ── Services / General ────────────────────────────────────────────────────
    'consumables': Icons.inventory_2_rounded,
    'office_supplies': Icons.business_center_rounded,
    'equipment': Icons.precision_manufacturing_rounded,
    'digital_products': Icons.computer_rounded,
    'other': Icons.category_rounded,
  };
}
