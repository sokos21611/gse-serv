-- ============================================================
-- gse-serv (총무 서비스) Supabase schema
-- Apply once via Supabase Dashboard → SQL Editor → New query → Run.
-- Re-running is safe: every block uses IF NOT EXISTS / DROP IF EXISTS.
-- ============================================================

-- ── Sequences (auto-generate human-readable codes) ───────────
CREATE SEQUENCE IF NOT EXISTS reports_seq START 1;
CREATE SEQUENCE IF NOT EXISTS assets_seq  START 9;  -- 시드 A001~A008 다음부터

-- ── Helper: next_report_id() / next_asset_id() ───────────────
CREATE OR REPLACE FUNCTION next_report_id() RETURNS TEXT
  LANGUAGE SQL VOLATILE
  AS $$ SELECT 'RPT-' || lpad(nextval('reports_seq')::text, 3, '0'); $$;

CREATE OR REPLACE FUNCTION next_asset_id() RETURNS TEXT
  LANGUAGE SQL VOLATILE
  AS $$ SELECT 'A'   || lpad(nextval('assets_seq')::text,  3, '0'); $$;

-- ── assets ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assets (
  id          TEXT PRIMARY KEY DEFAULT next_asset_id(),
  type        TEXT,
  category    TEXT,
  name        TEXT NOT NULL,
  model       TEXT,
  location    TEXT,
  installed   TEXT,
  reports     INTEGER NOT NULL DEFAULT 0,
  emoji       TEXT,
  manager     TEXT,
  memo        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── reports ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id           TEXT PRIMARY KEY DEFAULT next_report_id(),
  title        TEXT NOT NULL,
  category     TEXT NOT NULL,
  location     TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT '접수'
                 CHECK (status IN ('접수','처리중','완료')),
  date         DATE NOT NULL DEFAULT (now() AT TIME ZONE 'Asia/Seoul')::date,
  asset_id     TEXT REFERENCES assets(id) ON DELETE SET NULL,
  description  TEXT,
  anonymous    BOOLEAN NOT NULL DEFAULT false,
  timeline     JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS reports_status_idx   ON reports(status);
CREATE INDEX IF NOT EXISTS reports_asset_id_idx ON reports(asset_id);
CREATE INDEX IF NOT EXISTS reports_date_idx     ON reports(date DESC);

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER
  LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

DROP TRIGGER IF EXISTS reports_set_updated_at ON reports;
CREATE TRIGGER reports_set_updated_at
  BEFORE UPDATE ON reports
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Row Level Security ───────────────────────────────────────
-- 1차: 사내 익명 운영. anon/authenticated 모두 R/W 허용.
-- 관리자 게이트 도입 시 UPDATE/DELETE 정책을 authenticated로 좁힐 것.
ALTER TABLE assets  ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS assets_all  ON assets;
DROP POLICY IF EXISTS reports_all ON reports;

CREATE POLICY assets_all  ON assets  FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY reports_all ON reports FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- ── Seed assets (A001~A008) — 멱등 ───────────────────────────
INSERT INTO assets (id, type, name, model, location, installed, reports, emoji) VALUES
  ('A001','projector','B동 3층 회의실 프로젝터','Epson EB-2265U','B동 3층 회의실','2023.06',4,'📽️'),
  ('A002','printer',  'B동 4층 복합기',         'HP LaserJet M634','B동 4층',       '2024.01',2,'🖨️'),
  ('A003','restroom', 'A동 2층 남자화장실',     '',                'A동 2층',        '',       3,'🚻'),
  ('A004','room',     'B동 3층 회의실 2',       '10인실',          'B동 3층',        '2022.03',5,'🏢'),
  ('A005','parking',  '주차장 1층 게이트',       'ParkPlus G300',   '주차장 1층',     '2023.09',1,'🅿️'),
  ('A006','pantry',   'A동 5층 탕비실',         '',                'A동 5층',        '',       1,'☕'),
  ('A007','pantry',   '전자동 커피머신A',        'Jura GIGA X8c',   '37층 타운홀',    '',       0,'☕'),
  ('A008','restroom', '38층 남자 화장실',       '',                '38층 남자 화장실','',       0,'🚻')
ON CONFLICT (id) DO NOTHING;

-- ── Seed dummy reports — 멱등 ────────────────────────────────
INSERT INTO reports (id, title, category, location, status, date, asset_id, description, anonymous, timeline) VALUES
  ('RPT-001','프로젝터 전원 안 됨','IT장비','B동 3층 회의실','처리중','2026-03-24','A001',
    '회의 중 프로젝터 전원이 갑자기 꺼짐', false,
    '[{"date":"2026-03-24 09:30","action":"접수","note":"신고 접수됨"},{"date":"2026-03-24 14:00","action":"처리중","note":"담당자 배정 (김기사)"}]'::jsonb),
  ('RPT-002','복합기 용지 걸림 반복','IT장비','B동 4층','접수','2026-03-23','A002',
    '용지 걸림이 하루 3-4회 반복', false,
    '[{"date":"2026-03-23 11:20","action":"접수","note":"신고 접수됨"}]'::jsonb),
  ('RPT-003','화장실 수도꼭지 누수','시설','A동 2층 남자화장실','완료','2026-03-20','A003',
    '세면대 오른쪽 수도꼭지에서 물이 계속 흘러나옴', true,
    '[{"date":"2026-03-20 08:00","action":"접수","note":"익명 신고 접수"},{"date":"2026-03-20 10:30","action":"처리중","note":"배관 점검 시작"},{"date":"2026-03-21 16:00","action":"완료","note":"수도꼭지 교체 완료"}]'::jsonb),
  ('RPT-004','냉방 온도 너무 낮음','환경','B동 3층 사무실','접수','2026-03-25',NULL,
    '오후 시간대 실내 온도가 18도 이하로 추움', false,
    '[{"date":"2026-03-25 08:45","action":"접수","note":"신고 접수됨"}]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 시드 ID 충돌 방지 — 다음 채번이 RPT-005부터 시작하도록
SELECT setval('reports_seq', GREATEST(4, (SELECT COALESCE(MAX(NULLIF(regexp_replace(id,'\D','','g'),'')::int), 0) FROM reports)));
SELECT setval('assets_seq',  GREATEST(8, (SELECT COALESCE(MAX(NULLIF(regexp_replace(id,'\D','','g'),'')::int), 0) FROM assets)));
