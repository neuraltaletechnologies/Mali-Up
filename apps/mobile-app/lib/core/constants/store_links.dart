/// Store listings for Mali Up. Keep in sync with
/// apps/admin/components/mali/download-picker.tsx and the admin Version Gate
/// defaults (apps/admin/app/api/admin/version-gate/route.ts).
abstract final class StoreLinks {
  static const String androidPackage = 'com.neuraltale.maliup';
  static const String playStore =
      'https://play.google.com/store/apps/details?id=$androidPackage';

  /// Microsoft Store product ID (Partner Center → Product identity → Store ID).
  static const String microsoftStoreId = '9NDQXPM95Q99';
  static const String microsoftStoreWeb =
      'https://apps.microsoft.com/detail/$microsoftStoreId';

  /// Opens the listing straight in the Microsoft Store app (Windows only).
  static const String microsoftStoreApp =
      'ms-windows-store://pdp/?productid=$microsoftStoreId';
}
