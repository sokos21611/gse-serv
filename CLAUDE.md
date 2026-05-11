# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트

사내 불편사항 신고 + 자산 관리 프로토타입 (한국어, 모바일 웹 `max-width: 430px`). Vercel 프로젝트명은 `chongmu-service`.

## 빌드/실행

빌드 단계, 패키지 매니저, 테스트 스위트, lint 설정 없음. 순수 정적 HTML + 인라인 `<script>`. 로컬 확인은 정적 서버로 (`python -m http.server` 등) — `file://`로 열면 localStorage가 페이지마다 분리되어 데이터가 공유되지 않음.

## 아키텍처

### 각 HTML은 self-contained

공유 JS/CSS 파일이 없다. `:root { --primary ... }` CSS 변수 블록과 하단 `.bottom-nav`가 파일마다 복붙되어 있어, **디자인 토큰/네비 변경은 전 페이지 동시 수정 필요**.

`admin.html`만 외부 CDN 의존 (SheetJS, 엑셀 업로드용).

### localStorage가 곧 백엔드

서버·API 없음. 페이지 간 통신은 localStorage + URL 쿼리 파라미터뿐.

| 키 | 내용 | 쓰는 곳 |
|---|---|---|
| `gs_reports` | 신고 배열 | index(seed) / report(추가) / status(읽기) / admin(상태변경) |
| `gs_assets` | 자산 배열 | index(seed) / admin(seed+CRUD) / report(참조) |
| `gs_assets_v` | 자산 스키마 버전 (현재 `'4'`) | index/admin 공통 |

### 자산 스키마 (단일 계보, v4 기준)

`index.html`의 `ASSETS`와 `admin.html`의 `DEFAULT_ASSETS`가 **동일한 데이터**로 시드됨 (A001~A008, `type` 포함). 두 파일 모두 `gs_assets_v !== '4'`일 때만 시드를 덮어쓰고, 등록·엑셀 업로드 후에는 `saveAssets()`(admin) 또는 `setItem('gs_assets_v','4')` 유지로 **리셋되지 않음**.

스키마를 다시 손대려면:
1. `ASSETS_VERSION` 상수를 `'4'`에서 다음 값으로 올리기 (index.html, admin.html 둘 다).
2. `ASSETS` / `DEFAULT_ASSETS` 시드 수정.
3. **버전을 올리면 사용자가 admin에서 등록한 자산도 리셋된다** — 데이터 보존이 필요하면 마이그레이션 함수 추가.

`type` 필드는 `report.html`의 `typeMap`(projector/printer→it, restroom/room/pantry→facility, parking→parking)에서 카테고리 추론에 사용.

### report.html URL 파라미터 계약

- `?qr=1&name=&model=&loc=&emoji=&aid=&cat=` — QR 스캔 경로. `cat`이 주어지면 step 1 건너뛰고 step 2부터, QR hero 카드 표시.
- `?type=X&id=Y` — 레거시 자산 연결 (localStorage 조회).
- `?category=facility|environment|it|cleaning|parking|other` — 카테고리 프리셀렉트.
- `?anon=true` — 익명 모드 프리셀렉트.

### 기타 주의

- **신고 ID**: `'RPT-' + (reports.length + 1).padStart(3,'0')`. 삭제 시 충돌 — 삭제 기능 추가하려면 ID 전략부터 바꿀 것.
- **QR 관리 UI 부재**: `qr.html`은 삭제됐고 `admin.html`의 QR관리 버튼도 제거됨. QR 진입은 `report.html?qr=1&...` 딥링크로만 이루어짐. 관리자용 QR 발급/관리 화면이 필요해지면 `admin.html` 내부 모달 또는 별도 페이지로 신규 구현 필요.
