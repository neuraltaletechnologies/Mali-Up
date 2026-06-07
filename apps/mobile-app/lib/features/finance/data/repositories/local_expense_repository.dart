import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/expense_dao.dart';
import '../../domain/models/expense.dart';
import '../mappers/expense_mapper.dart';

class LocalExpenseRepository {
  final ExpenseDao _dao;
  final String businessId;

  LocalExpenseRepository(AppDatabase db, {required this.businessId})
      : _dao = db.expenseDao;

  Stream<List<Expense>> watchAll() =>
      _dao.watchAll(businessId).map((rows) => rows.map(ExpenseMapper.fromRow).toList());

  Stream<List<Expense>> watchByCategory(String category) =>
      _dao.watchByCategory(businessId, category).map(
            (rows) => rows.map(ExpenseMapper.fromRow).toList(),
          );

  Future<Expense?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? ExpenseMapper.fromRow(row) : null;
  }

  Future<ExpensesTableData?> getRawById(String id) => _dao.getById(id);

  Future<List<Expense>> getByDateRange(String fromDate, String toDate) async {
    final rows = await _dao.getByDateRange(businessId, fromDate, toDate);
    return rows.map(ExpenseMapper.fromRow).toList();
  }

  Future<double> getTotalByDateRange(String fromDate, String toDate) =>
      _dao.getTotalByDateRange(businessId, fromDate, toDate);

  Future<List<Expense>> getRecurringTemplates() async {
    final rows = await _dao.getRecurringTemplates(businessId);
    return rows.map(ExpenseMapper.fromRow).toList();
  }

  Future<void> upsert(
    Expense expense, {
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) =>
      _dao.upsert(
        ExpenseMapper.toCompanion(
          expense,
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
}
