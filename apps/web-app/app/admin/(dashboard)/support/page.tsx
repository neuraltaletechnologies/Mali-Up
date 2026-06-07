"use client";

import { useEffect, useState } from "react";
import { type ColumnDef } from "@tanstack/react-table";
import { MoreHorizontal, MessageSquare, Phone } from "lucide-react";
import type { SupportTicket } from "@/types/admin";
import { DataTable } from "@/components/admin/shared/DataTable";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { formatDateTime, timeAgo } from "@/lib/admin-utils";
import { fetchSupportTickets } from "@/lib/admin-api";
import { Skeleton } from "@/components/ui/skeleton";

const priorityColors: Record<SupportTicket["priority"], string> = {
  low:      "bg-slate-100 text-slate-600",
  medium:   "bg-blue-100 text-blue-700",
  high:     "bg-amber-100 text-amber-700",
  critical: "bg-red-100 text-red-700",
};

const statusColors: Record<SupportTicket["status"], string> = {
  open:        "bg-blue-100 text-blue-700",
  in_progress: "bg-yellow-100 text-yellow-700",
  resolved:    "bg-green-100 text-green-700",
  escalated:   "bg-red-100 text-red-700",
};

const issueLabels: Record<SupportTicket["issueType"], string> = {
  billing_dispute:  "Billing Dispute",
  account_locked:   "Account Locked",
  data_issue:       "Data Issue",
  feature_request:  "Feature Request",
  compliance_flag:  "Compliance Flag",
  other:            "Other",
};

export default function SupportPage() {
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<SupportTicket | null>(null);

  useEffect(() => {
    fetchSupportTickets()
      .then(setTickets)
      .finally(() => setLoading(false));
  }, []);

  const openCount = tickets.filter((t) => t.status === "open").length;
  const criticalCount = tickets.filter((t) => t.priority === "critical").length;

  const columns: ColumnDef<SupportTicket, unknown>[] = [
    {
      accessorKey: "priority",
      header: "Priority",
      cell: ({ row }) => (
        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold capitalize ${priorityColors[row.original.priority]}`}>
          {row.original.priority}
        </span>
      ),
    },
    {
      accessorKey: "bizName",
      header: "Business",
      cell: ({ row }) => (
        <div>
          <p className="text-sm font-medium text-slate-900">{row.original.bizName}</p>
          <p className="text-xs font-mono text-slate-400">{row.original.ownerPhone}</p>
        </div>
      ),
    },
    {
      accessorKey: "issueType",
      header: "Issue Type",
      cell: ({ row }) => (
        <span className="text-sm text-slate-600">{issueLabels[row.original.issueType]}</span>
      ),
    },
    {
      accessorKey: "status",
      header: "Status",
      cell: ({ row }) => (
        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold ${statusColors[row.original.status]}`}>
          {row.original.status.replace("_", " ")}
        </span>
      ),
    },
    {
      accessorKey: "assignedTo",
      header: "Assigned To",
      cell: ({ row }) => (
        <span className="text-sm text-slate-500">{row.original.assignedTo ?? "Unassigned"}</span>
      ),
    },
    {
      accessorKey: "createdAt",
      header: "Created",
      cell: ({ row }) => (
        <span className="text-sm text-slate-500">{timeAgo(row.original.createdAt)}</span>
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
          <DropdownMenuContent align="end" className="w-40">
            <DropdownMenuItem
              className="gap-2"
              onClick={() => setSelected(row.original)}
            >
              <MessageSquare className="h-3.5 w-3.5" />
              View Case
            </DropdownMenuItem>
            <DropdownMenuItem className="gap-2">
              <Phone className="h-3.5 w-3.5" />
              Call Owner
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  return (
    <div>
      <PageHeader
        title="Support Queue"
        description={`${openCount} open · ${criticalCount} critical`}
      />

      {criticalCount > 0 && (
        <div className="mb-4 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
          <strong>{criticalCount} critical ticket{criticalCount > 1 ? "s" : ""}</strong> require immediate attention.
        </div>
      )}

      {loading ? (
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full rounded-xl" />
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-slate-200 p-4">
          <DataTable
            columns={columns}
            data={tickets}
            searchPlaceholder="Search tickets..."
            exportFilename="support-tickets"
          />
        </div>
      )}

      <Sheet open={!!selected} onOpenChange={(open) => { if (!open) setSelected(null); }}>
        <SheetContent className="w-full max-w-lg overflow-y-auto">
          {selected && (
            <>
              <SheetHeader className="mb-6">
                <SheetTitle>{issueLabels[selected.issueType]}</SheetTitle>
              </SheetHeader>
              <div className="space-y-5 text-sm">
                <div className="flex items-center gap-3">
                  <span className={`px-2 py-0.5 rounded text-xs font-semibold capitalize ${priorityColors[selected.priority]}`}>
                    {selected.priority}
                  </span>
                  <span className={`px-2 py-0.5 rounded text-xs font-semibold ${statusColors[selected.status]}`}>
                    {selected.status.replace("_", " ")}
                  </span>
                </div>

                <dl className="space-y-3">
                  {[
                    { label: "Ticket ID", value: selected.ticketId },
                    { label: "Business", value: selected.bizName },
                    { label: "Owner Phone", value: selected.ownerPhone },
                    { label: "Assigned To", value: selected.assignedTo ?? "Unassigned" },
                    { label: "Created", value: formatDateTime(selected.createdAt) },
                    { label: "Updated", value: formatDateTime(selected.updatedAt) },
                  ].map(({ label, value }) => (
                    <div key={label} className="flex gap-4">
                      <dt className="w-28 flex-shrink-0 text-slate-500">{label}</dt>
                      <dd className="font-mono text-xs text-slate-800">{value}</dd>
                    </div>
                  ))}
                </dl>

                <div>
                  <p className="text-xs font-semibold text-slate-500 uppercase mb-2">Description</p>
                  <p className="text-sm text-slate-700 bg-slate-50 rounded-lg p-3 leading-relaxed">
                    {selected.description}
                  </p>
                </div>

                {selected.notes.length > 0 && (
                  <div>
                    <p className="text-xs font-semibold text-slate-500 uppercase mb-2">
                      Internal Notes ({selected.notes.length})
                    </p>
                    <div className="space-y-3">
                      {selected.notes.map((note) => (
                        <div key={note.noteId} className="bg-amber-50 border border-amber-100 rounded-lg p-3">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-xs font-semibold text-slate-700">{note.authorName}</span>
                            <span className="text-xs text-slate-400">{timeAgo(note.createdAt)}</span>
                          </div>
                          <p className="text-xs text-slate-600">{note.content}</p>
                        </div>
                      ))}
                    </div>
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
