import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAppStore } from '@/store/useAppStore';
import type { DailyTask } from '@/types';

function toTask(d: any): DailyTask {
  return {
    id: d.id, userId: d.user_id, checkInId: d.check_in_id,
    title: d.title, description: d.description,
    estimatedMinutes: d.estimated_minutes, difficulty: d.difficulty,
    reason: d.reason, status: d.status,
    scheduledFor: d.scheduled_for, completedAt: d.completed_at,
  };
}

export function useTasks() {
  const { user } = useAppStore();
  const today = new Date().toISOString().split('T')[0];
  const q = useQuery({
    queryKey: ['tasks', user?.id, today],
    queryFn: async () => {
      const { data, error } = await supabase.from('daily_tasks').select('*')
        .eq('user_id', user!.id).eq('scheduled_for', today)
        .order('created_at', { ascending: true });
      if (error) throw error;
      return data.map(toTask);
    },
    enabled: !!user?.id,
  });
  return { todaysTasks: q.data ?? [], isLoading: q.isLoading };
}
