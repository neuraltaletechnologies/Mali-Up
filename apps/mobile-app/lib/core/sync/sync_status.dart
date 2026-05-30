/// Thrown by SyncRepository.save() / delete() when the device has been
/// offline for more than 48 hours. The UI catches this and shows
/// OfflineRestrictionScreen rather than completing the operation.
class OfflineRestrictionException implements Exception {
  const OfflineRestrictionException();

  @override
  String toString() =>
      'OfflineRestrictionException: write blocked after 48 h offline';
}
