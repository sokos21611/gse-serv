# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트

사내 불편사항 신고 + 자산 관리 (한국어, 모바일 웹 `max-width: 430px`). Vercel 프로젝트명은 `chongmu-service`.

## 빌드/실행

빌드 단계, 패키지 매니저, 테스트 스위트, lint 설정 없음. 정적 HTML + ES module `<script type="module">`. 로컬 확인은 정적 서버 필수 (`python -m http.server` 등) — `file://`로 열면 ES module CORS 차단으로 동작 안 함.

## 아키텍처

### Supabase가 백엔드

- 프로젝트 URL: `https://qujeakbaqqeqyllpdene.supabase.co`
- 클라이언트 키 (publishable): `lib/supabase.js`에 인라인. anon 권한 + RLS로 보호.
- 모든 페이지가 `lib/supabase.js`의 헬퍼(`listReports`, `createReport`, `listAssets`, `createAsset`, …)를 import해서 사용.
- 더 이상 localStorage에 *데이터*를 저장하지 않음 (브라우저별 격리 문제 해소). 단 기기 단위 개인화 키 2개는 localStorage 사용: `gs_my_report_ids`(내가 접수한 신고 ID, status.html "내 신고만" 필터), `gs_fav_reports`(자주 쓰는 신고 콤보, index.html 즐겨찾기 카드).

### 스키마 (`supabase/schema.sql`)

| 테이블 | 키 컬럼 | 비고 |
|---|---|---|
| `assets` | `id TEXT` PK (DEFAULT `next_asset_id()`) | id 형식 `A001`. 시드 A001~A008. `type/category/name/model/location/installed/reports/emoji/manager/memo` |
| `reports` | `id TEXT` PK (DEFAULT `next_report_id()`) | id 형식 `RPT-001`. `status` CHECK(`접수/처리중/완료`). `timeline JSONB`. `asset_id` → `assets(id)` (ON DELETE SET NULL) |

- 채번은 PostgreSQL sequence(`reports_seq`, `assets_seq`) — 클라이언트가 ID 생성하지 않음. INSERT 시 id 빼면 자동 생성.
- 신고 ID 충돌(이전 `reports.length+1` 방식) 문제는 sequence로 해결됨.
- 스키마 변경 시: `supabase/schema.sql` 수정 → SQL Editor에서 재실행. 모든 블록이 `IF NOT EXISTS` / `ON CONFLICT DO NOTHING`이라 멱등.

### RLS 정책

현재 `assets`/`reports` 모두 anon+authenticated에 R/W 전체 허용 (`USING true`). 사내 익명 운영 가정. 관리자 게이트(이메일 매직 링크 등) 도입 시 `reports` UPDATE/`assets` 전체를 `authenticated`로 좁힐 것.

### 각 HTML은 self-contained (UI 측면)

공유 CSS 파일이 없다. `:root { --primary ... }` CSS 변수 블록과 하단 `.bottom-nav`가 파일마다 복붙되어 있어 **디자인 토큰/네비 변경은 전 페이지 동시 수정 필요**.

JS는 `lib/supabase.js` 한 곳에서 공유. `admin.html`만 추가로 SheetJS CDN 의존 (엑셀 업로드용).

### report.html URL 파라미터 계약

- `?qr=1&name=&model=&loc=&emoji=&aid=&cat=` — QR 스캔 경로. URL에 자산 정보가 모두 들어있어 DB 조회 없이 동작. `cat`이 주어지면 step 1 건너뛰고 step 2부터, QR hero 카드 표시.
- `?type=X&id=Y` — 자산 연결 (Supabase `getAsset(id)` 조회 → 카테고리 자동 추론).
- `?category=facility|environment|it|cleaning|parking|other` — 카테고리 프리셀렉트.
- `?category=X&sub=유형&loc=위치` — 즐겨찾기 딥링크. `sub`가 해당 카테고리의 유효한 세부 유형이면 위치까지 채우고 step 3(상세 입력)으로 바로 진입.
- `?anon=true` — 익명 모드 프리셀렉트.

### 기타 주의

- **인라인 onclick 호환**: ES module scope의 함수/state는 글로벌이 아니므로, inline `onclick`/`oninput`이 참조하는 식별자는 `window.foo = foo`로 노출해줘야 한다. 현재 `state`(report), `closeModal`(admin/status), `render`/`select*`/`submitReport`(report)가 그렇게 노출돼 있음.
- **QR 관리 UI 부재**: `qr.html`은 삭제됐고 `admin.html`의 QR관리 버튼도 제거됨. QR 진입은 `report.html?qr=1&...` 딥링크로만 이루어짐. 관리자용 QR 발급/관리 화면이 필요해지면 `admin.html` 내부 모달 또는 별도 페이지로 신규 구현 필요.
- **`migrate.html`**: 1회용 유틸. 기존 브라우저 localStorage(`gs_assets`/`gs_reports`)를 Supabase로 이관. 사내 배포 후엔 사용자 네비에서 숨겨도 무방.
