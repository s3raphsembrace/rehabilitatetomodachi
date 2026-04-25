import { create } from 'zustand';
import type { User } from '@supabase/supabase-js';

interface AppState {
  user: User | null;
  userLoaded: boolean;
  setUser: (user: User | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  user: null,
  userLoaded: false,
  setUser: (user) => set({ user, userLoaded: true }),
}));
