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
