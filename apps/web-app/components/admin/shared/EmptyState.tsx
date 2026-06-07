import { SearchX } from "lucide-react";

interface EmptyStateProps {
  title?: string;
  description?: string;
}

export function EmptyState({
  title = "No results found",
  description = "Try adjusting your search or filters.",
}: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="mb-4 rounded-full bg-slate-100 p-4">
        <SearchX className="h-8 w-8 text-slate-400" />
      </div>
      <p className="text-sm font-medium text-slate-700">{title}</p>
      <p className="mt-1 text-sm text-slate-500">{description}</p>
    </div>
  );
}
