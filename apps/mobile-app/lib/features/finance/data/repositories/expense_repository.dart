import '../../domain/models/expense.dart';

abstract interface class ExpenseRepository {
  Stream<List<Expense>> watchAll();
  Stream<List<Expense>> watchByCategory(String category);

  Future<Expense?> getById(String id);
  Future<List<Expense>> getByDateRange(String fromDate, String toDate);
  Future<double> getTotalByDateRange(String fromDate, String toDate);
  Future<List<Expense>> getRecurringTemplates();

  Future<void> save(Expense expense);
  Future<void> delete(String id);
}
