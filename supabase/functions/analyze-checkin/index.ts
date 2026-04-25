import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.24.0";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

const SYSTEM = `You are Sprout's inner voice — warm, non-judgmental, supporting recovery.
Analyze the check-in and return ONLY valid JSON, no markdown, no preamble.

Risk: low=mood>=6+craving<=4, medium=mood4-5 OR craving5-7, high=mood<=3 OR craving>=8, crisis=self-harm/overdose/suicidal.
If high/crisis: safety_action.needed=true, recommend 988 or SAMHSA 1-800-662-4357 or 911.
Never shame. Never diagnose. Never give medical advice. Tasks must be tiny (2-15 min).

Return exactly:
{"risk_level":"low|medium|high|crisis","emotional_summary":"2-3 sentences.","recommended_micro_task":{"title":"","description":"","estimated_minutes":5,"difficulty":"easy|medium|hard","reason":""},"companion_message":"1-3 sentences from Sprout.","companion_stat_changes":{"health":0,"happiness":0,"energy":0,"trust":0},"safety_action":{"needed":false,"message":"","recommended_next_step":""}}`;

const clamp = (v: number) => Math.min(100, Math.max(0, v));

serve(async (req) => {
  const auth = req.headers.get("Authorization");
  if (!auth) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });

  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: auth } } });
  const { data: { user }, error } = await sb.auth.getUser();
  if (error || !user) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });

  const body = await req.json();
  const { mood_score, craving_level, stress_level, sleep_quality, journal_text, check_in_id } = body;

  const { data: comp } = await sb.from("companions").select("streak,health,happiness,energy,trust,xp,level").eq("user_id", user.id).single();
  const { data: past } = await sb.from("daily_tasks").select("title").eq("user_id", user.id).eq("status", "completed").order("completed_at", { ascending: false }).limit(5);

  const msg = JSON.stringify({ mood_score, craving_level, stress_level, sleep_quality, journal_text: journal_text ?? null, streak_days: comp?.streak ?? 0, past_successful_tasks: past?.map((t: any) => t.title) ?? [] });

  const ai = await anthropic.messages.create({ model: "claude-sonnet-4-20250514", max_tokens: 1024, system: SYSTEM, messages: [{ role: "user", content: msg }] });
  const raw = ai.content[0].type === "text" ? ai.content[0].text : "";

  let parsed: any;
  try { parsed = JSON.parse(raw); }
  catch { return new Response(JSON.stringify({ error: "parse failed", raw }), { status: 500 }); }

  if (check_in_id) {
    await sb.from("check_ins").update({ ai_risk_level: parsed.risk_level, ai_emotional_summary: parsed.emotional_summary, ai_companion_message: parsed.companion_message, ai_raw_response: parsed }).eq("id", check_in_id).eq("user_id", user.id);
  }

  if (comp) {
    const sc = parsed.companion_stat_changes;
    const xp = comp.xp + 10;
    const lvl = Math.floor(xp / 100) + 1;
    const mood = parsed.risk_level === "crisis" || parsed.risk_level === "high" ? "worried" : sc.happiness >= 5 ? "happy" : sc.trust >= 3 ? "encouraged" : sc.energy < 0 ? "tired" : "calm";
    await sb.from("companions").update({ health: clamp(comp.health + sc.health), happiness: clamp(comp.happiness + sc.happiness), energy: clamp(comp.energy + sc.energy), trust: clamp(comp.trust + sc.trust), xp, level: lvl, mood_state: mood, last_message: parsed.companion_message, last_interaction_at: new Date().toISOString(), updated_at: new Date().toISOString() }).eq("user_id", user.id);
    if (lvl > comp.level) await sb.from("companion_events").insert({ user_id: user.id, event_type: "level_up", payload: { new_level: lvl } });
  }

  const task = parsed.recommended_micro_task;
  const { data: newTask } = await sb.from("daily_tasks").insert({ user_id: user.id, check_in_id: check_in_id ?? null, title: task.title, description: task.description, estimated_minutes: task.estimated_minutes, difficulty: task.difficulty, reason: task.reason, source: "ai", scheduled_for: new Date().toISOString().split("T")[0] }).select().single();

  return new Response(JSON.stringify({ ...parsed, task_id: newTask?.id }), { headers: { "Content-Type": "application/json" } });
});
