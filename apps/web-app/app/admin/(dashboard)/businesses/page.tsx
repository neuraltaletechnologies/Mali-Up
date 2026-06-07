import { fetchBusinesses } from "@/lib/admin-api";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { BusinessesTable } from "@/components/admin/businesses/BusinessesTable";

export const dynamic = "force-dynamic";

export default async function BusinessesPage() {
  const businesses = await fetchBusinesses();
  const active = businesses.filter((b) => b.status === "active").length;

  return (
    <div>
      <PageHeader
        title="Businesses"
        description={`${businesses.length} total · ${active} active`}
      />
      <div className="bg-white rounded-xl border border-slate-200 p-4">
        <BusinessesTable businesses={businesses} />
      </div>
    </div>
  );
}
