import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/team_dao.dart';
import '../../domain/models/team_member.dart';
import '../mappers/team_member_mapper.dart';

class LocalTeamRepository {
  final TeamDao _dao;
  final String businessId;

  LocalTeamRepository(AppDatabase db, {required this.businessId})
      : _dao = db.teamDao;

  Stream<List<TeamMember>> watchAll() =>
      _dao
          .watchAll(businessId)
          .map((rows) => rows.map(TeamMemberMapper.fromRow).toList());

  Future<TeamMember?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? TeamMemberMapper.fromRow(row) : null;
  }

  Future<TeamMembersTableData?> getRawById(String id) => _dao.getById(id);

  Future<void> upsert(
    TeamMember member, {
    required String syncStatus,
    required int createdAtMs,
    int? serverUpdatedAt,
  }) =>
      _dao.upsert(
        TeamMemberMapper.toCompanion(
          member,
          businessId: businessId,
          syncStatus: syncStatus,
          createdAtMs: createdAtMs,
          serverUpdatedAt: serverUpdatedAt,
        ),
      );

  Future<void> softDelete(String id) => _dao.softDelete(id);
  Future<void> markSynced(String id, int serverUpdatedAtMs) =>
      _dao.markSynced(id, serverUpdatedAt: serverUpdatedAtMs);
}
