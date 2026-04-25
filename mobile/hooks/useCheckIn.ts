import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAppStore } from '@/store/useAppStore';
import type { AICheckInResponse } from '@/types';

interface Payload {
  moodScore: number; cravingLevel: number; stressLevel: number;
  sleepQuality: number; journalText?: string;
}

export function useCheckIn() {
  const { user } = useAppStore();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (p: Payload): Promise<AICheckInResponse> => {
      const { data: checkIn, error } = await supabase.from('check_ins').insert({
        user_id: user!.id, mood_score: p.moodScore, craving_level: p.cravingLevel,
        stress_level: p.stressLevel, sleep_quality: p.sleepQuality,
        journal_text: p.journalText || null,
      }).select().single();
      if (error) throw error;

      const { data: aiResult, error: aiError } = await supabase.functions.invoke('analyze-checkin', {
        body: {
          mood_score: p.moodScore, craving_level: p.cravingLevel,
          stress_level: p.stressLevel, sleep_quality: p.sleepQuality,
          journal_text: p.journalText || null, check_in_id: checkIn.id,
        },
      });
      if (aiError) throw aiError;
      return aiResult as AICheckInResponse;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['companion'] });
      qc.invalidateQueries({ queryKey: ['tasks'] });
    },
  });
}
