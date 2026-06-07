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

  Future<double> getTotalOutstanding();
  Future<Map<String, double>> getMonthlySales(int year);
}
