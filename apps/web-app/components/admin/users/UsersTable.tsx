"use client";

import { useState } from "react";
import Link from "next/link";
import { type ColumnDef } from "@tanstack/react-table";
import { MoreHorizontal, UserX, UserCheck, Trash2, FileText } from "lucide-react";
import type { PlatformUser } from "@/types/admin";
import { DataTable } from "@/components/admin/shared/DataTable";
import { StatusBadge } from "@/components/admin/shared/StatusBadge";
import { ConfirmDialog } from "@/components/admin/shared/ConfirmDialog";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { formatDate, timeAgo, formatPhone } from "@/lib/admin-utils";
import { suspendUser, reinstateUser, deleteUser } from "@/lib/admin-api";
import { useAdminStore } from "@/store/adminStore";

type Action = "suspend" | "reinstate" | "delete";

interface UsersTableProps {
  users: PlatformUser[];
  userRole: string;
}

export function UsersTable({ users, userRole }: UsersTableProps) {
  const { addNotification } = useAdminStore();
  const [targetUser, setTargetUser] = useState<PlatformUser | null>(null);
  const [action, setAction] = useState<Action | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleConfirm(reason?: string) {
    if (!targetUser || !action) return;
    setLoading(true);
    try {
      if (action === "suspend") await suspendUser(targetUser.userId, reason ?? "");
      if (action === "reinstate") await reinstateUser(targetUser.userId);
      if (action === "delete") await deleteUser(targetUser.userId, reason ?? "");
      addNotification({
        type: "success",
        message: `User ${action === "delete" ? "deleted" : action + "d"} successfully.`,
      });
    } catch {
      addNotification({ type: "error", message: "Action failed. Please try again." });
    } finally {
      setLoading(false);
      setTargetUser(null);
      setAction(null);
    }
  }

  const columns: ColumnDef<PlatformUser, unknown>[] = [
    {
      accessorKey: "name",
      header: "Name",
      cell: ({ row }) => (
        <Link
          href={`/admin/users/${row.original.userId}`}
          className="font-medium text-slate-900 hover:text-[#1A6E8A] hover:underline"
        >
          {row.original.name}
        </Link>
      ),
    },
    {
      accessorKey: "phone",
      header: "Phone",
      enableSorting: false,
      cell: ({ row }) => (
        <span className="font-mono text-sm text-slate-600">{formatPhone(row.original.phone)}</span>
      ),
    },
    {
      accessorKey: "status",
      header: "Status",
      cell: ({ row }) => <StatusBadge status={row.original.status} />,
    },
    {
      accessorKey: "businessCount",
      header: "Businesses",
      cell: ({ row }) => (
        <span className="font-mono text-sm">{row.original.businessCount}</span>
      ),
    },
    {
      accessorKey: "lastLoginAt",
      header: "Last Login",
      cell: ({ row }) => (
        <span className="text-sm text-slate-500">{timeAgo(row.original.lastLoginAt)}</span>
      ),
    },
    {
      accessorKey: "createdAt",
      header: "Joined",
      cell: ({ row }) => (
        <span className="text-sm text-slate-500">{formatDate(row.original.createdAt)}</span>
      ),
    },
    {
      id: "actions",
      header: "",
      enableSorting: false,
      size: 60,
      cell: ({ row }) => {
        const user = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="sm" className="h-7 w-7 p-0">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-44">
              <DropdownMenuItem asChild>
                <Link href={`/admin/users/${user.userId}`} className="flex items-center gap-2">
                  <FileText className="h-3.5 w-3.5" />
                  View Details
                </Link>
              </DropdownMenuItem>
              {["ops_manager", "super_admin"].includes(userRole) && (
                <>
                  <DropdownMenuSeparator />
                  {user.status === "active" ? (
                    <DropdownMenuItem
                      className="text-amber-600 gap-2"
                      onClick={() => { setTargetUser(user); setAction("suspend"); }}
                    >
                      <UserX className="h-3.5 w-3.5" />
                      Suspend Account
                    </DropdownMenuItem>
                  ) : (
                    <DropdownMenuItem
                      className="text-emerald-600 gap-2"
                      onClick={() => { setTargetUser(user); setAction("reinstate"); }}
                    >
                      <UserCheck className="h-3.5 w-3.5" />
                      Reinstate Account
                    </DropdownMenuItem>
                  )}
                  {userRole === "super_admin" && (
                    <DropdownMenuItem
                      className="text-red-600 gap-2"
                      onClick={() => { setTargetUser(user); setAction("delete"); }}
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                      Delete Account
                    </DropdownMenuItem>
                  )}
                </>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  return (
    <>
      <DataTable
        columns={columns}
        data={users}
        searchPlaceholder="Search by name or phone..."
        exportFilename="users"
      />

      {targetUser && action === "suspend" && (
        <ConfirmDialog
          open
          onOpenChange={(open) => { if (!open) { setTargetUser(null); setAction(null); } }}
          title="Suspend Account"
          description={`Suspend ${targetUser.name}'s account? They will lose access to all Mali Up features.`}
          requireReason
          destructive
          loading={loading}
          onConfirm={handleConfirm}
        />
      )}
      {targetUser && action === "reinstate" && (
        <ConfirmDialog
          open
          onOpenChange={(open) => { if (!open) { setTargetUser(null); setAction(null); } }}
          title="Reinstate Account"
          description={`Reinstate ${targetUser.name}'s account? They will regain full access.`}
          loading={loading}
          onConfirm={handleConfirm}
        />
      )}
      {targetUser && action === "delete" && (
        <ConfirmDialog
          open
          onOpenChange={(open) => { if (!open) { setTargetUser(null); setAction(null); } }}
          title="Delete Account"
          description={`Permanently delete ${targetUser.name}'s account. This cannot be undone.`}
          requireReason
          requireTyping="DELETE"
          destructive
          loading={loading}
          onConfirm={handleConfirm}
        />
      )}
    </>
  );
}
