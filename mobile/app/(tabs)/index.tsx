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
