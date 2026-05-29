import { fetchUsers } from "@/lib/admin-api";
import { auth } from "@/auth";
import { PageHeader } from "@/components/admin/layout/PageHeader";
import { UsersTable } from "@/components/admin/users/UsersTable";

export const dynamic = "force-dynamic";

export default async function UsersPage() {
  const [users, session] = await Promise.all([fetchUsers(), auth()]);
  const userRole = session?.user?.role ?? "support_agent";

  return (
    <div>
      <PageHeader
        title="Users"
        description={`${users.length.toLocaleString()} total platform users`}
      />
      <div className="bg-white rounded-xl border border-slate-200 p-4">
        <UsersTable users={users} userRole={userRole} />
      </div>
    </div>
  );
}
