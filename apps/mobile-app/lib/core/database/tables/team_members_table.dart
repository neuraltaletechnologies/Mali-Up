import 'package:drift/drift.dart';

class TeamMembersTable extends Table {
  @override
  String get tableName => 'team_members';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get role => text()(); // TeamRole.name string
  // JSON array of AppPermission names for custom roles
  TextColumn get customPermissions =>
      text().withDefault(const Constant('[]'))();
  // Saved custom-role pointer + denormalized name (see CustomRole). Empty for
  // built-in roles and one-off custom permission sets.
  TextColumn get customRoleId => text().withDefault(const Constant(''))();
  TextColumn get customRoleName => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get invitedAt => integer()();
  IntColumn get acceptedAt => integer().nullable()();
  TextColumn get invitedBy => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get userId => text().withDefault(const Constant(''))();
  // 'all' (default) or 'own' — see DataScope in team_member.dart.
  TextColumn get dataScope => text().withDefault(const Constant('all'))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get serverUpdatedAt => integer().nullable()();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_create'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
