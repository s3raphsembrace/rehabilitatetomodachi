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
