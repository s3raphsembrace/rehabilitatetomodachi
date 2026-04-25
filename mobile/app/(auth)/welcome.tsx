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
