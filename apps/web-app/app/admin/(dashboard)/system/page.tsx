import { fetchServiceHealth } from "@/lib/admin-api";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { SystemCharts } from "./SystemCharts";
import { CheckCircle2, AlertTriangle, XCircle, AlertCircle } from "lucide-react";
import type { ServiceHealth } from "@/types/admin";

export const dynamic = "force-dynamic";
export const revalidate = 30;

function ServiceCard({ service }: { service: ServiceHealth }) {
  const isDown = service.status === "down";
  const isDegraded = service.status === "degraded";
  const latencyWarn = service.p95Latency > 200;
  const latencyDanger = service.p95Latency > 500;
  const errorWarn = service.errorRate > 1;
  const errorDanger = service.errorRate > 5;

  const statusIcon = isDown ? (
    <XCircle className="h-4 w-4 text-red-500" />
  ) : isDegraded ? (
    <AlertTriangle className="h-4 w-4 text-amber-500" />
  ) : (
    <CheckCircle2 className="h-4 w-4 text-emerald-500" />
  );

  const borderColor = isDown
    ? "border-red-200 bg-red-50"
    : isDegraded
    ? "border-amber-200 bg-amber-50"
    : "border-slate-200 bg-white";

  return (
    <div className={`rounded-xl border p-4 space-y-3 ${borderColor}`}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          {statusIcon}
          <span className="text-sm font-semibold text-slate-800 font-mono">
            {service.serviceName}
          </span>
        </div>
        <span className="text-xs font-mono text-slate-400">{service.containerCount}c</span>
      </div>

      <div className="grid grid-cols-2 gap-2 text-xs">
        <div>
          <span className="text-slate-400">Uptime</span>
          <p className="font-mono font-semibold text-slate-700">{service.uptime}</p>
        </div>
        <div>
          <span className="text-slate-400">Req/min</span>
          <p className="font-mono font-semibold text-slate-700">{service.requestsPerMin}</p>
        </div>
        <div>
          <span className="text-slate-400">p95 Latency</span>
          <p className={`font-mono font-semibold ${latencyDanger ? "text-red-600" : latencyWarn ? "text-amber-600" : "text-slate-700"}`}>
            {service.p95Latency}ms
          </p>
        </div>
        <div>
          <span className="text-slate-400">Error Rate</span>
          <p className={`font-mono font-semibold ${errorDanger ? "text-red-600" : errorWarn ? "text-amber-600" : "text-slate-700"}`}>
            {service.errorRate.toFixed(2)}%
          </p>
        </div>
      </div>
    </div>
  );
}

export default async function SystemHealthPage() {
  const services = await fetchServiceHealth();

  const downServices = services.filter((s) => s.status === "down");
  const degradedServices = services.filter((s) => s.status === "degraded");
  const healthyCount = services.filter((s) => s.status === "healthy").length;

  return (
    <div className="space-y-6">
      <PageHeader
        title="System Health"
        description={`${services.length} microservices monitored`}
      />

      {/* Alert banner */}
      {(downServices.length > 0 || degradedServices.length > 0) && (
        <div className={`rounded-xl border px-5 py-4 flex items-start gap-3 ${
          downServices.length > 0
            ? "bg-red-50 border-red-200 text-red-800"
            : "bg-amber-50 border-amber-200 text-amber-800"
        }`}>
          <AlertCircle className="h-5 w-5 mt-0.5 flex-shrink-0" />
          <div>
            <p className="font-semibold text-sm">
              {downServices.length > 0
                ? `${downServices.length} service(s) DOWN`
                : `${degradedServices.length} service(s) degraded`}
            </p>
            <p className="text-xs mt-0.5">
              Affected: {[...downServices, ...degradedServices].map((s) => s.serviceName).join(", ")}
            </p>
          </div>
        </div>
      )}

      {/* Summary stats */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: "Healthy", value: healthyCount, icon: CheckCircle2, color: "text-emerald-600 bg-emerald-50" },
          { label: "Degraded", value: degradedServices.length, icon: AlertTriangle, color: "text-amber-600 bg-amber-50" },
          { label: "Down", value: downServices.length, icon: XCircle, color: "text-red-600 bg-red-50" },
        ].map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="bg-white rounded-xl border border-slate-200 p-4 flex items-center gap-4">
            <div className={`rounded-lg p-2.5 ${color.split(" ")[1]}`}>
              <Icon className={`h-5 w-5 ${color.split(" ")[0]}`} />
            </div>
            <div>
              <p className="text-2xl font-bold text-slate-900 font-mono">{value}</p>
              <p className="text-xs text-slate-500">{label}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Services grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {services.map((service) => (
          <ServiceCard key={service.serviceName} service={service} />
        ))}
      </div>

      <SystemCharts services={services} />
    </div>
  );
}
