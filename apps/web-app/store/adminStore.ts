"use client";

import { create } from "zustand";

interface Notification {
  id: string;
  message: string;
  type: "success" | "error" | "info" | "warning";
}

interface UserFilters {
  status?: string;
  search?: string;
}

interface BusinessFilters {
  status?: string;
  planTier?: string;
  search?: string;
  location?: string;
}

interface AdminStore {
  globalSearch: string;
  setGlobalSearch: (q: string) => void;

  notifications: Notification[];
  addNotification: (n: Omit<Notification, "id">) => void;
  clearNotification: (id: string) => void;

  userFilters: UserFilters;
  setUserFilters: (f: UserFilters) => void;

  businessFilters: BusinessFilters;
  setBusinessFilters: (f: BusinessFilters) => void;
}

export const useAdminStore = create<AdminStore>((set) => ({
  globalSearch: "",
  setGlobalSearch: (globalSearch) => set({ globalSearch }),

  notifications: [],
  addNotification: (n) =>
    set((s) => ({
      notifications: [
        ...s.notifications,
        { ...n, id: `notif_${Date.now()}` },
      ],
    })),
  clearNotification: (id) =>
    set((s) => ({
      notifications: s.notifications.filter((n) => n.id !== id),
    })),

  userFilters: {},
  setUserFilters: (userFilters) => set({ userFilters }),

  businessFilters: {},
  setBusinessFilters: (businessFilters) => set({ businessFilters }),
}));
