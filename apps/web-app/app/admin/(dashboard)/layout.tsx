import { auth } from "@/auth";
import { Sidebar } from "@/components/admin/layout/Sidebar";
import { AdminProviders } from "./providers";

export default async function AdminDashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await auth();

  return (
    <AdminProviders session={session}>
      <div className="min-h-screen flex" style={{ backgroundColor: "#F8F9FC" }}>
        <Sidebar />
        <div className="flex-1 flex flex-col min-w-0 pl-60">
          <main className="flex-1 p-6">
            {children}
          </main>
        </div>
      </div>
    </AdminProviders>
  );
}
