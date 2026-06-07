"use client";

import { useState } from "react";
import { Save, AlertTriangle } from "lucide-react";
import type { PlatformConfig } from "@/types/admin";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { useAdminStore } from "@/store/adminStore";
import { useSession } from "next-auth/react";

const defaultConfig: PlatformConfig = {
  pricing: {
    growthMonthly: 30_000,
    businessMonthly: 70_000,
    smsCreditsPerPack: 5_000,
    exportBundlePrice: 2_000,
  },
  starterInvoiceLimit: 50,
  starterUserLimit: 1,
  growthUserLimit: 3,
  businessUserLimit: 10,
  vatRate: 18,
  vatEnabled: true,
  maintenanceMode: false,
  maintenanceBanner: "",
  onboardingEnabled: true,
};

function SectionCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-6 space-y-4">
      <h3 className="text-sm font-semibold text-slate-700 border-b border-slate-100 pb-3">{title}</h3>
      {children}
    </div>
  );
}

function ConfigField({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex items-start justify-between gap-8">
      <div className="flex-1">
        <Label className="text-sm font-medium text-slate-700">{label}</Label>
        {hint && <p className="text-xs text-slate-400 mt-0.5">{hint}</p>}
      </div>
      <div className="flex-shrink-0 w-56">{children}</div>
    </div>
  );
}

export default function ConfigPage() {
  const { data: session } = useSession();
  const { addNotification } = useAdminStore();
  const [config, setConfig] = useState<PlatformConfig>(defaultConfig);
  const [saving, setSaving] = useState(false);
  const [dirty, setDirty] = useState(false);

  const isSuperAdmin = session?.user?.role === "super_admin";

  function update<K extends keyof PlatformConfig>(key: K, value: PlatformConfig[K]) {
    setConfig((prev) => ({ ...prev, [key]: value }));
    setDirty(true);
  }

  function updatePricing<K extends keyof PlatformConfig["pricing"]>(
    key: K,
    value: number
  ) {
    setConfig((prev) => ({ ...prev, pricing: { ...prev.pricing, [key]: value } }));
    setDirty(true);
  }

  async function handleSave() {
    setSaving(true);
    await new Promise((r) => setTimeout(r, 800));
    setSaving(false);
    setDirty(false);
    addNotification({ type: "success", message: "Platform configuration saved and logged." });
  }

  function handleDiscard() {
    setConfig(defaultConfig);
    setDirty(false);
  }

  if (!isSuperAdmin) {
    return (
      <div>
        <PageHeader title="Platform Config" />
        <div className="bg-red-50 border border-red-200 rounded-xl p-10 text-center">
          <AlertTriangle className="h-8 w-8 text-red-400 mx-auto mb-3" />
          <p className="text-sm font-medium text-red-700">Super Admin access required</p>
          <p className="text-xs text-red-500 mt-1">Only super_admin accounts can modify platform configuration.</p>
        </div>
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title="Platform Config"
        description="Super Admin only. All changes are logged to the audit trail."
        actions={
          dirty ? (
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm" onClick={handleDiscard} disabled={saving}>
                Discard
              </Button>
              <Button
                size="sm"
                onClick={handleSave}
                disabled={saving}
                style={{ backgroundColor: "#0D1B3E" }}
              >
                {saving ? (
                  "Saving..."
                ) : (
                  <>
                    <Save className="mr-1.5 h-3.5 w-3.5" />
                    Save Changes
                  </>
                )}
              </Button>
            </div>
          ) : undefined
        }
      />

      <div className="space-y-4 max-w-2xl">
        {/* Pricing */}
        <SectionCard title="Pricing (TZS)">
          <ConfigField label="Growth Plan Monthly" hint="Charged per month for Growth tier">
            <Input
              type="number"
              value={config.pricing.growthMonthly}
              onChange={(e) => updatePricing("growthMonthly", Number(e.target.value))}
              className="font-mono"
            />
          </ConfigField>
          <ConfigField label="Business Plan Monthly" hint="Charged per month for Business tier">
            <Input
              type="number"
              value={config.pricing.businessMonthly}
              onChange={(e) => updatePricing("businessMonthly", Number(e.target.value))}
              className="font-mono"
            />
          </ConfigField>
          <ConfigField label="SMS Credits Pack" hint="Price per 100 SMS credits">
            <Input
              type="number"
              value={config.pricing.smsCreditsPerPack}
              onChange={(e) => updatePricing("smsCreditsPerPack", Number(e.target.value))}
              className="font-mono"
            />
          </ConfigField>
          <ConfigField label="Export Bundle Price" hint="Price per 10 document exports">
            <Input
              type="number"
              value={config.pricing.exportBundlePrice}
              onChange={(e) => updatePricing("exportBundlePrice", Number(e.target.value))}
              className="font-mono"
            />
          </ConfigField>
        </SectionCard>

        {/* Plan limits */}
        <SectionCard title="Plan Limits">
          <ConfigField label="Starter Invoice Limit" hint="Max invoices per month on free tier">
            <Input
              type="number"
              value={config.starterInvoiceLimit}
              onChange={(e) => update("starterInvoiceLimit", Number(e.target.value))}
              className="font-mono"
            />
          </ConfigField>
          <ConfigField label="Starter User Limit" hint="Max staff on Starter plan">
            <Input
              type="number"
              value={config.starterUserLimit}
              onChange={(e) => update("starterUserLimit", Number(e.target.value))}
              className="font-mono"
            />
          </ConfigField>
          <ConfigField label="Growth User Limit" hint="Max staff on Growth plan">
            <Input
              type="number"
              value={config.growthUserLimit}
              onChange={(e) => update("growthUserLimit", Number(e.target.value))}
              className="font-mono"
            />
          </ConfigField>
          <ConfigField label="Business User Limit" hint="Max staff on Business plan">
            <Input
              type="number"
              value={config.businessUserLimit}
              onChange={(e) => update("businessUserLimit", Number(e.target.value))}
              className="font-mono"
            />
          </ConfigField>
        </SectionCard>

        {/* Tax */}
        <SectionCard title="Tax Settings">
          <ConfigField label="VAT Rate (%)" hint="Applied to all invoices when enabled">
            <Input
              type="number"
              value={config.vatRate}
              onChange={(e) => update("vatRate", Number(e.target.value))}
              className="font-mono"
            />
          </ConfigField>
          <ConfigField label="VAT Enabled" hint="Toggle VAT application platform-wide">
            <Switch
              checked={config.vatEnabled}
              onCheckedChange={(v) => update("vatEnabled", v)}
            />
          </ConfigField>
        </SectionCard>

        {/* App settings */}
        <SectionCard title="App Settings">
          <ConfigField label="Onboarding Enabled" hint="Allow new users to register">
            <Switch
              checked={config.onboardingEnabled}
              onCheckedChange={(v) => update("onboardingEnabled", v)}
            />
          </ConfigField>
          <ConfigField label="Maintenance Mode" hint="Shows maintenance banner to all app users">
            <Switch
              checked={config.maintenanceMode}
              onCheckedChange={(v) => update("maintenanceMode", v)}
            />
          </ConfigField>
          {config.maintenanceMode && (
            <ConfigField label="Maintenance Message" hint="Shown in the app during maintenance">
              <Textarea
                value={config.maintenanceBanner}
                onChange={(e) => update("maintenanceBanner", e.target.value)}
                placeholder="We are performing scheduled maintenance..."
                rows={3}
                className="text-sm"
              />
            </ConfigField>
          )}
        </SectionCard>
      </div>
    </div>
  );
}
