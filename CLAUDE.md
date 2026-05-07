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
| `gs_assets_v` | 자산 스키마 버전 | admin 전용 |

### 자산 데이터의 두 계보 (주의)

같은 "자산"이 파일마다 다르게 시드됨:

- `index.html`의 `ASSETS` — 레거시 ID(`B3-P01`, `A2-REST-M` 등) + `type` 필드. QR 딥링크(`?type=X&id=Y`)가 이 ID에 의존.
- `admin.html`의 `DEFAULT_ASSETS` — 순차 ID(`A001`–`A008`), `type` 없음. `gs_assets_v !== '2'`이면 `gs_assets`를 **덮어씀**.

결과: admin이 먼저 로드되면 index의 QR 딥링크 ID가 사라짐. `gs_assets_v`를 올리면 사용자 데이터도 같이 리셋. 자산 스키마를 손댈 때는 두 계보를 어떻게 합치거나 마이그레이션할지부터 결정할 것.

### report.html URL 파라미터 계약

- `?qr=1&name=&model=&loc=&emoji=&aid=&cat=` — QR 스캔 경로. `cat`이 주어지면 step 1 건너뛰고 step 2부터, QR hero 카드 표시.
- `?type=X&id=Y` — 레거시 자산 연결 (localStorage 조회).
- `?category=facility|environment|it|cleaning|parking|other` — 카테고리 프리셀렉트.
- `?anon=true` — 익명 모드 프리셀렉트.

### 기타 주의

- **신고 ID**: `'RPT-' + (reports.length + 1).padStart(3,'0')`. 삭제 시 충돌 — 삭제 기능 추가하려면 ID 전략부터 바꿀 것.
- **깨진 링크**: `qr.html`은 삭제됐지만 `admin.html`의 `📱 QR관리` 버튼이 아직 `qr.html`을 가리킴. 복원할지 링크 제거할지 결정 필요.
- **test.html**은 개발용 시나리오 허브. 사용자 네비에 없고, QR 스캔/카테고리/익명 시나리오로 바로 진입.
