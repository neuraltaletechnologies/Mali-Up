import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/customer_dao.dart';
import '../../domain/models/customer.dart';
import '../mappers/customer_mapper.dart';

class LocalCustomerRepository {
  final CustomerDao _dao;
  final String businessId;

  LocalCustomerRepository(AppDatabase db, {required this.businessId})
      : _dao = db.customerDao;

  Stream<List<Customer>> watchAll() =>
      _dao.watchAll(businessId).map((rows) => rows.map(CustomerMapper.fromRow).toList());

  Future<Customer?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? CustomerMapper.fromRow(row) : null;
  }

  Future<CustomersTableData?> getRawById(String id) => _dao.getById(id);

  Future<List<Customer>> search(String query) async {
    final rows = await _dao.search(businessId, query);
    return rows.map(CustomerMapper.fromRow).toList();
  }

  Future<void> upsert(
    Customer customer, {
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) =>
      _dao.upsert(
        CustomerMapper.toCompanion(
          customer,
          businessId: businessId,
          syncStatus: syncStatus,
          localVersion: localVersion,
          createdAtMs: createdAtMs,
          serverUpdatedAt: serverUpdatedAt,
        ),
      );

  Future<void> softDelete(String id) => _dao.softDelete(id);
  Future<void> markSynced(String id, int serverUpdatedAtMs) =>
      _dao.markSynced(id, serverUpdatedAt: serverUpdatedAtMs);
  Future<void> markConflict(String id) => _dao.markConflict(id);
  Future<void> updateBalance(String id, double balance) =>
      _dao.updateBalance(id, balance);
}
