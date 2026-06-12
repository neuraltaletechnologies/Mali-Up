import '../../domain/models/debt.dart';

abstract interface class DebtRepository {
  Stream<List<Debt>> watchAll();
  Future<Debt?> getById(String id);
  Future<void> save(Debt debt);
  Future<void> delete(String id);
  Future<void> addPayment(String debtId, DebtPayment payment);
  Stream<List<DebtPayment>> watchPayments(String debtId);
}
