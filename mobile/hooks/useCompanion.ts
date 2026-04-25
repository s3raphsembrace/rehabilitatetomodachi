import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAppStore } from '@/store/useAppStore';
import type { Companion } from '@/types';

function toCompanion(d: any): Companion {
  return {
    id: d.id, userId: d.user_id, name: d.name, species: d.species,
    health: d.health, happiness: d.happiness, energy: d.energy, trust: d.trust,
    level: d.level, xp: d.xp, streak: d.streak, longestStreak: d.longest_streak,
    moodState: d.mood_state, lastInteractionAt: d.last_interaction_at,
    lastMessage: d.last_message ?? null,
  };
}

export function useCompanion() {
  const { user } = useAppStore();
  const q = useQuery({
    queryKey: ['companion', user?.id],
    queryFn: async () => {
      const { data, error } = await supabase.from('companions').select('*').eq('user_id', user!.id).single();
      if (error) throw error;
      return toCompanion(data);
    },
    enabled: !!user?.id,
    staleTime: 30_000,
  });
  return { companion: q.data ?? null, isLoading: q.isLoading, refetch: q.refetch };
}
