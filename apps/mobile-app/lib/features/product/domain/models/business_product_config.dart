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

  const BusinessProductConfig({
    this.showCategory = true,
    this.showExpiryDate = false,
    this.isExpiryRequired = false,
    this.showBatchNumber = false,
    this.showWarrantyPeriod = false,
    this.showBrand = false,
    this.showStock = true,
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
}
