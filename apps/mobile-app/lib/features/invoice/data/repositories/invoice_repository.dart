import '../../domain/models/invoice.dart';

/// Contract that all invoice repository implementations must satisfy.
/// The UI only ever depends on this interface — never on concrete classes.
abstract interface class InvoiceRepository {
  Stream<List<Invoice>> watchAll();
  Stream<List<Invoice>> watchByStatus(String status);
  Stream<List<Invoice>> watchOverdue();

  Future<Invoice?> getById(String id);
  Future<List<Invoice>> getByCustomer(String customerId);

  /// Creates a new invoice (id must be empty) or updates an existing one.
  Future<void> save(Invoice invoice);
  Future<void> delete(String id);

  /// Mirrors a return already committed to Firestore (credit note + stock
  /// reversal) into the local invoice so every reader — sales list,
  /// dashboard revenue, outstanding-balance calc — nets it out consistently.
  /// Not a normal write: it does not enqueue a sync-queue entry, since the
  /// Firestore side of the change already happened.
  Future<void> applyCommittedReturn(
    String id, {
    required double returnedAmountDelta,
    required String creditNoteNumber,
  });

  Future<double> getTotalOutstanding();
  Future<Map<String, double>> getMonthlySales(int year);
}
