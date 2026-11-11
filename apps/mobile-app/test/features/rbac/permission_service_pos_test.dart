import 'package:flutter_test/flutter_test.dart';
import 'package:mali_up/features/rbac/domain/permission_service.dart';
import 'package:mali_up/features/team/domain/models/team_member.dart';

void main() {
  group('PermissionService.isPosUser', () {
    PermissionService member(TeamRole role) =>
        PermissionService.forMember(defaultPermissionsFor(role));

    test('cashier is a POS user', () {
      expect(member(TeamRole.cashier).isPosUser, isTrue);
    });

    test('owner, manager, accountant and stock clerk are not', () {
      expect(PermissionService.owner().isPosUser, isFalse);
      expect(member(TeamRole.manager).isPosUser, isFalse);
      expect(member(TeamRole.accountant).isPosUser, isFalse);
      expect(member(TeamRole.stockClerk).isPosUser, isFalse);
    });

    test('custom role that sells without financial reports is a POS user', () {
      final ps = PermissionService.forMember({
        AppPermission.viewSales,
        AppPermission.createSale,
      });
      expect(ps.isPosUser, isTrue);
    });

    test('denied (loading/suspended) is not a POS user', () {
      expect(PermissionService.denied().isPosUser, isFalse);
    });
  });
}
