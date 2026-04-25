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

type Key = typeof STEPS[number]['key'];

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
