"use client";

import { useEffect, useState } from "react";
import { ToggleLeft, ToggleRight, Users, Building2, Clock } from "lucide-react";
import type { FeatureFlag } from "@/types/admin";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { Slider } from "@/components/ui/slider";
import { timeAgo } from "@/lib/admin-utils";
import { fetchFeatureFlags, updateFeatureFlag } from "@/lib/admin-api";
import { useAdminStore } from "@/store/adminStore";
import { Skeleton } from "@/components/ui/skeleton";

function FlagCard({ flag, onUpdate }: { flag: FeatureFlag; onUpdate: (f: FeatureFlag) => void }) {
  const { addNotification } = useAdminStore();
  const [saving, setSaving] = useState(false);
  const [rollout, setRollout] = useState(flag.rolloutPercentage);

  async function toggleGlobal() {
    setSaving(true);
    try {
      await updateFeatureFlag(flag.flagId, { globalEnabled: !flag.globalEnabled });
      onUpdate({ ...flag, globalEnabled: !flag.globalEnabled });
      addNotification({
        type: "success",
        message: `${flag.displayName} ${!flag.globalEnabled ? "enabled" : "disabled"} globally.`,
      });
    } catch {
      addNotification({ type: "error", message: "Failed to update flag." });
    } finally {
      setSaving(false);
    }
  }

  async function saveRollout(value: number) {
    setSaving(true);
    try {
      await updateFeatureFlag(flag.flagId, { rolloutPercentage: value });
      onUpdate({ ...flag, rolloutPercentage: value });
      addNotification({ type: "success", message: `Rollout updated to ${value}%.` });
    } catch {
      addNotification({ type: "error", message: "Failed to update rollout." });
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className={`bg-white rounded-xl border p-5 space-y-4 ${flag.globalEnabled ? "border-slate-200" : "border-slate-100 opacity-70"}`}>
      {/* Header */}
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <h3 className="text-sm font-semibold text-slate-900">{flag.displayName}</h3>
          <p className="text-xs font-mono text-slate-400 mt-0.5">{flag.name}</p>
        </div>
        <button
          onClick={toggleGlobal}
          disabled={saving}
          className="flex-shrink-0 transition-opacity disabled:opacity-50"
          title={flag.globalEnabled ? "Disable globally" : "Enable globally"}
        >
          {flag.globalEnabled ? (
            <ToggleRight className="h-7 w-7 text-[#1A6E8A]" />
          ) : (
            <ToggleLeft className="h-7 w-7 text-slate-300" />
          )}
        </button>
      </div>

      <p className="text-xs text-slate-500 leading-relaxed">{flag.description}</p>

      {/* Rollout slider */}
      <div className="space-y-2">
        <div className="flex items-center justify-between text-xs">
          <span className="text-slate-500">Rollout</span>
          <span className="font-mono font-semibold text-slate-800">{rollout}%</span>
        </div>
        <Slider
          min={0}
          max={100}
          step={5}
          value={[rollout]}
          onValueChange={([v]) => setRollout(v)}
          onValueCommit={([v]) => saveRollout(v)}
          disabled={!flag.globalEnabled || saving}
          className="cursor-pointer"
        />
      </div>

      {/* Overrides */}
      {(flag.specificUsers.length > 0 || flag.specificBusinesses.length > 0) && (
        <div className="flex items-center gap-3 text-xs text-slate-500">
          {flag.specificUsers.length > 0 && (
            <span className="flex items-center gap-1">
              <Users className="h-3 w-3" />
              {flag.specificUsers.length} user override{flag.specificUsers.length > 1 ? "s" : ""}
            </span>
          )}
          {flag.specificBusinesses.length > 0 && (
            <span className="flex items-center gap-1">
              <Building2 className="h-3 w-3" />
              {flag.specificBusinesses.length} biz override{flag.specificBusinesses.length > 1 ? "s" : ""}
            </span>
          )}
        </div>
      )}

      {/* Footer */}
      <div className="flex items-center gap-1.5 text-xs text-slate-400 border-t border-slate-50 pt-3">
        <Clock className="h-3 w-3" />
        Updated {timeAgo(flag.updatedAt)} by {flag.updatedBy}
      </div>
    </div>
  );
}

export default function FeatureFlagsPage() {
  const [flags, setFlags] = useState<FeatureFlag[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchFeatureFlags()
      .then(setFlags)
      .finally(() => setLoading(false));
  }, []);

  function handleUpdate(updated: FeatureFlag) {
    setFlags((prev) => prev.map((f) => (f.flagId === updated.flagId ? updated : f)));
  }

  const enabledCount = flags.filter((f) => f.globalEnabled).length;

  return (
    <div>
      <PageHeader
        title="Feature Flags"
        description={`${flags.length} flags · ${enabledCount} globally enabled`}
      />

      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-48 rounded-xl" />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {flags.map((flag) => (
            <FlagCard key={flag.flagId} flag={flag} onUpdate={handleUpdate} />
          ))}
        </div>
      )}
    </div>
  );
}
