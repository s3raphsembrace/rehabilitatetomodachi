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
