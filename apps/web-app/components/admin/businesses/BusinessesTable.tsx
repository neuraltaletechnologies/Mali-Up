"use client";

import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { MoreHorizontal, FileText } from "lucide-react";
import type { Business } from "@/types/admin";
import { DataTable } from "@/components/admin/shared/DataTable";
import { StatusBadge } from "@/components/admin/shared/StatusBadge";
import { PlanBadge } from "@/components/admin/shared/PlanBadge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { timeAgo, formatTZS } from "@/lib/admin-utils";

interface BusinessesTableProps {
  businesses: Business[];
}

export function BusinessesTable({ businesses }: BusinessesTableProps) {
  const columns: ColumnDef<Business, unknown>[] = [
    {
      accessorKey: "name",
      header: "Business Name",
      cell: ({ row }) => (
        <Link
          href={`/admin/businesses/${row.original.bizId}`}
          className="font-medium text-slate-900 hover:text-[#1A6E8A] hover:underline"
        >
          {row.original.name}
        </Link>
      ),
    },
    {
      accessorKey: "type",
      header: "Type",
      cell: ({ row }) => (
        <span className="text-sm text-slate-600">{row.original.type}</span>
      ),
    },
    {
      accessorKey: "ownerName",
      header: "Owner",
      cell: ({ row }) => (
        <div>
          <p className="text-sm font-medium text-slate-800">{row.original.ownerName}</p>
          <p className="text-xs font-mono text-slate-400">{row.original.ownerPhone}</p>
        </div>
      ),
    },
    {
      accessorKey: "planTier",
      header: "Plan",
      cell: ({ row }) => <PlanBadge tier={row.original.planTier} />,
    },
    {
      accessorKey: "status",
      header: "Status",
      cell: ({ row }) => <StatusBadge status={row.original.status} />,
    },
    {
      accessorKey: "staffCount",
      header: "Staff",
      cell: ({ row }) => (
        <span className="font-mono text-sm">{row.original.staffCount}</span>
      ),
    },
    {
      accessorKey: "monthlyRevenue",
      header: "Monthly Rev.",
      cell: ({ row }) => (
        <span className="font-mono text-sm text-slate-700">
          {row.original.monthlyRevenue > 0 ? formatTZS(row.original.monthlyRevenue) : "—"}
        </span>
      ),
    },
    {
      accessorKey: "lastActiveAt",
      header: "Last Active",
      cell: ({ row }) => (
        <span className="text-sm text-slate-500">{timeAgo(row.original.lastActiveAt)}</span>
      ),
    },
    {
      id: "actions",
      header: "",
      enableSorting: false,
      size: 60,
      cell: ({ row }) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="sm" className="h-7 w-7 p-0">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-44">
            <DropdownMenuItem asChild>
              <Link
                href={`/admin/businesses/${row.original.bizId}`}
                className="flex items-center gap-2"
              >
                <FileText className="h-3.5 w-3.5" />
                View Details
              </Link>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  return (
    <DataTable
      columns={columns}
      data={businesses}
      searchPlaceholder="Search businesses..."
      exportFilename="businesses"
    />
  );
}
