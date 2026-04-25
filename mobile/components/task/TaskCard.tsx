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
