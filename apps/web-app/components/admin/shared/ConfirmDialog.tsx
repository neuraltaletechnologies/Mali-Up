"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

interface ConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description: string;
  requireReason?: boolean;
  requireTyping?: string;
  destructive?: boolean;
  loading?: boolean;
  onConfirm: (reason?: string) => void;
}

export function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  requireReason = false,
  requireTyping,
  destructive = false,
  loading = false,
  onConfirm,
}: ConfirmDialogProps) {
  const [reason, setReason] = useState("");
  const [typed, setTyped] = useState("");

  const canConfirm =
    (!requireReason || reason.trim().length > 0) &&
    (!requireTyping || typed === requireTyping);

  function handleConfirm() {
    if (!canConfirm) return;
    onConfirm(requireReason ? reason : undefined);
  }

  function handleClose(val: boolean) {
    if (!val) {
      setReason("");
      setTyped("");
    }
    onOpenChange(val);
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>{description}</DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {requireReason && (
            <div className="space-y-2">
              <Label>Reason <span className="text-red-500">*</span></Label>
              <Textarea
                placeholder="Enter reason for this action..."
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                rows={3}
              />
            </div>
          )}

          {requireTyping && (
            <div className="space-y-2">
              <Label>
                Type <strong className="font-mono">{requireTyping}</strong> to confirm
              </Label>
              <Input
                value={typed}
                onChange={(e) => setTyped(e.target.value)}
                placeholder={requireTyping}
                className="font-mono"
              />
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => handleClose(false)} disabled={loading}>
            Cancel
          </Button>
          <Button
            variant={destructive ? "destructive" : "default"}
            onClick={handleConfirm}
            disabled={!canConfirm || loading}
          >
            {loading ? "Processing..." : "Confirm"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
