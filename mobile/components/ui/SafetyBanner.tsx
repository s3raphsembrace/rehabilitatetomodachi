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
