import '../../domain/models/customer.dart';

abstract interface class CustomerRepository {
  Stream<List<Customer>> watchAll();

  Future<Customer?> getById(String id);
  Future<Customer?> findByPhone(String phone);
  Future<List<Customer>> search(String query);

  /// Persists the customer locally and enqueues the remote sync.
  /// Returns the saved entity (with a generated id for new customers).
  Future<Customer> save(Customer customer);
  Future<void> delete(String id);
  Future<void> updateBalance(String id, double balance);
}
