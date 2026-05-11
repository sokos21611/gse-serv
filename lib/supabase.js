// Supabase client + CRUD helpers (ES module, browser-native).
// Static HTML 환경이라 URL/키를 인라인. publishable key는 anon 권한 + RLS로 보호됨.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = 'https://wavussrzhqzyircqpaiw.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_YeDia1ceIFRU5IKDXiIu0g_NE98Iq7V';

export const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: { persistSession: false }, // 익명 운영 — 세션 저장 불필요
});

// ── helpers ──────────────────────────────────────────────────
function ymdSeoul(d = new Date()) {
  // KST(Asia/Seoul) 기준 YYYY-MM-DD
  return new Date(d.getTime() + 9 * 3600 * 1000).toISOString().slice(0, 10);
}
function hmSeoul(d = new Date()) {
  return new Date(d.getTime() + 9 * 3600 * 1000).toISOString().slice(11, 16);
}

// ── reports ──────────────────────────────────────────────────
export async function listReports() {
  const { data, error } = await supabase
    .from('reports')
    .select('*')
    .order('date', { ascending: false })
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data || [];
}

export async function getReport(id) {
  const { data, error } = await supabase.from('reports').select('*').eq('id', id).maybeSingle();
  if (error) throw error;
  return data;
}

export async function createReport({ title, category, location, asset_id, description, anonymous }) {
  const date = ymdSeoul();
  const time = hmSeoul();
  const timeline = [{ date: `${date} ${time}`, action: '접수', note: anonymous ? '익명 신고 접수됨' : '신고 접수됨' }];
  const { data, error } = await supabase
    .from('reports')
    .insert({ title, category, location, asset_id: asset_id || null, description, anonymous, timeline, date })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function updateReportStatus(id, newStatus) {
  const cur = await getReport(id);
  if (!cur || cur.status === newStatus) return cur;
  const date = ymdSeoul();
  const time = hmSeoul();
  const timeline = [...(cur.timeline || []), { date: `${date} ${time}`, action: newStatus, note: `상태 변경: ${newStatus}` }];
  const { data, error } = await supabase
    .from('reports')
    .update({ status: newStatus, timeline })
    .eq('id', id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

// ── assets ───────────────────────────────────────────────────
export async function listAssets() {
  const { data, error } = await supabase.from('assets').select('*').order('id');
  if (error) throw error;
  return data || [];
}

export async function getAsset(id) {
  const { data, error } = await supabase.from('assets').select('*').eq('id', id).maybeSingle();
  if (error) throw error;
  return data;
}

export async function createAsset(asset) {
  // id 비우면 DB가 next_asset_id()로 자동 채번
  const payload = { ...asset };
  if (!payload.id) delete payload.id;
  const { data, error } = await supabase.from('assets').insert(payload).select().single();
  if (error) throw error;
  return data;
}

export async function bulkCreateAssets(assets) {
  // id가 빈 항목은 제거 (DB 채번)
  const payload = assets.map(a => {
    const x = { ...a };
    if (!x.id) delete x.id;
    return x;
  });
  const { data, error } = await supabase.from('assets').insert(payload).select();
  if (error) throw error;
  return data || [];
}
