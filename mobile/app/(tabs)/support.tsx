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
