import '../../domain/models/debt.dart';

abstract interface class DebtRepository {
  Stream<List<Debt>> watchAll();
  Future<Debt?> getById(String id);

  /// Looks up the receivable created for a sale, by the invoice number it
  /// was tagged with at creation. Used to reduce what's owed when a credit
  /// sale is returned.
  Future<Debt?> getByInvoiceRef(String invoiceRef);
  Future<void> save(Debt debt);
  Future<void> delete(String id);
  Future<void> addPayment(String debtId, DebtPayment payment);
  Stream<List<DebtPayment>> watchPayments(String debtId);
}
