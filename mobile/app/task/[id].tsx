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
