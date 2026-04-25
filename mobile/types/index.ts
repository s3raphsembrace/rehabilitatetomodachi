export type MoodState = 'happy' | 'calm' | 'tired' | 'worried' | 'proud' | 'sick' | 'encouraged';
export type RiskLevel = 'low' | 'medium' | 'high' | 'crisis';
export type TaskDifficulty = 'easy' | 'medium' | 'hard';

export interface Companion {
  id: string; userId: string; name: string; species: string;
  health: number; happiness: number; energy: number; trust: number;
  level: number; xp: number; streak: number; longestStreak: number;
  moodState: MoodState; lastInteractionAt: string | null; lastMessage?: string | null;
}

export interface DailyTask {
  id: string; userId: string; checkInId?: string;
  title: string; description: string; estimatedMinutes: number;
  difficulty: TaskDifficulty; reason?: string;
  status: 'pending' | 'completed' | 'skipped';
  scheduledFor: string; completedAt?: string;
}

export interface AICheckInResponse {
  risk_level: RiskLevel;
  emotional_summary: string;
  recommended_micro_task: {
    title: string; description: string;
    estimated_minutes: number; difficulty: TaskDifficulty; reason: string;
  };
  companion_message: string;
  companion_stat_changes: { health: number; happiness: number; energy: number; trust: number; };
  safety_action: { needed: boolean; message: string; recommended_next_step: string; };
  task_id?: string;
}
