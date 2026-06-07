"use client";

import { useEffect, useState } from "react";
import { type ColumnDef } from "@tanstack/react-table";
import { Eye } from "lucide-react";
import type { AuditLog } from "@/types/admin";
import { DataTable } from "@/components/admin/shared/DataTable";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { formatDateTime } from "@/lib/admin-utils";
import { fetchAuditLogs } from "@/lib/admin-api";

export default function AuditLogPage() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<AuditLog | null>(null);

  useEffect(() => {
    fetchAuditLogs()
      .then(setLogs)
      .finally(() => setLoading(false));
  }, []);

  const columns: ColumnDef<AuditLog, unknown>[] = [
    {
      accessorKey: "timestamp",
      header: "Timestamp",
      cell: ({ row }) => (
        <span className="font-mono text-xs text-slate-600">
          {formatDateTime(row.original.timestamp)}
        </span>
      ),
    },
    {
      accessorKey: "adminName",
      header: "Admin",
      cell: ({ row }) => (
        <span className="text-sm font-medium text-slate-800">{row.original.adminName}</span>
      ),
    },
    {
      accessorKey: "action",
      header: "Action",
      cell: ({ row }) => (
        <span className="font-mono text-xs bg-slate-100 text-slate-700 px-2 py-1 rounded">
          {row.original.action}
        </span>
      ),
    },
    {
      accessorKey: "resourceType",
      header: "Resource",
      cell: ({ row }) => (
        <span className="text-xs text-slate-500 capitalize">{row.original.resourceType}</span>
      ),
    },
    {
      accessorKey: "resourceId",
      header: "Resource ID",
      cell: ({ row }) => (
        <span className="font-mono text-xs text-slate-500">{row.original.resourceId}</span>
      ),
    },
    {
      accessorKey: "ipAddress",
      header: "IP Address",
      enableSorting: false,
      cell: ({ row }) => (
        <span className="font-mono text-xs text-slate-500">{row.original.ipAddress}</span>
      ),
    },
    {
      id: "view",
      header: "",
      enableSorting: false,
      size: 60,
      cell: ({ row }) => (
        <Button
          variant="ghost"
          size="sm"
          className="h-7 w-7 p-0"
          onClick={() => setSelected(row.original)}
        >
          <Eye className="h-3.5 w-3.5" />
        </Button>
      ),
    },
  ];

  return (
    <div>
      <PageHeader
        title="Audit Log"
        description="Immutable record of all admin actions. Read-only."
      />

      <div className="bg-white rounded-xl border border-slate-200 p-4">
        <DataTable
          columns={columns}
          data={logs}
          loading={loading}
          searchPlaceholder="Search audit logs..."
          exportFilename="audit-log"
        />
      </div>

      <Sheet open={!!selected} onOpenChange={(open) => { if (!open) setSelected(null); }}>
        <SheetContent className="w-full max-w-lg overflow-y-auto">
          {selected && (
            <>
              <SheetHeader className="mb-6">
                <SheetTitle className="font-mono text-sm">{selected.action}</SheetTitle>
              </SheetHeader>
              <div className="space-y-4 text-sm">
                <dl className="space-y-3">
                  {[
                    { label: "Log ID", value: selected.logId },
                    { label: "Timestamp", value: formatDateTime(selected.timestamp) },
                    { label: "Admin", value: selected.adminName },
                    { label: "Admin ID", value: selected.adminId },
                    { label: "Action", value: selected.action },
                    { label: "Resource Type", value: selected.resourceType },
                    { label: "Resource ID", value: selected.resourceId },
                    { label: "IP Address", value: selected.ipAddress },
                  ].map(({ label, value }) => (
                    <div key={label} className="flex gap-4">
                      <dt className="w-32 flex-shrink-0 text-slate-500">{label}</dt>
                      <dd className="font-mono text-slate-800 break-all">{value}</dd>
                    </div>
                  ))}
                </dl>

                {selected.before && (
                  <div>
                    <p className="text-xs font-semibold text-slate-500 uppercase mb-2">Before</p>
                    <pre className="rounded-lg bg-red-50 border border-red-100 p-3 text-xs font-mono text-red-800 overflow-auto">
                      {JSON.stringify(selected.before, null, 2)}
                    </pre>
                  </div>
                )}
                {selected.after && (
                  <div>
                    <p className="text-xs font-semibold text-slate-500 uppercase mb-2">After</p>
                    <pre className="rounded-lg bg-green-50 border border-green-100 p-3 text-xs font-mono text-green-800 overflow-auto">
                      {JSON.stringify(selected.after, null, 2)}
                    </pre>
                  </div>
                )}
              </div>
            </>
          )}
        </SheetContent>
      </Sheet>
    </div>
  );
}
