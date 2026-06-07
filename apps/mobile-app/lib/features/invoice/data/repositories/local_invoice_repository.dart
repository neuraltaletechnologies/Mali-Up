import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/invoice_dao.dart';
import '../../domain/models/invoice.dart';
import '../mappers/invoice_mapper.dart';

/// Drift-backed local invoice store.
/// The UI never calls this directly — SyncInvoiceRepository is the entry point.
/// SyncService (Phase 3) calls [upsertFromServer] after successful Firestore pulls.
class LocalInvoiceRepository {
  final InvoiceDao _dao;
  final String businessId;

  LocalInvoiceRepository(AppDatabase db, {required this.businessId})
      : _dao = db.invoiceDao;

  // ─── Streams (served to SyncInvoiceRepository) ────────────────────────────

  Stream<List<Invoice>> watchAll() =>
      _dao.watchAll(businessId).asyncMap(_hydrate);

  Stream<List<Invoice>> watchByStatus(String status) =>
      _dao.watchByStatus(businessId, status).asyncMap(_hydrate);

  Stream<List<Invoice>> watchOverdue() =>
      _dao.watchOverdue(businessId).asyncMap(_hydrate);

  // ─── Queries ───────────────────────────────────────────────────────────────

  Future<Invoice?> getById(String id) async {
    final row = await _dao.getById(id);
    if (row == null) return null;
    final items = await _dao.getItemsForInvoice(id);
    return InvoiceMapper.fromRow(row, items);
  }

  Future<InvoicesTableData?> getRawById(String id) => _dao.getById(id);

  Future<List<Invoice>> getByCustomer(String customerId) async {
    final rows = await _dao.getByCustomer(businessId, customerId);
    return Future.wait(rows.map((r) async {
      final items = await _dao.getItemsForInvoice(r.id);
      return InvoiceMapper.fromRow(r, items);
    }));
  }

  Future<double> getTotalOutstanding() =>
      _dao.getTotalOutstanding(businessId);

  Future<Map<String, double>> getMonthlySales(int year) =>
      _dao.getMonthlySales(businessId, year);

  // ─── Writes (called inside SyncInvoiceRepository transactions) ───────────

  Future<void> upsert(
    Invoice invoice, {
    required String syncStatus,
    required int localVersion,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) async {
    await _dao.upsert(
      InvoiceMapper.toCompanion(
        invoice,
        businessId: businessId,
        syncStatus: syncStatus,
        localVersion: localVersion,
        createdAtMs: createdAtMs,
        serverUpdatedAt: serverUpdatedAt,
      ),
    );
    await _dao.replaceItems(
      invoice.id,
      InvoiceMapper.toItemCompanions(invoice.items, invoice.id),
    );
  }

  Future<void> softDelete(String id) => _dao.softDelete(id);
  Future<void> markSynced(String id, int serverUpdatedAtMs) =>
      _dao.markSynced(id, serverUpdatedAt: serverUpdatedAtMs);
  Future<void> markConflict(String id) => _dao.markConflict(id);

  // ─── Internal ──────────────────────────────────────────────────────────────

  Future<List<Invoice>> _hydrate(List<InvoicesTableData> rows) =>
      Future.wait(rows.map((r) async {
        final items = await _dao.getItemsForInvoice(r.id);
        return InvoiceMapper.fromRow(r, items);
      }));
}
