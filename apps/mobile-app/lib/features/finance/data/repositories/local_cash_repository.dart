import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/cash_flow_dao.dart';
import '../../domain/models/cash_account.dart';
import '../../domain/models/cash_transaction.dart';
import '../../domain/models/daily_reconciliation.dart';
import '../mappers/cash_flow_mapper.dart';

class LocalCashRepository {
  final CashFlowDao _dao;
  final String businessId;

  LocalCashRepository(AppDatabase db, {required this.businessId})
      : _dao = db.cashFlowDao;

  // ─── Accounts ──────────────────────────────────────────────────────────────

  Stream<List<CashAccount>> watchAccounts() => _dao
      .watchAccounts(businessId)
      .map((rows) => rows.map(CashAccountMapper.fromRow).toList());

  Future<CashAccount?> getAccountById(String id) async {
    final row = await _dao.getAccountById(id);
    return row != null ? CashAccountMapper.fromRow(row) : null;
  }

  Future<CashAccountsTableData?> getRawAccountById(String id) =>
      _dao.getAccountById(id);

  Future<void> upsertAccount(
    CashAccount account, {
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) =>
      _dao.upsertAccount(
        CashAccountMapper.toCompanion(
          account,
          businessId: businessId,
          syncStatus: syncStatus,
          localVersion: localVersion,
          createdAtMs: createdAtMs,
          serverUpdatedAt: serverUpdatedAt,
        ),
      );

  Future<void> softDeleteAccount(String id) => _dao.softDeleteAccount(id);
  Future<void> markAccountSynced(String id, int serverUpdatedAtMs) =>
      _dao.markAccountSynced(id, serverUpdatedAt: serverUpdatedAtMs);
  Future<void> adjustAccountBalance(String id, double delta) =>
      _dao.adjustAccountBalance(id, delta);
  Future<void> updateAccountLastReconciled(String id, String date) =>
      _dao.updateAccountLastReconciled(id, date);

  // ─── Transactions ──────────────────────────────────────────────────────────

  Stream<List<CashTransaction>> watchTransactions() => _dao
      .watchTransactions(businessId)
      .map((rows) => rows.map(CashTransactionMapper.fromRow).toList());

  Future<CashTransactionsTableData?> getRawTransactionById(String id) =>
      _dao.getTransactionById(id);

  Future<void> upsertTransaction(
    CashTransaction txn, {
    required String syncStatus,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) =>
      _dao.upsertTransaction(
        CashTransactionMapper.toCompanion(
          txn,
          businessId: businessId,
          syncStatus: syncStatus,
          createdAtMs: createdAtMs,
          serverUpdatedAt: serverUpdatedAt,
        ),
      );

  Future<void> markTransactionSynced(String id, int serverUpdatedAtMs) =>
      _dao.markTransactionSynced(id, serverUpdatedAt: serverUpdatedAtMs);

  // ─── Reconciliations ───────────────────────────────────────────────────────

  Stream<List<DailyReconciliation>> watchReconciliations() => _dao
      .watchReconciliations(businessId)
      .map((rows) => rows.map(ReconciliationMapper.fromRow).toList());

  Future<DailyReconciliationsTableData?> getRawReconciliationById(
          String id) =>
      _dao.getReconciliationById(id);

  Future<void> upsertReconciliation(
    DailyReconciliation rec, {
    required String syncStatus,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) =>
      _dao.upsertReconciliation(
        ReconciliationMapper.toCompanion(
          rec,
          businessId: businessId,
          syncStatus: syncStatus,
          createdAtMs: createdAtMs,
          serverUpdatedAt: serverUpdatedAt,
        ),
      );

  Future<void> markReconciliationSynced(String id, int serverUpdatedAtMs) =>
      _dao.markReconciliationSynced(id, serverUpdatedAt: serverUpdatedAtMs);
}
