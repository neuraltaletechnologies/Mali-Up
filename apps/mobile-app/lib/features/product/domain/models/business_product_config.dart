/// Defines which product fields are shown/required based on the active business type.
/// Extend [forBusinessType] when new business types are introduced.
class BusinessProductConfig {
  final bool showCategory;
  final bool showExpiryDate;
  final bool isExpiryRequired;
  final bool showBatchNumber;
  final bool showWarrantyPeriod;
  final bool showBrand;
  final bool showStock;
  // 'stock' | 'service' | 'manufactured' — which product-type pill the Add
  // Product form pre-selects for a brand-new item. Matches ProductType.name
  // in inventory_screen.dart (kept as a string here to avoid pulling a
  // presentation-layer enum into this domain model).
  final String defaultProductType;

  const BusinessProductConfig({
    this.showCategory = true,
    this.showExpiryDate = false,
    this.isExpiryRequired = false,
    this.showBatchNumber = false,
    this.showWarrantyPeriod = false,
    this.showBrand = false,
    this.showStock = true,
    this.defaultProductType = 'stock',
  });

  static BusinessProductConfig forBusinessType(String businessType) {
    switch (businessType.toLowerCase()) {
      case 'pharmacy':
        return const BusinessProductConfig(
          showExpiryDate: true,
          isExpiryRequired: true,
          showBatchNumber: true,
          showBrand: true,
        );

      case 'restaurant':
      case 'food_beverages':
        return const BusinessProductConfig(
          showExpiryDate: true,
          showStock: false,
        );

      case 'electronics':
        return const BusinessProductConfig(
          showWarrantyPeriod: true,
          showBrand: true,
        );

      case 'health':
        return const BusinessProductConfig(
          showExpiryDate: true,
          showBatchNumber: true,
          showBrand: true,
        );

      case 'agriculture':
        return const BusinessProductConfig(showExpiryDate: true);

      // Service-first verticals: most items added are billed services
      // (a haircut, a consulting hour), not physical stock. 'service' is
      // the generic bucket _normalizeBusinessType() folds cleaning,
      // security, education, travel, ICT, financial services, etc. into —
      // see category_providers.dart. Deliberately NOT 'transport': that
      // bucket also holds Automotive & Spare Parts / Fuel & Lubricants,
      // which sell physical goods, so defaulting it to Service would be
      // wrong for those.
      case 'salon':
      case 'service':
        return const BusinessProductConfig(defaultProductType: 'service');

      default:
        return const BusinessProductConfig();
    }
  }

  static String productNameLabel(String businessType, {bool isSwahili = false}) {
    switch (businessType.toLowerCase()) {
      case 'pharmacy':
      case 'health':
        return isSwahili ? 'Jina la Dawa' : 'Medicine Name';
      case 'restaurant':
      case 'food_beverages':
        return isSwahili ? 'Jina la Chakula' : 'Food Name';
      default:
        return isSwahili ? 'Jina la Bidhaa' : 'Product Name';
    }
  }

  /// Example placeholder shown in the product-name field. Kept per-vertical
  /// so a pharmacy (etc.) isn't shown an unrelated grocery example like
  /// "Unga wa mahindi" (maize flour).
  static String productNameHint(String businessType, {bool isSwahili = false}) {
    switch (businessType.toLowerCase()) {
      case 'pharmacy':
      case 'health':
        return isSwahili ? 'k.m. Panadol 500mg' : 'e.g. Panadol 500mg';
      case 'restaurant':
      case 'food_beverages':
        return isSwahili ? 'k.m. Chipsi Kuku' : 'e.g. Chicken and Chips';
      case 'electronics':
        return isSwahili
            ? 'k.m. Simu ya Samsung A14'
            : 'e.g. Samsung A14 Phone';
      case 'agriculture':
        return isSwahili ? 'k.m. Mbolea ya NPK 50kg' : 'e.g. NPK Fertilizer 50kg';
      default:
        return isSwahili ? 'k.m. Unga wa mahindi 2kg' : 'e.g. Maize Flour 2kg';
    }
  }
}
