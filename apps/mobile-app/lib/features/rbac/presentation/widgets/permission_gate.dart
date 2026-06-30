import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../team/domain/models/team_member.dart';
import '../../data/rbac_providers.dart';
import '../../domain/permission_service.dart';

// ── PermissionGate ────────────────────────────────────────────────────────────
//
// Shows [child] only when the current user holds [permission].
// Use [fallback] to render an alternative (e.g., a disabled button).
// Leave [fallback] null to render nothing when access is denied.
//
// Example — hide "Add Product" button for users without addStock permission:
//
//   PermissionGate(
//     permission: AppPermission.addStock,
//     child: FloatingActionButton(onPressed: _addProduct, ...),
//   )

class PermissionGate extends ConsumerWidget {
  final AppPermission permission;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ps = ref.watch(permissionServiceProvider);
    if (ps.can(permission)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

// ── OwnerGate ─────────────────────────────────────────────────────────────────
//
// Shows [child] only for business owners (not team members).
// Use for actions that have no corresponding AppPermission, e.g. billing,
// subscription management, and business-level settings.

class OwnerGate extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const OwnerGate({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ps = ref.watch(permissionServiceProvider);
    if (ps.isOwner) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

// ── PermissionBuilder ─────────────────────────────────────────────────────────
//
// Builder variant that exposes the full PermissionService for complex
// conditional rendering that depends on multiple permissions.
//
// Example — show edit button only when user can both view and edit sales:
//
//   PermissionBuilder(
//     builder: (context, ps) => ps.canEditSale
//         ? IconButton(icon: Icon(Icons.edit), onPressed: _edit)
//         : const SizedBox.shrink(),
//   )

class PermissionBuilder extends ConsumerWidget {
  final Widget Function(BuildContext context, PermissionService permissions)
      builder;

  const PermissionBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ps = ref.watch(permissionServiceProvider);
    return builder(context, ps);
  }
}

// ── PermissionLoadingGuard ────────────────────────────────────────────────────
//
// Prevents a screen's content from rendering until permissions are resolved.
// Wraps the body of any protected screen to avoid a flash of unauthorised
// content before the first permission check.

class PermissionLoadingGuard extends ConsumerWidget {
  final Widget child;
  final Widget? loading;

  const PermissionLoadingGuard({
    super.key,
    required this.child,
    this.loading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(permissionsLoadedProvider);
    if (!ready) {
      // Permissions resolve in < 200 ms on first frame; show nothing rather
      // than a fullscreen spinner that blocks the entire screen.
      return loading ?? const SizedBox.shrink();
    }
    return child;
  }
}
