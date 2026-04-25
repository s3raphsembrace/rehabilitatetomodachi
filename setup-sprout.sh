#!/usr/bin/env bash
# ============================================================
# Sprout — Full Project Setup Script (WSL-safe)
# Usage:
#   ./setup-sprout.sh                          # fresh folder
#   ./setup-sprout.sh https://github.com/...  # clone existing repo
# ============================================================
set -e

GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
step() { echo -e "\n${BLUE}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }

# ── 0. Prerequisites ─────────────────────────────────────────
step "Checking prerequisites"

if ! command -v node &>/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
  nvm install 20 && nvm use 20
fi
ok "Node $(node -v)"

# Use npm (not pnpm) for global CLIs to avoid pnpm setup issues on WSL
npm install -g expo-cli 2>/dev/null || true
ok "npm $(npm -v)"

# Supabase CLI
if ! command -v supabase &>/dev/null; then
  SUPABASE_DIR="$HOME/.local/bin"
  mkdir -p "$SUPABASE_DIR"
  curl -fsSL https://github.com/supabase/cli/releases/download/v1.168.1/supabase_linux_amd64.tar.gz \
    | tar -xz -C "$SUPABASE_DIR" supabase
  export PATH="$SUPABASE_DIR:$PATH"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
ok "Supabase CLI ready"

# ── 1. Repo setup ────────────────────────────────────────────
step "Setting up repository"

REPO_URL="${1:-}"
PROJECT_NAME="sprout"

if [ -n "$REPO_URL" ]; then
  git clone "$REPO_URL" "$PROJECT_NAME" 2>/dev/null || true
  cd "$PROJECT_NAME"
  ok "Cloned $REPO_URL"
else
  mkdir -p "$PROJECT_NAME" && cd "$PROJECT_NAME"
  git init -q
  ok "Fresh repo at $(pwd)"
fi

# ── 2. Scaffold Expo app ─────────────────────────────────────
step "Scaffolding Expo app (using npx — no global install needed)"

npx create-expo-app@latest mobile --template blank-typescript --yes 2>/dev/null \
  || npx create-expo-app mobile --template blank-typescript --yes

cd mobile
ok "Expo app created"

# ── 3. Install dependencies ──────────────────────────────────
step "Installing dependencies"

npm install --legacy-peer-deps \
  expo-router \
  expo-status-bar \
  expo-linking \
  expo-constants \
  expo-system-ui \
  react-native-reanimated \
  react-native-gesture-handler \
  react-native-safe-area-context \
  react-native-screens \
  @supabase/supabase-js \
  zustand \
  @tanstack/react-query \
  expo-notifications \
  expo-device \
  @react-native-async-storage/async-storage \
  expo-secure-store \
  @expo/vector-icons \
  expo-haptics \
  date-fns \
  lottie-react-native

npm install --save-dev --legacy-peer-deps @types/react @types/react-native

ok "Dependencies installed"

# ── 4. Config files ──────────────────────────────────────────
step "Writing config files"

cat > app.json << 'APPJSON'
{
  "expo": {
    "name": "Sprout",
    "slug": "sprout",
    "version": "1.0.0",
    "orientation": "portrait",
    "scheme": "sprout",
    "userInterfaceStyle": "light",
    "splash": { "resizeMode": "contain", "backgroundColor": "#48BB78" },
    "ios": { "supportsTablet": false, "bundleIdentifier": "com.yourteam.sprout" },
    "android": {
      "adaptiveIcon": { "backgroundColor": "#48BB78" },
      "package": "com.yourteam.sprout"
    },
    "plugins": ["expo-router"],
    "experiments": { "typedRoutes": true }
  }
}
APPJSON

cat > babel.config.js << 'BABEL'
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: ['react-native-reanimated/plugin'],
  };
};
BABEL

cat > tsconfig.json << 'TSCONFIG'
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "baseUrl": ".",
    "paths": { "@/*": ["./*"] }
  },
  "include": ["**/*.ts", "**/*.tsx", ".expo/types/**/*.d.ts", "expo-env.d.ts"]
}
TSCONFIG

cat > .env << 'ENVFILE'
EXPO_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
ENVFILE

ok "Config files written"

# ── 5. Folder structure ──────────────────────────────────────
step "Creating folder structure"

mkdir -p \
  "app/(auth)" \
  "app/(tabs)" \
  "app/task" \
  components/companion \
  components/checkin \
  components/task \
  components/ui \
  components/journal \
  hooks \
  lib \
  store \
  types \
  constants \
  assets/animations

ok "Folders created"

# ── 6. Source files ──────────────────────────────────────────
step "Writing source files"

# types/index.ts
cat > types/index.ts << 'EOF'
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
EOF

# constants/theme.ts
cat > constants/theme.ts << 'EOF'
export const colors = {
  primary: '#48BB78', primaryDark: '#276749', background: '#FAFAF8',
  card: '#FFFFFF', text: '#2D3748', textMuted: '#718096', textLight: '#A0AEC0',
  border: '#E2E8F0', danger: '#FC8181', warning: '#F6E05E', success: '#68D391', info: '#76E4F7',
};
export const mood: Record<string, string> = {
  happy: '#A8E6CF', calm: '#B8D4E8', tired: '#D4C5E2',
  worried: '#FFD4A3', proud: '#FFE082', sick: '#C8E6C9', encouraged: '#B3E5FC',
};
EOF

# constants/safety.ts
cat > constants/safety.ts << 'EOF'
export const CRISIS_RESOURCES = [
  { label: '988 Suicide & Crisis Lifeline', number: '988', description: 'Call or text 988 — free, confidential, 24/7', isSms: false },
  { label: 'SAMHSA Helpline', number: '18006624357', description: '1-800-662-4357 — Substance use support, free & confidential', isSms: false },
  { label: 'Crisis Text Line', number: '741741', description: 'Text HOME to 741741', isSms: true },
];
EOF

# lib/supabase.ts
cat > lib/supabase.ts << 'EOF'
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const supabase = createClient(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      storage: AsyncStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  }
);
EOF

# store/useAppStore.ts
cat > store/useAppStore.ts << 'EOF'
import { create } from 'zustand';
import type { User } from '@supabase/supabase-js';

interface AppState {
  user: User | null;
  setUser: (user: User | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));
EOF

# hooks/useCompanion.ts
cat > hooks/useCompanion.ts << 'EOF'
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
EOF

# hooks/useTasks.ts
cat > hooks/useTasks.ts << 'EOF'
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
EOF

# hooks/useCheckIn.ts
cat > hooks/useCheckIn.ts << 'EOF'
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
EOF

# components/ui/SafetyBanner.tsx
cat > components/ui/SafetyBanner.tsx << 'EOF'
import React from 'react';
import { View, Text, TouchableOpacity, Linking, StyleSheet } from 'react-native';
import { CRISIS_RESOURCES } from '@/constants/safety';

interface Props { riskLevel: 'high' | 'crisis'; message: string; recommendedStep: string; }

export function SafetyBanner({ riskLevel, message, recommendedStep }: Props) {
  const isCrisis = riskLevel === 'crisis';
  return (
    <View style={[s.box, isCrisis ? s.crisis : s.high]}>
      <Text style={s.icon}>{isCrisis ? '🆘' : '💛'}</Text>
      <Text style={s.title}>{isCrisis ? "You don't have to face this alone" : 'Sprout is here with you'}</Text>
      <Text style={s.msg}>{message}</Text>
      <Text style={s.step}>{recommendedStep}</Text>
      {CRISIS_RESOURCES.map((r) => (
        <TouchableOpacity key={r.number} style={s.btn}
          onPress={() => Linking.openURL(r.isSms ? `sms:${r.number}` : `tel:${r.number}`)}>
          <Text style={s.btnTitle}>{r.label}</Text>
          <Text style={s.btnDesc}>{r.description}</Text>
        </TouchableOpacity>
      ))}
      <Text style={s.disc}>Sprout is not a crisis service. In immediate danger, call 911.</Text>
    </View>
  );
}

const s = StyleSheet.create({
  box: { borderRadius: 16, padding: 20, margin: 16 },
  high: { backgroundColor: '#FFFBEB', borderWidth: 1, borderColor: '#F6E05E' },
  crisis: { backgroundColor: '#FFF5F5', borderWidth: 1, borderColor: '#FC8181' },
  icon: { fontSize: 32, textAlign: 'center', marginBottom: 8 },
  title: { fontSize: 18, fontWeight: '700', color: '#2D3748', textAlign: 'center', marginBottom: 8 },
  msg: { fontSize: 15, color: '#4A5568', lineHeight: 22, marginBottom: 8 },
  step: { fontSize: 15, fontWeight: '600', color: '#2D3748', marginBottom: 16 },
  btn: { backgroundColor: 'white', borderRadius: 12, padding: 14, marginBottom: 8 },
  btnTitle: { fontSize: 15, fontWeight: '700', color: '#2D3748' },
  btnDesc: { fontSize: 13, color: '#718096', marginTop: 2 },
  disc: { fontSize: 12, color: '#A0AEC0', textAlign: 'center', marginTop: 8 },
});
EOF

# components/companion/CompanionStats.tsx
cat > components/companion/CompanionStats.tsx << 'EOF'
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, withTiming } from 'react-native-reanimated';
import type { Companion } from '@/types';

const STATS = [
  { key: 'health' as const, label: 'Health', color: '#FC8181', icon: '❤️' },
  { key: 'happiness' as const, label: 'Joy', color: '#F6E05E', icon: '☀️' },
  { key: 'energy' as const, label: 'Energy', color: '#68D391', icon: '⚡' },
  { key: 'trust' as const, label: 'Trust', color: '#76E4F7', icon: '🤝' },
];

function Bar({ label, icon, value, color }: { label: string; icon: string; value: number; color: string }) {
  const w = useSharedValue(0);
  React.useEffect(() => { w.value = withTiming(value, { duration: 800 }); }, [value]);
  const anim = useAnimatedStyle(() => ({ width: `${w.value}%` as any }));
  return (
    <View style={s.row}>
      <Text style={s.icon}>{icon}</Text>
      <Text style={s.label}>{label}</Text>
      <View style={s.track}><Animated.View style={[s.fill, anim, { backgroundColor: color }]} /></View>
      <Text style={s.val}>{Math.round(value)}</Text>
    </View>
  );
}

export function CompanionStats({ companion }: { companion: Companion }) {
  return (
    <View style={s.box}>
      {STATS.map((st) => <Bar key={st.key} label={st.label} icon={st.icon} value={companion[st.key]} color={st.color} />)}
    </View>
  );
}

const s = StyleSheet.create({
  box: { marginHorizontal: 24, marginTop: 16, backgroundColor: 'white', borderRadius: 16, padding: 16, gap: 10, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.05, shadowRadius: 8, elevation: 2 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  icon: { fontSize: 14, width: 20 },
  label: { fontSize: 12, fontWeight: '600', color: '#718096', width: 52 },
  track: { flex: 1, height: 8, backgroundColor: '#F0F4F8', borderRadius: 4, overflow: 'hidden' },
  fill: { height: '100%', borderRadius: 4 },
  val: { fontSize: 12, fontWeight: '700', color: '#4A5568', width: 28, textAlign: 'right' },
});
EOF

# components/task/TaskCard.tsx
cat > components/task/TaskCard.tsx << 'EOF'
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import type { DailyTask } from '@/types';

const DC: Record<string, string> = { easy: '#68D391', medium: '#F6E05E', hard: '#FC8181' };

export function TaskCard({ task, onPress }: { task: DailyTask; onPress: () => void }) {
  return (
    <TouchableOpacity style={s.card} onPress={onPress} activeOpacity={0.85}>
      <View style={s.header}>
        <Text style={s.title}>{task.title}</Text>
        <View style={[s.badge, { backgroundColor: DC[task.difficulty] + '33' }]}>
          <Text style={[s.badgeText, { color: DC[task.difficulty] }]}>{task.difficulty}</Text>
        </View>
      </View>
      <Text style={s.desc}>{task.description}</Text>
      <Text style={s.meta}>⏱ ~{task.estimatedMinutes} min</Text>
    </TouchableOpacity>
  );
}

const s = StyleSheet.create({
  card: { backgroundColor: 'white', borderRadius: 16, padding: 16, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.06, shadowRadius: 8, elevation: 2 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  title: { fontSize: 16, fontWeight: '700', color: '#2D3748', flex: 1 },
  badge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 20, marginLeft: 8 },
  badgeText: { fontSize: 11, fontWeight: '700', textTransform: 'uppercase' },
  desc: { fontSize: 14, color: '#4A5568', lineHeight: 20, marginBottom: 8 },
  meta: { fontSize: 12, color: '#718096' },
});
EOF

# app/_layout.tsx
cat > app/_layout.tsx << 'EOF'
import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { StatusBar } from 'expo-status-bar';
import { supabase } from '@/lib/supabase';
import { useAppStore } from '@/store/useAppStore';

const qc = new QueryClient();

export default function RootLayout() {
  const setUser = useAppStore((s) => s.setUser);
  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setUser(data.session?.user ?? null));
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_e, session) => setUser(session?.user ?? null));
    return () => subscription.unsubscribe();
  }, []);
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <QueryClientProvider client={qc}>
        <StatusBar style="dark" />
        <Stack screenOptions={{ headerShown: false }} />
      </QueryClientProvider>
    </GestureHandlerRootView>
  );
}
EOF

# app/(auth)/welcome.tsx
cat > "app/(auth)/welcome.tsx" << 'EOF'
import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { supabase } from '@/lib/supabase';

export default function WelcomeScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handleAuth() {
    setLoading(true);
    const { error } = isSignUp
      ? await supabase.auth.signUp({ email, password })
      : await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (error) Alert.alert('Error', error.message);
  }

  return (
    <View style={s.container}>
      <Text style={s.logo}>🌱</Text>
      <Text style={s.title}>Sprout</Text>
      <Text style={s.tagline}>Your companion in recovery</Text>
      <TextInput style={s.input} placeholder="Email" value={email} onChangeText={setEmail} keyboardType="email-address" autoCapitalize="none" placeholderTextColor="#A0AEC0" />
      <TextInput style={s.input} placeholder="Password" value={password} onChangeText={setPassword} secureTextEntry placeholderTextColor="#A0AEC0" />
      <TouchableOpacity style={s.btn} onPress={handleAuth} disabled={loading}>
        <Text style={s.btnText}>{loading ? '...' : isSignUp ? 'Create account' : 'Sign in'}</Text>
      </TouchableOpacity>
      <TouchableOpacity onPress={() => setIsSignUp((v) => !v)}>
        <Text style={s.toggle}>{isSignUp ? 'Already have an account? Sign in' : "Don't have an account? Sign up"}</Text>
      </TouchableOpacity>
    </View>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FAFAF8', alignItems: 'center', justifyContent: 'center', padding: 32 },
  logo: { fontSize: 72, marginBottom: 8 },
  title: { fontSize: 36, fontWeight: '800', color: '#2D3748' },
  tagline: { fontSize: 16, color: '#718096', marginBottom: 40 },
  input: { width: '100%', backgroundColor: 'white', borderRadius: 12, padding: 16, fontSize: 16, borderWidth: 1, borderColor: '#E2E8F0', marginBottom: 12, color: '#2D3748' },
  btn: { width: '100%', backgroundColor: '#48BB78', borderRadius: 12, padding: 18, alignItems: 'center', marginTop: 4 },
  btnText: { color: 'white', fontSize: 17, fontWeight: '700' },
  toggle: { marginTop: 20, color: '#718096', fontSize: 14 },
});
EOF

# app/(tabs)/_layout.tsx
cat > "app/(tabs)/_layout.tsx" << 'EOF'
import { Tabs } from 'expo-router';

export default function TabLayout() {
  return (
    <Tabs screenOptions={{
      headerShown: false,
      tabBarStyle: { backgroundColor: '#FAFAF8', borderTopColor: '#E2E8F0' },
      tabBarActiveTintColor: '#48BB78',
      tabBarInactiveTintColor: '#A0AEC0',
    }}>
      <Tabs.Screen name="index" options={{ title: 'Home' }} />
      <Tabs.Screen name="checkin" options={{ title: 'Check In' }} />
      <Tabs.Screen name="journal" options={{ title: 'Journal' }} />
      <Tabs.Screen name="progress" options={{ title: 'Progress' }} />
      <Tabs.Screen name="support" options={{ title: 'Support' }} />
    </Tabs>
  );
}
EOF

# app/(tabs)/index.tsx
cat > "app/(tabs)/index.tsx" << 'EOF'
import React, { useEffect } from 'react';
import { View, Text, ScrollView, TouchableOpacity, StyleSheet } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, withRepeat, withSequence, withTiming, Easing } from 'react-native-reanimated';
import { router } from 'expo-router';
import { useCompanion } from '@/hooks/useCompanion';
import { useTasks } from '@/hooks/useTasks';
import { CompanionStats } from '@/components/companion/CompanionStats';
import { TaskCard } from '@/components/task/TaskCard';
import type { MoodState } from '@/types';

const EMOJI: Record<MoodState, string> = { happy: '😊', calm: '😌', tired: '😴', worried: '😟', proud: '🥹', sick: '🤒', encouraged: '🌟' };
const BG: Record<MoodState, string> = { happy: '#A8E6CF40', calm: '#B8D4E840', tired: '#D4C5E240', worried: '#FFD4A340', proud: '#FFE08240', sick: '#C8E6C940', encouraged: '#B3E5FC40' };

export default function HomeScreen() {
  const { companion, isLoading } = useCompanion();
  const { todaysTasks } = useTasks();
  const floatY = useSharedValue(0);

  useEffect(() => {
    floatY.value = withRepeat(
      withSequence(withTiming(-8, { duration: 2000, easing: Easing.inOut(Easing.sin) }), withTiming(0, { duration: 2000, easing: Easing.inOut(Easing.sin) })),
      -1, true
    );
  }, []);

  const floatStyle = useAnimatedStyle(() => ({ transform: [{ translateY: floatY.value }] }));

  if (isLoading || !companion) return <View style={s.center}><Text style={s.loading}>Waking Sprout up... 🌿</Text></View>;

  const pending = todaysTasks.filter((t) => t.status === 'pending');
  const checkedIn = todaysTasks.length > 0;
  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

  return (
    <ScrollView style={s.container} contentContainerStyle={s.content} showsVerticalScrollIndicator={false}>
      <View style={[s.moodBg, { backgroundColor: BG[companion.moodState] }]} />
      <View style={s.header}>
        <Text style={s.greeting}>{greeting} 🌱</Text>
        <View style={s.streak}><Text style={s.streakTxt}>🔥 {companion.streak} days</Text></View>
      </View>
      <Animated.View style={[s.companionWrap, floatStyle]}>
        <Text style={s.emojiLarge}>{EMOJI[companion.moodState]}</Text>
        <Text style={s.name}>{companion.name}</Text>
        {companion.lastMessage && <View style={s.bubble}><Text style={s.bubbleTxt}>{companion.lastMessage}</Text></View>}
      </Animated.View>
      <CompanionStats companion={companion} />
      <View style={s.lvlRow}>
        <Text style={s.lvlTxt}>Lv {companion.level}</Text>
        <View style={s.xpTrack}><View style={[s.xpFill, { width: `${companion.xp % 100}%` }]} /></View>
      </View>
      {!checkedIn ? (
        <TouchableOpacity style={s.checkInBtn} onPress={() => router.push('/(tabs)/checkin')}>
          <Text style={s.checkInBtnTxt}>☀️ Start today's check-in</Text>
          <Text style={s.checkInSub}>Tell Sprout how you're feeling — 2 minutes</Text>
        </TouchableOpacity>
      ) : pending.length > 0 ? (
        <View style={s.section}>
          <Text style={s.sectionTitle}>Today's task</Text>
          <TaskCard task={pending[0]} onPress={() => router.push({ pathname: '/task/[id]', params: { id: pending[0].id } })} />
        </View>
      ) : (
        <View style={s.allDone}><Text style={s.allDoneTxt}>✨ All done! Sprout is proud of you.</Text></View>
      )}
      <View style={s.qa}>
        {[{ icon: '📓', label: 'Journal', path: '/(tabs)/journal' }, { icon: '📊', label: 'Progress', path: '/(tabs)/progress' }, { icon: '🆘', label: 'Support', path: '/(tabs)/support' }]
          .map((a) => (
            <TouchableOpacity key={a.label} style={s.qaBtn} onPress={() => router.push(a.path as any)}>
              <Text style={s.qaIcon}>{a.icon}</Text>
              <Text style={s.qaLabel}>{a.label}</Text>
            </TouchableOpacity>
          ))}
      </View>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FAFAF8' }, content: { paddingBottom: 40 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#FAFAF8' },
  loading: { fontSize: 16, color: '#718096' },
  moodBg: { position: 'absolute', top: 0, left: 0, right: 0, height: 300, borderBottomLeftRadius: 40, borderBottomRightRadius: 40 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 24, paddingTop: 60, paddingBottom: 8 },
  greeting: { fontSize: 18, fontWeight: '600', color: '#2D3748' },
  streak: { backgroundColor: '#FFF3CD', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20 },
  streakTxt: { fontSize: 13, fontWeight: '700', color: '#856404' },
  companionWrap: { alignItems: 'center', paddingVertical: 20 },
  emojiLarge: { fontSize: 96 },
  name: { fontSize: 18, fontWeight: '700', color: '#2D3748', marginTop: 4 },
  bubble: { backgroundColor: 'white', borderRadius: 16, padding: 12, marginTop: 10, marginHorizontal: 32, maxWidth: 280, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.06, shadowRadius: 8, elevation: 2 },
  bubbleTxt: { fontSize: 14, color: '#4A5568', textAlign: 'center', lineHeight: 20 },
  lvlRow: { flexDirection: 'row', alignItems: 'center', marginHorizontal: 24, marginTop: 12, gap: 10 },
  lvlTxt: { fontSize: 13, fontWeight: '600', color: '#718096', width: 48 },
  xpTrack: { flex: 1, height: 6, backgroundColor: '#E2E8F0', borderRadius: 3, overflow: 'hidden' },
  xpFill: { height: '100%', backgroundColor: '#68D391', borderRadius: 3 },
  checkInBtn: { backgroundColor: '#48BB78', marginHorizontal: 24, marginTop: 20, borderRadius: 16, paddingVertical: 18, alignItems: 'center' },
  checkInBtnTxt: { color: 'white', fontSize: 17, fontWeight: '700' },
  checkInSub: { color: 'rgba(255,255,255,0.8)', fontSize: 13, marginTop: 4 },
  section: { marginHorizontal: 24, marginTop: 20 },
  sectionTitle: { fontSize: 16, fontWeight: '700', color: '#2D3748', marginBottom: 10 },
  allDone: { backgroundColor: '#F0FFF4', borderRadius: 14, padding: 18, marginHorizontal: 24, marginTop: 20, alignItems: 'center', borderWidth: 1, borderColor: '#C6F6D5' },
  allDoneTxt: { fontSize: 15, color: '#276749', textAlign: 'center' },
  qa: { flexDirection: 'row', justifyContent: 'space-around', marginHorizontal: 24, marginTop: 24 },
  qaBtn: { alignItems: 'center', backgroundColor: 'white', borderRadius: 14, paddingVertical: 14, paddingHorizontal: 20, shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.04, shadowRadius: 6, elevation: 1 },
  qaIcon: { fontSize: 24 },
  qaLabel: { fontSize: 12, fontWeight: '600', color: '#718096', marginTop: 4 },
});
EOF

# app/(tabs)/checkin.tsx
cat > "app/(tabs)/checkin.tsx" << 'EOF'
import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, ScrollView, TouchableOpacity, KeyboardAvoidingView, Platform, Alert } from 'react-native';
import { router } from 'expo-router';
import { useCheckIn } from '@/hooks/useCheckIn';

const STEPS = [
  { key: 'moodScore', title: 'How are you feeling?', desc: 'Be honest — Sprout can handle it.', lo: '😔 Low', hi: '😊 Great' },
  { key: 'cravingLevel', title: 'Craving intensity?', desc: 'No judgment. Just checking in.', lo: '✅ None', hi: '🔥 Strong' },
  { key: 'stressLevel', title: "How's your stress?", desc: 'Work, relationships, all of it.', lo: '🌊 Calm', hi: '⚡ High' },
  { key: 'sleepQuality', title: 'How did you sleep?', desc: 'Sleep affects everything.', lo: '😴 Poor', hi: '⭐ Great' },
] as const;

type Key = 'moodScore' | 'cravingLevel' | 'stressLevel' | 'sleepQuality';

export default function CheckInScreen() {
  const [step, setStep] = useState(0);
  const [form, setForm] = useState<Record<Key, number>>({ moodScore: 5, cravingLevel: 3, stressLevel: 4, sleepQuality: 6 });
  const [journal, setJournal] = useState('');
  const mutation = useCheckIn();
  const isJournal = step === STEPS.length;
  const cur = STEPS[step];

  async function submit() {
    try {
      const result = await mutation.mutateAsync({ ...form, journalText: journal });
      router.replace({ pathname: '/task/[id]', params: { id: result.task_id ?? 'new', aiResult: JSON.stringify(result) } });
    } catch {
      Alert.alert('Error', 'Check-in failed. Please try again.');
    }
  }

  return (
    <KeyboardAvoidingView style={s.wrap} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView contentContainerStyle={s.content}>
        <View style={s.dots}>
          {[...STEPS, 'j'].map((_, i) => <View key={i} style={[s.dot, i <= step && s.dotOn]} />)}
        </View>
        {!isJournal && cur ? (
          <>
            <Text style={s.q}>{cur.title}</Text>
            <Text style={s.desc}>{cur.desc}</Text>
            <View style={s.scale}>
              {[1,2,3,4,5,6,7,8,9,10].map((v) => (
                <TouchableOpacity key={v} style={[s.num, form[cur.key as Key] === v && s.numOn]} onPress={() => setForm((f) => ({ ...f, [cur.key]: v }))}>
                  <Text style={[s.numTxt, form[cur.key as Key] === v && s.numTxtOn]}>{v}</Text>
                </TouchableOpacity>
              ))}
            </View>
            <View style={s.lbls}><Text style={s.lo}>{cur.lo}</Text><Text style={s.lo}>{cur.hi}</Text></View>
          </>
        ) : (
          <>
            <Text style={s.q}>Want to tell Sprout more?</Text>
            <Text style={s.desc}>Completely optional. Write anything.</Text>
            <TextInput style={s.journal} multiline placeholder="Today I'm feeling..." placeholderTextColor="#A0AEC0" value={journal} onChangeText={setJournal} textAlignVertical="top" />
          </>
        )}
        <View style={s.nav}>
          {step > 0 && <TouchableOpacity style={s.back} onPress={() => setStep((v) => v - 1)}><Text style={s.backTxt}>← Back</Text></TouchableOpacity>}
          {isJournal
            ? <TouchableOpacity style={[s.next, mutation.isPending && s.nextOff]} onPress={submit} disabled={mutation.isPending}><Text style={s.nextTxt}>{mutation.isPending ? 'Checking in... 🌱' : 'Show Sprout →'}</Text></TouchableOpacity>
            : <TouchableOpacity style={s.next} onPress={() => setStep((v) => v + 1)}><Text style={s.nextTxt}>Next →</Text></TouchableOpacity>
          }
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const s = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: '#FAFAF8' }, content: { padding: 24, paddingTop: 60, paddingBottom: 40 },
  dots: { flexDirection: 'row', gap: 6, justifyContent: 'center', marginBottom: 40 },
  dot: { width: 8, height: 8, borderRadius: 4, backgroundColor: '#E2E8F0' }, dotOn: { backgroundColor: '#48BB78' },
  q: { fontSize: 24, fontWeight: '700', color: '#2D3748', marginBottom: 8 },
  desc: { fontSize: 15, color: '#718096', marginBottom: 32, lineHeight: 22 },
  scale: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, justifyContent: 'center', marginBottom: 12 },
  num: { width: 44, height: 44, borderRadius: 22, backgroundColor: '#EDF2F7', alignItems: 'center', justifyContent: 'center' },
  numOn: { backgroundColor: '#48BB78' },
  numTxt: { fontSize: 16, fontWeight: '600', color: '#718096' }, numTxtOn: { color: 'white' },
  lbls: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 40 },
  lo: { fontSize: 13, color: '#A0AEC0' },
  journal: { backgroundColor: 'white', borderRadius: 16, padding: 16, minHeight: 140, fontSize: 16, color: '#2D3748', borderWidth: 1, borderColor: '#E2E8F0', marginBottom: 32, lineHeight: 24 },
  nav: { flexDirection: 'row', gap: 12 },
  back: { paddingVertical: 14, paddingHorizontal: 20, borderRadius: 12, backgroundColor: '#EDF2F7' },
  backTxt: { fontSize: 16, fontWeight: '600', color: '#718096' },
  next: { flex: 1, paddingVertical: 16, borderRadius: 12, backgroundColor: '#48BB78', alignItems: 'center' },
  nextOff: { backgroundColor: '#A0AEC0' }, nextTxt: { fontSize: 17, fontWeight: '700', color: 'white' },
});
EOF

# app/(tabs)/journal.tsx
cat > "app/(tabs)/journal.tsx" << 'EOF'
import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, Alert } from 'react-native';
import { supabase } from '@/lib/supabase';
import { useAppStore } from '@/store/useAppStore';

export default function JournalScreen() {
  const { user } = useAppStore();
  const [text, setText] = useState('');
  const [saving, setSaving] = useState(false);

  async function save() {
    if (!text.trim()) return;
    setSaving(true);
    const { error } = await supabase.from('journal_entries').insert({ user_id: user!.id, content: text.trim() });
    setSaving(false);
    if (error) { Alert.alert('Error', 'Could not save.'); return; }
    setText('');
    Alert.alert('Saved ✓', 'Sprout will remember that. 🌱');
  }

  return (
    <ScrollView style={s.container} contentContainerStyle={s.content} keyboardDismissMode="on-drag">
      <Text style={s.title}>📓 Journal</Text>
      <Text style={s.sub}>Write anything. This is just for you and Sprout.</Text>
      <TextInput style={s.input} multiline placeholder="What's on your mind today..." placeholderTextColor="#A0AEC0" value={text} onChangeText={setText} textAlignVertical="top" />
      <TouchableOpacity style={[s.btn, saving && s.btnOff]} onPress={save} disabled={saving}>
        <Text style={s.btnTxt}>{saving ? 'Saving...' : 'Save entry'}</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FAFAF8' }, content: { padding: 24, paddingTop: 60, paddingBottom: 40 },
  title: { fontSize: 28, fontWeight: '800', color: '#2D3748', marginBottom: 4 },
  sub: { fontSize: 15, color: '#718096', marginBottom: 24, lineHeight: 22 },
  input: { backgroundColor: 'white', borderRadius: 16, padding: 16, minHeight: 200, fontSize: 16, color: '#2D3748', borderWidth: 1, borderColor: '#E2E8F0', lineHeight: 24, marginBottom: 20 },
  btn: { backgroundColor: '#48BB78', borderRadius: 12, padding: 18, alignItems: 'center' },
  btnOff: { backgroundColor: '#A0AEC0' }, btnTxt: { color: 'white', fontSize: 17, fontWeight: '700' },
});
EOF

# app/(tabs)/progress.tsx
cat > "app/(tabs)/progress.tsx" << 'EOF'
import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useCompanion } from '@/hooks/useCompanion';

export default function ProgressScreen() {
  const { companion } = useCompanion();
  if (!companion) return null;
  const milestones = [1, 3, 7, 14, 30, 60, 90];
  return (
    <ScrollView style={s.container} contentContainerStyle={s.content}>
      <Text style={s.title}>📊 Progress</Text>
      <View style={s.card}><Text style={s.lbl}>Current Streak</Text><Text style={s.big}>{companion.streak} 🔥</Text><Text style={s.sub}>Best: {companion.longestStreak} days</Text></View>
      <View style={s.card}><Text style={s.lbl}>Companion Level</Text><Text style={s.big}>Lv {companion.level} 🌱</Text><Text style={s.sub}>{companion.xp % 100}/100 XP</Text></View>
      <Text style={s.sectionLbl}>Milestones</Text>
      <View style={s.ms}>
        {milestones.map((m) => (
          <View key={m} style={[s.m, companion.longestStreak >= m && s.mOn]}>
            <Text style={s.mNum}>{m}</Text><Text style={s.mDay}>days</Text>
          </View>
        ))}
      </View>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FAFAF8' }, content: { padding: 24, paddingTop: 60, paddingBottom: 40 },
  title: { fontSize: 28, fontWeight: '800', color: '#2D3748', marginBottom: 20 },
  card: { backgroundColor: 'white', borderRadius: 16, padding: 20, marginBottom: 16, alignItems: 'center', shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.05, shadowRadius: 8, elevation: 2 },
  lbl: { fontSize: 13, color: '#718096', fontWeight: '600', textTransform: 'uppercase', letterSpacing: 0.5 },
  big: { fontSize: 48, fontWeight: '800', color: '#2D3748', marginVertical: 4 },
  sub: { fontSize: 13, color: '#A0AEC0' },
  sectionLbl: { fontSize: 13, fontWeight: '700', color: '#A0AEC0', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 12, marginTop: 8 },
  ms: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  m: { width: 72, height: 72, borderRadius: 36, backgroundColor: '#EDF2F7', alignItems: 'center', justifyContent: 'center' },
  mOn: { backgroundColor: '#48BB78' },
  mNum: { fontSize: 20, fontWeight: '800', color: '#2D3748' }, mDay: { fontSize: 10, color: '#718096' },
});
EOF

# app/(tabs)/support.tsx
cat > "app/(tabs)/support.tsx" << 'EOF'
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Linking } from 'react-native';
import { CRISIS_RESOURCES } from '@/constants/safety';

export default function SupportScreen() {
  return (
    <ScrollView style={s.container} contentContainerStyle={s.content}>
      <Text style={s.title}>🆘 Support</Text>
      <Text style={s.sub}>You don't have to do this alone.</Text>
      <Text style={s.lbl}>Crisis Resources</Text>
      {CRISIS_RESOURCES.map((r) => (
        <TouchableOpacity key={r.number} style={s.card} onPress={() => Linking.openURL(r.isSms ? `sms:${r.number}` : `tel:${r.number}`)}>
          <Text style={s.cardTitle}>{r.label}</Text>
          <Text style={s.cardDesc}>{r.description}</Text>
          <Text style={s.cta}>{r.isSms ? 'Send text →' : 'Call now →'}</Text>
        </TouchableOpacity>
      ))}
      <Text style={s.disc}>Sprout is not a medical provider or crisis service. In an emergency, call 911.</Text>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FAFAF8' }, content: { padding: 24, paddingTop: 60, paddingBottom: 40 },
  title: { fontSize: 28, fontWeight: '800', color: '#2D3748', marginBottom: 4 },
  sub: { fontSize: 15, color: '#718096', marginBottom: 24 },
  lbl: { fontSize: 13, fontWeight: '700', color: '#A0AEC0', textTransform: 'uppercase', letterSpacing: 1, marginBottom: 12 },
  card: { backgroundColor: 'white', borderRadius: 16, padding: 18, marginBottom: 12, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.05, shadowRadius: 8, elevation: 2 },
  cardTitle: { fontSize: 16, fontWeight: '700', color: '#2D3748', marginBottom: 4 },
  cardDesc: { fontSize: 14, color: '#718096', lineHeight: 20, marginBottom: 8 },
  cta: { fontSize: 14, fontWeight: '600', color: '#48BB78' },
  disc: { fontSize: 12, color: '#A0AEC0', textAlign: 'center', lineHeight: 18, marginTop: 16 },
});
EOF

# app/task/[id].tsx
cat > "app/task/[id].tsx" << 'EOF'
import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import * as Haptics from 'expo-haptics';
import { supabase } from '@/lib/supabase';
import { SafetyBanner } from '@/components/ui/SafetyBanner';
import type { AICheckInResponse } from '@/types';

export default function TaskScreen() {
  const { id, aiResult } = useLocalSearchParams<{ id: string; aiResult: string }>();
  const [done, setDone] = useState(false);
  const result: AICheckInResponse | null = aiResult ? JSON.parse(aiResult) : null;

  async function complete() {
    await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    if (id && id !== 'new') {
      await supabase.from('daily_tasks').update({ status: 'completed', completed_at: new Date().toISOString() }).eq('id', id);
    }
    setDone(true);
  }

  if (!result) return <View style={s.center}><Text>Loading...</Text></View>;

  const { risk_level, emotional_summary, recommended_micro_task: task, companion_message, safety_action } = result;

  return (
    <ScrollView style={s.container} contentContainerStyle={s.content}>
      {(risk_level === 'high' || risk_level === 'crisis') && safety_action?.needed && (
        <SafetyBanner riskLevel={risk_level} message={safety_action.message} recommendedStep={safety_action.recommended_next_step} />
      )}
      <View style={s.bubble}>
        <Text style={s.bEmoji}>🌱</Text>
        <Text style={s.bTxt}>{companion_message}</Text>
      </View>
      <Text style={s.summary}>{emotional_summary}</Text>
      <View style={s.taskCard}>
        <Text style={s.taskTitle}>{task.title}</Text>
        <Text style={s.taskDesc}>{task.description}</Text>
        <Text style={s.taskMeta}>⏱ ~{task.estimated_minutes} min · {task.difficulty}</Text>
        {task.reason && <Text style={s.taskReason}>💡 {task.reason}</Text>}
      </View>
      {!done ? (
        <TouchableOpacity style={s.btn} onPress={complete}>
          <Text style={s.btnTxt}>I did it! ✓</Text>
        </TouchableOpacity>
      ) : (
        <View style={s.celebrate}>
          <Text style={s.celebEmoji}>🎉</Text>
          <Text style={s.celebTxt}>Sprout is growing stronger because you showed up.</Text>
          <TouchableOpacity style={s.homeBtn} onPress={() => router.replace('/(tabs)')}>
            <Text style={s.homeBtnTxt}>Back to Sprout</Text>
          </TouchableOpacity>
        </View>
      )}
    </ScrollView>
  );
}

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FAFAF8' }, content: { padding: 24, paddingTop: 60, paddingBottom: 40 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  bubble: { backgroundColor: '#F0FFF4', borderRadius: 20, padding: 20, alignItems: 'center', marginBottom: 20, borderWidth: 1, borderColor: '#C6F6D5' },
  bEmoji: { fontSize: 40, marginBottom: 8 }, bTxt: { fontSize: 16, color: '#276749', textAlign: 'center', lineHeight: 24, fontWeight: '500' },
  summary: { fontSize: 15, color: '#4A5568', lineHeight: 22, marginBottom: 24, textAlign: 'center' },
  taskCard: { backgroundColor: 'white', borderRadius: 16, padding: 20, marginBottom: 24, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.06, shadowRadius: 8, elevation: 2 },
  taskTitle: { fontSize: 20, fontWeight: '700', color: '#2D3748', marginBottom: 8 },
  taskDesc: { fontSize: 15, color: '#4A5568', lineHeight: 22, marginBottom: 12 },
  taskMeta: { fontSize: 13, color: '#718096', marginBottom: 8 },
  taskReason: { fontSize: 13, color: '#718096', fontStyle: 'italic', lineHeight: 18 },
  btn: { backgroundColor: '#48BB78', borderRadius: 16, padding: 20, alignItems: 'center' },
  btnTxt: { color: 'white', fontSize: 19, fontWeight: '800' },
  celebrate: { alignItems: 'center', padding: 20 },
  celebEmoji: { fontSize: 64, marginBottom: 16 },
  celebTxt: { fontSize: 16, color: '#2D3748', textAlign: 'center', lineHeight: 24, marginBottom: 24, fontWeight: '500' },
  homeBtn: { backgroundColor: '#2D3748', borderRadius: 12, paddingVertical: 14, paddingHorizontal: 32 },
  homeBtnTxt: { color: 'white', fontSize: 16, fontWeight: '700' },
});
EOF

ok "All source files written"

# ── 7. Supabase files ────────────────────────────────────────
step "Writing Supabase files"

mkdir -p ../supabase/functions/analyze-checkin ../supabase/migrations

cat > ../supabase/migrations/001_initial_schema.sql << 'EOF'
create extension if not exists vector;

create table public.users (
  id uuid references auth.users(id) on delete cascade primary key,
  display_name text not null default 'Friend',
  recovery_start_date date, dependency_type text,
  timezone text default 'UTC', created_at timestamptz default now()
);

create table public.companions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null unique,
  name text not null default 'Sprout', species text not null default 'seedling',
  health int not null default 70 check (health between 0 and 100),
  happiness int not null default 70 check (happiness between 0 and 100),
  energy int not null default 70 check (energy between 0 and 100),
  trust int not null default 50 check (trust between 0 and 100),
  level int not null default 1, xp int not null default 0,
  streak int not null default 0, longest_streak int not null default 0,
  mood_state text not null default 'calm'
    check (mood_state in ('happy','calm','tired','worried','proud','sick','encouraged')),
  last_message text, last_interaction_at timestamptz,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table public.check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  mood_score int not null check (mood_score between 1 and 10),
  craving_level int not null check (craving_level between 1 and 10),
  stress_level int not null check (stress_level between 1 and 10),
  sleep_quality int not null check (sleep_quality between 1 and 10),
  journal_text text, ai_risk_level text check (ai_risk_level in ('low','medium','high','crisis')),
  ai_emotional_summary text, ai_companion_message text, ai_raw_response jsonb,
  created_at timestamptz default now()
);

create table public.daily_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  check_in_id uuid references public.check_ins(id),
  title text not null, description text not null,
  estimated_minutes int default 5,
  difficulty text check (difficulty in ('easy','medium','hard')) default 'easy',
  reason text, source text default 'ai',
  status text default 'pending' check (status in ('pending','completed','skipped')),
  scheduled_for date default current_date, completed_at timestamptz,
  created_at timestamptz default now()
);

create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  content text not null, ai_triggers text[], ai_emotions text[],
  ai_coping_strategies text[], embedding vector(1536),
  created_at timestamptz default now()
);

create table public.support_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  name text not null, relationship text, phone text,
  is_primary boolean default false, created_at timestamptz default now()
);

create table public.companion_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  event_type text not null, payload jsonb, seen boolean default false,
  created_at timestamptz default now()
);

alter table public.users enable row level security;
alter table public.companions enable row level security;
alter table public.check_ins enable row level security;
alter table public.daily_tasks enable row level security;
alter table public.journal_entries enable row level security;
alter table public.support_contacts enable row level security;
alter table public.companion_events enable row level security;

create policy "own" on public.users for all using (auth.uid() = id);
create policy "own" on public.companions for all using (auth.uid() = user_id);
create policy "own" on public.check_ins for all using (auth.uid() = user_id);
create policy "own" on public.daily_tasks for all using (auth.uid() = user_id);
create policy "own" on public.journal_entries for all using (auth.uid() = user_id);
create policy "own" on public.support_contacts for all using (auth.uid() = user_id);
create policy "own" on public.companion_events for all using (auth.uid() = user_id);

create or replace function public.handle_new_user() returns trigger as $$
begin
  insert into public.users (id) values (new.id);
  insert into public.companions (user_id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create index on public.check_ins(user_id, created_at desc);
create index on public.daily_tasks(user_id, scheduled_for);
EOF

cat > ../supabase/functions/analyze-checkin/index.ts << 'EOF'
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.24.0";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

const SYSTEM = `You are Sprout's inner voice — warm, non-judgmental, supporting recovery.
Analyze the check-in and return ONLY valid JSON, no markdown, no preamble.

Risk: low=mood>=6+craving<=4, medium=mood4-5 OR craving5-7, high=mood<=3 OR craving>=8, crisis=self-harm/overdose/suicidal.
If high/crisis: safety_action.needed=true, recommend 988 or SAMHSA 1-800-662-4357 or 911.
Never shame. Never diagnose. Never give medical advice. Tasks must be tiny (2-15 min).

Return exactly:
{"risk_level":"low|medium|high|crisis","emotional_summary":"2-3 sentences.","recommended_micro_task":{"title":"","description":"","estimated_minutes":5,"difficulty":"easy|medium|hard","reason":""},"companion_message":"1-3 sentences from Sprout.","companion_stat_changes":{"health":0,"happiness":0,"energy":0,"trust":0},"safety_action":{"needed":false,"message":"","recommended_next_step":""}}`;

const clamp = (v: number) => Math.min(100, Math.max(0, v));

serve(async (req) => {
  const auth = req.headers.get("Authorization");
  if (!auth) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });

  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: auth } } });
  const { data: { user }, error } = await sb.auth.getUser();
  if (error || !user) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });

  const body = await req.json();
  const { mood_score, craving_level, stress_level, sleep_quality, journal_text, check_in_id } = body;

  const { data: comp } = await sb.from("companions").select("streak,health,happiness,energy,trust,xp,level").eq("user_id", user.id).single();
  const { data: past } = await sb.from("daily_tasks").select("title").eq("user_id", user.id).eq("status", "completed").order("completed_at", { ascending: false }).limit(5);

  const msg = JSON.stringify({ mood_score, craving_level, stress_level, sleep_quality, journal_text: journal_text ?? null, streak_days: comp?.streak ?? 0, past_successful_tasks: past?.map((t: any) => t.title) ?? [] });

  const ai = await anthropic.messages.create({ model: "claude-sonnet-4-20250514", max_tokens: 1024, system: SYSTEM, messages: [{ role: "user", content: msg }] });
  const raw = ai.content[0].type === "text" ? ai.content[0].text : "";

  let parsed: any;
  try { parsed = JSON.parse(raw); }
  catch { return new Response(JSON.stringify({ error: "parse failed", raw }), { status: 500 }); }

  if (check_in_id) {
    await sb.from("check_ins").update({ ai_risk_level: parsed.risk_level, ai_emotional_summary: parsed.emotional_summary, ai_companion_message: parsed.companion_message, ai_raw_response: parsed }).eq("id", check_in_id).eq("user_id", user.id);
  }

  if (comp) {
    const sc = parsed.companion_stat_changes;
    const xp = comp.xp + 10;
    const lvl = Math.floor(xp / 100) + 1;
    const mood = parsed.risk_level === "crisis" || parsed.risk_level === "high" ? "worried" : sc.happiness >= 5 ? "happy" : sc.trust >= 3 ? "encouraged" : sc.energy < 0 ? "tired" : "calm";
    await sb.from("companions").update({ health: clamp(comp.health + sc.health), happiness: clamp(comp.happiness + sc.happiness), energy: clamp(comp.energy + sc.energy), trust: clamp(comp.trust + sc.trust), xp, level: lvl, mood_state: mood, last_message: parsed.companion_message, last_interaction_at: new Date().toISOString(), updated_at: new Date().toISOString() }).eq("user_id", user.id);
    if (lvl > comp.level) await sb.from("companion_events").insert({ user_id: user.id, event_type: "level_up", payload: { new_level: lvl } });
  }

  const task = parsed.recommended_micro_task;
  const { data: newTask } = await sb.from("daily_tasks").insert({ user_id: user.id, check_in_id: check_in_id ?? null, title: task.title, description: task.description, estimated_minutes: task.estimated_minutes, difficulty: task.difficulty, reason: task.reason, source: "ai", scheduled_for: new Date().toISOString().split("T")[0] }).select().single();

  return new Response(JSON.stringify({ ...parsed, task_id: newTask?.id }), { headers: { "Content-Type": "application/json" } });
});
EOF

ok "Supabase files written"

# ── 8. Git commit ────────────────────────────────────────────
step "Git commit"
cd ..

cat > .gitignore << 'EOF'
node_modules/
.expo/
dist/
.env
*.local
.DS_Store
EOF

git add -A
git commit -m "feat: full Sprout MVP scaffold"

# ── Done ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Done! Sprout is ready.${NC}"
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Create project at https://supabase.com"
echo "   Copy URL + anon key into sprout/mobile/.env"
echo ""
echo "2. Paste supabase/migrations/001_initial_schema.sql"
echo "   into Supabase Dashboard > SQL Editor > Run"
echo ""
echo "3. Supabase Dashboard > Edge Functions > Secrets"
echo "   Add: ANTHROPIC_API_KEY = sk-ant-..."
echo ""
echo "4. Deploy edge function:"
echo "   supabase login"
echo "   supabase link --project-ref YOUR_PROJECT_REF"
echo "   supabase functions deploy analyze-checkin"
echo ""
echo "5. Start dev server:"
echo "   cd sprout/mobile && npx expo start"
echo ""
echo "6. Push to GitHub:"
echo "   git remote add origin YOUR_REPO_URL"
echo "   git push -u origin main"
