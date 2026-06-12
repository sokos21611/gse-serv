# WORK_IN_PROGRESS — Supabase 백엔드 도입

마지막 업데이트: 2026-05-11

## 현재 상태

- **Supabase로 백엔드 전환** (이전: localStorage). 프로젝트 `gse-serv`, URL `https://wavussrzhqzyircqpaiw.supabase.co`, region Singapore, 무료 티어.
- 4개 페이지(index/report/status/admin) 모두 `lib/supabase.js`를 import해서 데이터 R/W. ES module 기반.
- `migrate.html` — 기존 브라우저의 localStorage 데이터를 Supabase로 1회 이관하는 유틸.

## 사용자(운영자)가 1회 해야 할 것

1. **SQL Editor에서 `supabase/schema.sql` 실행** — 테이블/시퀀스/RLS/시드까지 한 번에. 멱등이라 재실행 안전.
2. (선택) `migrate.html` 열어 기존 localStorage 데이터 이관 후 "localStorage 초기화" 버튼.
3. 정적 서버로 띄워 동작 확인 (`python -m http.server`).

## 미해결 / 다음 차례

### 우선순위 ↓

- **관리자 인증 게이트**: 현재 `admin.html`은 누구나 접근/상태변경 가능. Supabase Auth 매직 링크 + 화이트리스트 이메일 또는 단순 PIN 게이트 도입 필요. RLS 정책도 `authenticated`로 좁혀야 함.
- **Realtime 구독**: `status.html`/`admin.html`에 `supabase.channel().on('postgres_changes', ...)` 도입하면 다중 사용자 실시간 동기화 가능. 지금은 페이지 로드 시점 스냅샷.
- **assets.reports 자동 카운트**: 현재 정적 컬럼. 트리거로 신고 생성/삭제 시 자동 증감 가능.
- **디자인 토큰 중복**: `:root { --primary ... }` 와 `.bottom-nav`가 4개 HTML에 복붙. 공유 CSS로 빼면 유지보수 비용 절감.
- **GitHub/Vercel 새 계정 이전**: 이전 origin(`dearsokos/gse-chongmu`)은 404 — 새 계정에 레포 생성 후 `git remote set-url origin <새 URL>` → `git push -u origin main`. Vercel은 새 계정에서 해당 레포 Import (정적 사이트라 빌드 설정 불필요, Framework Preset: Other). `.vercel/`은 git 추적 해제됨 — 새 계정에서 `vercel link` 시 자동 재생성.
- **QR 딥링크 도메인 주의**: 이미 인쇄/배포된 QR 코드가 있다면 이전 Vercel 도메인을 가리킴. 새 배포 도메인이 달라지면 기존 QR 전부 재발급 필요 (또는 커스텀 도메인으로 통일).

### 해결됨

- ~~localStorage 데이터 휘발/브라우저 격리 문제~~ → Supabase 도입.
- ~~신고 ID 충돌 (`reports.length+1`)~~ → PostgreSQL sequence + `next_report_id()`.
- ~~자산 데이터 두 계보 (index/admin DEFAULT_ASSETS 중복)~~ → DB 단일 시드.

## 참고 파일

- `CLAUDE.md` — 프로젝트 컨텍스트.
- `lib/supabase.js` — Supabase 클라이언트 + CRUD 헬퍼.
- `supabase/schema.sql` — DB 스키마 + RLS + 시드.
- `migrate.html` — localStorage → Supabase 1회 이관.
- `index.html` / `report.html` / `status.html` / `admin.html` — 페이지 4개.
