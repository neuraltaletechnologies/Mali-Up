import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/debt_dao.dart';
import '../../domain/models/debt.dart';
import '../mappers/debt_mapper.dart';

class LocalDebtRepository {
  final DebtDao _dao;
  final String businessId;

  LocalDebtRepository(AppDatabase db, {required this.businessId})
      : _dao = db.debtDao;

  // ─── Debt reads ────────────────────────────────────────────────────────────

  Stream<List<Debt>> watchAll() =>
      _dao.watchAll(businessId).map((rows) => rows.map(DebtMapper.fromRow).toList());

  Future<Debt?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? DebtMapper.fromRow(row) : null;
  }

  Future<DebtsTableData?> getRawById(String id) => _dao.getById(id);

  Future<void> upsert(
    Debt debt, {
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) =>
      _dao.upsert(
        DebtMapper.toCompanion(
          debt,
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
  Future<void> updatePaidAmount(String id, double paidAmount) =>
      _dao.updatePaidAmount(id, paidAmount);

  // ─── DebtPayment reads ─────────────────────────────────────────────────────

  Stream<List<DebtPayment>> watchPayments(String debtId) =>
      _dao
          .watchPaymentsForDebt(debtId)
          .map((rows) => rows.map(DebtPaymentMapper.fromRow).toList());

  Future<List<DebtPayment>> getPayments(String debtId) async {
    final rows = await _dao.getPaymentsForDebt(debtId);
    return rows.map(DebtPaymentMapper.fromRow).toList();
  }

  Future<DebtPaymentsTableData?> getRawPaymentById(String id) =>
      _dao.getPaymentById(id);

  Future<void> upsertPayment(
    DebtPayment payment, {
    required String debtId,
    required String syncStatus,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) =>
      _dao.upsertPayment(
        DebtPaymentMapper.toCompanion(
          payment,
          debtId: debtId,
          businessId: businessId,
          syncStatus: syncStatus,
          createdAtMs: createdAtMs,
          serverUpdatedAt: serverUpdatedAt,
        ),
      );

  Future<void> softDeletePayment(String id) => _dao.softDeletePayment(id);
  Future<void> markPaymentSynced(String id, int serverUpdatedAtMs) =>
      _dao.markPaymentSynced(id, serverUpdatedAt: serverUpdatedAtMs);
}
