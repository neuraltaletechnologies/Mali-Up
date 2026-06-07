import '../../domain/models/customer.dart';

abstract interface class CustomerRepository {
  Stream<List<Customer>> watchAll();

  Future<Customer?> getById(String id);
  Future<List<Customer>> search(String query);

  Future<void> save(Customer customer);
  Future<void> delete(String id);
  Future<void> updateBalance(String id, double balance);
}
